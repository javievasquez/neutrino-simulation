#!/usr/bin/env bash
set -euo pipefail

# Uso: ./simulate.sh [N=1000] [SLEEP=0]
N=${1:-1000}
SLEEP=${2:-0}
OUTDIR="events"
EVENTS_CSV="$OUTDIR/events.csv"
RESULTS_FILE="results.txt"
PERF_FILE="performance.txt"

mkdir -p "$OUTDIR"
: > "$EVENTS_CSV"

start=$(date +%s.%N)

for ((i=1;i<=N;i++)); do
  idx=$(printf "%04d" "$i")
  fname="$OUTDIR/$idx.txt"
  epoch=$(date +%s.%N)
  human=$(date +"%Y-%m-%d %H:%M:%S %z")
  neutrinos=$((RANDOM % 11))   # 0..10

  printf "timestamp_epoch:%s\ntimestamp_human:%s\nneutrinos:%d\n" \
    "$epoch" "$human" "$neutrinos" > "$fname"

  printf "%s,%s,%d\n" "$idx" "$epoch" "$neutrinos" >> "$EVENTS_CSV"

  if [ "$SLEEP" != "0" ]; then
    sleep "$SLEEP"
  fi
done

: > "$RESULTS_FILE"
for ((i=1;i<=N;i++)); do
  idx=$(printf "%04d" "$i")
  printf "=== Event %s ===\n" "$idx" >> "$RESULTS_FILE"
  cat "$OUTDIR/$idx.txt" >> "$RESULTS_FILE"
  printf "\n" >> "$RESULTS_FILE"
done

avg_interval=$(awk -F, 'NR==1{prev=$2; next} {diff=$2-prev; sum+=diff; n++; prev=$2} END{ if(n>0) printf "%.6f", sum/n; else print "0"}' "$EVENTS_CSV")

end=$(date +%s.%N)
runtime=$(awk -v s="$start" -v e="$end" 'BEGIN{printf "%.6f", e - s}')

cat > "$PERF_FILE" <<EOF
N_events: $N
average_interval_seconds: $avg_interval
script_runtime_seconds: $runtime
generated_at: $(date +"%Y-%m-%d %H:%M:%S %z")
EOF

echo "Done: $N files -> $OUTDIR/, $RESULTS_FILE, $PERF_FILE"
