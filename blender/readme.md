# Blender

```bash
# Pull Blender container:
# https://github.com/linuxserver/docker-blender
singularity pull --dir $PWD/sif docker://lscr.io/linuxserver/blender:latest

# Pull Blender example file
# https://www.blender.org/download/demo-files/#geometry-nodes
wget https://mirror.clarkson.edu/blender/demo/geometry-nodes/fields/ball-in-grass.blend -O $PWD/input/ball-in-grass.blend

# Submit a job:
condor_submit blender.sub

# Check your queue:
condor_q netid
```
