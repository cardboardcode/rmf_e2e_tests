#!/bin/bash

# Assume simulation has been restarted.

ros2 run rmf_demos_tasks dispatch_go_to_place -p kitchen -F deliveryRobot -R deliveryBot_1 --use_sim_time
ros2 run rmf_demos_tasks wait_for_task_complete -F deliveryRobot -R deliveryBot_1 --timeout 200
ret=$?
if [ $ret -ne 0 ]; then
        echo "Test failed"
        exit -1
fi

ros2 run rmf_demos_tasks dispatch_go_to_place -p clean_lobby -F cleanerBotA -R cleanerBotA_2 --use_sim_time
ros2 run rmf_demos_tasks wait_for_task_complete -F cleanerBotA -R cleanerBotA_2 --timeout 200
ret=$?
if [ $ret -ne 0 ]; then
        echo "Test failed"
        exit -1
fi
