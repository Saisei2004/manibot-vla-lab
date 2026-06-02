#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/robot_ws/worlds"
mkdir -p "$HOME/robot_ws/src"

cp "$repo_root"/omx_grasp_lab/bin/omx-* "$HOME/.local/bin/"
chmod +x "$HOME"/.local/bin/omx-*

cp "$repo_root/omx_grasp_lab/omx_grasp_lab.sdf" "$HOME/robot_ws/worlds/omx_grasp_lab.sdf"
cp "$repo_root/omx_grasp_lab/worlds/omx_mobile_grasp_lab.sdf" "$HOME/robot_ws/worlds/omx_mobile_grasp_lab.sdf"

rm -rf "$HOME/robot_ws/src/omx_mobile_lab"
cp -R "$repo_root/omx_grasp_lab/ros2_ws/src/omx_mobile_lab" "$HOME/robot_ws/src/omx_mobile_lab"

if [ -f /opt/ros/jazzy/setup.bash ] && command -v colcon >/dev/null 2>&1; then
  (
    cd "$HOME/robot_ws"
    source /opt/ros/jazzy/setup.bash
    colcon build --symlink-install --packages-select omx_mobile_lab
  )
fi

if ! grep -q 'source /opt/ros/jazzy/setup.bash' "$HOME/.bashrc"; then
  echo 'source /opt/ros/jazzy/setup.bash' >> "$HOME/.bashrc"
fi

if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.bashrc"; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
fi

echo "Installed OpenMANIPULATOR X lab files."
echo "Open a new terminal, then run: omx-grasp-gz"
