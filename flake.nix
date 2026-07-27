# =========================================================================
# Nix Flake 設定ファイル (~/.config/home-manager/flake.nix)
# =========================================================================
{
  description = "Home Manager configuration of nalt";

  inputs = {
    # Nixpkgs & Home Manager の入力ソース定義
    nixpkgs.url      = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url            = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # nixGL の入力ソース定義 (OpenGLラッパー)
    nixgl = {
      url            = "github:nix-community/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Yazi Kanagawa Dragon フレーバーの入力ソース定義
    kanagawa-dragon-yazi = {
      url   = "github:Naruto-Takahashi/kanagawa-dragon.yazi";
      flake = false;
    };

    # nix-darwin の入力ソース定義
    darwin = {
      url   = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, nixgl, kanagawa-dragon-yazi, darwin, ... }:
    let
      system = "x86_64-linux";
      pkgs   = nixpkgs.legacyPackages.${system};
    in
    {
      homeConfigurations = {
        # WSL環境用プロファイル
        "nalt-wsl" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./hosts/wsl ];
          extraSpecialArgs = { inherit nixgl kanagawa-dragon-yazi; };
        };

        # Mac環境用プロファイル (M1 Mac Mini)
        "nalt-mac" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages."aarch64-darwin";
          modules = [ ./hosts/mac ];
          extraSpecialArgs = { inherit kanagawa-dragon-yazi; };
        };
      };

      # NixOS環境用プロファイル
      nixosConfigurations = {
        "nixos" = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./hosts/nixos
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.nalt = import ./hosts/nixos/home.nix;
              home-manager.extraSpecialArgs = { inherit nixgl kanagawa-dragon-yazi; };
            }
          ];
        };
      };

      # Mac (nix-darwin) 環境用プロファイル
      darwinConfigurations = {
        "nalt-mac" = darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          modules = [
            ./hosts/mac/darwin.nix
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.nalt = import ./hosts/mac;
              home-manager.extraSpecialArgs = { inherit kanagawa-dragon-yazi; };
              home-manager.backupFileExtension = "backup";
            }
          ];
        };
      };
    };
}
