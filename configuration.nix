{ config, pkgs, ... }:

{
  # Enable the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.availableKernelModules = [
    "aesni_intel"
    "btrfs"
    "cryptd"
  ];

  boot.initrd.systemd.enable = true;

  # Use LUKS encryption for the root partition.
  boot.initrd.luks.devices = {
    root = {
      device = "/dev/disk/by-label/root";
    };
  };

#  # Use LVM for the logical volumes.
#  boot.initrd.luks.devices.root.lvm = {
#    enable = true;
#    volumes."root" = {
#      device = "/dev/vg/root";
#      fsType = "btrfs";
#      options = [ "subvol=nixos" ];
#    };
#    volumes."boot" = {
#      device = "/dev/vg/boot";
#      fsType = "vfat";
#    };
#  };

  # Mount the filesystems.
  fileSystems."/" = {
    device = "/dev/mapper/vg-root";
    fsType = "btrfs";
    options = [ "subvol=nixos" ];
  };
  fileSystems."/boot" = {
    device = "/dev/mapper/vg-boot";
    fsType = "vfat";
  };
  fileSystems."/home" = {
    device = "/dev/mapper/vg-root";
    fsType = "btrfs";
    options = [ "subvol=home" ];
  };

  # Enable swapfile.
  swapDevices = [
    { device = "/swapfile"; }
  ];

  # Set your hostname.
  networking.hostName = "3HeadedMonkey";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select the wireless network interface.
  networking.wireless.enable = true;
  networking.wireless.interfaces = [ "wlan0" ];

  # Set the NixOS release channel.
  nix.nixPath = [ "nixpkgs=https://nixos.org/channels/nixos-21.11" ];

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    wget
    vim
  ];

  # Enable the CUPS daemon for printing.
  # services.printing.enable = true;
  # services.printing.drivers = with pkgs; [ hplip ];

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.layout = "de";
  services.xserver.xkbOptions = "eurosign:e";

  # Enable touchpad support.
  services.xserver.libinput.enable = true;

  # Enable the KDE Desktop Environment.
#  services.xserver.displayManager.sddm.enable = true;
#  services.xserver.desktopManager.plasma5.enable = true;

#  # Clone nix config from git repo and apply it.
#  imports = [
#    (builtins.fetchGit {
#      url = "https://github.com/user/nix-config.git";
#      ref = "master";
#    })
#  ];

  # Enable the SSH daemon.
  services.openssh.enable = true;
}
