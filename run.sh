#!/bin/bash

IMAGE_ID=$(basename $(pwd))

docker image build -t "${IMAGE_ID}" .

docker container run --rm -it -p 4000:4000 "${IMAGE_ID}"
