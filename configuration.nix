{
  config,
  pkgs,
  username,
  host,
  lib,
  ...
}:
{

  imports = [
    ./hardware-configuration.nix
  ];

  # ===== Boot Configuration =====
  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
      grub = {
        enable = true;
        device = "nodev";
        efiSupport = true;
        useOSProber = true;
        theme = pkgs.fetchFromGitHub {
           owner = "shvchk";
           repo = "fallout-grub-theme";
           rev = "80734103d0b48d724f0928e8082b6755bd3b2078";
           sha256 = "sha256-7kvLfD6Nz4cEMrmCA9yq4enyqVyqiTkVZV5y4RyUatU=";
        };
      };
    };
    kernelPackages = pkgs.linuxPackages_zen;
  };

  # ===== Hardware Configuration =====
  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };
    bluetooth = {
      enable = true;
      powerOnBoot = false;
    };
  };

  # ===== Filesystems =====
  # USER EDITABLE ADD FILESYSTEMS HERE

  # ===== Security =====
  security = {
    polkit.enable = true;
    sudo = {
      enable = true;
      extraRules = [
        {
          commands = [
            {
              command = "${pkgs.systemd}/bin/reboot";
              options = [ "NOPASSWD" ];
            }
            {
              command = "${pkgs.systemd}/bin/poweroff";
              options = [ "NOPASSWD" ];
            }
            {
              command = "${pkgs.systemd}/bin/shutdown";
              options = [ "NOPASSWD" ];
            }
          ];
          groups = [ "wheel" ];
        }
      ];
    };
  };
  # ===== System Services =====
  services = {
    libinput.enable = true;
    spice-vdagentd.enable = true;
    qemuGuest.enable = true;
    blueman.enable = true;
    pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true;
      wireplumber.enable = true;
    };
    dbus.enable = true;
    xserver = {
      enable = false;
      videoDrivers = [ "amdgpu" ];
    };
    openssh.enable = true;
    displayManager = {
      sddm = {
        enable = true;
        wayland.enable = true;
        settings = {
          autoLogin.enable = true;
          autoLogin.user = username;
          AutoLogin = {
            User = username;
            Session = "hyprland.desktop";
          };
        };
        theme = "catppuccin-mocha";
        package = pkgs.kdePackages.sddm;
      };
      sessionPackages = [ pkgs.hyprland ];
    };
  };

  networking = {
    hostName = host;
    networkmanager.enable = true;
  };
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      # SSH
      22
      # Pipewire
      4713
    ];
    allowedUDPPorts = [
      # Pipewire
      4713
      # DHCP
      68
      546
    ];
  };
  # XDG Desktop Portal stuff
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    config.common.default = "*";
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
    ];
  };
  # OpenRazer
  hardware.openrazer.enable = true;
  hardware.openrazer.users = ["akira"];

  i18n.inputMethod = {
    type = "fcitx5";
    enable = true;
    fcitx5.waylandFrontend = true;
    fcitx5.addons = with pkgs; [
      rime-data
      fcitx5-rime
      fcitx5-gtk
      #kdePackages.fcitx5-qt
      fcitx5-unikey
      fcitx5-bamboo
      fcitx5-chinese-addons  # table input method support
      fcitx5-nord            # a color theme
     ];
   };

  # ===== System Configuration =====
  time.timeZone = "Asia/Ho_Chi_Minh"; #https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
  i18n.defaultLocale = "en_CA.UTF-8";

  # ===== User Configuration =====
  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
    ];
  };
  users.defaultUserShell = pkgs.zsh;

  # ===== Nix Configuration =====
  nix.settings = {
    auto-optimise-store = true;
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    substituters = [ "https://cache.nixos.org" ];
    trusted-public-keys = [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" ];
    extra-substituters = [
      "https://hyprland.cachix.org"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  # ===== System Packages =====
  environment.systemPackages = with pkgs; [
    # Core Packages
    lld
    gcc
    glibc
    clang
    udev
    llvmPackages.bintools
    wget
    procps
    killall
    zip
    unzip
    bluez
    busybox
    bluez-tools
    brightnessctl
    light
    xdg-utils
    pipewire
    wireplumber
    alsaLib
    pkg-config
    kdePackages.qtsvg
    usbutils
    lxqt.lxqt-policykit
    home-manager
    mesa

    # sddm
    kdePackages.sddm
    (catppuccin-sddm.override { flavor = "mocha"; })

    # Standard Packages
    networkmanager
    networkmanagerapplet
    git
    fzf
    tldr
    sox
    yad
    flatpak
    ffmpeg

    # GTK Packages
    gtk2
    gtk3
    gtk4
    tela-circle-icon-theme
    bibata-cursors

    # QT Packages
    qtcreator
    qt5.qtwayland
    qt6.qtwayland
    qt6.qmake
    libsForQt5.qt5.qtwayland
    qt5ct
    gsettings-qt

    # Xorg Libraries
    xorg.libX11
    xorg.libXcursor

    # Other Hyprdots dependencies
    hyprland
    waybar
    xwayland
    cliphist
    alacritty
    swww
    swaynotificationcenter
    lxde.lxsession
    gtklock
    eww
    xdg-desktop-portal-hyprland
    where-is-my-sddm-theme
    firefox
    pavucontrol
    blueman
    trash-cli
    ydotool
    lsd
    parallel
    pwvucontrol
    pamixer
    udiskie
    dunst
    swaylock-effects
    wlogout
    hyprpicker
    slurp
    swappy
    polkit_gnome
    libinput-gestures
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
    jq
    kdePackages.qtimageformats
    kdePackages.ffmpegthumbs
    kdePackages.kde-cli-tools
    libnotify
    libsForQt5.qt5.qtquickcontrols
    libsForQt5.qt5.qtquickcontrols2
    libsForQt5.qt5.qtgraphicaleffects
    libsForQt5.qt5ct
    libsForQt5.qtstyleplugin-kvantum
    kdePackages.qtstyleplugin-kvantum
    kdePackages.qt6ct
    kdePackages.wayland
    rofi-wayland
    nwg-look
    ark
    dolphin
    kitty
    eza
    oh-my-zsh
    zsh
    zsh-powerlevel10k
    envsubst
    hyprcursor
    imagemagick
    gnumake
    tree
    papirus-icon-theme
    wofi
    vscode
    openssh
    vim
    git
    gnumake
    cachix
    wl-clipboard
    grim
    grimblast
    
    # Custom
    google-chrome
    vesktop
    spotify
    vscodium
    spicetify-cli
    mission-center
    wev
    xorg.xev
    linuxHeaders
    linuxKernel.packages.linux_zen.system76
    mcontrolcenter
    hypridle
    hyprlock
    obs-studio
    xdg-desktop-portal
    razergenie
    mpv
    pulseaudio
    alsa-utils
    playerctl
    libsForQt5.fcitx5-with-addons
    fcitx5
    fcitx5-bamboo
    fcitx5-unikey
    neofetch
  ];

  # ===== Program Configurations =====
  programs = {
    git.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestions.enable = true;
      syntaxHighlighting.enable = true;
      shellAliases = {
        ll = "ls -l";
      };
      ohMyZsh = {
        enable = true;
        plugins = [
          "git"
        ];
        theme = "robbyrussell";
      };
      shellInit = ''
        if [ -d $HOME/.nix-profile/share/applications ]; then
          XDG_DATA_DIRS="$HOME/.nix-profile/share:$XDG_DATA_DIRS"
        fi
      '';
    };
  };

  # ===== Font Configuration =====
  fonts = {
    fontDir.enable = true;
    packages = with pkgs; [
      noto-fonts
      noto-fonts-emoji
      noto-fonts-cjk
      (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
      noto-fonts-color-emoji
      material-icons
      font-awesome
      atkinson-hyperlegible
    ];
  };

  # ===== Environment Configuration =====
  environment = {
    sessionVariables.NIXOS_OZONE_WL = "1";
    shellInit = ''
      if [ -d $HOME/.nix-profile/share/applications ]; then
        XDG_DATA_DIRS="$HOME/.nix-profile/share:$XDG_DATA_DIRS"
      fi
    '';

  };

  # ===== System Version =====
  system.stateVersion = "24.11"; # Don't change this
}
