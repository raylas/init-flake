{
  description = "For kernel and root FS time";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};

    buildLib = pkgs.callPackage ./build {};

    linuxConfigs = pkgs.callPackage ./configs/kernel.nix {};
    inherit (linuxConfigs) kernelArgs kernelConfig;

    # Config file derivation
    configfile = buildLib.buildKernelConfig {
      inherit
        (kernelConfig)
        generateConfigFlags
        structuredExtraConfig
        ;
      inherit kernel nixpkgs;
    };

    # Kernel derivation
    kernelDrv = buildLib.buildKernel {
      inherit
        (kernelArgs)
        src
        modDirVersion
        version
        ;

      inherit configfile nixpkgs;
    };

    linuxDev = pkgs.linuxPackagesFor kernelDrv;
    kernel = linuxDev.kernel;

    initramfs = buildLib.buildInitramfs {
      inherit kernel;

      extraBin =
        {
          strace = "${pkgs.strace}/bin/strace";
        };
      storePaths = [pkgs.foot.terminfo] ++ [pkgs.python3];
    };

    runQemu = buildLib.buildQemuCmd {inherit kernel initramfs;};

    devShell = let
      nativeBuildInputs = with pkgs;
        [
          bear # for compile_commands.json, use bear -- make
          runQemu
          git
          qemu
          pahole
        ];
      buildInputs = [pkgs.nukeReferences kernel.dev];
    in
      pkgs.mkShell {
        inherit buildInputs nativeBuildInputs;
        KERNEL = kernel.dev;
        KERNEL_VERSION = kernel.modDirVersion;
      };
  in {
    lib = {
      builders = import ./build/default.nix;
    };

    packages.${system} = {
      inherit initramfs kernel;
      kernelConfig = configfile;
    };

    devShells.${system}.default = devShell;
  };
}