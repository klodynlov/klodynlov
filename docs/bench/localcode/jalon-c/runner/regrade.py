#!/usr/bin/env python3
"""Recorrige les essais d'un lot avec la règle de diff FINALE (dossiers d'état des agents exclus
symétriquement : .localcode-agent/ et .klody/), sans relancer d'agent.

Usage : python3 -I regrade.py <lot>  → runs/<lot>/results_regraded.jsonl
Le workspace /tmp/localcode-evals/<tâche>-<agent>-<n> doit encore exister (sinon : essai marqué non recorrigé).
"""
import json, os, re, subprocess, sys
from pathlib import Path

EVC = Path.home() / "bench-localcode/evalc"
TASKS = Path.home() / "bench-localcode/src/evals/tasks"
GRADER_PATH = f"{Path.home() / 'local-suno/.venv/bin'}:/usr/bin:/bin:/usr/sbin:/sbin"
CACHE_NOISE_RE = re.compile(r"(^|/)(__pycache__/|\.pytest_cache/|\.mypy_cache/)|\.pyc$")
STATE_DIRS = (".eval/", ".localcode-agent/", ".klody/")


def main():
    lot = sys.argv[1]
    src = EVC / "runs" / lot / "results.jsonl"
    out = (EVC / "runs" / lot / "results_regraded.jsonl").open("w")
    for line in src.read_text().splitlines():
        r = json.loads(line)
        ws = Path(f"/tmp/localcode-evals/{r['task']}-{r['agent']}-{r['n']}")
        task = TASKS / r["task"]
        if not ws.exists():
            r["regrade"] = "workspace absent"
            out.write(json.dumps(r, ensure_ascii=False) + "\n")
            continue
        st = subprocess.run(["git", "status", "--porcelain", "--untracked-files=all"], cwd=ws,
                            capture_output=True, text=True).stdout
        changed = sorted({l[3:].split(" -> ")[-1] for l in st.splitlines()
                          if l.strip() and not l[3:].startswith(STATE_DIRS) and not CACHE_NOISE_RE.search(l[3:])})
        (ws / ".eval" / "diff.txt").write_text("\n".join(changed) + ("\n" if changed else ""))
        (ws / ".eval" / "reward.json").unlink(missing_ok=True)
        subprocess.run(["bash", str(task / "tests" / "test.sh")], cwd=ws,
                       env={**os.environ, "WORKSPACE": str(ws), "TASK_DIR": str(task), "PATH": GRADER_PATH},
                       capture_output=True, text=True, timeout=300)
        rw = json.loads((ws / ".eval" / "reward.json").read_text())
        r.update(pass_initial=r["pass"], notes_initial=r["notes"], changed_initial=r["changed"],
                 pass_=None)
        r.pop("pass_")
        r["pass"], r["notes"], r["changed"], r["regrade"] = rw.get("pass"), rw.get("notes"), changed, "ok"
        out.write(json.dumps(r, ensure_ascii=False) + "\n")
    out.close()


if __name__ == "__main__":
    main()
