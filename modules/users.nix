# modules/users.nix
#
# User account configuration.
#
# IMPORTANT on a tmpfs root: user accounts MUST be declared here.
# Any user created imperatively (useradd, passwd, etc.) will vanish
# on the next reboot because /etc/passwd and /etc/shadow live on the
# ephemeral root unless you explicitly persist them (not recommended —
# declare users declaratively instead).
#
# Password note: use `initialHashedPassword` (not `initialPassword`)
# in production. Generate a hash with:
#   nix-shell -p mkpasswd --run 'mkpasswd -m SHA-512'

{ pkgs, ... }:

{
  # Disallow imperative user/group mutations (adduser, passwd, etc.).
  # All users must be declared in this file.
  users.mutableUsers = false;

  # ── Root account ────────────────────────────────────────────────────────────
  # Set a hashed password or disable root login in production.
  users.users.root = {
    # Generate with: nix-shell -p mkpasswd --run 'mkpasswd -m SHA-512'
    # Replace the string below with your actual hash.
    initialHashedPassword = "";   # ← set this before installing
  };

  # ── Primary user ────────────────────────────────────────────────────────────
  users.users.harpartap = {        # ← change to your username
    isNormalUser = true;
    description = "Harpartap Singh Sandhu";
    # Generate with: nix-shell -p mkpasswd --run 'mkpasswd -m SHA-512'
    initialHashedPassword = "";    # ← set this before installing
    extraGroups = [
      "wheel"           # sudo access
      "networkmanager"  # manage network connections without sudo
      "audio"
      "video"
    ];
    shell = pkgs.bash;
  };

  # Allow members of the wheel group to use sudo.
  security.sudo.wheelNeedsPassword = true;
}
