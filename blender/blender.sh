#!/bin/bash

# Returns rendering device type based on detected hardware
check_nvidia_gpu() {
    local gpu_info=$(lspci | grep -i 'NVIDIA')

    case "$gpu_info" in
        *NVIDIA*)
            echo "CUDA CPU"
            ;;
        "")
            echo "CPU"
            ;;
        *)
            echo "CPU"
            ;;
    esac
}

# Call the function and save its output to a variable
RENDER_DEVICE=$(check_nvidia_gpu)
echo $RENDER_DEVICE

### Local paths
# Path to blender container
BLENDER_PATH=$PWD/sif/blender_latest.sif
# Path to input
INPUT_PATH=$PWD/input
# Path to output
OUTPUT_PATH=$PWD/output
# Input file name
INPUT_FILE=ball-in-grass.blend


# Every frame
singularity exec --nv --bind $INPUT_PATH:/input,$OUTPUT_PATH:/output $BLENDER_PATH blender -b /input/$INPUT_FILE --enable-autoexec -E CYCLES -F PNG -o /output/frame_##### -f $((Frame++)) -- --cycles-device $RENDER_DEVICE --cycles-print-stats

# Every 10th frame 
#singularity exec --nv --bind $WORKING_PATH:/work $BLENDER_PATH blender -b $INPUT_PATH --enable-autoexec -E CYCLES -F PNG -o $OUTPUT_PATH/frame_##### -f $((Frame*10)) -- --cycles-device $RENDER_DEVICE --cycles-print-stats

# Specific frame 
#singularity exec --nv --bind $WORKING_PATH:/work $BLENDER_PATH blender -b $INPUT_PATH --enable-autoexec -E CYCLES -F PNG -o $OUTPUT_PATH/frame_##### -f 100 -- --cycles-device $RENDER_DEVICE --cycles-print-stats

# Entire project on one node
#singularity exec --nv --bind $WORKING_PATH:/work $BLENDER_PATH blender -b $INPUT_PATH --enable-autoexec -E CYCLES -F PNG -o $OUTPUT_PATH/frame_##### -a -- --cycles-device $RENDER_DEVICE --cycles-print-stats

exit
