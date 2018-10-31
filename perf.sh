#!/bin/bash

print_usage()
{

  echo "./perf.sh 'command' 'time_in_seconds'"

}

#get parameters
duration_in_s=$(echo "$2")
command=$(echo "$1")
echo "going to call $command"

#start record and command
perf record -F 99 -a -g -- sleep $duration_in_s &
sleep 1
$command &
pid="$!"

#get memory information
./tools/stackcount.py -p $pid -df -D $duration_in_s -U c:malloc > out.stacks
./tools/mallocstacks.py -p $pid -f $duration_in_s > out.malloc &

#stop the process
sleep $((duration_in_s+5))
kill $pid

#generate kernel report
perf script > out.perf
./flamegraph/stackcollapse-perf.pl out.perf > out.folded
./flamegraph/flamegraph.pl out.folded > kernel_flamegraph.svg

#generate malloc report
./flamegraph/flamegraph.pl --color=mem --title="malloc() Flame Graph" --countname="calls" out.stacks > malloc_calls.svg
./flamegraph/flamegraph.pl --color=mem --title="malloc() bytes Flame Graph" --countname=bytes out.malloc > malloc_memory.svg

#clean up
rm -f out.perf
rm -f out.stacks
rm -f out.malloc
rm -f out.folded
rm -f perf.data
rm -f perf.data.old