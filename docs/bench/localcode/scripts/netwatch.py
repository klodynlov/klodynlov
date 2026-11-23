#!/usr/bin/env python3
"""Échantillonne chaque seconde les connexions réseau des processus localcode.
Filtre : exécutable ou ligne de commande contenant 'bench-localcode' ou '.local/share/localcode'.
Sortie : JSONL (ts, pid, comm, proto, local, remote, state) + dédoublonnage en fin."""
import json, subprocess, sys, time
out = open(sys.argv[1], "a")
MARK = ("bench-localcode", ".local/share/localcode", "localcode-ui", "llama-server")
def pids():
    ps = subprocess.run(["ps", "-axo", "pid=,command="], capture_output=True, text=True).stdout
    r = {}
    for line in ps.splitlines():
        pid, _, cmd = line.strip().partition(" ")
        if any(m in cmd for m in MARK) and "netwatch" not in cmd:
            r[pid] = cmd[:160]
    return r
while True:
    p = pids()
    if p:
        ls = subprocess.run(["lsof", "-nP", "-i", "-a", "-p", ",".join(p)], capture_output=True, text=True).stdout
        for line in ls.splitlines()[1:]:
            f = line.split()
            if len(f) < 9: continue
            name = " ".join(f[8:])
            out.write(json.dumps({"ts": time.time(), "pid": f[1], "comm": f[0], "proto": f[7], "name": name, "cmd": p.get(f[1], "")}) + "\n")
        out.flush()
    time.sleep(1)
