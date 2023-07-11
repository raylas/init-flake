# init-flake

A Nix flake for reproducible Linux kernels and initramfs archives.

Motivated by [jordanisaacs](https://github.com/jordanisaacs/kernel-module-flake/tree/4ae601bcab389e51233f071df9382b3f5fad1478) and [chrisdone](https://gist.github.com/chrisdone/02e165a0004be33734ac2334f215380e).

## Usage

```sh
nix develop .#

# Run VM
runvm
# Exit with CTRL + A X
```

### Individual

Kernel:
```sh
nix build .#kernel
```

initramfs:
```sh
nix build .#initramfs
```

## Usage as an input

```nix
{
   inputs.kernelFlake.url = "github:raylas/onesie-flake";

   outputs =  {
     self,
     nixpkgs,
     kernelFlake
   }: let
     system = "x86_64-system";
     pkgs = nixpkgs.legacyPackages.${system};

     kernelLib = kernelFlake.lib.builders {inherit pkgs;};

     configfile = buildLib.buildKernelConfig {
       generateConfigFlags = {};
       structuredExtraConfig = {};

       inherit kernel nixpkgs;
     };

     kernel = buildLib.buildKernel {
       inherit configfile;

       src = ./kernel-src;
       version = "";
       modDirVersion = "";
     };

     modules = [exampleModule];

     initramfs = buildLib.buildInitramfs {
       inherit kernel modules;
     };

     runQemu = buildLib.buildQemuCmd {inherit kernel initramfs;};
   in { };
}
```
