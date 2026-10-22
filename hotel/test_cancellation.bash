#!/bin/bash

# Assume simulation has been restarted.

# Send deliveryBot_1 to [restaurant], then send tinyBot_1 to [restaurant]
ros2 run rmf_demos_tasks dispatch_go_to_place -p restaurant -F deliveryRobot -R deliveryBot_1 --use_sim_time
ros2 run rmf_demos_tasks dispatch_go_to_place -p restaurant -F tinyRobot -R tinyBot_1 --use_sim_time

# Send a follow-up task for deliveryBot_1 to [kitchen] after it completes the previous task
ros2 run rmf_demos_tasks dispatch_go_to_place -p kitchen -F deliveryRobot -R deliveryBot_1 --use_sim_time
sleep 6

# Cancel deliveryBot_1's [restaurant] task. deliveryBot_1 should move to kitchen, and [restaurant] will
# be freed up for tinyBot_1
ros2 run rmf_demos_tasks cancel_robot_task -F deliveryRobot -R deliveryBot_1
ros2 run rmf_demos_tasks wait_for_task_complete -F tinyRobot -R tinyBot_1 --timeout 500
ret=$?
if [ $ret -ne 0 ]; then
        echo "Test failed"
        exit -1
fi

# Check that deliveryBot_1 is at [kitchen]
loc=$(ros2 run rmf_demos_tasks get_robot_location -F deliveryRobot -R deliveryBot_1 --timeout 5)
echo "$loc" | grep -q 'kitchen'
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
