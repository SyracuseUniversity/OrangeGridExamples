#!/bin/bash

eval "$(/home/$( whoami )/miniconda3/bin/conda shell.bash hook)"  
conda activate tf-gpu

python3 tensorflow_demo.py

# singularity exec --nv sif/tensorflow_latest-gpu.sif python3 tensorflow_demo.py

