#!/bin/bash

./run_server.sh &

sleep 60

eval "$(/home/$(whoami)/miniconda3/bin/conda shell.bash hook)"
conda activate grobid
grobid_client --input pdfin --output pdfout processFulltextDocument

