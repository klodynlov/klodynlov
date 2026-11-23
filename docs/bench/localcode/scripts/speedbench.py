#!/usr/bin/env python3
"""Banc de vitesse reproductible pour un endpoint OpenAI-compatible (llama-server, mlx_lm.server, gateway).

Mesures côté client, en streaming :
  - ttft_s      : envoi de la requête -> premier fragment de contenu (prefill + 1er token)
  - decode_tps  : (tokens générés - 1) / (t_dernier - t_premier)
  - total_s     : durée totale
Le nombre de tokens vient de `usage` (stream_options.include_usage) si le serveur le renvoie,
sinon du nombre de fragments (noté `tokens_source`).

Usage :
  python3 -I speedbench.py --url http://127.0.0.1:PORT/v1 --model NOM --label L [--key KEY]
          [--max-tokens 600] [--reps 1] [--warmup] [--no-think-kwargs] --out runs.jsonl
Stdlib uniquement.
"""
import argparse, json, time, urllib.request, platform, datetime

PROMPTS = {
    "P1_codegen": (
        "Write a Python module `duration.py` with a function `parse_iso8601_duration(s: str) -> datetime.timedelta` "
        "that supports PnYnMnDTnHnMnS (years=365 days, months=30 days), raises ValueError on invalid input, "
        "and include a pytest test file covering 8 cases. Output only code."
    ),
    "P2_explain": (
        "Explain to a senior backend engineer, in about 400 words, how a write-ahead log gives durability and "
        "atomicity in a database, including what happens on crash recovery and how checkpoints bound recovery time."
    ),
    "P3_refactor": (
        "Refactor the following Python code to use dataclasses and type hints, keeping behaviour identical. "
        "Return the full refactored file.\n\n```python\n"
        + "\n".join(
            f"class Item{i}:\n    def __init__(self, name, price, qty):\n        self.name = name\n"
            f"        self.price = price\n        self.qty = qty\n    def total(self):\n"
            f"        return self.price * self.qty\n    def __repr__(self):\n"
            f"        return 'Item{i}(%s, %s, %s)' % (self.name, self.price, self.qty)\n"
            for i in range(6)
        )
        + "```"
    ),
}
WARMUP = "Write a detailed, 1200-word technical essay about B-tree node splitting, with pseudocode."


def run_one(url, model, key, prompt, max_tokens, think_kwargs, timeout=600):
    body = {
        "model": model,
        "messages": [{"role": "user", "content": prompt}],
        "max_tokens": max_tokens,
        "temperature": 0,
        "seed": 42,
        "stream": True,
        "stream_options": {"include_usage": True},
    }
    if think_kwargs:
        body["chat_template_kwargs"] = {"enable_thinking": False}
    req = urllib.request.Request(
        url.rstrip("/") + "/chat/completions",
        data=json.dumps(body).encode(),
        headers={"content-type": "application/json", **({"authorization": f"Bearer {key}"} if key else {})},
    )
    t0 = time.perf_counter()
    t_first = t_last = None
    n_frag = 0
    usage = None
    text = []
    reasoning_chars = 0
    with urllib.request.urlopen(req, timeout=timeout) as r:
        for raw in r:
            line = raw.decode("utf-8", "replace").strip()
            if not line.startswith("data:"):
                continue
            data = line[5:].strip()
            if data == "[DONE]":
                break
            ev = json.loads(data)
            if ev.get("usage"):
                usage = ev["usage"]
            for ch in ev.get("choices") or []:
                d = ch.get("delta") or {}
                c = d.get("content") or ""
                rc = d.get("reasoning_content") or d.get("reasoning") or ""
                reasoning_chars += len(rc)
                if c or rc:
                    now = time.perf_counter()
                    if t_first is None:
                        t_first = now
                    t_last = now
                    n_frag += 1
                    text.append(c)
    t_end = time.perf_counter()
    ntok = (usage or {}).get("completion_tokens") or n_frag
    src = "usage" if usage and usage.get("completion_tokens") else "fragments"
    decode = (ntok - 1) / (t_last - t_first) if t_first and t_last and t_last > t_first and ntok > 1 else None
    out = "".join(text)
    return {
        "ttft_s": round(t_first - t0, 3) if t_first else None,
        "decode_tps": round(decode, 2) if decode else None,
        "total_s": round(t_end - t0, 3),
        "completion_tokens": ntok,
        "prompt_tokens": (usage or {}).get("prompt_tokens"),
        "tokens_source": src,
        "reasoning_chars": reasoning_chars,
        "think_tag_in_output": "<think>" in out,
        "output_head": out[:160],
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--url", required=True)
    ap.add_argument("--model", required=True)
    ap.add_argument("--label", required=True)
    ap.add_argument("--key")
    ap.add_argument("--max-tokens", type=int, default=600)
    ap.add_argument("--reps", type=int, default=1)
    ap.add_argument("--warmup", action="store_true")
    ap.add_argument("--no-think-kwargs", action="store_true")
    ap.add_argument("--out", required=True)
    a = ap.parse_args()
    think = not a.no_think_kwargs
    if a.warmup:
        w = run_one(a.url, a.model, a.key, WARMUP, 1200, think)
        print("warmup", a.label, w["completion_tokens"], "tok", w["decode_tps"], "tok/s", flush=True)
    with open(a.out, "a") as f:
        for rep in range(a.reps):
            for pid, p in PROMPTS.items():
                res = run_one(a.url, a.model, a.key, p, a.max_tokens, think)
                rec = {"ts": datetime.datetime.now().isoformat(timespec="seconds"), "label": a.label,
                       "prompt": pid, "rep": rep, "model": a.model, "max_tokens": a.max_tokens,
                       "host": platform.node(), **res}
                f.write(json.dumps(rec, ensure_ascii=False) + "\n")
                f.flush()
                print(a.label, pid, rep, "ttft", res["ttft_s"], "decode", res["decode_tps"],
                      "tok", res["completion_tokens"], res["tokens_source"], flush=True)


if __name__ == "__main__":
    main()
