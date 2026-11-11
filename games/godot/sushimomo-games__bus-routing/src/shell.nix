{ pkgs ? import <nixpkgs> { } }:

(pkgs.buildFHSEnv {
  name = "dotnet-fhs-shell";
  targetPkgs = pkgs: with pkgs; [
    dotnetCorePackages.sdk_9_0_1xx-bin
    icu
    zlib
    openssl
    stdenv.cc.cc.lib
  ];
  runScript = "bash";
}).env
