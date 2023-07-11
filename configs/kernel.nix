{
  pkgs,
  lib ? pkgs.lib,
}: let
  version = "6.1.4";
  localVersion = "-dev"; # Set default and allow override
in {
  kernelArgs = {
    inherit version;
    src =
      pkgs.fetchurl {
        url = "mirror://kernel/linux/kernel/v6.x/linux-${version}.tar.xz";
        sha256 = "sha256-iqj2T6YLsTOBqWCNH++90FVeKnDECyx9BnGw1kqkVZ4=";
      };

    inherit localVersion;
    modDirVersion = 
      version + localVersion;
  };

  kernelConfig = {
    # See https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/system/boot/kernel_config.nix
    structuredExtraConfig = with lib.kernel;
      {
        # Debugging
        DEBUG_FS = yes;
        DEBUG_KERNEL = yes;
        DEBUG_BUGVERBOSE = yes;
        DEBUG_MEMORY_INIT = yes;
        SLUB_DEBUG = yes;

        STACKTRACE = yes;

        MAGIC_SYSRQ = yes;

        LOCALVERSION = freeform localVersion;

        BUG_ON_DATA_CORRUPTION = yes;
        UNWINDER_FRAME_POINTER = yes;
        "64BIT" = yes;

        # initramfs/initrd ssupport
        BLK_DEV_INITRD = yes;

        PRINTK = yes;
        PRINTK_TIME = yes;
        EARLY_PRINTK = yes;

        # Support elf and #! scripts
        BINFMT_ELF = yes;
        BINFMT_SCRIPT = yes;

        # Create a tmpfs/ramfs early at bootup.
        DEVTMPFS = yes;
        DEVTMPFS_MOUNT = yes;

        TTY = yes;
        SERIAL_8250 = yes;
        SERIAL_8250_CONSOLE = yes;

        PROC_FS = yes;
        SYSFS = yes;

        MODULES = yes;
        MODULE_UNLOAD = yes;

        # FW_LOADER = yes;
      };

    # Flags that get passed to generate-config.pl
    generateConfigFlags = {
      # Ignores any config errors (eg unused config options)
      ignoreConfigErrors = false;
      # Build every available module
      autoModules = false;
      preferBuiltin = false;
    };
  };
}
