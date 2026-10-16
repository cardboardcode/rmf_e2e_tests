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

# Start a patrol task for deliveryBot_1 to [restaurant]
ros2 run rmf_demos_tasks dispatch_go_to_place -p restaurant -F deliveryRobot -R deliveryBot_1 --use_sim_time
sleep 10

# Trigger the emergency signal. deliveryBot_1 should find a free spot to park which is [deliverybot_charger].
case "$ROS_DISTRO" in
    rolling|lyrical|kilted)
        ros2 topic pub /emergency_signal rmf_fleet_msgs/msg/EmergencySignal "{\"is_emergency\": true, \"fleet_names\": []}" --once --qos-reliability reliable --qos-durability transient_local
        ;;
    *)
        ros2 topic pub /fire_alarm_trigger std_msgs/msg/Bool "{data: true}" --once --qos-reliability reliable --qos-durability transient_local
        ;;
esac
sleep 30

# Check that deliveryBot_1 is at [deliverybot_charger]
ros2 run rmf_demos_tasks get_robot_location -F deliveryRobot -R deliveryBot_1 -B deliverybot_charger --timeout 500
ret=$?
if [ $ret -ne 0 ]; then
        echo "Test failed"
        exit -1
fi

# Switch off the emergency signal. deliveryBot_1 should continue its task to reach [restaurant].
case "$ROS_DISTRO" in
    rolling|lyrical|kilted)
        ros2 topic pub /emergency_signal rmf_fleet_msgs/msg/EmergencySignal "{\"is_emergency\": false, \"fleet_names\": []}" --once --qos-reliability reliable --qos-durability transient_local
        ;;
    *)
        ros2 topic pub /fire_alarm_trigger std_msgs/msg/Bool "{data: false}" --once --qos-reliability reliable --qos-durability transient_local
        ;;
esac

ros2 run rmf_demos_tasks wait_for_task_complete -F deliveryRobot -R deliveryBot_1 --timeout 500
ret=$?
if [ $ret -ne 0 ]; then
        echo "Test failed"
        exit -1
fi
