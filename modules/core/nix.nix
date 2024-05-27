{ lib
, config
, inputs
, username
, hostname
, ...
}:
{
  nixpkgs = {
    overlays = [ ];
    config.allowUnfree = true;
  };

  nix = {
    # Allows referring to flakes with nixpkgs#flake
    registry = (lib.mapAttrs (_: flake: { inherit flake; })) ((lib.filterAttrs (_: lib.isType "flake")) inputs);

    settings = {
      # enable flakes
      experimental-features = "nix-command flakes";
      # save space by removing duplicate files from the store
      auto-optimise-store = true;
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  # Add flake inputs to the system's legacy channels
  nix.nixPath = [ "/etc/nix/path" ];
  environment.etc =
    lib.mapAttrs'
      (name: value: {
        name = "nix/path/${name}";
        value.source = value.flake;
      })
      config.nix.registry;

  programs.zsh = {
    enable = true;
    shellAliases = {
      # test of nix config
      rebuild-test = "sudo nixos-rebuild test --flake /home/${username}/.config/nixos#${hostname}";
      # hot switch of nix config
      rebuild-switch = "sudo nixos-rebuild switch --flake /home/${username}/.config/nixos#${hostname}";
      # build nix config
      rebuild-build = "sudo nixos-rebuild build --flake /home/${username}/.config/nixos#${hostname}";
      # build and set it to apply on next boot
      rebuild-boot = "sudo nixos-rebuild boot --flake /home/${username}/.config/nixos#${hostname}";
    };
  };
}
