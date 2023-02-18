0. Prepare a 64-bit nixos [minimal iso image](https://channels.nixos.org/nixos-22.11/latest-nixos-minimal-x86_64-linux.iso) and burn it, then enter the live system. Suppose I have divided two partitions `/dev/vda1` `/dev/vda2` 

[![Push Blog](https://github.com/ruixi-rebirth/flakes/actions/workflows/push_blog.yml/badge.svg)](https://ruixi-rebirth.github.io) 

<p align="center"><img src="https://user-images.githubusercontent.com/75824585/210402874-da3422d5-ab65-4975-b73a-c300065c6792.png" width=300px></p>
<h2 align="center">Ruixi-rebirth's NixOS Config</h2>
<p align="center"><img src="https://user-images.githubusercontent.com/75824585/196195007-ecebb290-2c6b-4fab-9e1e-2dbb12f7eb44.png" width=300px></p>


### 系统组件
||NixOS(Wayland)|Nixos(Xorg)|
| - | :--: | :--: |
|**Window Manager**|[Sway](https://github.com/swaywm/sway), [Hyprland](https://github.com/hyprwm/Hyprland)|[bspwm](https://github.com/baskerville/bspwm)|
|**Terminal Emulator**|[Kitty](https://github.com/kovidgoyal/kitty)|[Kitty](https://github.com/kovidgoyal/kitty)|
|**Bar**|[Waybar](https://github.com/Alexays/Waybar)|[Polybar](https://github.com/polybar/polybar)|
|**Application Launcher**|[Rofi-wayland](https://github.com/lbonn/rofi)|[rofi](https://github.com/polybar/polybar)|
|**Notification Daemon**|[Mako](https://github.com/emersion/mako)|[Dunst](https://github.com/dunst-project/dunst)|
|**Display Manager**|None(TTY1 Login)|None(TTY1 Login)|
|**network management tool**|[NetworkManager](https://networkmanager.dev/)|[NetworkManager](https://networkmanager.dev/)|
|**Input method framework**|[Fcitx5](https://github.com/fcitx/fcitx5)|[Fcitx5](https://github.com/fcitx/fcitx5)|
|**System resource monitor**|[Btop](https://github.com/aristocratos/btop)|[Btop](https://github.com/aristocratos/btop)|
|**File Manager**|[Ranger](https://github.com/ranger/ranger), [Nemo](https://github.com/linuxmint/nemo)|[Ranger](https://github.com/ranger/ranger), [Nemo](https://github.com/linuxmint/nemo)|
|**Lockscreen**|[Swaylock-effects](https://github.com/mortie/swaylock-effects)|[i3lock-fancy](https://github.com/meskarune/i3lock-fancy)|
|**Shell**|[Fish](https://github.com/fish-shell/fish-shell)|[Fish](https://github.com/fish-shell/fish-shell)|
|**Music Player**|[mpd](https://github.com/MusicPlayerDaemon/MPD), [ncmpcpp](https://github.com/ncmpcpp/ncmpcpp), [mpc](https://github.com/MusicPlayerDaemon/mpc), [Netease-cloud-music-gtk](https://github.com/gmg137/netease-cloud-music-gtk)|[mpd](https://github.com/MusicPlayerDaemon/MPD), [ncmpcpp](https://github.com/ncmpcpp/ncmpcpp), [mpc](https://github.com/MusicPlayerDaemon/mpc), [Netease-cloud-music-gtk](https://github.com/gmg137/netease-cloud-music-gtk)|
|**Media Player**|[mpv](https://github.com/mpv-player/mpv)|[mpv](https://github.com/mpv-player/mpv)|
|**Text Editor**|[Neovim](https://github.com/neovim/neovim)|[Neovim](https://github.com/neovim/neovim)|
|**Icons**|[Papirus](https://github.com/PapirusDevelopmentTeam/papirus-icon-theme)|[Papirus](https://github.com/PapirusDevelopmentTeam/papirus-icon-theme)|
|**Fonts**|[Nerd fonts](https://github.com/ryanoasis/nerd-fonts)|[Nerd fonts](https://github.com/ryanoasis/nerd-fonts)|
|**Image Viewer**|[imv](https://sr.ht/~exec64/imv/)|[feh](https://feh.finalrewind.org/)|
|**Screenshot Software**|[grimshot](https://github.com/swaywm/sway/blob/master/contrib/grimshot),[grimblast](https://github.com/hyprwm/contrib)|[flameshot](https://github.com/flameshot-org/flameshot)|
|**Screen Recording**|[wf-recorder](https://github.com/ammen99/wf-recorder), [OBS](https://obsproject.com)|[OBS](https://obsproject.com)|
|**Clipboard**|[wl-clipboard](https://github.com/bugaevc/wl-clipboard)|[xclip](https://opensource.com/article/19/7/xclip)|
|**Color Picker**|[hyprpicker](https://github.com/hyprwm/hyprpicker)||

### 窗口管理器

**sway & hyprland**

https://user-images.githubusercontent.com/75824585/201473117-578af0df-e4ea-4dc9-91a6-c30281d46e7a.mp4

sway 与 hyprland 外观一致,此处展示的是hyprland

**bspwm**

### 主题

> hyprland & sway 

**catppuccin-light**
![2023-01-12T02:21:59](https://user-images.githubusercontent.com/75824585/211895195-e0a47165-e635-4256-922c-17d7da1ed62e.png)

**catppuccin-dark**
![2023-01-12T03:00:29](https://user-images.githubusercontent.com/75824585/211895280-41d12bfe-453c-41da-a2a6-3f7f483ea8ad.png)

**nord**
![2023-01-17T00:15:22](https://user-images.githubusercontent.com/75824585/212723937-c56200da-52f4-407b-9d8e-428348ed5ed0.png)


*安装主题任意选择一个即可：具体见[这里](https://github.com/Ruixi-rebirth/flakes/blob/main/hosts/laptop/wayland/home.nix#L11-L13)*

> bspwm 

只有nord主题

### 目录结构
```
.
├── flake.lock
├── flake.nix
├── hosts
│   ├── default.nix
│   ├── laptop
│   └── system.nix
├── modules
│   ├── desktop
│   ├── devlop
│   ├── editors
│   ├── environment
│   ├── fonts
│   ├── hardware
│   ├── programs
│   ├── scripts
│   ├── shell
│   ├── theme
│   └── virtualisation
├── overlays
│   └── default.nix
├── pkgs
│   ├── catppuccin-cursors
│   ├── catppuccin-gtk
│   └── default.nix
├── README_en.md
├── README.md
└── screenshot
    └── screenshot.png
```

### 如何安装？
最小安装(包含wm,没有tmpfs as root)，前往[此处](https://github.com/Ruixi-rebirth/flakes/tree/minimal)

### 如何安装?(root on tmpfs)


0. 准备一个64位的nixos [minimal iso image](https://channels.nixos.org/nixos-22.11/latest-nixos-minimal-x86_64-linux.iso) 烧录好,然后进入live系统。假设我已经分好两个分区`/dev/nvme0n1p1` `/dev/nvme0n1p3`
1. 格式化分区

1. Format the partition 
```bash
mkfs.fat -F 32 /dev/vda1 
mkfs.ext4 /dev/vda2
```
2. Moount 
```bash 
mount /dev/vda2 /mnt 
mkdir /mnt/boot 
mount /dev/vda1 /mnt/boot
```
3. Generate a basic configuration 
```bash
nixos-generate-config --root /mnt
```
4. Clone the repository locally 
```bash
nix-shell -p git
git clone  https://github.com/Ruixi-rebirth/flakes.git --branch=minimal /mnt/etc/nixos/Flakes 
cd /mnt/etc/nixos/Flakes/
nix develop --extra-experimental-features nix-command --extra-experimental-features flakes 
```
5. Copy `hardware-configuration.nix` from /mnt/etc/nixos to /mnt/etc/nixos/Flakes/hosts/laptop/hardware-configuration.nix 
```bash 
cp /mnt/etc/nixos/hardware-configuration.nix /mnt/etc/nixos/Flakes/hosts/laptop/hardware-configuration.nix
```
6. remove '/mnt/etc/nixos/Flakes/.git' 
```bash 
rm -rf .git
```
7. Username modification: edit `/mnt/etc/nixos/Flakes/flake.nix` to modify **user** variable, hostname modification: edit `/mnt/etc/nixos/Flakes/hosts/system.nix` to modify* The **hostName** value in the **networking** property group

8. Use the hash password generated by the `mkpasswd {PASSWORD} -m sha-512` command to replace the value of `users.users.<name>.hashedPassword` in `/mnt/etc/nixos/Flakes/hosts/laptop/{wayland | x11}/default.nix` ( there is two place needs to be displace )

9. Install bspwm or hyprland see [here](https://github.com/Ruixi-rebirth/flakes/blob/44b2d4cf868dbce743e714e47dbf4975c13fe958/hosts/default.nix#L17-L18) and [here](https://github.com/Ruixi-rebirth/flakes/blob/44b2d4cf868dbce743e714e47dbf4975c13fe958/hosts/default.nix#L31-L32) 

10. Perform install
```bash
nixos-install --no-root-passwd --flake .#laptop
```

11. Reboot 
```bash
reboot
```

12. Enjoy it!

