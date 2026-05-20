#!/usr/bin/env python3
import json
import math
import os
from pathlib import Path

from ament_index_python.packages import get_package_share_directory
from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument
from launch.actions import IncludeLaunchDescription
from launch.actions import RegisterEventHandler
from launch.actions import SetEnvironmentVariable
from launch.event_handlers import OnProcessExit
from launch.launch_description_sources import PythonLaunchDescriptionSource
from launch.substitutions import LaunchConfiguration
from launch_ros.actions import Node
import xacro


GRASP_DISTANCE = 0.226


def mobile_base_goal():
    target_path = Path.home() / ".ros/omx_mobile_grasp_target.json"
    if not target_path.exists():
        return 0.0, 0.0, 0.0
    target = json.loads(target_path.read_text())
    tx, ty = target["x"], target["y"]
    yaw = math.atan2(ty, tx)
    return (
        tx - math.cos(yaw) * GRASP_DISTANCE,
        ty - math.sin(yaw) * GRASP_DISTANCE,
        yaw,
    )


def generate_launch_description():
    open_manipulator_description_path = get_package_share_directory("open_manipulator_description")
    open_manipulator_bringup_path = get_package_share_directory("open_manipulator_bringup")
    ros_gz_sim_launch = os.path.join(get_package_share_directory("ros_gz_sim"), "launch", "gz_sim.launch.py")

    base_x, base_y, _base_yaw = mobile_base_goal()

    gazebo_resource_path = SetEnvironmentVariable(
        name="GZ_SIM_RESOURCE_PATH",
        value=[
            os.path.join(open_manipulator_bringup_path, "worlds"),
            ":" + str(Path(open_manipulator_description_path).parent.resolve()),
            ":" + str((Path.home() / "robot_ws/worlds").resolve()),
        ],
    )

    arguments = LaunchDescription([
        DeclareLaunchArgument("world", default_value=str(Path.home() / "robot_ws/worlds/omx_mobile_grasp_lab"), description="Gz sim world without .sdf"),
    ])

    gazebo = IncludeLaunchDescription(
        PythonLaunchDescriptionSource([ros_gz_sim_launch]),
        launch_arguments=[
            ("gz_args", [LaunchConfiguration("world"), ".sdf", " -v 1", " -r"])
        ],
    )

    xacro_file = os.path.join(
        open_manipulator_description_path,
        "urdf",
        "open_manipulator_x",
        "open_manipulator_x.urdf.xacro",
    )
    doc = xacro.process_file(xacro_file, mappings={"use_sim": "true"})
    robot_desc = doc.toprettyxml(indent="  ")

    robot_state_publisher = Node(
        package="robot_state_publisher",
        executable="robot_state_publisher",
        output="screen",
        parameters=[{"robot_description": robot_desc}],
    )

    gz_spawn_entity = Node(
        package="ros_gz_sim",
        executable="create",
        output="screen",
        arguments=[
            "-string",
            robot_desc,
            "-x",
            f"{base_x:.5f}",
            "-y",
            f"{base_y:.5f}",
            "-z",
            "0.0",
            "-R",
            "0.0",
            "-P",
            "0.0",
            "-Y",
            "0.0",
            "-name",
            "open_manipulator_x",
            "-allow_renaming",
            "false",
            "-use_sim",
            "true",
        ],
    )

    joint_state_broadcaster_spawner = Node(
        package="controller_manager",
        executable="spawner",
        arguments=["joint_state_broadcaster", "--controller-manager", "/controller_manager"],
        output="screen",
    )

    arm_controller_spawner = Node(
        package="controller_manager",
        executable="spawner",
        arguments=["arm_controller"],
        output="screen",
    )

    gripper_controller_spawner = Node(
        package="controller_manager",
        executable="spawner",
        arguments=["gripper_controller"],
        output="screen",
    )

    bridge = Node(
        package="ros_gz_bridge",
        executable="parameter_bridge",
        arguments=["/clock@rosgraph_msgs/msg/Clock[gz.msgs.Clock"],
        output="screen",
    )

    return LaunchDescription([
        RegisterEventHandler(
            event_handler=OnProcessExit(
                target_action=gz_spawn_entity,
                on_exit=[joint_state_broadcaster_spawner],
            )
        ),
        RegisterEventHandler(
            event_handler=OnProcessExit(
                target_action=joint_state_broadcaster_spawner,
                on_exit=[arm_controller_spawner, gripper_controller_spawner],
            )
        ),
        bridge,
        gazebo_resource_path,
        arguments,
        gazebo,
        robot_state_publisher,
        gz_spawn_entity,
    ])
