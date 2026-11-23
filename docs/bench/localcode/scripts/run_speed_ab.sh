#!/bin/bash
# Banc vitesse phase 1 : localcode (llama.cpp patché, drafting on/off) vs Klody (MLX) — ordre ABBA, repos 120 s.
# Usage : bash run_speed_ab.sh  (sortie : ../logs/speed_runs.jsonl + ../logs/speed_ab.log)
set -u
B=~/bench-localcode
T=$B/tools
L=$B/logs
OUT=$L/speed_runs.jsonl
AUTH=$HOME/.local/share/localcode-agent/run/auth.json
SP=$B/venv/lib/python3.12/site-packages/localcode
MODEL_LC=Qwen3.6-35B-A3B-UD-Q8_K_XL
PORT_DEF=50303
PORT_ND=50404
KEY_ND=bench-nodraft-$(date +%s)
REPS=2

key() { python3 -I -c "import json;print(json.load(open('$AUTH'))['$1'])"; }
gpu() { ioreg -r -d 1 -c IOAccelerator | grep -o '"Device Utilization %"=[0-9]*' | head -1 | cut -d= -f2; }
rest() {  # 120 s minimum, puis attendre GPU <= 10 % (max 120 s de plus)
  echo "$(date +%T) repos 120 s" ; sleep 120
  for i in $(seq 1 24); do g=$(gpu); [ "${g:-0}" -le 10 ] && break; sleep 5; done
  echo "$(date +%T) GPU avant passe = $(gpu) %"
}
bench() {  # label url model key [extra]
  PYTHONSAFEPATH= python3 -c "import sys;sys.path.insert(0,'$T');import speedbench as s;sys.argv=['x','--url','$2','--model','$3','--label','$1','--reps','$REPS','--warmup','--out','$OUT']+(['--key','$4'] if '$4' else [])+sys.argv[1:];s.main()" ${5:-}
}

echo "=== début $(date)"; sysctl -n machdep.cpu.brand_string; memory_pressure | tail -1

# Serveur sans drafting : commande EXACTE du superviseur, moins --model-draft/--spec-type, autre port/clé.
CMD=$(sed -E "s/--model-draft [^ ]+ //; s/--spec-type [^ ]+ //; s/--port $PORT_DEF/--port $PORT_ND/; s/--api-key [^ ]+/--api-key $KEY_ND/" $L/llama_cmd_default.txt)
echo "cmd nodraft: $(echo "$CMD" | sed -E 's/--api-key [^ ]+/--api-key <R>/')"
nohup $CMD > $L/server_nodraft.log 2>&1 &
ND_PID=$!
for i in $(seq 1 120); do curl -s -m 2 -H "authorization: Bearer $KEY_ND" 127.0.0.1:$PORT_ND/health | grep -q ok && break; sleep 1; done
echo "nodraft prêt (pid $ND_PID)"

KEY_DEF=$(key server_key)
rest; bench L_draft  http://127.0.0.1:$PORT_DEF/v1 $MODEL_LC "$KEY_DEF" --no-think-kwargs
rest; bench L_nodraft http://127.0.0.1:$PORT_ND/v1 $MODEL_LC "$KEY_ND" --no-think-kwargs
rest; bench L_nodraft http://127.0.0.1:$PORT_ND/v1 $MODEL_LC "$KEY_ND" --no-think-kwargs
rest; bench L_draft  http://127.0.0.1:$PORT_DEF/v1 $MODEL_LC "$KEY_DEF" --no-think-kwargs

# Libérer la RAM avant Klody : arrêter nodraft + serveur du superviseur.
kill $ND_PID; sleep 3
curl -s -m 30 -X POST -H "X-Localcode-Token: $(key control_token)" -H 'content-type: application/json' -d '{}' 127.0.0.1:8323/server/stop; echo
sleep 5; memory_pressure | tail -1

# Klody : gateway :8090, worker brain = unsloth/Qwen3.6-35B-A3B-MLX-8bit (chargé à la 1re requête).
rest; bench K_mlx8 http://127.0.0.1:8090/v1 brain ""
rest; bench K_mlx8 http://127.0.0.1:8090/v1 brain ""
curl -s -m 30 -X POST localhost:8090/admin/unload -H 'content-type: application/json' -d '{"model":"brain"}'; echo
echo "=== fin $(date)"
