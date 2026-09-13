# 🛠️ ruru — NixOS Installation Guide

This document provides a step-by-step runbook for performing a clean NixOS installation on the **`ruru`** host (Lenovo ThinkCentre M720q Tiny) configured as a loginless Jellyfin media kiosk using Disko, Impermanence, and TPM2 LUKS auto-unlock.

---

## 📋 Host Overview

- **Host Target:** `ruru`
- **Chassis:** Lenovo ThinkCentre M720q Tiny
- **Primary User:** `ruru`
- **Role:** Loginless Jellyfin Kiosk with Cage Wayland compositor and HDMI output to TV
- **Target Drive:** `/dev/nvme0n1` (Change to `/dev/sda` in `hosts/ruru/disko.nix` if using 2.5" SATA)
- **Encryption:** LUKS2 (`crypted`) auto-unlocked via TPM 2.0
- **Filesystem:** Btrfs with `tmpfs` stateless root

---

## 🚀 Installation Runbook

### Step 1: Boot & Connect to Network

1. Insert the NixOS Live USB into the Lenovo M720q, power on, and press **F12** to enter the boot menu.
2. Select the UEFI USB drive.
3. Open a terminal (or switch to virtual console) and elevate to root:
   ```bash
   sudo -i
   ```
4. Connect to network:
   - **Ethernet**: DHCP is active automatically.
   - **Wi-Fi**:
     ```bash
     systemctl start iwd
     iwctl
     # In iwctl:
     station wlan0 scan
     station wlan0 get-networks
     station wlan0 connect "Your-SSID"
     quit
     ```
5. Verify connectivity:
   ```bash
   ping -c 3 nixos.org
   ```

> [!TIP]
> **Optional — Remote Access from whio during install:**
> If you wish to execute the installation commands remotely from `whio`:
> ```bash
> passwd root
> systemctl start sshd
> ip -br addr
> ```
> Then from `whio`: `ssh root@<lenovo-ip>`.

---

### Step 2: Clone Configuration Repository

Clone this configuration repository:

```bash
git clone https://github.com/factoryidiot/.nixos.git ~/.nixos
cd ~/.nixos
```

---

### Step 3: Prepare Disk with Disko

1. Verify target disk device name (`/dev/nvme0n1` or `/dev/sda`):
   ```bash
   lsblk
   ```
   *(If your drive is `/dev/sda`, update the `device = "/dev/nvme0n1";` line in `hosts/ruru/disko.nix`)*.

2. Execute automated Disko partitioning:
   ```bash
   nix --experimental-features "nix-command flakes" \
     run github:nix-community/disko/latest -- \
     --mode disko \
     ./hosts/ruru/disko.nix
   ```

   > [!NOTE]
   > Disko will prompt you to set a LUKS2 passphrase. This passphrase acts as your recovery key before TPM2 enrollment and will remain as a fallback.

3. Enable and verify the swapfile:
   ```bash
   swapon /mnt/swap/swapfile
   swapon -s
   ```

4. Verify active mounts:
   ```bash
   lsblk
   df -h
   ```

---

### Step 4: Generate Hardware UUIDs

1. Scan system hardware:
   ```bash
   nixos-generate-config --root /mnt
   ```

2. Export partition and filesystem UUIDs directly into helper file `hosts/ruru/UUID`:
   ```bash
   cat <<EOF > hosts/ruru/UUID
     BOOT_ESP_UUID  = "$(blkid -s UUID -o value /dev/nvme0n1p1)"; # FAT32 EFI partition
     NVME_LUKS_UUID = "$(blkid -s UUID -o value /dev/nvme0n1p2)"; # LUKS partition
     BTRFS_UUID     = "$(blkid -s UUID -o value /dev/mapper/crypted)"; # Decrypted BTRFS filesystem
   EOF
   cat hosts/ruru/UUID
   ```
   *(If using SATA `/dev/sda`, adjust device names to `/dev/sda1` and `/dev/sda2`)*.

3. Update the `let` block in [`hosts/ruru/hardware-configuration.nix`](file:///home/factory/.nixos/hosts/ruru/hardware-configuration.nix) to match the UUIDs generated above.

4. Remove the temporary template directory:
   ```bash
   rm -rf /mnt/etc/nixos/*
   ```

---

### Step 5: Execute NixOS Installation

1. Stage local changes in git:
   ```bash
   git add .
   ```

2. Run the NixOS installer targeting `ruru`:
   ```bash
   nixos-install --root /mnt --no-root-password --flake .#ruru --no-write-lock-file
   ```

---

### Step 6: Post-Installation Persistence Setup

Prepare the persistent directories so essential state and SSH host keys survive the stateless tmpfs reboot:

1. Create persistent directory structure:
   ```bash
   mkdir -p /mnt/persistent/home/ruru/.nixos
   mkdir -p /mnt/persistent/etc
   ```

2. Move generated host SSH keys to persistent storage:
   ```bash
   mv /mnt/etc/ssh /mnt/persistent/etc/
   ```

3. Copy the repository to persistent user storage:
   ```bash
   cp -r ~/.nixos/* ~/.nixos/.* /mnt/persistent/home/ruru/.nixos/ 2>/dev/null || cp -r ~/.nixos /mnt/persistent/home/ruru/
   ```

4. Set proper file ownership (`1000:100` for user `ruru`):
   ```bash
   chown -R 1000:100 /mnt/persistent/home/ruru
   ```

---

### Step 7: Reboot & TPM2 LUKS Auto-Unlock Setup

1. Reboot the system:
   ```bash
   reboot
   ```

2. Upon reboot, enter your LUKS passphrase when prompted.
3. The system will automatically log into Cage and start Jellyfin Media Player in Big Screen TV mode under user `ruru`.
4. From `whio`, SSH into `ruru` as root (authenticated with your `rhys@whio` SSH key):
   ```bash
   ssh root@<ruru-ip>
   ```
   *(Note: User `ruru` is an unprivileged kiosk account without sudo access. Administration and updates from `whio` are performed directly via `ssh root@<ruru-ip>`)*.

5. Enroll the TPM 2.0 security chip for automatic passwordless unlocking:
   ```bash
   systemd-cryptenroll --tpm2-device auto --tpm2-pcrs "0+2+7+12" /dev/disk/by-uuid/<NVME_LUKS_UUID>
   ```
6. Reboot once more to verify unattended, passwordless boot straight into the Jellyfin kiosk:
   ```bash
   reboot
   ```
