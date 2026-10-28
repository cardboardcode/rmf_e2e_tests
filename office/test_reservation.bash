#!/bin/bash

# Assume simulation has been restarted and custom tinyRobot_config.yaml has been utilized.

# Send tinyRobot2 to [pantry] and stay there.
ros2 run rmf_demos_tasks dispatch_go_to_place -p pantry -F tinyRobot -R tinyRobot2 --use_sim_time

ros2 run rmf_demos_tasks get_robot_location -F tinyRobot -R tinyRobot2 -B pantry --timeout 500
ret=$?
if [ $ret -ne 0 ]; then
        echo "Test failed"
        exit -1
fi

# Send tinyRobot1 to [pantry]. RMF reservation node should send it to [tinyRobot2_charger] since it is a parking spot closest to [pantry].
ros2 run rmf_demos_tasks dispatch_go_to_place -p pantry -F tinyRobot -R tinyRobot1 --use_sim_time
ros2 run rmf_demos_tasks get_robot_location -F tinyRobot -R tinyRobot1 -B tinyRobot2_charger --timeout 500
ret=$?
if [ $ret -ne 0 ]; then
        echo "Test failed"
        exit -1
fi

# Send tinyRobot2 to [lounge]. tinyRobot1 then moves to [pantry] since RMF reservation node has freed up [pantry].
ros2 run rmf_demos_tasks dispatch_go_to_place -p lounge -F tinyRobot -R tinyRobot2 --use_sim_time

ros2 run rmf_demos_tasks get_robot_location -F tinyRobot -R tinyRobot1 -B pantry --timeout 500
ret=$?
if [ $ret -ne 0 ]; then
        echo "Test failed"
        exit -1
fi

ros2 run rmf_demos_tasks get_robot_location -F tinyRobot -R tinyRobot2 -B lounge --timeout 500
ret=$?
if [ $ret -ne 0 ]; then
        echo "Test failed"
        exit -1
fi