#!/bin/bash

# Assume simulation has been restarted and custom fleet_config.yaml has been utilized.

# Send tinyRobot2 a single patrol to [coe]. Capture the output so we can extract the TASK_ID (patrol_...) from the dispatch response.
DISPATCH_OUT="$(mktemp)"
ros2 run rmf_demos_tasks dispatch_patrol -F tinyRobot -R tinyRobot2 -p coe -n 1 --use_sim_time 2>&1 | tee "$DISPATCH_OUT"

# Deducing the TASK_ID from the dispatch response.
TASK_ID="$(grep -oE "patrol_[0-9a-f-]{36}" "$DISPATCH_OUT" | head -n1 || true)"
if [ -z "$TASK_ID" ]; then
    echo "Test failed"
    exit -1
fi
echo "Task id: $TASK_ID"

# Verify the robot is driving: tinyRobot2 has to reach the waypoint [patrol_A2] on the patrol route.
ros2 run rmf_demos_tasks get_robot_location -F tinyRobot -R tinyRobot2 -B patrol_A2 --timeout 500
ret=$?
if [ $ret -ne 0 ]; then
        echo "Test failed"
        exit -1
fi
echo "tinyRobot2 is driving (reached patrol_A2)."

# Interrupt the task (pause).
INTERCEPT_JSON="$(mktemp)"
echo "{\"type\": \"interrupt_task_request\", \"task_id\": \"$TASK_ID\", \"labels\": [\"pause\"]}" > "$INTERCEPT_JSON"
echo "Interrupt payload: $(cat "$INTERCEPT_JSON")"
INTERRUPT_OUT="$(ros2 run rmf_demos_tasks api_request -f "$INTERCEPT_JSON" 2>&1)"
echo "$INTERRUPT_OUT"

# Verify the response indicates success + token (task is paused).
if echo "$INTERRUPT_OUT" | grep -q "success.*True" && echo "$INTERRUPT_OUT" | grep -q "token"; then
    echo "SUCCESS: task $TASK_ID was interrupted (paused)."
else
    echo "FAILURE: interrupt task request was not accepted as expected." >&2
    exit -1
fi

# Cancel the interrupted (paused) task.
CANCEL_OUT="$(ros2 run rmf_demos_tasks cancel_task -id "$TASK_ID" 2>&1)"
echo "$CANCEL_OUT"

if echo "$CANCEL_OUT" | grep -q "success.*True"; then
    echo "SUCCESS: task $TASK_ID was cancelled."
else
    echo "FAILURE: cancel task request was not accepted as expected." >&2
    exit -1
fi

# Send tinyRobot2 to [patrol_C].
ros2 run rmf_demos_tasks dispatch_go_to_place -F tinyRobot -R tinyRobot2 -p patrol_C  --use_sim_time

ros2 run rmf_demos_tasks get_robot_location -F tinyRobot -R tinyRobot2 -B patrol_C --timeout 500
ret=$?
if [ $ret -ne 0 ]; then
        echo "Test failed"
        exit -1
fi
