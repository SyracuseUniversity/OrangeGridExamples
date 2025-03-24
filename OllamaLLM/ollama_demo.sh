#!/bin/bash

# Ensure HOME is set correctly
export HOME=/home/$(whoami)

# Load environment variables
source ~/.bashrc

# Activate Conda environment (adjust path as needed)
eval "$(/home/$(whoami)/miniconda3/bin/conda shell.bash hook)" # Or miniforge depending on how you installed Conda
conda activate base  # Replace with the actual Conda environment name

# Start Ollama server in the background
echo "Starting Ollama server..."
nohup $HOME/bin/ollama/ollama serve > $HOME/ollama/server/ollama_server.log 2>&1 &

# Startup Timuing
timeout=120   # Total time to wait, in seconds
elapsed=0
while ! curl -s http://localhost:11434/api/tags > /dev/null; do
    echo "Waiting for Ollama... ($elapsed seconds)"
    sleep 10 # check every 10 seconds
    elapsed=$((elapsed + 10)) # increment elapsed time with sleep timer
    if [ "$elapsed" -ge "$timeout" ]; then
        echo "Ollama did not start within $timeout seconds"
        exit 1
    fi
done

# Define the question
QUESTION="What is HTCondor?"

# Echo the question into the output file
echo "Question: $QUESTION"

# Run inference using the preloaded model
echo "Running inference..."
$HOME/bin/ollama/ollama run gemma3 "$QUESTION" # Or appropriate model name, run '~/bin/ollama/ollama list' to review

# Shut down Ollama after inference
echo "Shutting down Ollama..."
pkill -f "ollama serve"
