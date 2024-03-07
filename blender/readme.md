# Blender
Blender is a free and open-source 3D computer graphics software toolset used for creating animated films, visual effects, art, 3D printed models, motion graphics, interactive 3D applications, virtual reality, and computer games.

https://www.blender.org/

## Setup
```bash
# Pull Blender container:
# https://github.com/linuxserver/docker-blender
singularity pull --dir $PWD/sif docker://lscr.io/linuxserver/blender:latest

# Pull Blender example file
# https://www.blender.org/download/demo-files/#geometry-nodes
wget https://mirror.clarkson.edu/blender/demo/geometry-nodes/fields/ball-in-grass.blend -O $PWD/input/ball-in-grass.blend
```

## Usage
```bash
# Submit a job:
condor_submit blender.sub

# Check your queue:
condor_q netid
```
