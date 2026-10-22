#!/bin/bash

# Assume simulation has been restarted.

# Start a multi-waypoint patrol task for tinyBot_1 to [lobby], then to [shop]
ros2 run rmf_demos_tasks dispatch_patrol -F tinyRobot -R tinyBot_1 -p lobby shop -n 2 --use_sim_time

ros2 run rmf_demos_tasks wait_for_task_complete -F tinyRobot -R tinyBot_1 --timeout 500
ret=$?
if [ $ret -ne 0 ]; then
        echo "Test failed"
        exit -1
fi