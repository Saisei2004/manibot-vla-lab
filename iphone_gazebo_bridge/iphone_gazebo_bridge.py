#!/usr/bin/env python3
import argparse
import json
import socket
import time


def local_addresses():
    addrs = []
    try:
        hostname = socket.gethostname()
        for item in socket.getaddrinfo(hostname, None, socket.AF_INET):
            ip = item[4][0]
            if not ip.startswith("127.") and ip not in addrs:
                addrs.append(ip)
    except Exception:
        pass
    return addrs


def main():
    parser = argparse.ArgumentParser(description="Forward iPhone UDP teleop packets to the Ubuntu VM.")
    parser.add_argument("--listen-port", type=int, default=8765)
    parser.add_argument("--vm-host", default="192.168.64.2")
    parser.add_argument("--vm-port", type=int, default=8766)
    args = parser.parse_args()

    recv_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    recv_sock.bind(("0.0.0.0", args.listen_port))
    send_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

    print("iPhone Gazebo bridge")
    print(f"  iPhone sends to: this Mac, UDP port {args.listen_port}")
    print(f"  forwarding to:   {args.vm_host}:{args.vm_port}")
    addrs = local_addresses()
    if addrs:
        print("  try these Mac IPs in the app: " + ", ".join(addrs))
    else:
        print("  Mac IP not detected here; check System Settings > Wi-Fi > Details")
    print("waiting for packets...")

    last_log = 0.0
    count = 0
    while True:
        data, addr = recv_sock.recvfrom(2048)
        try:
            json.loads(data.decode("utf-8"))
        except Exception:
            continue
        send_sock.sendto(data, (args.vm_host, args.vm_port))
        count += 1
        now = time.monotonic()
        if now - last_log > 1.0:
            print(f"forwarded {count} packets; last from {addr[0]}:{addr[1]}")
            last_log = now


if __name__ == "__main__":
    main()
