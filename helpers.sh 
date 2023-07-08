#!/bin/bash

# ntopng after downloading it from ECR

apt install redis-server -y

docker run -itd -p 3000:3000  --net=host public.ecr.aws/y2f4h6b6/ntop -i eth0 --community