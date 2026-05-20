# OpenMANIPULATOR X Grasp Lab

This adds a small Gazebo world for practicing object grasping with OpenMANIPULATOR X.

## Launch

Open two terminals.

Terminal 1:

```bash
omx-grasp-gz
```

For a random reachable object pose:

```bash
omx-random-grasp-gz
```

For repeated random trials with automatic reset after a 3 second hold:

```bash
omx-random-grasp-loop
```

Run a fixed number of trials:

```bash
omx-random-grasp-loop 5
```

Terminal 2:

```bash
omx-moveit-sim
```

For direct joint/gripper control:

```bash
omx-gui
```

## Auto Grasp

After Gazebo is fully loaded:

```bash
omx-auto-grasp
```

For the random object:

```bash
omx-random-grasp
```

This moves above the block, descends, closes the gripper, and lifts.

## Manual Sequence

After Gazebo is running:

```bash
omx-open
omx-pregrasp
omx-lower
omx-close
omx-lift
```

The world uses a high-friction cube sized for the OpenMANIPULATOR X gripper. Use MoveIt/RViz or the OpenMANIPULATOR GUI to tune the grasp if needed.
