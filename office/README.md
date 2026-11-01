# Open-RMF High-Level Stress Tests — `office`

This folder contains bash scripts for high-level integration tests of Open-RMF in the `office` simulation. The script initializes robots from the `tinyRobot` fleet, dispatches tasks via `rmf_demos_tasks`, and verifies completed locations.

## Fleet configuration — `configs/tinyRobot_config.yaml`

A custom fleet config used by the tests. Key parameters:

| Parameter | Value | Notes |
|---|---|---|
| Robots | `tinyRobot1`, `tinyRobot2` | Home chargers `tinyRobot1_charger`, `tinyRobot2_charger` |
| `task_capabilities.loop` | `True` | Enables patrol tasks |
| `finishing_request` | `nothing` | Robots do not auto-park/charge on task completion (except when overridden by a task) |
| `responsive_wait` | `False` | Fleet-wide & per-robot default |
| `use_parking_reservations` | `True` | **Enabled — this is what the reservation test exercises** |
| `recharge_threshold` | `0.10` | Fleet will not operate below 10% battery |

## test_reservation

Exercises the RMF parking-reservation node (`use_parking_reservations: True`). It verifies that when a request for an occupied place is dispatched, RMF reserves the nearest parking spot instead, and that the original place becomes available as soon as the reserving robot leaves.

Sequence:

1. **`tinyRobot2` → `pantry`** and stays there (occupies the place).
2. **`tinyRobot1` → `pantry`** — the place is occupied, so the RMF reservation node sends `tinyRobot1` to `tinyRobot2_charger`, the parking spot closest to `pantry`.
3. **`tinyRobot2` → `lounge`** — `pantry` is now freed, so `tinyRobot1` moves on to `pantry`.
4. Both robots' final locations are asserted: `tinyRobot1` at `pantry`, `tinyRobot2` at `lounge`.

```mermaid
flowchart TD
    A["dispatch tinyRobot2 to pantry"] --> B["assert tinyRobot2 at pantry"]
    B --> C["dispatch tinyRobot1 to pantry"]
    C --> D["RMF reservation: tinyRobot1 diverted to tinyRobot2_charger"]
    D --> E["assert tinyRobot1 at tinyRobot2_charger"]
    E --> F["dispatch tinyRobot2 to lounge (frees pantry)"]
    F --> G["tinyRobot1 moves to pantry"]
    G --> H["assert tinyRobot1 at pantry"]
    H --> I["assert tinyRobot2 at lounge"]
```

Each assertion uses `ros2 run rmf_demos_tasks get_robot_location ... -B <place> --timeout 500` and fails the script if the robot is not at the expected location.

## test_interrupt_cancel

Exercises the task interrupt (pause) and cancel flow. It dispatches a single patrol task, pauses it while the robot is in motion via an `interrupt_task_request`, cancels the paused task, and then confirms the robot remains operational by dispatching it to a new place.

Sequence:

1. **`tinyRobot2` → patrol `coe`** (single lap) — the `TASK_ID` (`patrol_...`) is extracted from the dispatch response.
2. **Driving check** — `tinyRobot2` is asserted to reach waypoint `patrol_A2` on the patrol route, confirming the task is actually in motion.
3. **Interrupt (pause)** — an `interrupt_task_request` with the `pause` label is sent via `ros2 run rmf_demos_tasks api_request`; the response must report `success: True` and include a `token`.
4. **Cancel** — the paused task is cancelled via `ros2 run rmf_demos_tasks cancel_task`; the response must report `success: True`.
5. **Recovery check** — `tinyRobot2` → `patrol_C` and its final location at `patrol_C` is asserted, confirming the robot still accepts and completes new tasks.

```mermaid
flowchart TD
    A["dispatch patrol task to tinyRobot2 (coe)"] --> B["extract TASK_ID from response"]
    B --> C["assert tinyRobot2 at patrol_A2 (driving)"]
    C --> D["interrupt task: pause label"]
    D --> E["assert response success: True + token"]
    E --> F["cancel the paused task"]
    F --> G["assert cancel response success: True"]
    G --> H["dispatch tinyRobot2 to patrol_C"]
    H --> I["assert tinyRobot2 at patrol_C"]
```

Location assertions use `ros2 run rmf_demos_tasks get_robot_location ... -B <place> --timeout 500`, while the interrupt and cancel assertions inspect the corresponding `ros2 run` responses for a successful `success: True` — the script fails if any check is missing.

## test_interrupt_resume

Exercises the task interrupt (pause) and resume flow. It dispatches a single patrol task, pauses it while the robot is in motion via an `interrupt_task_request`, extracts the resume token from the interrupt response, and then resumes the paused task via a `resume_task_request`.

Sequence:

1. **`tinyRobot2` → patrol `coe`** (single lap) — the `TASK_ID` (`patrol_...`) is extracted from the dispatch response.
2. **Driving check** — `tinyRobot2` is asserted to reach waypoint `patrol_A2` on the patrol route, confirming the task is actually in motion.
3. **Interrupt (pause)** — an `interrupt_task_request` with the `pause` label is sent via `ros2 run rmf_demos_tasks api_request`; the request is retried up to 5 times to absorb the race where the task is still `queued` when the interrupt fires. The response must report `success: True` and include a `token`.
4. **Extract resume token** — the `token` value is parsed from the interrupt response; the script fails if it cannot be extracted.
5. **Resume** — a `resume_task_request` is submitted via `ros2 run rmf_demos_tasks api_request` referencing the `TASK_ID` and the extracted token.
6. **Recovery check** — `tinyRobot2` is asserted to return to `coe` after the resumed patrol completes, confirming the task finished after the pause was lifted.

```mermaid
flowchart TD
    A["dispatch patrol task to tinyRobot2 (coe)"] --> B["extract TASK_ID from response"]
    B --> C["assert tinyRobot2 at patrol_A2 (driving)"]
    C --> D["interrupt task: pause label (retry x5)"]
    D --> E["assert response success: True + token"]
    E --> F["extract resume token from response"]
    F --> G["submit resume_task_request with token"]
    G --> H["assert tinyRobot2 at coe"]
```

Location assertions use `ros2 run rmf_demos_tasks get_robot_location ... -B <place> --timeout 500`, while the interrupt assertion inspects the `ros2 run` response for a successful `success: True` and an extractable `token` — the script fails if any check is missing.

## Prerequisites

- RMF simulation with the `office` map and the `tinyRobot` fleet running (simulation must use the config in `configs/tinyRobot_config.yaml`).
- ROS 2 environment with `rmf_demos_tasks` available.
- Simulation time enabled (`--use_sim_time`).

## Usage

```bash
cd office
chmod +x test_reservation.bash test_interrupt_cancel.bash test_interrupt_resume.bash
./test_reservation.bash
./test_interrupt_cancel.bash
./test_interrupt_resume.bash
```

The scripts print `Test failed` (or a `FAILURE: ...` line) and exit non-zero if any assertion fails or times out.
