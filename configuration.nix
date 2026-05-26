# configuration.nix
# Main NixOS system configuration.
# Imports hardware settings and all sub-modules.

{ config, pkgs, lib, ... }:

{
  imports = [
    ./modules/impermanence.nix
    ./modules/users.nix
    ./modules/services.nix
  ];

  # ── System identity ─────────────────────────────────────────────────────────
  networking.hostName = "hostname"; # ← change to your hostname
  time.timeZone = "Asia/Kolkata";   # ← change to your timezone
  i18n.defaultLocale = "en_IN";

  # ── Boot loader ─────────────────────────────────────────────────────────────
  # Using systemd-boot (EFI). Switch to GRUB below if needed.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  # Keep the last N generations in the boot menu for rollback.
  boot.loader.systemd-boot.configurationLimit = 10;

  # Uncomment to use GRUB instead of systemd-boot:
  # boot.loader.grub = {
  #   enable = true;
  #   efiSupport = true;
  #   device = "nodev";
  #   configurationLimit = 10;
  # };

  # ── Nix settings ────────────────────────────────────────────────────────────
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };

  # Periodic garbage collection keeps /nix from growing unboundedly.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # ── Networking ──────────────────────────────────────────────────────────────
  networking.networkmanager.enable = true;

  # ── Base packages ───────────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    git
    vim
    curl
    wget
    htop
    tree
    ncdu    # useful for auditing what's accumulating in the tmpfs root
  ];

  # ── State version ───────────────────────────────────────────────────────────
  # Do NOT change this after initial install — it controls stateful migration.
  system.stateVersion = "24.11";
}
