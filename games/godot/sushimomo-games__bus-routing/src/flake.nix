{
  description = "Godot Mono 4.5 & .NET 9 FHS Environment";

  inputs = {
    nixpkgs-godot45.url = "github:nixos/nixpkgs/c27cdad491a991b11ed731760aa2ef8db0cb0410";
  };

  outputs = { self, nixpkgs-godot45 }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs-godot45 {
        inherit system;
        config.allowUnfree = true;
      };

      fhsEnv = pkgs.buildFHSEnv {
        name = "dotnet-fhs-shell";
        targetPkgs = pkgs: with pkgs; [
          # Target the explicit attribute set path for 4.5 Mono
          godotPackages_4_5.godot-mono

          # .NET dependencies
          dotnetCorePackages.sdk_9_0_1xx-bin
          icu
          zlib
          openssl
          stdenv.cc.cc.lib
        ];
        runScript = "bash";
      };
    in
    {
      devShells.${system}.default = fhsEnv.env;
    };
}