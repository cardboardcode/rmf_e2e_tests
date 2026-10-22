#!/bin/bash

# Assume simulation has been restarted.

ros2 run rmf_demos_tasks dispatch_clean -cs clean_waiting_area -F cleanerBotA -R cleanerBotA_2 --use_sim_time
ros2 run rmf_demos_tasks wait_for_task_complete -F cleanerBotA -R cleanerBotA_2 --timeout 500
ret=$?
if [ $ret -ne 0 ]; then
        echo "Test failed"
        exit -1
fi
