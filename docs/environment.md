# Environment Snapshot

This repository stores the project code, launch helpers, iPhone app, bridge, worlds,
documentation, screenshots, and demo video for the current lab state.

It does not store VM disk images, Ubuntu installers, UTM installers, Xcode build
products, or SSH keys. Those are local machine artifacts and either too large for
normal GitHub storage or unsafe to publish.

## Host

- Host OS: macOS
- Virtualization: UTM
- iPhone app IDE: Xcode
- Bridge runtime: Python 3 on macOS

## VM

- Guest OS: Ubuntu 24.04 ARM64 / aarch64
- ROS distribution: ROS 2 Jazzy
- Simulator: Gazebo Sim
- Desktop used during development: Xfce/Xubuntu-style desktop
- Typical VM memory tested: 3 GB to 4 GB

## ROS/Gazebo capabilities captured here

- OpenMANIPULATOR X Gazebo world
- OpenMANIPULATOR X random object grasp trials
- Gripper pressure regulation using joint effort
- Mobile approach/grasp world helper
- TurtleBot3 Burger + Nav2 demo media
- iPhone-to-Gazebo teleoperation server
- Mac UDP bridge from iPhone to VM

## Ubuntu packages used

The VM was built around ROS 2 Jazzy packages and common robotics tooling:

```bash
sudo apt update
sudo apt install -y \
  git curl python3-pip python3-scipy python3-colcon-common-extensions \
  ros-jazzy-desktop \
  ros-jazzy-ros-gz \
  ros-jazzy-navigation2 ros-jazzy-nav2-bringup \
  ros-jazzy-turtlebot3 ros-jazzy-turtlebot3-gazebo ros-jazzy-turtlebot3-navigation2 \
  ros-jazzy-moveit \
  ros-jazzy-open-manipulator-bringup \
  ros-jazzy-open-manipulator-description
```

Depending on the package mirror, some OpenMANIPULATOR package names may be
provided through a related metapackage. If an exact package name is unavailable,
search with:

```bash
apt search ros-jazzy-open-manipulator
```

## Restore this lab into the VM

Clone the repository in the Ubuntu VM, then run:

```bash
cd manibot-vla-lab
bash scripts/install_vm_files.sh
```

Open a new terminal after installation so `.bashrc` changes are loaded.

## Main runtime commands

```bash
omx-grasp-gz              # OpenMANIPULATOR X Gazebo world
omx-iphone-teleop-server  # UDP receiver and ROS control bridge
omx-reset-objects         # Reset/randomize grasp objects
omx-open                  # Open gripper
omx-close                 # Close gripper with pressure regulation
omx-random-grasp          # One automatic grasp
omx-random-grasp-loop     # Repeated automatic grasp trials
omx-mobile-grasp-gz       # Mobile manipulator approach/grasp world
```

On macOS, run:

```bash
python3 iphone_gazebo_bridge/iphone_gazebo_bridge.py
```

Then run the iPhone app from Xcode and send packets to the Mac IP printed by the
bridge, port `8765`.

## Local artifacts not committed

These files existed locally during setup but are intentionally not committed:

| File | SHA256 | Reason |
| --- | --- | --- |
| `UTM-4.7.5.dmg` | `a8435c93cfb5f8bbfeea4b134cfad1ac66b67632b75e438c63b1a8ae043bef0e` | Large installer; download from UTM release page |
| `ubuntu-24.04.4-live-server-arm64.iso` | `9a6ce6d7e66c8abed24d24944570a495caca80b3b0007df02818e13829f27f32` | 2.8 GB installer image; download from Ubuntu |
| `.ssh-vm/ubuntu24_codex_key` | not published | SSH private key |
| `.xcode-derived/`, `.xcode-derived-iphone-teleop/` | not published | Xcode generated build/cache output |

## Current limitation

At the time this snapshot was prepared, SSH to the VM at `192.168.64.2` was not
reachable from macOS, likely because the VM had not been started after reboot.
The repository therefore reflects the code and assets already present in the
project workspace, plus restore documentation, rather than a freshly queried VM
package dump.
