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

# Interrupt the task (pause). Retry to absorb the race where the task is still
# `queued` (not yet active) when we fire the interrupt right after the robot
# reports being at patrol_A2.
INTERCEPT_JSON="$(mktemp)"
echo "{\"type\": \"interrupt_task_request\", \"task_id\": \"$TASK_ID\", \"labels\": [\"pause\"]}" > "$INTERCEPT_JSON"
echo "Interrupt payload: $(cat "$INTERCEPT_JSON")"
INTERRUPT_OUT=""
for attempt in 1 2 3 4 5; do
    INTERRUPT_OUT="$(ros2 run rmf_demos_tasks api_request -f "$INTERCEPT_JSON" 2>&1)"
    echo "Interrupt attempt $attempt response: $INTERRUPT_OUT"
    if echo "$INTERRUPT_OUT" | grep -q "success.*True" && echo "$INTERRUPT_OUT" | grep -q "token"; then
        break
    fi
    echo "Retry in 2s (task may still be queued/transitioning)..."
    sleep 2
done

# Verify the response indicates success + token (task is paused).
if echo "$INTERRUPT_OUT" | grep -q "success.*True" && echo "$INTERRUPT_OUT" | grep -q "token"; then
    echo "SUCCESS: task $TASK_ID was interrupted (paused)."
else
    echo "FAILURE: interrupt task request was not accepted as expected." >&2
    exit -1
fi

# Extract the resume token returned by the interrupt request, e.g. "{'success': True, 'token': '0'}".
RESUME_TOKEN="$(sed -nE "s/.*'token': *'([0-9]+)'.*/\1/p" <<< "$INTERRUPT_OUT" | head -n1)"
if [ -z "$RESUME_TOKEN" ]; then
    echo "FAILURE: could not extract resume token from interrupt response: $INTERRUPT_OUT" >&2
    exit -1
fi
echo "Resuming task $TASK_ID with token: $RESUME_TOKEN"

# Create a temporary payload file
RESUME_JSON="$(mktemp)"
echo "{\"type\": \"resume_task_request\", \"for_task\": \"$TASK_ID\", \"for_tokens\": [\"$RESUME_TOKEN\"]}" > "$RESUME_JSON"

# Submit the resume request to Open-RMF
ros2 run rmf_demos_tasks api_request -f "$RESUME_JSON"

ros2 run rmf_demos_tasks get_robot_location -F tinyRobot -R tinyRobot2 -B coe --timeout 500
ret=$?
if [ $ret -ne 0 ]; then
        echo "Test failed"
        exit -1
fi