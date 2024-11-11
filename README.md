
<p align="center">
  <img src="https://github.com/larsonmars/sysvars/assets/33299122/0c5c48a3-638b-4caa-a48e-8da800cdeea6">
</p>

# Overview
sysvars is a small CLI tool for the Amiga that creates several environment variables holding valuable system information. These variables can be used, for example, in the startup-sequence to enable/disable certain patches, assigns, and so on.

Currently, the following variables are set:
|Variable|Description|
|--------------|------------------------------------------|
| **``$CPU``** | installed CPU, for example ``68030``[^1] |
| **``$FPU``** | installed FPU, one of ``68881``, ``68882``, ``internal``[^2] (for non-LC/EC 040 and 060 CPUs), or empty if no FPU is available |
| **``$Chipset``** |installed graphics chipset, one of ``OCS``, ``ECS``, ``AGA``, ``SAGA`` |
| **``$VFreq``** |vertical frequency of the native display, can be either ``50`` (PAL 50Hz) or ``60`` (NTSC 60Hz) |
| **``$KickVer``** & **``$KickRev``** |Kickstart version and revision [^3] |
| **``$BSDSockLib``**, **``$BSDSockLibVer``**, **``$BSDSockLibRev``** |id, version and revision of bsdsocket.library available, empty if bsdsocket.library is not available |
| **``$UAEMajor``**, **``$UAEMinor``**, **``$UAERev``** |version of UAE detected, empty if UAE was not detected[^4] |
| **``$VampireType``** |type of vampire installed, for example "V2_600", or "V4_Standalone" |
| **``$VampireCoreRev``** |core revision of the currently flashed firmware .jic file[^5] |
| **``$VampireClockMult``** |vampire clock multiplier |

# Requirements

The tool works best with Amiga OS 2.0 or later. Here, it calls ``SetVar``, which allows for local scope variables. Local scope is no limitation, because the workbench is also loaded in the scope of the startup-sequence. Another advantage is that it does not require ENV:. This means it can run very early, even before SetPatch.

However, for the purists, sysvars runs happily also on OS 1.3 and even down to OS 1.1. However, there are some limitations to consider (see [limitations](#Limitations-and-Disclaimer))

# Installing

1. Copy sysvars to your hard or floppy disk drive (e.g., in the c directory)
2. Add it to your startup-sequence or User-Startup
   - For OS 2.0 or greater there is no issue to call sysvars very early, even before SetPatch
   - For OS 1.3 and OS 1.2, you must ensure that ENV: exists prior running sysvars (see [previous section](#Requirements))

# Building

The source should build with [VASM](http://www.compilers.de/vasm.html), [AsmOne](http://www.theflamearrows.info/documents/asmone.html)[^6], [AsmTwo](http://coppershade.org/articles/Code/Tools/AsmTwo/), [AsmPro](https://aminet.net/package/dev/asm/ASMPro1.19), and [asmotor](https://github.com/asmotor/asmotor/tree/master)

You can also compile this in VSCode using a [nice VSCode plugin](https://github.com/prb28/vscode-amiga-assembly), a suitable configuration is included in the .vscode directory.

# Testing

There is a filesystem structure in test/sysvars-test that can be used for testing in vscode (virtual filesystem) or on a bootable floppy/partition on a real Amiga. There is a small script `CreateTestDisk` that creates such a bootable disk. The test can also be executed from Workbench (via IconX).

To make it also work with KS 1.2 and 1.3, some files from Workbench1.3 are required, which I cannot distribute. If you need this, just insert your Workbench1.3 disk and start the script `Add OS 1.3 Support`. Note that Workbench prior 1.3 cannot be used, due to the lack of support for environment variables.

# Why such a Tool?

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

# Limitations and Disclaimer

## OS 1.3
- Sysvars currently detects CPUs above 68020 as 68020 and any FPUs as 68881.
- Environment variables can only have global scope (i.e., they reside in ENV:). This means you must have ENV: mounted (e.g., to some folder on RAM:). This is not required for OS 2.0 and above.

## OS 1.2 and below
- Environment variables can only be used with the IF command (things like ``ECHO $CPU`` do not work. You must use ``IF $CPU GE 68010``)
- UAE detection does not work
- the IF command does not support environment variables. You can use the IF command from Workbench 1.3, but only EQ (equal) seems to work here.

## General
As sysvars is optimized for speed, being compact and system friendly. It is not an elaborate H/W detection tool, such as WhichAmiga, which means that there might be system combinations, where sysvars gets it wrong (you can of course file a bug report)

# Future Plans/Known Bugs

The tool is already quite useable, but there are still some things missing, which I want to fix in future versions (no particular order):

- Add memory-related variables, such as ``$Chipmem``, ``$Fastmem``, and ``$Slowmem`` (especially to distinguish Amiga 5000 trapdoor/slow memory from actual Z2/Z3 Fast memory)
- Add ``$RTG`` variable to enable/disable stuff like FBlit or swap screen mode configurations
- For Os 1.3: add detection for CPUs > 68020 and at least the 68882
- Make use of boards.library and identify.library if available for even more expansions.
- Make a WinUAE/FS-UAE-based test suite for automated tests (CI/CD-like)

[^1]: 68080 (Vampire) detection is implemented. On OS 1.3 and below, CPUs > 68020 are currently detected as 68020.
[^2]: On OS 1.3 and below, all FPUs are detected as 68881.
[^3]: Workbench 2.0 and above 
[^4]: UAE is detected via the uae.resource, which is only there if a virtual hard drive or another UAE expansion to be enabled. Thus, detection will fail on floppy-only-unexpanded Amiga configurations.
[^5]: Some beta cores might not have a valid core revision, in which case ``$VampireCoreRev`` is set to "N/A"
[^6]: Currently only the original 1.2 is supported. 1.48 and 1.49 seem to have problems with nested macros