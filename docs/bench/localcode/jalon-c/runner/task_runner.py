#!/usr/bin/env python3
"""Runner minimal du jalon C, SANS Inspect AI : tâches au format localcode/evals, pour localcode ET Klody.

Reproduit le contrat de `evals/localcode_evals/agent.py:run_trial` :
  workspace/ copié dans /tmp/localcode-evals/<tâche>-<agent>-<n> → git init + commit → .eval/ créé
  → agent lancé (consigne = instruction.md, 1 tour) → .eval/diff.txt (git status --porcelain, même filtre)
  + final.txt → `bash tests/test.sh` (WORKSPACE, TASK_DIR) → .eval/reward.json.
Agents : localcode via `localcode-ui run` sans --auto (comme son harnais officiel, agent.py:309) ;
Klody via WebSocket d'une instance de test isolée, approbations TOUTES accordées (politique « humain qui
approuve les actions demandées » ; Klody demande avant chaque écriture/exécution).

Usage : python3 -I task_runner.py <nom_lot> <agent> <tâche>[,<tâche>…] <n_essais>
Résultats : ~/bench-localcode/evalc/runs/<nom_lot>/results.jsonl
"""
import json, os, re, shutil, subprocess, sys, time, urllib.request
from pathlib import Path

EVC = Path.home() / "bench-localcode/evalc"
TASKS = Path.home() / "bench-localcode/src/evals/tasks"
PY_LC = Path.home() / "bench-localcode/venv/bin/python"
PY_KL = Path.home() / "Projets/klody-code-ai/.venv/bin/python"
# python3 du grader épinglé (FABLE : sinon c'est celui du shell courant) : venv avec pytest 9.0.3.
GRADER_PY = Path.home() / "local-suno/.venv/bin"
GRADER_PATH = f"{GRADER_PY}:/usr/bin:/bin:/usr/sbin:/sbin"
# Dossiers d'état des agents (.localcode-agent/, .klody/) exclus symétriquement du diff.
CACHE_NOISE_RE = re.compile(r"(^|/)(__pycache__/|\.pytest_cache/|\.mypy_cache/)|\.pyc$")  # agent.py:63


def budget_of(task: Path) -> int:
    m = re.search(r"^budget_seconds\s*=\s*(\d+)", (task / "task.toml").read_text(), re.M)
    return int(m.group(1)) if m else 900


def turns_of(instruction: str) -> list[str]:  # agent.py:257-260
    if "## Turn 1" in instruction:
        return [s.strip() for s in re.split(r"^## Turn \d+\s*$", instruction, flags=re.M) if s.strip()]
    return [instruction.strip()]


def git(ws: Path, *a):
    return subprocess.run(["git", "-c", "user.email=e@x", "-c", "user.name=e", *a], cwd=ws, capture_output=True, text=True)


def peak_rss_sampler(out: Path, stop_file: Path, pat: tuple):
    """Échantillonne toutes les 0,5 s la RSS cumulée des processus de l'agent (llama-server / python klody / MLX)."""
    code = f'''
import subprocess, time, pathlib
pat = {pat!r}
peak = 0
while not pathlib.Path({str(stop_file)!r}).exists():
    ps = subprocess.run(["ps", "-axo", "rss=,command="], capture_output=True, text=True).stdout
    tot = sum(int(l.split(None, 1)[0]) for l in ps.splitlines() if any(p in l for p in pat))
    peak = max(peak, tot)
    time.sleep(0.5)
pathlib.Path({str(out)!r}).write_text(str(peak))
'''
    return subprocess.Popen(["python3", "-I", "-c", code])


