#!/bin/bash

eval "$(/home/$(whoami)/miniconda3/bin/conda shell.bash hook)"

python3 python_demo.py

