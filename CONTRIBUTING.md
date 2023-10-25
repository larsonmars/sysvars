**You are welcome to contribute to this project!**

If you do, please make sure that:
- You use pull requests
- The source compiles at least with ASM-{ONE|Two|Pro} and VASM
- The source is dependency-free (standard Amiga Dos libraries are ok, of course)
- The source remains in one file, because it should be kept (a) simple and (b) easily debuggable in ASM-{ONE|Two|Pro}
- You try to adopt the current style
  - Max. 60 columns including comments (so all is visible in ASM-ONE with line-numbers enabled on a standard 640 pixel wide screen mode)
  - All assembler instructions lower case (also the registers and section types)
  - No spaces between operands
  - Global labels and section names are PascalCase, local labels .camelCase
  - Constants in ALL_CAPS, except when they refer to some fixed/known symbol, such as library vector offsets. Then it is ``LVOFunctionName``
  - Comments always start with semicolon and a space
  - Comments can be either a full line or aligned for a block of code (two spaces after instruction)
- Test the result (e.g., see the test folder for an example simple harddisk configuration)

Thank You!