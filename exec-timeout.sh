#!/bin/bash

function exec_timeout()
# $1 = min timeout
# $2... = command + arguments
{
    START=$(( $(date +%s%N) / 1000000 ))
    TIMEOUT=$1
    DELTA=0
    shift;

    #execute command    
    $@

    while [ $DELTA -le $TIMEOUT ]; do 
      END=$(( $(date +%s%N) / 1000000 ))
      DELTA=$(( $END - $START ))
    done
    
}

exec_timeout 1000 echo "ciao"
 
