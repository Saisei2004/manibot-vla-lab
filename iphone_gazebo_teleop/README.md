# iPhone Gazebo Teleop

This folder contains a small SwiftUI iOS app source for controlling the Open Manipulator X end effector from iPhone motion.

Traffic path:

1. iPhone app sends UDP JSON to the Mac bridge on port 8765.
2. Mac bridge forwards packets to the Ubuntu VM on port 8766.
3. `omx-iphone-teleop-server` converts packets to ROS 2 arm and gripper actions.

## How to run

Terminal 1 on the Ubuntu VM:

```bash
omx-grasp-gz
```

You can also use the mobile-field world:

```bash
omx-mobile-grasp-gz
```

Wait until Gazebo and the Open Manipulator controllers are ready.

Terminal 2 on the Ubuntu VM:

```bash
omx-iphone-teleop-server
```

Terminal on the Mac:

```bash
python3 iphone_gazebo_bridge/iphone_gazebo_bridge.py
```

Open `iphone_gazebo_teleop/iPhoneGazeboTeleop.xcodeproj` in Xcode, select your iPhone, sign with your Apple team, and run.

In the app, enter the Mac IP printed by the bridge and port `8765`, then press Start.

## Motion mapping

- Move the iPhone forward/back: reach in/out.
- Move the iPhone left/right: move sideways.
- Raise/lower the iPhone: move up/down.
- Pitch the iPhone vertically: rotate the end effector pitch.
- Roll/flip the iPhone: open/close the gripper.

The VM side uses the OpenMANIPULATOR X URDF joint limits for IK. If a requested Cartesian pose is outside the real reachable workspace, the server keeps the last valid pose and logs `IK failed`.
