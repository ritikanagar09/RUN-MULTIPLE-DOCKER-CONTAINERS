#!/bin/bash

docker exec -d  d99a5a8f6cdd /bin/sh -c "/aes/main64 >> /aes/log.txt" 
docker top d99a5a8f6cdd | grep "/bin/sh -c /aes/main64 >> /aes/log.txt" # displays the running commands of the container 