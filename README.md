# sysvars

sysvars is a small CLI tool for the Amiga that creates several environment variables holding valuable system information. These variables can be used, for example, in the startup-sequence to enable/disable certain patches, assigns, and so on.

The following variables are Set
- **CPU**: installed CPU, for example ``68030``[^1]
- **FPU**: installed FPU, one of ``68881``, ``68882``[^2], ``internal``[^2] (for non-LC/EC 040 and 060 CPUs), or empty if no FPU is available
- **Chipset**: installed graphics chipset, one of ``OCS``, ``ECS``, ``AGA``[^3]
- **VFreq**: the vertical frequency of the native display, can be either ``50`` (PAL 50Hz) or ``60`` (NTSC 60Hz)
- **UAE**: The version of UAE detected, empty if UAE was not detected[^4]

The tool works best with Amiga OS 2.0 or later. However, it runs also on OS 1.3, but currently cannot detect CPUs above 68020 and FPUs other than the 68881. Furthermore, in OS 1.3 the environment variables can only have global scope (they reside in ENV:). They are also less convenient compared to 2.0 or greater. Things like ``ECHO $CPU`` do not work. You must use something like ``IF CPU GE 68010``.

When run on OS 2.0 or later, sysvars calls ``SetVar``, which allows for local scope (no cluttering of ENV:) and better OS 1.3 support will be considered in a future version (using an alternative detection routine).

[^1]: On OS 1.3, CPUs > 68020 are currently detected as 68020. Also, 68080 (Vampire) detection for the CPU is experimental, I do not own one, so I cannot test it
[^2]: On OS 1.3, all FPUs are detected as 68881.
[^3]: SAGA (Vampire) support is not yet available. I do not own one, so I do not know what ``VPOSR`` might be on the Vampire.
[^4]: UAE is detected via the uae.resource, which is only there if a virtual hard drive or another UAE expansion to be enabled. Thus, detection will fail on floppy-only-unexpanded Amiga configurations.

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

- Add memory-related variables, such as ``Chipmem``, ``Fastmem``, and ``Slowmem`` (especially to distinguish Amiga 5000 trapdoor/slow memory from actual Z2/Z3 Fast memory)
- Add ``RTG`` variable to enable/disable stuff like FBlit or swap screen mode configurations
- For Os 1.3: add detection for CPUs > 68020 and at least the 68882
- Add full support for Vampire

## Release History
### Version 0.9
- Added limited OS 1.3 Support (CPU/FPU detection up to 68020/68881) via a custom SetVar implementation (setenv-like functionality)
- small code improvements
### Version 0.8
- Initial Release on GitHub and Aminet