# Project Manifest

This is the current public snapshot of the Manibot VLA Lab work.

## Included

- `README.md`
  - Research direction, architecture, milestones, demo media, and quick start.
- `ubuntu-24.04-vm-setup.md`
  - UTM + Ubuntu 24.04 ARM64 VM setup notes.
- `docs/environment.md`
  - Environment snapshot, package notes, restore instructions, and local artifact hashes.
- `docs/media/`
  - Nav2 screenshot.
  - OpenMANIPULATOR X grasp demo video.
  - README-friendly GIF preview.
- `iphone_gazebo_bridge/`
  - Python UDP bridge from iPhone packets on the Mac to the Ubuntu VM.
- `iphone_gazebo_teleop/`
  - SwiftUI/Xcode iPhone app.
  - ARKit/CoreMotion-based 3D end-effector teleoperation.
  - Gripper control from device orientation.
  - Custom app icon assets.
- `omx_grasp_lab/`
  - OpenMANIPULATOR X Gazebo worlds.
  - ROS 2 helper scripts for launch, grasping, pressure-regulated gripper control, random object reset, mobile approach, and iPhone teleop.
  - `omx_mobile_lab` ROS 2 package for the mobile manipulator launch helper.
- `vm_launchers/`
  - Desktop launcher examples for common VM-side gripper commands.
- `scripts/install_vm_files.sh`
  - Restore/install helper for copying repository scripts and worlds into a fresh Ubuntu VM.

## Excluded

- SSH private keys.
- Ubuntu ISO images.
- UTM installer DMGs.
- VM disk images.
- Xcode DerivedData/build outputs.
- Python bytecode caches.
- ROS build/install/log directories.

## Network layout used during development

```text
iPhone app
  -> Mac UDP :8765
  -> iphone_gazebo_bridge.py
  -> Ubuntu VM UDP :8766
  -> omx-iphone-teleop-server
  -> ROS 2 actions/controllers
  -> Gazebo OpenMANIPULATOR X
```

The VM IP used during development was `192.168.64.2`. The bridge prints the
candidate Mac IPs to enter into the iPhone app.

## Research state

The repository is not a finished product. It is a lab notebook plus runnable
codebase for moving from manual teleoperation to VLA-oriented data collection:

1. Simulate a robot body and workspace.
2. Navigate with TurtleBot3/Nav2.
3. Grasp with OpenMANIPULATOR X.
4. Teleoperate from iPhone motion.
5. Record actions, observations, and outcomes.
6. Train imitation/VLA models from collected behavior.
