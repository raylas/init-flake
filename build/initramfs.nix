{
  lib,
  buildEnv,
  writeScript,
  makeInitrdNG,
  bash,
  busybox,
  kmod,
}: {
  kernel,
  modules ? [],
  extraBin ? {},
  extraContent ? {},
  storePaths ? [],
  extraInit ? "",
}: let
  busyboxStatic = busybox.override {enableStatic = true;};

  initrdBinEnv = buildEnv {
    name = "initrd-emergency-env";
    paths = map lib.getBin initrdBin;
    pathsToLink = ["/bin" "/sbin"];
    postBuild = lib.concatStringsSep "\n" (lib.mapAttrsToList (n: v: "ln -s ${v} $out/bin/${n}") extraBin);
  };

  moduleEnv = buildEnv {
    name = "initrd-modules";
    paths = modules;
    pathsToLink = ["/lib/modules/${kernel.modDirVersion}/misc"];
  };

  content =
    {
      "/bin" = "${initrdBinEnv}/bin";
      "/sbin" = "${initrdBinEnv}/sbin";
      "/init" = init;
      "/modules" = "${moduleEnv}/lib/modules/${kernel.modDirVersion}/misc";
    }
    // extraContent;

  initrdBin = [bash busyboxStatic kmod];

  initialRamdisk = makeInitrdNG {
    compressor = "gzip";
    strip = false;
    contents =
      map (path: {
        object = path;
        symlink = "";
      })
      storePaths
      ++ lib.mapAttrsToList
      (n: v: {
        object = v;
        symlink = n;
      })
      content;
  };

  init = writeScript "init" ''
    #!/bin/sh

    export PATH=/bin/

    mkdir /proc
    mkdir /sys
    mount -t proc none /proc
    mount -t sysfs none /sys
    mount -t debugfs debugfs /sys/kernel/debug

    mknod -m 666 /dev/null c 1 3
    mknod -m 666 /dev/tty c 5 0
    mknod -m 644 /dev/random c 1 8
    mknod -m 644 /dev/urandom c 1 9

    mkdir -p /run/booted-system/kernel-modules/lib/modules/${kernel.modDirVersion}/build

    ${extraInit}

    cat <<!

    Boot took $(cut -d' ' -f1 /proc/uptime) seconds

    ██╗   ██╗███╗   ██╗██╗████████╗ █████╗ ██████╗ ██████╗ 
    ██║   ██║████╗  ██║██║╚══██╔══╝██╔══██╗██╔══██╗██╔══██╗
    ██║   ██║██╔██╗ ██║██║   ██║   ███████║██████╔╝██║  ██║
    ██║   ██║██║╚██╗██║██║   ██║   ██╔══██║██╔══██╗██║  ██║
    ╚██████╔╝██║ ╚████║██║   ██║   ██║  ██║██║  ██║██████╔╝
    ╚═════╝ ╚═╝  ╚═══╝╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ 
    Welcome to Unitard Linux :)


    !

    # Get a new session to allow for job control and ctrl-* support
    exec setsid -c /bin/sh
  '';
in
  initialRamdisk
