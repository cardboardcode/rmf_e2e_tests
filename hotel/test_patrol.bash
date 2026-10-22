#!/bin/bash

# NOTE: Test with finishing request set to [nothing]
# Initialize robot positions
ros2 run rmf_demos_tasks dispatch_go_to_place -p tinybot_charger -F tinyRobot -R tinyBot_1 --use_sim_time
ros2 run rmf_demos_tasks dispatch_go_to_place -p cleanerbot_charger1 -F cleanerBotA -R cleanerBotA_1 --use_sim_time
ros2 run rmf_demos_tasks dispatch_go_to_place -p cleanerbot_charger2 -F cleanerBotA -R cleanerBotA_2 --use_sim_time
ros2 run rmf_demos_tasks dispatch_go_to_place -p deliverybot_charger -F deliveryRobot -R deliveryBot_1 --use_sim_time
ros2 run rmf_demos_tasks wait_for_task_complete -F tinyRobot -R tinyBot_1 --timeout 500
ros2 run rmf_demos_tasks wait_for_task_complete -F cleanerBotA -R cleanerBotA_1 --timeout 500
ros2 run rmf_demos_tasks wait_for_task_complete -F cleanerBotA -R cleanerBotA_2 --timeout 500
ros2 run rmf_demos_tasks wait_for_task_complete -F deliveryRobot -R deliveryBot_1 --timeout 500
ret=$?
if [ $ret -ne 0 ]; then
        echo "Test failed"
        exit -1
fi

# Start a multi-waypoint patrol task for tinyBot_1 to [lobby], then to [shop]
ros2 run rmf_demos_tasks dispatch_patrol -F tinyRobot -R tinyBot_1 -p lobby shop -n 2 --use_sim_time

ros2 run rmf_demos_tasks wait_for_task_complete -F tinyRobot -R tinyBot_1 --timeout 500
ret=$?
if [ $ret -ne 0 ]; then
        echo "Test failed"
        exit -1
fi
ros2 run rmf_demos_tasks wait_for_task_complete -F deliveryRobot -R deliveryBot_1 --timeout 500
ret=$?
if [ $ret -ne 0 ]; then
        echo "Test failed"
        exit -1
fi