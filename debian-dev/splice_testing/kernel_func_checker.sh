#! /usr/bin/env bash

# Extracts unresolved symbols for a Loadable Kernel Module (LKM)
# then checks systemtap to see if those symbols are available
# in the kernel symbol map, returning only those which are able
# to be tapped.
# Note: one may also append a '?' to the function
# in the stap script to denote optional probes:
#   probe kernel.function("foo")? , kernel.function("bar"), ...  { println(pp()) }
# or check faster with:
#   stap -l 'kernel.function("foo"),kernel.function("bar"),kernel.function("schedule")'
#   stap -l 'kernel.{function("foo"),function("bar"),function("schedule")}'
#
# Usage: Insert your path to .ko file path for $kernel_calls
#
# nm -u for unresolved symbols
# Sequential Producer Consumer to run it the checks in parallel
#
# 2016-09-07 Joe Gorse

# found bdi_init strncpy_from_user __test_set_page_writeback
# failed cpu_tss current_kernel_time64 current_task

kernel_calls=$(nm -u /vagrant/openafs/src/libafs/MODLOAD-4.7.0-MP/libafs.ko | awk '{print $2}')

# kernel_calls="bdi_init cpu_tss current_kernel_time64 current_task strncpy_from_user system_freezing_cnt system_wq __test_set_page_writeback"
kernel_calls_arr=( $kernel_calls )

maxjobs=$(nproc)
totaljobs=0
pids=()
# Producer: Run nproc concurrent processes
for func in ${kernel_calls}; do
  ( stap -l 'kernel.function("'${func}'")' > /dev/null ) &
  ((totaljobs+=1))
  pids+=("$!")
  while (( $(jobs | wc -l) >= ${maxjobs} )); do
    sleep 0.1
    jobs > /dev/null
  done
done

# Consumer loop
consumed=0
while (( ${consumed} < ${totaljobs} )); do
  if wait ${pids[$consumed]}; then
    echo "${kernel_calls_arr[$consumed]}"
  fi
  ((consumed+=1))
done

# Single threaded
# for func in ${kernel_calls}; do
#   ( stap -l 'kernel.function("'${func}'")' > /dev/null )
#   if (( $? == 0 )) ; then
#     echo "found ${kernel_calls_arr[$totaljobs]}"
#   else
#     echo "failed ${kernel_calls_arr[$totaljobs]}"
#   fi
#   ((totaljobs+=1))
# done
