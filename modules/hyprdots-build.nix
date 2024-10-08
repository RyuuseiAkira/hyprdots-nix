{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.modules.hyprdots-build;

  # Helper function to fetch theme files
  fetchThemeFiles =
    theme:
    pkgs.fetchFromGitHub {
      owner = "prasanthrangan";
      repo = "hyde-themes";
      rev = theme;
      sha256 = "sha256-YbT1Rm49igI3H1wH21V5f+npjgbj0ya0Dfh9tM62nVI=";
    };

in
{
  options.modules.hyprdots-build = {
    enable = mkEnableOption "Hyprdots build";

    hyprdotsRepo = mkOption {
      type = types.path;
      description = "Path to the Hyprdots repository";
    };

    files = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [
        ".config/hypr"
        ".config/kitty"
        ".zshrc"
      ];
      description = "List of files or folders to install from Hyprdots";
    };

    theme = mkOption {
      type = types.str;
      default = "Catppuccin-Mocha";
      example = "Catppuccin-Mocha";
      description = "Theme to install from Hyprdots";
    };

    cleanBuild = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to install all Hyprdots configurations";
    };
  };

  config = mkIf cfg.enable {
    modules.hyprdots-build.hyprdotsRepo = pkgs.fetchFromGitHub {
      owner = "prasanthrangan";
      repo = "hyprdots";
      rev = "main";
      sha256 = "sha256-aB6b4qRH/D0Zna0WC4YoTZrm9wWAkSrAxDVFvFWrXy0=";
    };

    # Copy Hyprdots configs and scripts
    home.file = mkMerge [
      (
        let
          configsDir = "${cfg.hyprdotsRepo}/Configs";
          copyFiles = if cfg.cleanBuild then builtins.attrNames (builtins.readDir configsDir) else cfg.files;
        in
        builtins.listToAttrs (
          map (file: {
            name = file;
            value = {
              source = "${configsDir}/${file}";
              recursive = true;
              force = true;
            };
          }) copyFiles
        )
      )

      {
        ".hyprdots-version".text = cfg.hyprdotsRepo.rev;
      }

      (
        let
          scriptsDir = "${cfg.hyprdotsRepo}/Scripts";
          copyScripts = builtins.attrNames (builtins.readDir scriptsDir);
        in
        builtins.listToAttrs (
          map (file: {
            name = ".local/share/bin/${file}";
            value = {
              source = "${scriptsDir}/${file}";
              recursive = true;
              force = true;
              executable = true;
            };
          }) copyScripts
        )
      )

      # link theme files from fetchThemeFiles for apply theme to use
      (
        let
          themeDir = fetchThemeFiles cfg.theme;
          linkTheme = builtins.attrNames (builtins.readDir themeDir);
        in
        builtins.listToAttrs (
          map (file: {
            name = ".config/hypr/${file}";
            value = {
              source = "${themeDir}/${file}";
              recursive = true;
            };
          }) linkTheme
        )
      )
    ];

    # apply theme
    home.activation = {
      # TODO: nixify themes. this just runs themepatcher.sh with the supplied themes. there seems to be some issues with the theme preview in switcher. restore_cfg.sh won't work because nix is a readonly FS. would need to fully manage themes with nix
      applyTheme = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        export PATH="${
          lib.makeBinPath [
            pkgs.gawk
            pkgs.coreutils
            pkgs.gnused
            pkgs.gnutar
            pkgs.gzip
            pkgs.parallel
            pkgs.bash
            pkgs.imagemagick
          ]
        }:$PATH"
        ${pkgs.bash}/bin/bash $HOME/.local/share/bin/themepatcher.sh "${
          lib.strings.replaceStrings [ "-" ] [ " " ] cfg.theme
        }" "${fetchThemeFiles cfg.theme}"
      '';

    };
  };
}
