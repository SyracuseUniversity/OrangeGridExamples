#!/bin/bash

eval "$(/home/$(whoami)/miniconda3/bin/conda shell.bash hook)"

# If you installed R into a virtual environment you would need to activate it here:
# conda activate rbase   

Rscript r_demo.R


