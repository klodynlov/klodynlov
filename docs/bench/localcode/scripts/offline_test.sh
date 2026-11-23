#!/bin/bash
# Test hors ligne localcode : attend la coupure réseau, la prouve, lance localcode, journalise.
L=~/bench-localcode/logs; LOG=$L/offline_test.log
echo "$(date '+%F %T') attente de la coupure réseau (coupe le Wi-Fi)..." | tee -a $LOG
while curl -s -m 3 -o /dev/null https://huggingface.co; do sleep 2; done
echo "$(date '+%F %T') HORS LIGNE confirmé : curl huggingface.co échoue ; route = $(route -n get default 2>&1 | grep -E 'interface|not in table' | xargs)" | tee -a $LOG
date +%s > $L/t0_offline
cd ~/bench-localcode/repo-offline
echo "$(date '+%F %T') lancement localcode --model qwen-q8" | tee -a $LOG
~/bench-localcode/venv/bin/localcode --model qwen-q8
echo "$(date '+%F %T') localcode quitté (code $?) ; réseau : $(curl -s -m 3 -o /dev/null -w '%{http_code}' https://huggingface.co || echo hors-ligne)" | tee -a $LOG
git -C ~/bench-localcode/repo-offline status --short | tee -a $LOG
echo "Tu peux rallumer le Wi-Fi." | tee -a $LOG
