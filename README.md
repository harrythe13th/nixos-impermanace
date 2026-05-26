# nixos-impermanence

Immutable NixOS system configuration using a **tmpfs root** and the **Impermanence** module.

Every boot starts from a clean, known state. Only paths explicitly declared in
`modules/impermanence.nix` survive across reboots. Everything else is ephemeral
by default — written to RAM and discarded on shutdown.

---

## Repository Structure

```
nixos-impermanence/
├── flake.nix                  # Entry point; pins nixpkgs + impermanence inputs
├── flake.lock                 # Locked dependency versions (auto-generated)
├── configuration.nix          # Top-level system config (hostname, locale, packages)
├── hardware-configuration.nix # Partition layout, tmpfs root, hardware settings
└── modules/
    ├── impermanence.nix       # Persistence boundary — what survives reboots
    ├── users.nix              # Declarative user accounts (mutableUsers = false)
    └── services.nix           # System services (SSH, firewall, etc.)
```

---

## Partition Layout

| Partition | Filesystem | Mount Point | Purpose |
|-----------|------------|-------------|---------|
| ESP | FAT32 | `/boot/efi` | EFI System Partition / bootloader |
| NIX | ext4 | `/nix` | Immutable Nix store |
| PERSIST | ext4 | `/persist` | Durable state — only declared paths |
| *(none)* | tmpfs (RAM) | `/` | Ephemeral root — wiped on every reboot |

---

## Boot Sequence

```
GRUB / systemd-boot
  └─▶ initrd mounts / as tmpfs (RAM)
        └─▶ NixOS activation applies declarative config
              └─▶ Impermanence bind-mounts /persist/... into /
                    └─▶ Operational system (ephemeral root + persisted paths)
```

---

## Fresh Install

### 1. Partition the disk

```bash
DISK=/dev/disk/by-id/YOUR-DISK-ID

parted $DISK -- mklabel gpt
parted $DISK -- mkpart ESP fat32 1MiB 512MiB
parted $DISK -- set 1 esp on
parted $DISK -- mkpart NIX ext4 512MiB 30GiB
parted $DISK -- mkpart PERSIST ext4 30GiB 42GiB
# Remaining space can be used for swap or left unallocated
```

### 2. Format and label partitions

```bash
mkfs.vfat  -n ESP     ${DISK}-part1
mkfs.ext4  -L NIX     ${DISK}-part2
mkfs.ext4  -L PERSIST ${DISK}-part3
```

### 3. Mount the filesystems

```bash
mount -t tmpfs none /mnt

mkdir -p /mnt/{boot/efi,nix,persist}

mount ${DISK}-part1 /mnt/boot/efi
mount ${DISK}-part2 /mnt/nix
mount ${DISK}-part3 /mnt/persist

# Pre-create directories that impermanence will bind-mount
mkdir -p /mnt/persist/{etc/nixos,var/log,home}
```

### 4. Clone this configuration

```bash
mkdir -p /mnt/etc/nixos
git clone https://github.com/harrythe13th/nixos-impermanence /mnt/etc/nixos
```

### 5. Set passwords

Edit `modules/users.nix` and fill in `initialHashedPassword` for each user:

```bash
nix-shell -p mkpasswd --run 'mkpasswd -m SHA-512'
```

### 6. Adjust hardware settings

- In `hardware-configuration.nix`: verify partition labels/UUIDs match your disk.
- In `configuration.nix`: set `networking.hostName` and `time.timeZone`.
- In `modules/users.nix`: set your username and hashed password.

### 7. Install

```bash
nixos-install --flake /mnt/etc/nixos#hostname --no-root-passwd
reboot
```

---

## Day-to-Day Usage

### Rebuild and switch (apply changes)

```bash
sudo nixos-rebuild switch --flake /etc/nixos#hostname
```

### Roll back to the previous generation

```bash
sudo nixos-rebuild switch --rollback
# or select a generation at boot from the systemd-boot / GRUB menu
```

### Audit what is accumulating in the ephemeral root

```bash
sudo ncdu -x /
```
Anything here that you care about needs a corresponding entry in `modules/impermanence.nix`.

### Add a new persistent path

Edit `modules/impermanence.nix`, add the path to `directories` or `files`, then:

```bash
sudo nixos-rebuild switch --flake /etc/nixos#hostname
```

---

## What Persists

Declared in `modules/impermanence.nix`:

| Path | Why |
|------|-----|
| `/etc/nixos` | The configuration itself |
| `/var/log` | System journals across reboots |
| `/var/lib/bluetooth` | Bluetooth device pairings |
| `/var/lib/systemd/coredump` | Crash dumps for debugging |
| `/var/lib/systemd/timers` | Periodic timer last-run tracking |
| `/etc/NetworkManager/system-connections` | Saved Wi-Fi / VPN credentials |
| `/var/lib/nixos` | UID/GID map and other NixOS module state |
| `/home` | User home directories |
| `/etc/machine-id` | Stable systemd journal host identity |
| `/etc/ssh/ssh_host_*` | SSH host key stability across reboots |

---

## References

- Graham Christensen — [Erase Your Darlings](https://grahamc.com/blog/erase-your-darlings)
- Elis Hirwing — [tmpfs as root](https://elis.nu/blog/2020/05/nixos-tmpfs-as-root/)
- Elis Hirwing — [tmpfs as home](https://elis.nu/blog/2020/06/nixos-tmpfs-as-home/)
- Will Bush — [Impermanent NixOS with VM and Flakes](https://willbush.dev/blog/impermanent-nixos/)
- mt-caret — [Opt-in State on NixOS](https://mt-caret.github.io/blog/posts/2020-06-29-optin-state.html)
- Guekka — [NixOS as a Server Part 1: Impermanence](https://guekka.github.io/nixos-server-1/)
- [NixOS Wiki: Impermanence](https://wiki.nixos.org/wiki/Impermanence)
- [nix-community/impermanence](https://github.com/nix-community/impermanence)
