#!/bin/bash

proc=$(lscpu -p | grep "#" -v | wc -l)

myArray=("00cebaaebc48" "908e71444cd1")

# for ((i=0;i<2;i++))
# do
#     containerid=$(docker run -d nbench)
#     myArray+=($containerid)
#     echo $containerid
# done

for t in ${myArray[@]} 
do  
    echo $t
done