#!/bin/bash
# Banc vitesse v2 : serveur llama.cpp NEUF à chaque répétition (état ngram/cache vierge),
# chaque prompt joué UNE fois par serveur. Ordre D N N D D N, repos 120 s.
# Corrige l'artefact du v1 : ngram-mod (copy drafting) réutilisait les sorties identiques (temp 0).
set -u
B=~/bench-localcode; T=$B/tools; L=$B/logs; OUT=$L/speed_runs_fresh.jsonl
PORT=50410; MODEL=Qwen3.6-35B-A3B-UD-Q8_K_XL
gpu() { ioreg -r -d 1 -c IOAccelerator | grep -o '"Device Utilization %"=[0-9]*' | head -1 | cut -d= -f2; }
rest() { sleep 120; for i in $(seq 1 24); do g=$(gpu); [ "${g:-0}" -le 10 ] && break; sleep 5; done; echo "$(date +%T) GPU=$(gpu)%"; }
run() {  # label (D|N) rep
  KEY=bench-$1-$2-$RANDOM
  if [ "$1" = D ]; then
    CMD=$(sed -E "s/--port [0-9]+/--port $PORT/; s/--api-key [^ ]+/--api-key $KEY/" $L/llama_cmd_default.txt)
  else
    CMD=$(sed -E "s/--model-draft [^ ]+ //; s/--spec-type [^ ]+ //; s/--port [0-9]+/--port $PORT/; s/--api-key [^ ]+/--api-key $KEY/" $L/llama_cmd_default.txt)
  fi
  $CMD > $L/server_fresh_$1_$2.log 2>&1 & P=$!
  for i in $(seq 1 120); do curl -s -m 2 127.0.0.1:$PORT/health | grep -q ok && break; sleep 1; done
  PYTHONSAFEPATH= python3 -c "import sys;sys.path.insert(0,'$T');import speedbench as s;sys.argv=['x','--url','http://127.0.0.1:$PORT/v1','--model','$MODEL','--label','L_$([ $1 = D ] && echo draft || echo nodraft)_fresh','--key','$KEY','--reps','1','--warmup','--no-think-kwargs','--out','$OUT'];s.main()"
  kill $P; wait $P 2>/dev/null; sleep 2
}
echo "=== début $(date)"
i=0
for c in D N N D D N; do i=$((i+1)); rest; echo "--- run $i : $c"; run $c $i; done
echo "=== fin $(date)"
