#! /usr/bin/env bash

# Some function that takes a long time to process
longprocess() {
    # Sleep up to 6 seconds
    sleep $((3 + RANDOM % 3))
    # Randomly exit with 0 or 1
    exit $((RANDOM % 2))
}

maxjobs=$(nproc)
totaljobs=16
# Producer: Run nproc concurrent processes
for n in $(seq $totaljobs); do
  ( longprocess ) &
  # echo "pid $! $(jobs | wc -l) >= ${maxjobs}"
  while (( $(jobs | wc -l) >= ${maxjobs} )); do
    sleep 0.1
    jobs > /dev/null
  done
done

# Consumer loop
consumed=1
# sleep 1
while (( ${consumed} <= ${totaljobs} )); do
  if wait $(jobs -p | head -1); then
    echo "Process ${consumed} success"
  else
    echo "Process ${consumed} fail"
  fi
  ((consumed+=1))
  # echo "consumed ${consumed}"
done
