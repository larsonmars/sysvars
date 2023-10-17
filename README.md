# sysvars

sysvars is a small CLI tool for the Amiga that creates several environment variables holding valuable system information. These variables can be used, for example, in the startup-sequence to enable/disable certain patches, assigns, and so on.

The following variables are Set
- **CPU**: installed CPU, for example ``68030``[^1]
- **FPU**: installed FPU, one of ``68881``, ``68882``, ``internal`` (for non-LC/EC 040 and 060 CPUs), or empty if no FPU is available
- **Chipset**: installed graphics chipset, one of ``OCS``, ``ECS``, ``AGA``[^2]
- **VFreq**: the vertical frequency of the native display, can be either ``50`` (PAL 50Hz) or ``60`` (NTSC 60Hz)
- **UAE**: The version of UAE detected, empty if UAE was not detected[^3]

The tool currently requires at least dos.library version 36 (Amiga OS 2.x) due to the use of ``SetVar``. OS 1.3 support will be considered in a future version (using an alternative for the ``SetVar`` calls…).
[^1]: 68080 (Vampire) support for the CPU is experimental, I do not own one, so I cannot test it
[^2]: SAGA (Vampire) support is not yet available. I do not own one, so I do not know what ``VPOSR`` might be on the Vampire.
[^3]: UAE is detected via the uae.resource, which is only there if a virtual hard drive or another UAE expansion to be enabled. Thus, detection will fail on floppy-only-unexpanded Amiga configurations.

## Building

The source should build with [VASM](http://www.compilers.de/vasm.html), [AsmOne](http://www.theflamearrows.info/documents/asmone.html), [AsmTwo](http://coppershade.org/articles/Code/Tools/AsmTwo/), and [AsmPro](https://aminet.net/package/dev/asm/ASMPro1.19).

You can also compile this in VSCode using a [nice VSCode plugin](https://github.com/prb28/vscode-amiga-assembly), a suitable configuration is included in the .vscode directory.

## Why such a Tool?

As many Amiga users, I have multiple Amigas, booting from flash memory. However, I do not want to maintain multiple operating system configurations. In the past, I have used several tools to branch during startup, which yielded a complex startup-sequence/user-startup and an extended boot time.

I wanted a small fast utility that gives me neat environment variables, so I can write something like this in the startup-sequence:

```
IF $CPU GE 68020
  MCP
ENDIF
```

or

```
IF $FPU EQ internal
  FastIEEE
ENDIF
```

Also, I always wanted to learn M68k assembler. After 30 years using an Amiga this was about time!

## Future Plans

The tool is already quite useable, but there are still some things missing, which I want to fix in future versions:

- Add memory-related variables, such as ``ChipRam``, ``FastRam``, and ``SlowRam`` (especially to distinguish slow ram from fast ram)
- Add ``RTG`` variable to enable/disable stuff like FBlit or swap screen mode configurations
- Make it work in OS 1.3 (because, why not?)
- Add full support for Vampire
