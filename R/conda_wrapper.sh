#!/bin/bash

eval "$(/home/$(whoami)/miniconda3/bin/conda shell.bash hook)"

conda activate rbase   

Rscript r_demo.R


