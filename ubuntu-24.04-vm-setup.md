# Ubuntu 24.04 VM Setup on This Mac

## Prepared files

- UTM installer: `UTM-4.7.5.dmg`
- Ubuntu ISO: `ubuntu-24.04.4-live-server-arm64.iso`

The Ubuntu ISO checksum was verified against Canonical's `SHA256SUMS`.

## Recommended VM settings

- VM type: Virtualize
- OS: Linux
- Architecture: ARM64 / aarch64
- CPU cores: 2
- Memory: 3072 MB
- Disk: 64 GB
- ISO: `ubuntu-24.04.4-live-server-arm64.iso`

This Mac has 8 GB memory, so 3 GB for the VM is a good first setting.

## UTM install

1. Open `UTM-4.7.5.dmg` in Finder.
2. Drag `UTM.app` to `Applications`.
3. Launch UTM.

## Create Ubuntu VM

1. In UTM, choose `Create a New Virtual Machine`.
2. Choose `Virtualize`.
3. Choose `Linux`.
4. Select `ubuntu-24.04.4-live-server-arm64.iso` as the boot ISO.
5. Set memory to `3072 MB` and CPU cores to `2`.
6. Set disk to `64 GB`.
7. Save and start the VM.

## During Ubuntu install

- Install type: Ubuntu Server
- Network: use the default
- Storage: use the entire virtual disk
- Optional packages: OpenSSH is useful if you want terminal access from macOS

After installation finishes, shut down the VM, remove/eject the ISO from the VM settings, then boot the VM again.

## Optional desktop UI

If you want a full Ubuntu desktop after the server install, log in and run:

```bash
sudo apt update
sudo apt install ubuntu-desktop
sudo reboot
```

If performance feels heavy on 8 GB RAM, use a lighter desktop:

```bash
sudo apt update
sudo apt install xubuntu-desktop
sudo reboot
```
