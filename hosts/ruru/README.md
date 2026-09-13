# 🦉 ruru — Hardware Specifications & Architecture

`ruru` is a dedicated loginless media kiosk running NixOS on a **Lenovo ThinkCentre M720q Tiny**, connected via HDMI to a Samsung TV. It runs **Jellyfin Media Player** in TV mode inside the lightweight **Cage** Wayland compositor with automated TPM2 LUKS full-disk encryption, hardware-accelerated video decoding, and display power-saving via `swayidle`.

---

## ⚙️ Hardware Specifications

| Component | Specification | Details / Notes |
| :--- | :--- | :--- |
| **Chassis / Model** | Lenovo ThinkCentre M720q Tiny | Ultra-compact 1-liter desktop |
| **Processor (CPU)** | Intel Core 8th / 9th Gen (Coffee Lake) | 65W/35W low-power desktop APU |
| **Graphics (iGPU)** | Intel UHD Graphics 630 | Intel QuickSync Video & VA-API (`intel-media-driver` / `iHD`) |
| **Video Output** | HDMI / DisplayPort | Output directly to Samsung TV (Audio + Video) |
| **Audio** | Intel HD Audio via PipeWire | HDMI multi-channel audio & 3.5mm analog out |
| **Network Interfaces** | Intel I219-V Gigabit Ethernet + Intel Wi-Fi | Managed via `iwd` (wireless) / `systemd-networkd` |
| **Security Chip** | Discrete TPM 2.0 | Automated LUKS2 volume auto-decryption on boot |
| **Primary Storage** | M.2 NVMe SSD (`/dev/nvme0n1`) | LUKS2 encrypted Btrfs with stateless `tmpfs` root |

---

## 💽 Storage & Filesystem Architecture

```
Drive: /dev/nvme0n1 (M.2 NVMe SSD)
├── /dev/nvme0n1p1 (500 MiB FAT32) ──────────────── /boot (EFI System Partition)
└── /dev/nvme0n1p2 (LUKS2 Container 'crypted')
    ├── / (tmpfs, 8 GiB RAM) ────────────────────── Ephemeral stateless root
    ├── subvol=@nix ──────────────────────────────── /nix (Nix Store, zstd:1)
    ├── subvol=@persistent ───────────────────────── /persistent (Preserved state, SSH keys, Wi-Fi keys, Jellyfin session)
    ├── subvol=@swap ─────────────────────────────── /swap (16 GiB swapfile)
    ├── subvol=@tmp ──────────────────────────────── /tmp (Temporary files)
    └── subvolid=5 ───────────────────────────────── /btr_pool
```

---

## 📺 Kiosk & Power Management Architecture

- **Display Compositor:** **Cage** (Wayland kiosk compositor) runs on TTY1 under the `ruru` user.
- **Media Player:** **Jellyfin Media Player** starts automatically in 10-foot Big Screen mode (`--tv`).
- **Idle & Power Saving:**
  - **`swayidle`** monitors user activity and turns off HDMI display output via `wlopm --off "*"` after 15 minutes of inactivity.
  - **Playback Protection:** During media playback, Jellyfin Media Player requests Wayland idle inhibition (`zwp_idle_inhibit_manager_v1`), ensuring the screen never blanks while shows or movies are playing.
  - As soon as input is detected (or casting begins), `swayidle` triggers `wlopm --on "*"`, instantly turning the display back on.
- **Remote SSH Administration:** OpenSSH is active and authorized for `rhys@whio`, enabling headless maintenance, updates, and troubleshooting from `whio`.

---

## 🔗 Related Documentation

- 📖 [**ruru Installation Guide**](file:///home/factory/.nixos/hosts/ruru/INSTALL.md) — Step-by-step clean installation and TPM2 enrollment runbook.
