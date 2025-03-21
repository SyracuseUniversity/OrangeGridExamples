#!/bin/bash

# Ensure HOME is set correctly
export HOME=/home/$(whoami)

# Set Ollama model directory (using the pre-downloaded model)
export OLLAMA_MODELS=$HOME/.ollama/models

# Load environment variables
source ~/.bashrc

# Activate Conda environment (adjust path as needed)
eval "$(/home/$(whoami)/miniconda3/bin/conda shell.bash hook)" # Or miniforge depending on how you installed Conda
conda activate base  # Replace with the actual Conda environment name

# Start Ollama server in the background
echo "Starting Ollama server..."
nohup $HOME/bin/ollama/ollama serve > $HOME/ollama/server/ollama_server.log 2>&1 &
sleep 5  # Give it time to start

# Define the question
QUESTION="What is HTCondor?"

# Echo the question into the output file
echo "Question: $QUESTION"

# Run inference using the preloaded model
echo "Running inference..."
$HOME/bin/ollama/ollama run gemma3:1b "QUESTION" # Or replace with appropriate model, deepseek example below
# deepseek-r1 example: $HOME/bin/ollama/ollama run deepseek-r1 "$QUESTION"

# Shut down Ollama after inference
echo "Shutting down Ollama..."
pkill -f "ollama serve"
