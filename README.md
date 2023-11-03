# sysvars

sysvars is a small CLI tool for the Amiga that creates several environment variables holding valuable system information. These variables can be used, for example, in the startup-sequence to enable/disable certain patches, assigns, and so on.

Currently, the following variables are set:
- **``$CPU``**: installed CPU, for example ``68030``[^1]
- **``$FPU``**: installed FPU, one of ``68881``, ``68882``[^2], ``internal``[^2] (for non-LC/EC 040 and 060 CPUs), or empty if no FPU is available
- **``$Chipset``**: installed graphics chipset, one of ``OCS``, ``ECS``, ``AGA``[^3]
- **``$VFreq``**: the vertical frequency of the native display, can be either ``50`` (PAL 50Hz) or ``60`` (NTSC 60Hz)
- **``$KickVer``** & **``$KickRev``**: Kickstart version and revision [^4]
- **``$BSDSockLib``**, **``$BSDSockLibVer``**, and **``$BSDSockLibRev``**: The id, version and revision of bsdsocket.library available, empty if bsdsocket.library is not available
- **``$UAEMajor``**, **``$UAEMinor``**, **``$UAERev``**: The version of UAE detected, empty if UAE was not detected[^5]

The tool works best with Amiga OS 2.0 or later. Here, it calls ``SetVar``, which allows for local scope variables. Local scope is no limitiation, because the workbench is also loaded in the scope of the startup-sequence. Another advantage is that it does not require ENV:. This means it can run very early, even before SetPatch.

However, for the purists, sysvars runs happily also on OS 1.3 and even down to OS 1.1. However, there are some limitations to consider
1. In OS 1.3 and below, sysvars will currently detect CPUs above 68020 as 68020 and any FPUs as 68881.
2. in OS 1.3, environment variables can only have global scope (i.e., they reside in ENV:). This means you must have ENV: mounted (e.g., to some folder on RAM:). This is not required for OS 2.0 and above.
3. In OS 1.3, environment variables are not useable with every command, but only with IF. Thus, things like ``ECHO $CPU`` do not work. You must use something like ``IF $CPU GE 68010``.
4. Below OS 1.3, UAE detection does not work
5. Below OS 1.3, the IF command does not support environment variables. You must use the IF command from Workbench 1.3. Also, only EQ (equal) seems to work here.

[^1]: On OS 1.3 and below, CPUs > 68020 are currently detected as 68020. Also, 68080 (Vampire) detection for the CPU is experimental, I do not own one, so I cannot test it
[^2]: On OS 1.3 and below, all FPUs are detected as 68881.
[^3]: SAGA (Vampire) support is not yet available. I do not own one, so I do not know what ``VPOSR`` might be on the Vampire.
[^4]: Workbench 2.0 and above 
[^5]: UAE is detected via the uae.resource, which is only there if a virtual hard drive or another UAE expansion to be enabled. Thus, detection will fail on floppy-only-unexpanded Amiga configurations.

## Building

The source should build with [VASM](http://www.compilers.de/vasm.html), [AsmOne](http://www.theflamearrows.info/documents/asmone.html), [AsmTwo](http://coppershade.org/articles/Code/Tools/AsmTwo/), and [AsmPro](https://aminet.net/package/dev/asm/ASMPro1.19)[^6].

You can also compile this in VSCode using a [nice VSCode plugin](https://github.com/prb28/vscode-amiga-assembly), a suitable configuration is included in the .vscode directory.

[^6]: Currently, not compiling, needs more investigation

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

## Future Plans/Known Bugs

The tool is already quite useable, but there are still some things missing, which I want to fix in future versions (no particular order):

- Currently, sysvars can no longer be compiled using ASM-Pro and ASM-One 1.4. VASM, ASM-One 1.2 and AsmTwo work fine
- Add memory-related variables, such as ``$Chipmem``, ``$Fastmem``, and ``$Slowmem`` (especially to distinguish Amiga 5000 trapdoor/slow memory from actual Z2/Z3 Fast memory)
- Add ``$RTG`` variable to enable/disable stuff like FBlit or swap screen mode configurations
- For Os 1.3: add detection for CPUs > 68020 and at least the 68882
- Add full support for Vampire
- Make use of boards.library and identify.library if available for even more expansions.
- Make a WinUAE/FS-UAE-based test suite for automated tests (CI/CD-like)

## Release History
### Version 0.10
- Added ``$KickVer`` and ``$KickEnv`` that provide kickstart version and revision
- ``$UAE`` is now split in ``$UAEMajor``, ``$UAEMinor`` and ``$UAERev`` for more convenient scripting
- Added detection of bsdsocket.library (``$BSDSockLib`` contains the id string, ``$BSDSockLibVer`` the version, and ``$BSDSockRev`` the revision)
- Refactoring and code improvements (still learning though)
  - Easy way to disable certain variables/features at the beginning of the file using constants (Adapt to your need and make the tool as tiny as possible)
  - Unified SetVar approach using macros
  - Easier integration of new features via consistent scheme
  - Better comments
- added test script for startup-sequence
### Version 0.9
- Added limited OS 1.3 Support (CPU/FPU detection up to 68020/68881) via a custom SetVar implementation (setenv-like functionality)
- small code improvements
### Version 0.8
- Initial Release on GitHub and Aminet