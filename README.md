
<p align="center">
  <img src="https://github.com/larsonmars/sysvars/assets/33299122/0c5c48a3-638b-4caa-a48e-8da800cdeea6">
</p>

# Overview
sysvars is a small CLI tool for the Amiga that creates several environment variables holding valuable system information. These variables can be used, for example, in the startup-sequence to enable/disable certain patches, assigns, and so on.

Currently, the following variables are supported:
<a name="overview_table"></a>
|Variable|Availability|Description
|--------------|------------------------------------------|------------------------------------------
| **``$CPU``** | always | installed CPU, for example ``68030`` (68080 is supported, but see [limitations](#Kickstart-13-and-below))
| **``$FPU``** | if CPU ≥ 68020 | installed FPU, one of ``68881``, ``68882``, ``internal``, or empty for LC/EC 040 and 060 CPUs where no FPU is available (see [limitations](#Kickstart-13-and-below))
| **``$Chipset``** | always | installed graphics chipset, one of ``OCS``, ``ECS``, ``AGA``, ``SAGA``
| **``$VFreq``** | always | vertical frequency of the native display, can be either ``50`` (PAL 50Hz) or ``60`` (NTSC 60Hz)
| **``$TotalChipRam``** | always | total amount of Chip RAM installed (in KB)
| **``$TotalFastRam``** | always | total amount of real Fast[^1] RAM installed (in KB)
| **``$TotalSlowRam``** | if present | total amount of Slow[^1] RAM installed (in KB)
| **``$SlowRamFirst``** | see description | The variable is set to ``1`` if Slow RAM is first to be allocated as non-Chip RAM[^2], otherwise this variable is unavailable
| **``$KickVer``** & **``$KickRev``** | always | Kickstart version and revision (see [limitations](#Kickstart-12-and-below))
| **``$BSDSockLib``**, **``$BSDSockLibVer``**, **``$BSDSockLibRev``** | if present | ID, version and revision of bsdsocket.library
| **``$UAEMajor``**, **``$UAEMinor``**, **``$UAERev``** | if detected | major, minor version and revision of UAE detected (see [limitations](#UAE-detection))
| **``$VampireType``** | if CPU = 68080 | type of vampire installed, for example "V2_600", or "V4_Standalone"
| **``$VampireCoreRev``** | if CPU = 68080 | core revision of the currently flashed firmware .jic file[^3]
| **``$VampireClockMult``** | if CPU = 68080 | vampire clock multiplier


# Requirements

The tool works best with Amiga OS 2.0 or later. Here, it calls ``SetVar``, which allows for local scope variables. Local scope is no limitation, because the workbench is also loaded in the scope of the startup-sequence. Another advantage is that it does not require ENV:. This means it can run very early, even before SetPatch.

However, for the purists, sysvars runs happily also on OS 1.3 and even down to OS 1.2. However, there are some limitations to consider (see [limitations](#Limitations-and-Disclaimer)).

# Installing

1. Copy sysvars (and the other tools if you need them) to your hard or floppy disk drive (e.g., in the c directory)
2. Add it to your startup-sequence or User-Startup
   - For OS 2.0 or greater there is no issue to call sysvars very early, even before SetPatch
   - For OS 1.3 and OS 1.2, you must ensure that ENV: exists prior running sysvars (see [limitations](#Limitations-and-Disclaimer))

# Building

The source should build with [VASM](http://www.compilers.de/vasm.html), [AsmOne](http://www.theflamearrows.info/documents/asmone.html)[^4], [AsmTwo](http://coppershade.org/articles/Code/Tools/AsmTwo/), [AsmPro](https://aminet.net/package/dev/asm/ASMPro1.19), [PhxAss](http://phoenix.owl.de/phxass_e.html) and [asmotor](https://github.com/asmotor/asmotor/tree/master)

You can also compile this in VSCode using a [nice VSCode plugin](https://github.com/prb28/vscode-amiga-assembly), a suitable configuration is included in the .vscode directory.

# Testing

There is a filesystem structure in test/sysvars-test that can be used for testing in vscode (virtual filesystem) or on a bootable floppy/partition on a real Amiga. The actual test is the startup-sequence. It uses some other utilities described [here](#The-other-Utilities).

There is a small script `CreateTestDisk` that creates such a bootable disk. The test can also be executed from Workbench (via IconX). To make it also work with KS 1.2 and 1.3, some files from Workbench 1.3 are required, which I cannot distribute. If you need this, just insert your Workbench 1.3 disk and start the script `Add OS 1.3 Support`. Note that Workbench prior 1.3 cannot be used, due to the lack of support for environment variables.

# Why such a Tool?

As many Amiga users, I have multiple Amigas, booting from flash memory. However, I do not want to maintain multiple operating system configurations. In the past, I have used several tools to branch during startup, which yielded a complex startup-sequence/user-startup and an extended boot time.

I wanted a small fast utility that gives me neat environment variables, so I can write something like this in the startup-sequence:

```
IF $CPU GE 68020 VAL
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

As sysvars is optimized for speed, being compact and system friendly, it is not an elaborate H/W detection tool, such as WhichAmiga. This means that there might be system combinations, where sysvars gets it wrong. Some known limititaions are listed below. Anyway, you can always file a bug report, if you think that sysvars can be optimized.

## Kickstart 1.3 and below
- Sysvars currently detects CPUs above 68020 as 68020 and any FPUs as 68881.
- Environment variables can only have global scope (i.e., they reside in ENV:). This means you must have ENV: mounted (e.g., to some folder on RAM:). This is not required for OS 2.0 and above.
- Environment variables can only be used with the IF command (things like
  ``ECHO $CPU`` do not work. You must use ``IF $CPU GE 68010``).

## Kickstart 1.2
- The native IF command does not support environment variables, but you can use the IF command from Workbench 1.3
- Even with the Workbench 1.3 IF command, only ``EQ`` seems to work
- ``$KickRev`` is set, but to an empty value

## Slow RAM detection
RAM speed is not actually measured. Instead, it is assumed that any non-Chip RAM residing at $C0xxxx is actually Slow RAM. This is common for the Amiga 500s with a trapdoor expansion. Thus, if you have an expansion that actually maps real Fast RAM into the $C0 region, sysvars still consideres it to be Slow RAM.

## UAE detection
UAE is detected via the uae.resource, which is only there if
- a virtual hard drive or another UAE expansion is enabled
- Kickstart is at least version 34 (OS 1.3)
Thus, detection will fail on any floppy-only-unexpanded Amiga configurations and on anything with a ROM older than 1.3

# The other Utilities

The following utilities are mainly intended to test sysvars, but could also be useful in other contexts.

## ``ksge36``
Quickly check if Kick ROM is at least version 36, that is OS 2.0 or greater. If it detects a version below 36, it returns WARN (error code 5). It can be used (like it is in the sysvar test) to write startup-sequences that work for both OS 1.3 and OS2.0+, branching where needed.

## ``probevar`` [New in 0.14]

A tool for all Amiga operating systems to quickly check for the existence of a local (OS 2.0 and up) or global (OS 1.3 and below) environment variable. It is similar to the ``Get`` command of OS 2.0 in that it returns SUCCESS (error code 0) If a variable is available and WARN (error code 5),
if not. The difference is that
1. probevar does not write out the actual value, so you do not have to do a ``>NIL:`` to suppress it
2. probevar can be used in OS 1.3 and below (only there it queries global variables)

*Why is this tool needed now?*

In the past, sysvars would set environment variables, such as ``$UAEMajor`` to an empty string if it did not detect UAE. So one could always use ``IF "$UAEMajor" EQ ""``. However, with the growing number of supported use cases and variables, the variable space became increasingly polluted.
Therefore, I decided to only ever set variables, when the environment warrants for it (see the "Availability" column [table at the top](#overview_table)). Thus, if UAE is not detected, ``$UAEMajor`` will now not be available at all. So, the line ``IF "$UAEMajor" EQ ""`` would bring up an unwanted requester asking for ENV:, because the OS tries to search for a
global variable.

# Future Plans/Known Bugs

The tool is already quite useable, but there are still some things missing, which I want to fix in future versions (no particular order):

- Add ``$RTG`` variable to enable/disable stuff like FBlit or swap screen mode configurations
- For Os 1.3: add detection for CPUs > 68020 and at least the 68882
- Make use of boards.library and identify.library if available for even more expansions.
- Make a WinUAE/FS-UAE-based test suite for automated tests (CI/CD-like)

[^1]: Slow RAM (a.k.a Ranger Memory) is explicitly not counted as Fast RAM, because it is not fast (see [limitations](#Slow-RAM-detection)).
[^2]: If you have an Amiga 500 with actual Fast RAM (e.g., through a side expansion), but also a Slow RAM trapdoor memory expansion, an unpatched OS 1.x may priorize the latter by positioning it before any other (non-Chip) RAM in the memory list. This can have a severe negative performance impact. To fix it, run FastMemFirst.
[^3]: Some beta cores might not have a valid core revision, in which case ``$VampireCoreRev`` is set to "N/A"
[^4]: Currently only the original 1.2 is supported. 1.48 and 1.49 seem to have problems with nested macros
