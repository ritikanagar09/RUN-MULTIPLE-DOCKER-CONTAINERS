#!/bin/bash

proc=$(lscpu -p | grep "#" -v | wc -l)
backup_dir=$(date +'%y-%m-%d,%H.%M.%S')

myArray=()

for ((i=0;i<30;i++))
do
    containerid=$(docker run -d nbench)
    myArray+=($containerid)
    echo "creating container $containerid"
done
for i in {1..5}
do 
    for t in ${myArray[@]} 
    do  
        echo "running main64 on $t"
        docker exec -d $t /bin/sh -c "/aes/main64 > /aes/output.txt"
    done
    for t in ${myArray[@]} 
    do  
        
        x=$(docker top $t | grep main64 | wc -l)
        while [ $x != "0" ] ;
        do
        x=$(docker top $t | grep main64 | wc -l)
        sleep 1
        echo "waiting..."
        done
        echo "finished run $i on $t"

        
        docker cp $t:/aes/output.txt ./temp.txt
        cat ./temp.txt >> $t.txt
    done
done

for t in ${myArray[@]} 
do  
    echo "deleting container $t"
    docker rm -f $t
done