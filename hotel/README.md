# Open-RMF High-Level Stress Tests

This folder contains bash scripts for high-level integration tests of Open-RMF. Each script dispatches tasks via `rmf_demos_tasks` (go-to-place, patrol, clean, delivery) across the fleets (`tinyRobot`, `cleanerBotA`, `deliveryRobot`) and verifies completion.

> [!NOTE]
> These stress tests are all based in the `hotel` simulation.

> [!IMPORTANT]
> All scripts assume the simulation has been **restarted** immediately before execution, so that every robot is at its default position. No robot initialization is performed inside the scripts.

## test_basic

Sends `tinyBot_1` to `lobby`, verifying that Open-RMF can plan and execute a basic navigation task seamlessly.

```mermaid
flowchart TD
    A["tinyBot_1 to lobby"] --> B["Wait tinyBot_1 complete"]
```

## test_cancellation

Creates a conflict by sending `deliveryBot_1` and then `tinyBot_1` to `restaurant`, followed by a follow-up task for `deliveryBot_1` to `kitchen`. Cancels `deliveryBot_1`'s first task halfway through, verifying that it immediately proceeds to `kitchen`, freeing up `restaurant` for `tinyBot_1`.

```mermaid
flowchart TD
    A["deliveryBot_1 to restaurant"] --> B["tinyBot_1 to restaurant (overlap conflict)"]
    B --> C["deliveryBot_1 follow-up to kitchen"]
    C --> D["Sleep 6s"]
    D --> E["Cancel deliveryBot_1 restaurant task"]
    E --> F["Wait tinyBot_1 complete"]
    F --> G["Verify deliveryBot_1 at kitchen"]
    G --> H["Wait deliveryBot_1 complete"]
```

## test_clean

Verifies that the `cleanerBotA_2` robot can properly execute a specialized cleaning task by dispatching it to `clean_waiting_area` and waiting for completion.

```mermaid
flowchart TD
    A["cleanerBotA_2 clean task at clean_waiting_area"] --> B["Wait cleanerBotA_2 complete"]
```

## test_current_waitspot

Verifies correct wait-spot behavior by dispatching `deliveryBot_1` and `tinyBot_1` to the same constrained location (`restaurant`). While `tinyBot_1` arrives at `restaurant`, `deliveryBot_1` is allocated `kitchen` as its wait spot. After `tinyBot_1` completes, the script verifies `deliveryBot_1` held position at `kitchen`.

```mermaid
flowchart TD
    A["deliveryBot_1 to restaurant"] --> B["tinyBot_1 to restaurant"]
    B --> C["Wait tinyBot_1 complete"]
    C --> D["Verify deliveryBot_1 at kitchen (wait spot)"]
    D --> E["Wait deliveryBot_1 complete"]
```

## test_delivery

Dispatches a delivery task from the `hotel_kitchen_dispenser` at `kitchen` to the `guest_receiver` ingestor at `L2_master_suite` for `deliveryBot_1`. Waits for the robot at each stop and artificially publishes the dispenser and ingestor task results (10× each) to ensure the RMF integration workflow successfully runs end-to-end.

```mermaid
flowchart TD
    A["dispatch_delivery kitchen (hotel_kitchen_dispenser) to L2_master_suite (guest_receiver)"] --> B["Wait deliveryBot_1 at kitchen"]
    B --> C["Publish ×10 dispenser_results"]
    C --> D["Wait deliveryBot_1 at L2_master_suite"]
    D --> E["Publish ×10 ingestor_results"]
    E --> F["Wait deliveryBot_1 task complete"]
```

## test_door_interact

Tests physical object interactions securely by sending `deliveryBot_1` to `kitchen` and `cleanerBotA_2` to `clean_lobby`, forcing the navigation system to orchestrate opening and closing of doors safely along the routes.

```mermaid
flowchart TD
    A["deliveryBot_1 to kitchen"] --> B["Wait deliveryBot_1 complete"]
    B --> C["cleanerBotA_2 to clean_lobby"]
    C --> D["Wait cleanerBotA_2 complete"]
```

## test_emergency_pullover

Starts a task to `restaurant` for `deliveryBot_1` and triggers an emergency alarm to force pullover behaviors. The alarm topic is selected based on `ROS_DISTRO`: `emergency_signal` (`EmergencySignal`) on rolling/lyrical/kilted, `fire_alarm_trigger` (`Bool`) on other distros. After the robot parks at `deliverybot_charger`, the alarm is disabled and the robot is expected to resume and complete its task.

```mermaid
flowchart TD
    A["deliveryBot_1 to restaurant"] --> B["Sleep 10s"]
    B --> C{"ROS_DISTRO?"}
    C -->|rolling / lyrical / kilted| D["Publish /emergency_signal is_emergency=true"]
    C -->|other| E["Publish /fire_alarm_trigger data=true"]
    D --> F["Sleep 30s (robots park)"]
    E --> F
    F --> G["Verify deliveryBot_1 parked at deliverybot_charger"]
    G --> H{"ROS_DISTRO?"}
    H -->|rolling / lyrical / kilted| I["Publish /emergency_signal is_emergency=false"]
    H -->|other| J["Publish /fire_alarm_trigger data=false"]
    I --> K["Wait deliveryBot_1 complete (resume to restaurant)"]
    J --> K
```

## test_lift_door_interact

Tests a complex, multi-modal interaction sequence by tasking `deliveryBot_1` to `L3_master_suite`, which requires seamlessly engaging first with a lift mechanism and sequentially with door modules gracefully.

```mermaid
flowchart TD
    A["deliveryBot_1 to L3_master_suite"] --> B["Wait deliveryBot_1 complete"]
```

## test_lift_interact

Specifically tests the interaction protocol with the simulated lift by sending `deliveryBot_1` to `L3_room1`, bridging multiple floors flawlessly.

```mermaid
flowchart TD
    A["deliveryBot_1 to L3_room1"] --> B["Wait deliveryBot_1 complete"]
```

## test_patrol

Issues a multi-waypoint patrol for `tinyBot_1` across `lobby` and `shop` for 2 rounds, verifying that a baseline multi-waypoint patrol task executes to completion.

```mermaid
flowchart TD
    A["tinyBot_1 patrol: lobby → shop, n=2"] --> B["Wait tinyBot_1 complete"]
    B --> C["Wait deliveryBot_1 complete"]
```
