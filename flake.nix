{
  description = "NixOS configuration for Hyprdots";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland.url = "git+https://github.com/hyprwm/Hyprland?submodules=1";
    spicetify-nix.url = "github:the-argus/spicetify-nix";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      inputs,
      ...
    }:
    let
      system = "x86_64-linux";

      username = "akira";
      gitUser = "RyuuseiAkira";
      gitEmail = "haokhanh713@gmail.com";
      host = "nixos";

      # you need to change this with passwd when you boot
      # root will have the same password
      defaultPassword = "khanhhao1310";

      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        config.allowUnfreePredicate = _: true;
      };

      mkVM =
        { nixosSystem, ... }:
        nixosSystem.extendModules {
          modules = [
            (
              { config, pkgs, ... }:
              {
                virtualisation.libvirtd.enable = true;
                virtualisation.vmVariant = {
                  virtualisation = {
                    memorySize = 8192;
                    cores = 4;
                    diskSize = 20480;
                    qemu = {
                      options = [
                        "-device virtio-vga-gl"
                        "-display gtk,gl=on"
                      ];
                    };
                  };
                  services.xserver = {
                    displayManager.autoLogin = {
                      enable = true;
                      user = username;
                    };
                    videoDrivers = [ "virtio" ];
                  };

                };
                users.users.${username} = {
                  initialPassword = defaultPassword;
                };
                environment.systemPackages = with pkgs; [
                  open-vm-tools
                  spice-vdagent
                ];
                services.qemuGuest.enable = true;
                services.spice-vdagentd = {
                  enable = true;
                };
              }
            )
          ];
        };

    in
    {
      nixosConfigurations = {
        hyprdots-nix = nixpkgs.lib.nixosSystem {
          inherit system pkgs;

          specialArgs = {
            inherit
              username
              gitUser
              gitEmail
              host
              ;
          };

          modules = [
            ./configuration.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.${username} = import ./home.nix;
              home-manager.extraSpecialArgs = {
                inherit username gitUser gitEmail;
              };
            }
          ];
        };

        hyprdots-nix-vm = mkVM {
          nixosSystem = nixpkgs.lib.nixosSystem {
            inherit system pkgs;
            specialArgs = {
              inherit
                username
                gitUser
                gitEmail
                host
                defaultPassword
                ;
            };
            modules = [
              ./configuration.nix
              home-manager.nixosModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.users.${username} = import ./home.nix;
                home-manager.extraSpecialArgs = {
                  inherit username gitUser gitEmail;
                };
              }
            ];
          };
        };
      };
      packages.${system} = {
        default = self.nixosConfigurations.hyprdots-nix-vm.config.system.build.vm;
        hyprdots-nix-vm = self.nixosConfigurations.hyprdots-nix-vm.config.system.build.vm;
      };

      homeConfigurations = {
        ${username} = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = {inherit inputs;};
          modules = [
            ./home.nix
            ./modules/spicetify.nix
          ];
          extraSpecialArgs = {
            inherit username gitUser gitEmail;
          };
        };
      };
    };
}
