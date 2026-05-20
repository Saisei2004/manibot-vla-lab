# manibot-vla-lab

OpenMANIPULATOR X と Gazebo を土台に、iPhone 遠隔操作、物体把持、Nav2/MoveIt 連携、そして将来的な VLA（Vision-Language-Action）実装まで育てるためのロボット実験ラボです。

「まずは手で動かして、次に掴ませて、最後は見て考えて動くロボットへ」という流れを、ROS 2 Jazzy + Gazebo + iPhone テレオペで積み上げます。

## What Is Inside

- `omx_grasp_lab/`
  - OpenMANIPULATOR X 用の Gazebo ワールド
  - ランダム物体生成、把持、自動リセット、圧力を見ながら握るグリッパ制御
  - iPhone 操作を ROS 2 action に変換する VM 側サーバー
- `iphone_gazebo_teleop/`
  - iPhone の ARKit/CoreMotion を使った SwiftUI テレオペアプリ
  - 3D位置、手首ピッチ、グリッパ開閉を UDP で送信
- `iphone_gazebo_bridge/`
  - Mac で受けた iPhone UDP パケットを Ubuntu VM に転送するブリッジ
- `vm_launchers/`
  - VM デスクトップから起動できるランチャー
- `ubuntu-24.04-vm-setup.md`
  - UTM + Ubuntu 24.04 VM のセットアップメモ

## Current Features

- ROS 2 Jazzy / Gazebo 上の OpenMANIPULATOR X シミュレーション
- iPhone を動かしてエンドエフェクタ位置を操作
- iPhone の縦回転をエンドエフェクタのピッチへ反映
- iPhone の横向き/反転でグリッパ開閉
- グリッパの effort を見ながら、強く掴みつつ過負荷だけ逃がす圧力制御
- ランダム生成された物体に対する自動把持
- OpenMANIPULATOR X の URDF 関節可動域に基づく IK

## Quick Start

Ubuntu VM 側で Gazebo を起動します。

```bash
omx-grasp-gz
```

別ターミナルで iPhone 操作サーバーを起動します。

```bash
omx-iphone-teleop-server
```

Mac 側で UDP ブリッジを起動します。

```bash
python3 iphone_gazebo_bridge/iphone_gazebo_bridge.py
```

Xcode で `iphone_gazebo_teleop/iPhoneGazeboTeleop.xcodeproj` を開き、iPhone 実機へ Run します。アプリにはブリッジが表示する Mac IP と port `8765` を入力します。

## Useful VM Commands

```bash
omx-grasp-gz              # Gazebo world
omx-iphone-teleop-server  # iPhone teleop receiver
omx-reset-objects         # Randomize/reset objects
omx-open                  # Open gripper
omx-close                 # Close gripper with pressure regulation
omx-random-grasp          # Auto grasp current random target
omx-random-grasp-loop     # Repeat random grasp trials
```

## Roadmap

- カメラ入力と物体状態の記録
- デモ軌道収集
- 行動データセット化
- imitation learning / behavior cloning
- VLA モデルによる「見る・言う・動く」の統合
- 実機 OpenMANIPULATOR X への移行

## Note

このリポジトリには VM の SSH 秘密鍵、Ubuntu ISO、UTM installer、Xcode の DerivedData は含めません。必要な環境は各自で用意します。
