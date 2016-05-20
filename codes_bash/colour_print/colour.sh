#!/bin/bash
for i in {0..255};
do
    printf "\x1b[38;5;${i}mcolour${i}  \t";
    declare -i loop=10
    declare -i test=$i%$loop;
    if [ $test -eq $(($loop-1)) ]; then
        printf "\x1b[0m\n";
    fi;
done;
printf "\x1b[0m\n";

#for i in {0..255};
#do
#    printf "\x1b[38;5;${i}m\x1b[47mcolour${i}  \t";
#    declare -i loop=10
#    declare -i test=$i%$loop;
#    if [ $test -eq $(($loop-1)) ]; then
#        printf "\x1b[0m\n";
#    fi;
#done;
#printf "\x1b[0m\n";
