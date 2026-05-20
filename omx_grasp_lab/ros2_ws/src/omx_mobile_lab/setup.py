from setuptools import setup

package_name = "omx_mobile_lab"

setup(
    name=package_name,
    version="0.0.1",
    packages=[package_name],
    data_files=[
        ("share/ament_index/resource_index/packages", [f"resource/{package_name}"]),
        (f"share/{package_name}", ["package.xml"]),
        (f"share/{package_name}/launch", ["launch/mobile_open_manipulator_gz.launch.py"]),
    ],
    install_requires=["setuptools"],
    zip_safe=True,
    maintainer="mani_bot",
    maintainer_email="mani_bot@example.com",
    description="Mobile grasp launch helpers for OpenMANIPULATOR X lab.",
    license="Apache-2.0",
)
