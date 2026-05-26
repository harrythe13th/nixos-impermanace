# modules/impermanence.nix
#
# Declares the persistence boundary for the tmpfs root system.
#
# RULE: anything NOT listed here is written to the ephemeral tmpfs root
# and will be GONE after the next reboot. Add paths here deliberately
# and only when their state genuinely needs to survive reboots.
#
# The impermanence module bind-mounts every declared path from /persist
# into the ephemeral root at Stage 3 of the boot sequence.

{ config, ... }:

{
  # Required so that bind-mounts are invisible to df/findmnt (cleaner UX).
  programs.fuse.userAllowOther = true;

  environment.persistence."/persist" = {
    # Hide the bind-mount entries from df and findmnt output.
    hideMounts = true;

    # ── Persistent directories ─────────────────────────────────────────────
    directories = [
      # NixOS configuration — your flake lives here on the running system.
      "/etc/nixos"

      # System journals — keeps journalctl history across reboots.
      "/var/log"

      # Bluetooth pairing data — avoids re-pairing devices after every reboot.
      "/var/lib/bluetooth"

      # systemd crash dumps — useful for post-mortem debugging.
      "/var/lib/systemd/coredump"

      # systemd persistent timers (e.g. OnCalendar= last-run tracking).
      "/var/lib/systemd/timers"

      # NetworkManager saved connections — avoids re-entering Wi-Fi passwords.
      "/etc/NetworkManager/system-connections"

      # nixos-module user tracking state (UID/GID map, etc.).
      "/var/lib/nixos"

      # User home directories.
      # Remove this if you want /home on its own partition or its own tmpfs.
      "/home"
    ];

    # ── Persistent files ───────────────────────────────────────────────────
    files = [
      # machine-id is used by systemd to correlate journal entries across
      # boots. Without persistence, journalctl -b -1 will not work.
      "/etc/machine-id"

      # SSH host keys — persisting these keeps the host fingerprint stable
      # so remote clients don't get a "host key changed" warning after reboot.
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
    ];
  };
}
