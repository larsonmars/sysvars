# Contributing #

**You are welcome to contribute to this project!**

If you do, please follow the rules stated below! Thank You!

## General ##
- You use pull requests
- The source compiles at least with ASM-{ONE|Two|Pro} and VASM
- The source is dependency-free
  - standard Amiga Dos libraries are ok, of course
  - optional dependencies are ok, too (e.g., boards.library or identify.library)
- Please test the code, ideally in multiple configurations (e.g., see the test folder for an example simple hard disk configuration)

## Form ##  
- The source should currently remain in one file to keep it compact and easily debuggable in ASM-{ONE|Two|Pro} (Includes tend to cause problems)

## Conventions ##
- sub routines that are called more than once (utiliy functions) should by default preserve all but the scratch registers D0, D1, A0, A1.
- sub routines that are called on top-level and have no interdependencies can use all registers (Please use comments stating which registers are overwritten)

## Style ##
- Max. 60 columns including comments (so all is visible in ASM-ONE with line-numbers enabled on a standard 640 pixel wide screen mode)
- No spaces between operands
- Labels start at column 0 and have a colon
- Commenting
  - Is mandatory!
  - State your assumptions.
  - Explain your magic! The source should also serve for people to learn M68K ASM
  - Comments must always start with semicolon and a space
  - Comments can either be a full line or aligned for a block of code (two spaces after longest instruction)
- Casing
  - All assembler instructions lower case (also the registers and section types) except constants, such as ``NARG``
  - section names in PascalCase,
  - local labels .camelCase
  - non-exported sub routines (currently no plans to make a library out of the program) in camelCase (to distinguish them from OS functions)
  - Constants in ALL_CAPS, except when they refer to some fixed/known symbol, such as library vector offsets. Then it is ``_LVOFunctionName`` (by convention)
  - Macro labels in ALL_CAPS (to distinguish them easily from labels and sub routines)