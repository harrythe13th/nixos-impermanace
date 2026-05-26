# modules/services.nix
#
# System service configuration.
# Enable only what is needed — every extra service is state that needs
# to be audited for persistence requirements.

{ ... }:

{
  # ── OpenSSH ─────────────────────────────────────────────────────────────────
  # Host keys are persisted via modules/impermanence.nix so the fingerprint
  # stays stable across reboots.
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;  # Use SSH keys; safer default.
    };
    # Keys are persisted by impermanence.nix — no explicit hostKeys needed here
    # unless you want to move them to a different path.
  };

  # ── Firewall ─────────────────────────────────────────────────────────────────
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];    # SSH — add more ports as needed
    allowedUDPPorts = [ ];
  };

  # ── Automatic upgrades (optional) ───────────────────────────────────────────
  # Disabled by default; uncomment to enable unattended security updates.
  # system.autoUpgrade = {
  #   enable = true;
  #   flake = "github:harrythe13th/nixos-impermanence#hostname";
  #   flags = [ "--update-input" "nixpkgs" ];
  #   dates = "04:00";
  # };
}
