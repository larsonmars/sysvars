# Contributing #

**You are welcome to contribute to this project!**

If you do, please follow the rules stated below! Thank You!

## General ##
- Use pull requests
- The source compiles with [VASM](http://www.compilers.de/vasm.html), [AsmOne 1.2](http://www.theflamearrows.info/documents/asmone.html), [AsmTwo](http://coppershade.org/articles/Code/Tools/AsmTwo/), [AsmPro](https://aminet.net/package/dev/asm/ASMPro1.19), and [asmotor](https://github.com/asmotor/asmotor/tree/master)
- The source is dependency-free
  - standard Amiga Dos libraries are ok, of course
  - optional dependencies are ok, too (e.g., boards.library or identify.library)
- Please test the code, ideally in multiple configurations (e.g., see the test folder for an example simple hard disk configuration)

## Form ##  
- The source should currently remain in one file to keep it compact and easily debuggable in ASM-One and its derivatives (Includes tend to cause problems)

## Conventions ##
- Subroutines that are called more than once (utility functions) should by default preserve all but the scratch registers D0, D1, A0, A1.
- Subroutines that are called on top-level and have no interdependencies can use all registers (Please use comments stating which registers are overwritten)
- No ``NARG`` and no ``REG``[^1]

## Style ##
- Max. 60 columns including comments (so all is visible in ASM-One with line-numbers enabled on a standard 640 pixel wide screenmode)
- No spaces between operands
- Labels start at column 0 and have a colon
- Use ``endc`` instead of ``endif``[^1]
- Commenting
  - Is mandatory!
  - State your assumptions.
  - Explain your magic! The source should also serve for people to learn M68K ASM
  - Comments must always start with semicolon and a space
  - Comments can either be a full line or aligned for a block of code (two spaces after longest instruction)
- Casing
  - All assembler instructions lower case (also the registers and section types)
  - Section names in PascalCase in quotes[^1],
  - Jump/Branch labels in camelCase
  - Labels for variables/memory in PascalCase
  - Constants in ALL_CAPS, except when they refer to some fixed/known symbol, such as library vector offsets. Then it is ``_LVOFunctionName`` (by convention)
  - Macro labels in ALL_CAPS (to distinguish them easily from labels and sub routines)

  [^1]: Maintain [asmotor](https://github.com/asmotor/asmotor/tree/master) compatibility