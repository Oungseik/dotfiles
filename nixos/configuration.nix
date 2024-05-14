# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Asia/Yangon";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.gdk-pixbuf.modulePackages = [ pkgs.librsvg ];


  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Enable AwesomeWM
  # services.xserver = {
  #   windowManager.awesome = {
  #     enable = true;
  #     luaModules = with pkgs.luaPackages; [
  #       luarocks # is the package manager for Lua modules
  #       luadbi-mysql # Database abstraction layer
  #     ];
  #   };
  # };

  services.mpd = {
    enable = true;
    musicDirectory = /home/oung/Music;

    # Optional:
    # network.listenAddress = "any"; # if you want to allow non-localhost connections
    startWhenNeeded = true; # systemd feature: only start MPD service upon connection to its socket
    user = "oung";
  };

  systemd.services.mpd.environment = {
    XDG_RUNTIME_DIR = "/run/user/${toString config.users.users.oung.uid}"; # User-id must match above user. MPD will look inside this directory for the PipeWire socket.
  };

  # Configure keymap in X11
  services.xserver = {
    layout = "us";
    xkbVariant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  users.defaultUserShell = pkgs.zsh;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.oung = {
    isNormalUser = true;
    description = "Min Aung Thu Win";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      # bun
      brightnessctl
      # deno
      firefox
      hyprland
      google-chrome
      grim
      jq
      lunarvim
      neovide
      nodejs_20
      pavucontrol
      python3
      python311Packages.pip
      vscode
      rofi
      rustup
      slurp
      starship
      xfce.thunar
      waybar
      wl-clipboard
      wofi
    ];
  };


  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;


  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
   amberol
   alacritty
   curl
   clang
   deja-dup
   gcc
   git
   lxappearance
   neovim
   openvpn
   tmux
   unzip
   wezterm
   wget
   xsel
  ];


  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  programs.zsh.enable = true;
  programs.hyprland.enable = true;

  # Fonts
  # fonts = {
  #   enableDefaultPackages = true;
  #   packages = with pkgs; [
  #     roboto
  #     # (nerdfonts.override { fonts = [  ]; })
  #   ];

  #   fontconfig = {
  #     allowBitmaps = true;
  #   };
  # };


  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?

}
