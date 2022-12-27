#!/bin/bash

proc=$(lscpu -p | grep "#" -v | wc -l)
backup_dir="logs/$(date +'%y.%m.%d-%H.%M.%S')"
mkdir -p $backup_dir

myArray=()


for ((i=0;i<30;i++))
do
    containerid=$(docker run -d aesbench)
    myArray+=($containerid)
    
    echo "$i creating container ${containerid:0:10}"
done
for i in {1..2}
do 
    for t in ${myArray[@]} 
    do  
        echo "$i running main1464 on ${t:0:10}"
        docker exec -d $t /bin/sh -c "/aes/main1464 > /aes/output.txt"
        
    done
    for t in ${myArray[@]} 
    do  
        
        x=$(docker top $t | grep main1464 | wc -l)
        while [ $x != "0" ] ;
        do
        x=$(docker top $t | grep main1464 | wc -l)
        sleep 1
        echo "waiting..."
        done
        echo "finished run $i on ${t:0:10}"

        
        docker cp $t:/aes/output.txt ./temp.txt
        cat ./temp.txt >> "./$backup_dir/${t:0:10}.txt"
    done
done

for t in ${myArray[@]} 
do  
    echo "deleting container ${t:0:10}"
    docker rm -f $t
done