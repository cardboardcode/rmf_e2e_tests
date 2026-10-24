#!/bin/bash

# Assume simulation has been restarted.


# Send deliveryBot_1 to [restaurant], then send tinyBot_1 to [restaurant]
ros2 run rmf_demos_tasks dispatch_go_to_place -p restaurant -F deliveryRobot -R deliveryBot_1 --use_sim_time
ros2 run rmf_demos_tasks dispatch_go_to_place -p restaurant -F tinyRobot -R tinyBot_1 --use_sim_time

# deliveryBot_1 will be allocated to [kitchen] as its waitspot while it waits for tinyBot_1 to arrive at [restaurant]
ros2 run rmf_demos_tasks wait_for_task_complete -F tinyRobot -R tinyBot_1 --timeout 500
ret=$?
if [ $ret -ne 0 ]; then
        echo "Test failed"
        exit -1
fi

# Check that deliveryBot_1 is at [kitchen]
ros2 run rmf_demos_tasks get_robot_location -F deliveryRobot -R deliveryBot_1 -B kitchen --timeout 500
ret=$?
if [ $ret -ne 0 ]; then
        echo "Test failed"
        exit -1
fi