def run(lot: str, agent: str, task_id: str, n: int) -> dict:
    task = TASKS / task_id
    meta_toml = (task / "task.toml").read_text()
    instr = (task / "instruction.md").read_text()
    turns = turns_of(instr)
    assert len(turns) == 1, f"{task_id} : multi-tour non géré par ce runner"
    ws = Path(f"/tmp/localcode-evals/{task_id}-{agent}-{n}")
    if ws.exists():
        shutil.rmtree(ws)
    shutil.copytree(task / "workspace", ws)
    git(ws, "init", "-q"); git(ws, "add", "-A"); git(ws, "commit", "-qm", "init", "--allow-empty")
    ev = ws / ".eval"; ev.mkdir(exist_ok=True)
    essai = EVC / "runs" / lot / agent / task_id / f"essai-{n}"
    (essai / "_etat").mkdir(parents=True, exist_ok=False)
    pf = essai / "_etat" / "prompt.txt"
    pf.write_text(turns[0])
    budget = budget_of(task)
    env = {**os.environ, "BENCH_PROMPT_FILE": str(pf), "BENCH_BUDGET_S": str(budget)}
    stop = essai / "_etat" / ".stop"; peak_f = essai / "_etat" / "peak_rss_kb.txt"
    # RSS (inclut les pages mmap du modèle) des seuls processus de l'agent testé.
    pat = ("bin/llama-server", "bin/localcode-ui") if agent == "localcode" else ("uvicorn.run(s.app", "mlx_server_guarded")  # Klody : tous les workers MLX résidents
    sampler = peak_rss_sampler(peak_f, stop, pat)
    t0 = time.time()
    if agent == "localcode":
        h = subprocess.run([str(PY_LC), "-I", str(EVC / "run_localcode.py"), str(essai), str(ws.resolve()), "A"],
                           env=env, capture_output=True, text=True, timeout=budget + 400)
    else:
        if agent == "klody-brain":
            env["BENCH_KLODY_MODEL"] = "brain"
        h = subprocess.run([str(PY_KL), str(EVC / "run_klody.py"), str(essai), str(ws.resolve()), "B"],
                           env=env, capture_output=True, text=True, timeout=budget + 400)
    wall = time.time() - t0
    stop.write_text("1"); sampler.wait(timeout=10)
    # Contrat .eval (agent.py:378-384)
    status = git(ws, "status", "--porcelain", "--untracked-files=all").stdout
    changed = sorted({l[3:].split(" -> ")[-1] for l in status.splitlines()
                      if l.strip() and not l[3:].startswith((".eval/", ".localcode-agent/", ".klody/")) and not CACHE_NOISE_RE.search(l[3:])})
    ev.mkdir(exist_ok=True)
    (ev / "diff.txt").write_text("\n".join(changed) + ("\n" if changed else ""))
    meta = json.loads((essai / "_etat" / "meta.json").read_text()) if (essai / "_etat" / "meta.json").exists() else {}
    # final.txt = tout le texte du tour (comme agent.py:339,363) ; Klody : jetons texte du flux WS.
    final = ""
    if agent == "localcode" and (essai / "_etat" / "run.jsonl").exists():
        parts = []
        for l in (essai / "_etat" / "run.jsonl").read_text(errors="replace").splitlines():
            if l.startswith("{"):
                try:
                    e = json.loads(l)
                except ValueError:
                    continue
                if e.get("type") == "text":
                    parts.append((e.get("part") or {}).get("text", ""))
        final = "\n".join(parts).strip()
    served = {}
    if agent.startswith("klody") and (essai / "_etat" / "events.jsonl").exists():
        for l in (essai / "_etat" / "events.jsonl").read_text().splitlines():
            e = json.loads(l)
            if e.get("type") == "message_stats":
                served[e.get("model")] = served.get(e.get("model"), 0) + 1
    if agent.startswith("klody") and (essai / "_etat" / "events.jsonl").exists():
        final = "".join(str(json.loads(l).get("content", "")) for l in (essai / "_etat" / "events.jsonl").read_text().splitlines()
                        if json.loads(l).get("type") == "token").strip()
    (ev / "final.txt").write_text(final)
    for name in ("commands.log", "ui_errors.txt"):  # vides, comme verify_oracles.py:15
        (ev / name).write_text("")
    g = subprocess.run(["bash", str(task / "tests" / "test.sh")], cwd=ws,
                       env={**os.environ, "WORKSPACE": str(ws), "TASK_DIR": str(task), "PATH": GRADER_PATH},
                       capture_output=True, text=True, timeout=300)
    try:
        reward = json.loads((ev / "reward.json").read_text())
    except Exception as e:
        reward = {"pass": None, "notes": f"reward.json illisible : {e!r} ; rc={g.returncode} {g.stderr[-300:]}"}
    # Copie du dépôt final pour audit.
    shutil.copytree(ws, essai / "workspace_final", ignore=shutil.ignore_patterns(".git"))
    return {"lot": lot, "agent": agent, "task": task_id, "n": n, "pass": reward.get("pass"), "notes": reward.get("notes"),
            "changed": changed, "wall_s": round(wall, 1), "agent_s": meta.get("agent_s"),
            "timeout": meta.get("timeout"), "harness_rc": h.returncode, "harness_err": h.stderr.strip()[-500:],
            "peak_rss_gb": round(int(peak_f.read_text()) / 1024 / 1024, 1) if peak_f.exists() else None,
            "budget_s": budget, "served_models": served, "pinned": meta.get("pinned"), "grader_python": str(GRADER_PY / "python3"), "final_len": len(final), "purpose": re.search(r'^purpose\s*=\s*"(\w+)"', meta_toml, re.M).group(1)}


def unload_brain():
    try:
        req = urllib.request.Request("http://127.0.0.1:8090/admin/unload", data=b'{"model":"brain"}',
                                     headers={"content-type": "application/json"})
        return urllib.request.urlopen(req, timeout=60).read().decode()
    except OSError as e:
        return f"unload impossible : {e}"


def main():
    lot, agent, tasks, n = sys.argv[1], sys.argv[2], sys.argv[3].split(","), int(sys.argv[4])
    out = (EVC / "runs" / lot); out.mkdir(parents=True, exist_ok=True)
    if agent == "localcode":
        print("déchargement brain :", unload_brain(), flush=True)
    with (out / "results.jsonl").open("a") as f:
        for i in range(1, n + 1):
            for t in tasks:
                r = run(lot, agent, t, i)
                f.write(json.dumps(r, ensure_ascii=False) + "\n"); f.flush()
                print(time.strftime("%T"), agent, t, i, "pass", r["pass"], "wall", r["wall_s"], "rss", r["peak_rss_gb"],
                      "rc", r["harness_rc"], (r["notes"] or "")[:80], flush=True)
                time.sleep(20)  # petit repos entre essais
    if agent.startswith("klody"):
        print("déchargement brain :", unload_brain(), flush=True)


if __name__ == "__main__":
    main()
