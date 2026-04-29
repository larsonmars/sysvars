************************************************************
*                                                          *
*                      SYSVARS V.0.19                      *
*                                                          *
* SPDX-FileCopyrightText: (c) 2023-2025 Lars Stockmann     *
* SPDX-License-Identifier: MIT                             *
*                                                          *
*                                                          *
* SYNOPSIS:                                                *
*                                                          *
* Puts system information into environment variables       *
*                                                          *
************************************************************

PROGVER: macro
    dc.b "$VER: SYSVARS 0.19",0
    endm

******************** Feature Selection *********************

DISABLE: macro
E_\1 = 0
    endm

; Uncomment to disable environment variable!
; With vasm, you can also disable them on the command line
; like so: -DDISABLE_CPU

    ; DISABLE KickVer
    ; DISABLE KickRev

    ; DISABLE CPU
    ; DISABLE CPURev
    ; DISABLE FPU

    ; DISABLE Chipset
    ; DISABLE VFreq

    ; DISABLE TotalRam
    ; DISABLE TotalChipRam
    ; DISABLE TotalSlowRam
    ; DISABLE TotalFastRam
    ; DISABLE SlowRamFirst

    ; DISABLE BSDSockLibVer
    ; DISABLE BSDSockLibRev
    ; DISABLE BSDSockLib

    ; DISABLE Emulation
    ; DISABLE UAEMajor
    ; DISABLE UAEMinor
    ; DISABLE UAERev

    ; DISABLE VampireCoreRev
    ; DISABLE VampireType
    ; DISABLE VampireClockMult


************** Feature Selection Evaluation ****************

; Checks if any of the environment variables is disabled,
; either above, or via compile parameter

CHECK_ENABLED: macro
    ifnd E_\1
        ifd DISABLE_\1
E_\1 = 0
        else
E_\1 = 1
        endc
    endc
    endm

    CHECK_ENABLED KickVer
    CHECK_ENABLED KickRev

    CHECK_ENABLED CPU
    CHECK_ENABLED CPURev
    CHECK_ENABLED FPU

    CHECK_ENABLED Chipset
    CHECK_ENABLED VFreq

    CHECK_ENABLED TotalRam
    CHECK_ENABLED TotalChipRam
    CHECK_ENABLED TotalSlowRam
    CHECK_ENABLED TotalFastRam
    CHECK_ENABLED SlowRamFirst

    CHECK_ENABLED BSDSockLibVer
    CHECK_ENABLED BSDSockLibRev
    CHECK_ENABLED BSDSockLib

    CHECK_ENABLED Emulation
    CHECK_ENABLED UAEMajor
    CHECK_ENABLED UAEMinor
    CHECK_ENABLED UAERev

    CHECK_ENABLED VampireCoreRev
    CHECK_ENABLED VampireType
    CHECK_ENABLED VampireClockMult    
    
********************  Global Constants  ********************

FALSE =  0
TRUE  = -1

; exception vectors
IllegalInstructionVector    EQU $10
Line1111EmulatorVector      EQU $2c

CPU_68000   EQU 0
CPU_68010   EQU 1
CPU_68020   EQU 2
CPU_68030   EQU 3
CPU_68040   EQU 4
CPU_68060   EQU 6
CPU_68080   EQU 8

FPU_NONE    EQU 0
FPU_68881   EQU 1
FPU_68882   EQU 2
FPU_INT     EQU 3

EMU_NONE    EQU 0
EMU_UAE     EQU 1
EMU_MUSASHI EQU 2
EMU_EMU68   EQU 3

; processor configuration register disable floating-point unit (68060)
PCRB_DPF EQU 1
PCRF_DPF EQU 1<<1

; cache control enable data cache (68030)
CACRB_ED EQU 8
CACRF_ED EQU 1<<8

; cache control instruction cache enable (68040+)
CACRB_IE EQU 15
CACRF_IE EQU 1<<15

AC68080_ID EQU $0440
MC68060_ID EQU $0430

; Exec Constants and _LVOs
EXEC_BASE      = 4
EXEC_Node_SIZE = 14
EXEC_LIB_HDR_S = EXEC_Node_SIZE+20
EXEC_O_LIB_VER = EXEC_Node_SIZE+6

; exec.library
_LVOSupervisor = -30
_LVOFindName     = -276
_LVOCloseLibrary = -414
_LVOOpenResource = -498
_LVOOpenLibrary  = -552

_LVOAttnFlags = $128
_LVOResourceList = $150

; expansion.library
_LVOFindConfigDev = -72
musashi_mid EQU $7db
musashi_interaction_pid EQU $6b

; Dos _LVOs

_LVOSetVar = -900

; Flags

GVF_LOCAL_ONLY = $200


************************* Macros  **************************


;-----------------------------------------------------------
; get's exec.library base address to passed address register
;-----------------------------------------------------------
; Macro Arguments:
; 1: address register to store the exec.library address in
;-----------------------------------------------------------
EXECBASE macro
	movea.l EXEC_BASE.w,\1
  endm

;-----------------------------------------------------------
; Uses the sysvars naming scheme to generate environment
; variable name string.
;-----------------------------------------------------------
; Macro Arguments:
; 1: Environment variable name
;-----------------------------------------------------------
DEFINE_ENV_VAR: macro
    if E_\1                    ; if not enabled, do not set
\1EnvVarName: dc.b "\1",0
    endc
    endm

;-----------------------------------------------------------
; Macro to set environment variable
;-----------------------------------------------------------
; Macro Arguments:
; 1: Environment variable name
; 2: long address to content string
; 3: long source for length (register, variable...)
;-----------------------------------------------------------
; Note: There is a dedicated version for short constant
;       length values
;-----------------------------------------------------------
; Potentially overwrites: D0, D1, D2, D3, A0, A1
;-----------------------------------------------------------
SET_ENV_VAR: macro
    if E_\1                          ; Only set if enabled
        move.l #\1EnvVarName,d1      ; arg1: name address
        ifnc "\2",""
            move.l \2,d2             ; arg2: content address
            ifnc "\3",""
                move.l \3,d3         ; arg3: content length
            else
                moveq #-1,d3
            endc
        else
            moveq #0,d3
        endc
        bsr    setEnvVar
        bne.b  .setVarDone\@
        move.l #\1EnvVarName,d1      ; print error
        bsr    printErrorMsg
        moveq  #0,d0                 ; indicate error
.setVarDone\@:
    endc
    endm

;-----------------------------------------------------------
; Macro to set environment variable with a known content
; length < 128
;-----------------------------------------------------------
; Arguments: 1: Environment variable name
;            2: long address to content string
;            3: length constant (< 128, -1 for null-
;               terminated content)
;-----------------------------------------------------------
; Potentially overwrites: D0, D1, D2, D3, A0, A1
;-----------------------------------------------------------
SET_ENV_VAR_CLEN: macro
    if E_\1                         ; Only set if enabled
        move.l #\1EnvVarName,d1     ; arg1: name address
        ifne \3
        move.l \2,d2                ; arg2: content address
        endc
        moveq  #\3,d3               ; arg3: content length
        bsr    setEnvVar
        bne.b .setVarDone\@
        move.l #\1EnvVarName,d1     ; print error
        bsr   printErrorMsg
        moveq #0,d0                 ; indicate error
.setVarDone\@:
    endc
    endm

;-----------------------------------------------------------
; Macro to set an environment variable to hold a number
;-----------------------------------------------------------
; Arguments: 1: Environment variable name
;            2: source for number
;-----------------------------------------------------------
; Potentially overwrites: D0, D1, D2, D3, A0, A1
;-----------------------------------------------------------
SET_NUMERIC_ENV_VAR: macro
    if E_\1                   ; if not enabled, do not set
        ifnc "\2","d0"
            move.l \2,d0
        endc
        bsr    printNumber
        SET_ENV_VAR \1,a1,d0
    endc
    endm

;-----------------------------------------------------------
; Macro to delete environment variable
;-----------------------------------------------------------
; Arguments: 1: Environment variable name
;-----------------------------------------------------------
; Potentially overwrites: D0, D1, D2, D3, A0, A1
;-----------------------------------------------------------
DELETE_ENV_VAR: macro
    if E_\1                            ; Only set if enabled
        move.l #\1EnvVarName,d1        ; arg1: name address
        bsr    deleteEnvVar
.deleteVarDone\@:
    endc
    endm

;-----------------------------------------------------------
; Macro that creates a stack frame that is guaranteed to be
; long word aligned so you can copy in 32bit
;-----------------------------------------------------------
; Arguments: 1: source of desired size
;-----------------------------------------------------------
; After invocation, D0 will hold the actual size of the
; stack frame.
;-----------------------------------------------------------
CREATE_ALIGNED_STACK_FRAME: macro
    ifnc "\1","d0"
        move.l \1,d0
    endc
    neg.l   d0       ; stack grows negative
    add.l   sp,d0    ; d0 possibly analigned address
    ; round d0 down to multiple of 4 to align to 32 bit
    andi.b  #$fc,d0  ; clear last 2 bits
    sub.l   sp,d0
    neg.l   d0
    sub.l   d0,sp
    endm

;-----------------------------------------------------------
; Macro that performs a 32bit integer multiplication by 10.
; No overflow check is performed!
;-----------------------------------------------------------
; Arguments: 1: source reg. that is to be multiplied by 10
;            2: target reg. that receives result
;-----------------------------------------------------------
LMUL10: macro
    ifc "\1","\2"
        fail "Source and target register must be distinct!"
    endc
    move.l \1,\2
    add.l \2,\2 ; x * 2
    add.l \2,\2 ; x * 4
    add.l \1,\2 ; x * 5
    add.l \2,\2 ; x * 10
    endm

;-----------------------------------------------------------
; Macro to conveniently open the library with the given
; name. After completion, the library ref is stored in D0
; and the status bits are set.
;-----------------------------------------------------------
; Arguments: 1: Library name 
;            2: Minimum Version of Library
;            3 (opt.): place used to preserve A6.
;                      Note: Don't use a scratch register as
;                            it will be overwritten!
;-----------------------------------------------------------
; Potentially overwrites: D0, D1, A0, A1
; Overwrites A6 if no 3. argument is given to preserve it
;-----------------------------------------------------------
OPEN_LIBRARY: macro 
    lea   \1,a1   ; library name
    moveq #\2,d0  ; version is macro param

    ifc "\3","d0"
        fail "Do not use scratch register D0!"
    endc
    ifc "\3","d1"
        fail "Do not use scratch register D1!"
    endc
    ifc "\3","a0"
        fail "Do not use scratch register A0!"
    endc
    ifc "\3","a1"
        fail "Do not use scratch register A1!"
    endc
    ifnc "\3",""
        movea.l a6,\3
    endc

    EXECBASE a6         ; get exec base in A6
    jsr     _LVOOpenLibrary(a6)
    ifnc "\3",""
        movea.l \3,a6
    endc
    tst.l   d0
    endm

;-----------------------------------------------------------
; Macro to conveniently close a library
;-----------------------------------------------------------
; Arguments: 1: lbrary reference
;            2 (opt.): place used to preserve A6.
;                      Note: Don't use a scratch register as
;                            it will be overwritten!
;-----------------------------------------------------------
; Potentially overwrites: D0, D1, A0, A1
; Overwrites A6 if no 3. argument is given to preserve it
;-----------------------------------------------------------
CLOSE_LIBRARY: macro
        ifnc "\1","a1"
            movea.l \1,a1  ; library pointer
        endc

        ifc "\2","d0"
            fail "Do not use scratch register D0!"
        endc
        ifc "\2","d1"
            fail "Do not use scratch register D1!"
        endc
        ifc "\2","a0"
            fail "Do not use scratch register A0!"
        endc
        ifc "\2","a1"
            fail "Do not use scratch register A1!"
        endc
        ifnc "\2",""
            movea.l a6,\2
        endc

    EXECBASE a6         ; get exec base in A6
    jsr     _LVOCloseLibrary(a6)
    ifnc "\2",""
        movea.l \2,a6
    endc
    endm

************************ Main Entry ************************
   
    section "Code",CODE

main:
    ; A6 is assumed to point to dos.library throughout the
    ; program. A6 = 0 indicates that dos.library is not
    ; loaded

    suba.l a6,a6    
    OPEN_LIBRARY DosLibName,0
    move.l d0,a6

    bsr setAllVariables

    CLOSE_LIBRARY a6  ; close dos.library
    moveq #0,d0       ; return code 0
    rts

    section "Strings",CODE

DosLibName: dc.b "dos.library",0

************************ Kickstart *************************

    if E_KickVer+E_KickRev
    
    section "Code",CODE
;-----------------------------------------------------------
; Determines the kickstart version and revision and puts
; them into environment variabes $KickVer and $KickRev
;
; Note: Below Kickstart 1.2, the revision cannot be
;       determined and the respective environment variable
;       is set without content.
;-----------------------------------------------------------
; IN/OUT: A6 - dos.library reference
;-----------------------------------------------------------
; Potentially overwrites all registers, except A6
;-----------------------------------------------------------
setKickstartEnvVars:

KS_END            = $1000000
KS_END_OFFSET_LEN = -20
KS_VER_OFFSET     = 12

_LVOSoftVer   = $14

    lea    KS_END,a0
    suba.l KS_END_OFFSET_LEN(a0),a0  ; Subtract KS length
    lea    KS_VER_OFFSET(a0),a0
    moveq  #0,d5                     ; clean D5
    moveq  #0,d6                     ; clean D6
    move.w (a0)+,d5                  ; KickVer --> D5
    move.w (a0),d6                   ; KickRev --> D6

    ; On KS < 1.2, this mechanism will not work and both
    ; KickVer and KickRev are $ffff (-1).
    bpl.b .setEnvVar  ; test sign of last move

    ; On KS < 1.2, we detect that here and fetch the version
    ; via _LVOSoftVer of EXEC.
    EXECBASE a6                     ; get exec base in A6
    move.w  _LVOSoftVer(a0),d5      ; get KS version
    SET_NUMERIC_ENV_VAR KickVer,d5
    SET_ENV_VAR KickRev
    rts

.setEnvVar:
    SET_NUMERIC_ENV_VAR KickVer,d5
    SET_NUMERIC_ENV_VAR KickRev,d6
    rts

    section "Strings",CODE

    DEFINE_ENV_VAR KickVer
    DEFINE_ENV_VAR KickRev

    endc

*********************** CPU and FPU ************************

    if E_CPU+E_FPU+E_CPURev
    
    section "Code",CODE

;-----------------------------------------------------------
; Determines the CPU and FPU type and writes it into
; environment variables $CPU and $FPU
;
; 68080 detection according to
; http://adevnoo.wikidot.com/detect-080-code
;
; Note: Below Kickstart 2.0, CPUs > 68020 are recognized as
;       68020 and all FPUs are recognized as 68881.
;-----------------------------------------------------------
; IN/OUT: A6 - dos.library reference
;-----------------------------------------------------------
; Potentially overwrites all registers, except A6
;-----------------------------------------------------------
setCPUAndFPUEnvVars:
    ; detect CPU
    EXECBASE a0             ; get exec base in A0
    lea .detectCPU(pc),a5   ; fetch pointer to function
    jsr _LVOSupervisor(a0)  ; execute function in supervisor
                            ; mode

    move.l  d7,d0
    add.l   #$30,d0         ; convert to ascii
    lea     CPUStr,a0
    move.b  d0,3(a0)
    ; set cpu environment variable
    SET_ENV_VAR CPU,#CPUStr

    ; detect FPU
    EXECBASE a0             ; get exec base in A0
    move.l  d7,d1           ; recall cpu model
    lea .detectFPU(pc),a5
    jsr _LVOSupervisor(a0)

; D0 gets the FPU version as ASCII character that replaces
; the "?" in "6888?" or the whole string gets mangled
.writeFPUString:
    lea     FPUStr,a0
    cmp.l   #FPU_NONE,d0
    beq.s   .fpuNone
    cmp.l   #FPU_INT,d0
    beq.s   .fpuInternal
    add.l   #$30,d0         ; convert to ascii

.fpu68882:
.fpu68881:
    move.b  d0,4(a0)
    ; zero terminate the string
    move.b  #0,5(a0)
    bra.s   .setFPUEnvVar
.fpuNone:
    DELETE_ENV_VAR FPU
    bra.s   .end
.fpuInternal:
    move.l #"inte",(a0)    ; "internal"
.setFPUEnvVar:
    SET_ENV_VAR FPU,#FPUStr

    ; set CPU revision for MC68060/AC68080
    cmp.b #CPU_68040,d7
    ble.s .end
    SET_NUMERIC_ENV_VAR CPURev,d6

.end
    rts

    section "Code",CODE

;-----------------------------------------------------------
; Determines the CPU type
; This function must be called in supervisor mode
;
; Based on code by
; Chris Hooper: detecting MC680x0 cpus by cleverly
; exploiting their CACR and PCR capabilities
; https://github.com/cdhooper/amigapci_stm32/blob/main/amiga/cpu_control.c

; Photon: call a function in supervisor mode and use
; dc.w to allow compiling with 68000 function set
; http://coppershade.org/asmskool/PhotonsMiniStartup/PhotonsMiniWrapper1.04!.S

; Markus Wandel: providing Kickstart 1.2 disassembly to ensure
; that - and how - MC68010 and MC68020 detection is done
; https://wandel.ca/homepage/execdis/exec_disassembly.txt

; Apollo AC68080 PROGRAMMER'S REFERENCE MANUAL
; telling the MC68060 and AC68080 apart by its PCR ID value
; http://www.apollo-core.com/documentation/AC68080PRM.pdf
;
;-----------------------------------------------------------
; OUT: D7 - CPU type
;      D6 - CPU revision (MC68060/AC68080 only)
;
;-----------------------------------------------------------
; Note: Doesn't preserve any registers
;-----------------------------------------------------------

.detectCPU:
    EXECBASE a0             ; get exec base in A0

    ; save Illegal Instruction vector from absolute address
    move.l  IllegalInstructionVector.w,d6
    ; install Illegal Instruction trap on absolute address
    lea     .illegalInstructionTrap(pc),a0
    move.l  a0,IllegalInstructionVector.w

    moveq   #CPU_68000,d7   ; assume 68000
    ; execute instruction illegal on MC68000
    dc.w    $4e7a,$0801     ; movec vbr,d0

    tst.l   d0              ; check for zero VBR
    beq.s   .zeroVBR

    ; install Illegal Instruction trap on vbr address
    movea.l d0,a1
    move.l  IllegalInstructionVector(a1),d5
    move.l  a0,IllegalInstructionVector.w(a1)

.zeroVBR:
    moveq   #CPU_68010,d7   ; assume 68010
    ; execute instruction illegal on MC68010
    dc.w    $4e7a,$0002     ; movec cacr,d0

    moveq   #CPU_68020,d7   ; assume 68020
    move.l  #CACRF_IE,d1    ; CACR value to enable 68040+
                            ; instruction cache
    jsr     .writeCACR(pc)

    btst    #CACRB_IE,d1    ; test for 68040
    bne.s   .is040

    ; it's either 68020 or 68030
    move.l  #CACRF_ED,d1    ; CACR value to enable 68030
                            ; data cache
    jsr     .writeCACR(pc)
    btst    #CACRB_ED,d1
    beq.s   .detectCPU_end  ; it's 68020

	moveq   #CPU_68030,d7   ; it's 68030
    bra.s   .detectCPU_end

.is040:
    moveq   #CPU_68040,d7   ; assume 68040
    dc.w    $4e7a,$1808     ; hex for 'movec.l pcr, d1 ; read pcr

    ; store revision
    moveq   #0,d6
    move.w  d1,d6
    lsr.w   #8,d6
    ; it's either MC68060 or AC68080
    moveq   #CPU_68080,d7   ; assume 68080
    clr.w   d1
    swap    d1
    cmp.w   #AC68080_ID,d1
    beq.s   .detectCPU_end  ; it's 68080
    moveq   #CPU_68060,d7   ; it's 68060
    bra.s   .detectCPU_end

.cleanupCPU
    ; restore Illegal Instruction vector on absolute address
    move.l  d6,IllegalInstructionVector.w
    tst.l   d7
    beq.s   .detectCPU_end

    ; check if Illegal Instruction vector on VBR address needs to be restored 
    dc.w    $4e7a,$1801     ; movec vbr,d1
    tst.l   d1
    beq.s   .detectCPU_end

    ; restore Illegal Instruction vector on VBR address
    move.l  d1,a1
    move.l  d5,IllegalInstructionVector(a1)
.detectCPU_end
    rte

.illegalInstructionTrap:
    tst.l   d7
    bne.s   .sixWordFrame
; 68000 generates 4 word stack frames on exception (Four-Word Stack Frame, Format $0)
.fourWordFrame
    addq.l  #$6,sp
    bra.s   .cleanupCPU
; 68010+ generate 6 word stack frames on exception (Six-Word Stack Frame, Format $2)
.sixWordFrame
    addq.l  #$8,sp
    bra.s   .cleanupCPU

.writeCACR
    dc.w    $4e7a,$0002     ; hex for 'movec.l cacr, d0' ; save cacr
    dc.w    $4e7b,$1002     ; hex for 'movec.l d1, cacr' ; write cacr
    dc.w    $4e7a,$1002     ; hex for 'movec.l cacr, d1' ; read cacr back
    dc.w    $4e7b,$0002     ; hex for 'movec.l d0, cacr' ; restore cacr
    rts

;-----------------------------------------------------------
; Determines the FPU type and FPU version, returns them in
; registers D0 and D1
; This function must be called in supervisor mode
;
; Based on information obtained from:
; 1. MOTOROLA M68000 FAMILY Programmer’s Reference Manual Rev.1
; 2. M68060 User’s Manual
; 3. MC68881/882 Floating-point Coprocessor User's Manual Second Edition
;
;-----------------------------------------------------------
; IN:  D1 - CPU type
; OUT: D0 - FPU type
;      D1 - FPU version
;-----------------------------------------------------------
; Note: Doesn't preserve any registers
;-----------------------------------------------------------
.detectFPU:
    move.l  d1,d7

    cmp.l   #CPU_68060,d7
    blo.s   .no060
    ; try enabling fpu on MC68060
    dc.w    $4e7a,$0808     ; hex for 'movec.l pcr, d0 ; read pcr
    and.b   #(~PCRF_DPF),d0
    dc.w    $4e7b,$0808     ; hex for 'movec.l d0, pcr ; write pcr

.no060:
    ; save Line 1111 Emulator (Unimplemented F-Line Opcode) vector
    move.l  Line1111EmulatorVector.w,d3
    lea     .line1111Trap(pc),a0
    move.l  a0,Line1111EmulatorVector.w

    ; check for any fpu
    moveq   #FPU_NONE,d0    ; assume no fpu
    dc.w    $f280,$0000     ; fnop

    moveq   #1,d0           ; assume mc68881
    dc.w    $f327           ; fsave -(sp)
    moveq   #0,d1
    moveq   #0,d2
    move.b  (sp),d1         ; get fpu version
    move.b  1(sp),d2        ; get state frame size
    dc.w    $f35f           ; frestore (sp)+
    cmpi    #$18,d2         ; MC68881 idle state frame size is $18
    beq.s   .cleanup
    cmpi    #$38,d2         ; MC68882 idle state frame size is $38
    beq.s   .mc68882
    tst.w   d2              ; MC68040 idle state frame size is $00
                            ; MC68060 has a different frame format
    beq.s   .internal
    moveq   #0,d0           ; assume no fpu
    beq.s   .cleanup

.internal
    moveq   #FPU_INT,d0     ; internal 68040/68060/68080 fpu
    bra.s   .cleanup

.mc68882
    moveq   #FPU_68882,d0   ; mc68882 fpu

.cleanup
    ; restore Line 1111 Emulator (Unimplemented F-Line Opcode) vector
    move.l  d3,Line1111EmulatorVector.w
    rte

.line1111Trap:
    cmp.l   #CPU_68000,d7
    beq.s   .fourwordframe
    cmp.l   #CPU_68040,d7
    blo.s   .sixwordframe
; MC68EC040 and MC68LC040 Floating-Point Unimplemented Stack Frame, Format $4
.eightwordframe
    lea     $10(sp),sp
    bra.s   .cleanup
; all other cpus except 68000 without fpu generate 6 word stack frames on exception
; (Six-Word Stack Frame, Format $2)
.sixwordframe
    addq.l  #$8,sp
    bra.s   .cleanup
; 68000 generates 4 word stack frames on exception (Four-Word Stack Frame, Format $0)
.fourwordframe
    addq.l  #$6,sp
    bra.s   .cleanup

    section "VariableData",DATA
    
CPUStr:
    dc.b "680?0",0

; The string for the FPU is composed using a long  move.
; Thus the target string must be aligned accordingly.
    cnop 0,4
FPUStr:
    dc.b "6888rnal",0
    
    section "Strings",CODE

    DEFINE_ENV_VAR CPU
    DEFINE_ENV_VAR CPURev
    DEFINE_ENV_VAR FPU    

    endc

********************* Vampire Support **********************

    if E_VampireType+E_VampireCoreRev+E_VampireClockMult
    
    section "Code",CODE

;-----------------------------------------------------------
; Determines the type, core revision and clock multiplier
; and writes it into environment variables $VampireType,
; $VampireCoreRev and $VampireClockMult
;-----------------------------------------------------------
; IN/OUT: A6 - dos.library reference
;-----------------------------------------------------------
; Potentially overwrites all registers, except A6
;-----------------------------------------------------------
setVampireEnvVars:

VAMP_CORE_REV_ADDR = $dff3ea
VAMP_VER_ADDR      = $dff3fc

; We skip the Vampire detection if no 68080 CPU is present.
; Thus, check again AttnFlags...
    EXECBASE a0                     ; get exec base in A0
    move.w  _LVOAttnFlags(a0),d5    ; get cpu info in D5
    btst    #10,d5
    bne.b   .haveVampire

; no vampire    
    DELETE_ENV_VAR VampireCoreRev
    DELETE_ENV_VAR VampireType
    DELETE_ENV_VAR VampireClockMult
    rts      

.haveVampire:
; Vampire Core Revision
    if E_VampireCoreRev

    moveq  #0,d0
    move.w VAMP_CORE_REV_ADDR,d0
    beq.b  .setCoreRevNotAvailable  ; 0 is invalid
    bmi.b  .setCoreRevNotAvailable  ; negative is invalid

    SET_NUMERIC_ENV_VAR VampireCoreRev,d0
    bra.b   .processClockMultAndVersion

.setCoreRevNotAvailable:
    SET_ENV_VAR_CLEN VampireCoreRev,#VAMP_CORE_REV_NA,-1

    endc

.processClockMultAndVersion:
    if E_VampireType+E_VampireClockMult
    move.w VAMP_VER_ADDR,d4 ; D4, bec. D0-D3 are overwritten

    ; Clock Multiplier
    moveq  #0,d0 ; clean D0
    move.b d4,d0 ; lower 8 bits are clock mult

    SET_NUMERIC_ENV_VAR VampireClockMult,d0

    ; Vampire Card
    lea    VAMP_T_UNKNOWN,a0    ; A0 -> unknown as default
    lea    VAMP_TYPE_OFFSETS,a1 ; we need the offsets later
    lsr.w  #8,d4                ; get higher 8 bits for type
    subq.b #1,d4                ; constants start at 1
    bmi.b  .setVampType         ; if < 0, print unknown
    cmpi.b #VAMP_TYPE_COUNT,d4  ; compare against type count 
    bge.b  .setVampType         ; if greater, print unknown
    lea    VAMP_TYPE_STRINGS,a0 ; valid type, A0 -> strings
    move.b (a1,d4),d4           ; nth (D4) offset into D4
    adda   d4,a0                ; Add offset (D4) to A0

.setVampType:
    SET_ENV_VAR_CLEN VampireType,a0,-1

    endc

    rts 
  
    section "Strings",CODE

    DEFINE_ENV_VAR VampireCoreRev
    DEFINE_ENV_VAR VampireType
    DEFINE_ENV_VAR VampireClockMult

VAMP_CORE_REV_NA: dc.b "N/A",0

    if E_VampireType

VAMP_TYPE_STRINGS:
VAMP_T_1:       dc.b "V2_600",0
VAMP_T_2:       dc.b "V2_500",0
VAMP_T_3:       dc.b "V4_500/1000/2000",0
VAMP_T_4:       dc.b "V4_1200",0
VAMP_T_5:       dc.b "V4_Standalone",0
VAMP_T_6:       dc.b "V2_1200",0
VAMP_T_7:       dc.b "V4_600",0
VAMP_T_8:       dc.b "V4_A6000",0
VAMP_T_UNKNOWN: dc.b "Unknown",0

VAMP_TYPE_OFFSETS:
    dc.b VAMP_T_1-VAMP_TYPE_STRINGS
    dc.b VAMP_T_2-VAMP_TYPE_STRINGS
    dc.b VAMP_T_3-VAMP_TYPE_STRINGS
    dc.b VAMP_T_4-VAMP_TYPE_STRINGS
    dc.b VAMP_T_5-VAMP_TYPE_STRINGS
    dc.b VAMP_T_6-VAMP_TYPE_STRINGS
    dc.b VAMP_T_7-VAMP_TYPE_STRINGS
    dc.b VAMP_T_8-VAMP_TYPE_STRINGS
    dc.b VAMP_T_UNKNOWN-VAMP_TYPE_STRINGS
VAMP_TYPE_OFFSETS_END:

VAMP_TYPE_COUNT = VAMP_TYPE_OFFSETS_END-VAMP_TYPE_OFFSETS

    endc

    endc

******************** Chipset and VFreq *********************

    if E_Chipset+E_VFreq

VPOSR  = $dff004
POTGOR = $dff016

    section "Code",CODE

;-----------------------------------------------------------
; Determines the availble chipset (OCS, ECS, AGA, SAGA) and
; the vertical frequency (50/60) in Hz and fills the
; environment variables $Chipset and $VFreq
;
; SAGA detection according to
; http://adevnoo.wikidot.com/detect-080-code
;-----------------------------------------------------------
; IN/OUT: A6 - dos.library reference
;-----------------------------------------------------------
; Potentially overwrites all registers, except A6
;-----------------------------------------------------------
setChipsetAndVFreqEnvVars:
    ; Check SAGA via chip ID of POTGOR register
    move.l #"SAGA",d5
    move.w POTGOR,d0
    andi.w #$fe,d0       ; mask chip ID (bits 1-7)
    bne.b  .storeChipset

    ; We use VPOSR to detect Agnus/Alice
    move.b VPOSR,d1  ; get VPOSR bits
    andi.b #$7f,d1   ; mask out LOF
    move.b d1,d0     ; bits in D0

    ; D5 is used to create the chipset string.
    move.l #"OCS_"-"_",d5 ; "OCS\0"
    cmpi.b #10,d0
    bls.b  .storeChipset
    move.l #"ECS_"-"_",d5 ; "ECS\0"
    andi.b #$F,d0
    cmpi.b #1,d0
    bls.b  .storeChipset
    move.l #"AGA_"-"_",d5 ; "AGA\0"
    cmpi.b #3,d0
    bhi.b  .getVFreq

.storeChipset:
    move.l d5,ChipsetStr                  

.getVFreq:
    move.b d1,d0         ; bits in D0
    ; PAL or NTSC shall result in "5" or "6" in D1
    lsr.b  #4,d0
    andi.b #1,d0         ; 0 (PAL) 1 (NTSC)
    addi.b #'5',d0       ; "5" (PAL) "6" (NTSC)
    move.b d0,VFreqStr
    
    SET_ENV_VAR_CLEN Chipset,#ChipsetStr,-1
    SET_ENV_VAR_CLEN VFreq,#VFreqStr,2
    rts
    
    section "VariableData",DATA

    ; Note: ChipsetStr is cmposed using a long move. Thus
    ;       the target string must be aligned
    cnop 0,4
ChipsetStr: dc.b "?",0,0,0,0
VFreqStr:   dc.b "?0"

    section "Strings",CODE

    DEFINE_ENV_VAR Chipset
    DEFINE_ENV_VAR VFreq

    endc

************************** Memory **************************

    if E_TotalRam+E_TotalChipRam+E_TotalFastRam+E_TotalSlowRam

    section "Code",CODE

;-----------------------------------------------------------
; Determines the installed RAM (total, Chip, Fast and Slow)
; and fills the environment variables $TotalRam,
; $TotalFastRam, $TotalChipRam, if present $TotalSlowRam,
; and $SlowRamFirst
;-----------------------------------------------------------
; IN/OUT: A6 - dos.library reference
;-----------------------------------------------------------
; Potentially overwrites all registers, except A6
;-----------------------------------------------------------
setMemoryEnvVars:

TID_MEM = $a

_LVOMemList      = $142

CHIP_MEM_BIT = 1
FAST_MEM_BIT = 2

ln_Type = $08
ln_Pri  = $09
ln_Name = $0a

mh_Attributes = $0e
mh_Lower      = $14
mh_Upper      = $18

    EXECBASE a0                 ; get exec base in A0
    move.l _LVOMemList(a0),d0   ; get memory list

; initialize registers
; Note: D0 - D3 are potentially overwritten by SET_ENV_VAR
; and DELETE_ENV_VAR. Hence, only use D4 and up

    moveq  #0,d4      ; D4 will hold total chip ram  
    moveq  #0,d5      ; D5 will hold total fast ram
    moveq  #0,d6      ; D6 will hold total slow ram  
    move.l #$ffff,d7  ; D7 needed as operand

.traverseMemList:
    movea.l d0,a3
    cmp.b   #TID_MEM,ln_Type(a3)  ; check if type is memory
    bne.b   .next
    move.w  mh_Attributes(a3),d1  ; signify chip vs. fast
    beq.b   .next                 ; 0 is invalid
    move.l  mh_Lower(a3),a1       ; mem start address
    move.l  mh_Upper(a3),a2       ; mem end address

; Calculate the size in D2, rounding up on 64K boundary
    move.l a2,d2
    sub.l  a1,d2
    add.l  d7,d2
    swap   d2    
    and.l  d7,d2
    lsl.l  #6,d2

; Check if it is chip ram
    btst  #CHIP_MEM_BIT,d1
    beq.b .processOtherMem
    add.l d2,d4             ; add amount to total chip ram
    bra.b .next

.processOtherMem:
    btst   #FAST_MEM_BIT,d1
    beq.b  .next
    move.l a1,d0    
    swap   d0
    cmp.w  #$c0,d0          ; usuallly, slow ram reside here
    beq.b  .processSlowRam
    add.l  d2,d5            ; add amount to total fast ram
    bra.b .next

.processSlowRam:
    add.l  d2,d6  ; add amount to total slow ram

    ; Now test if slow ram came first (total fast ram = 0)
    tst.l d5
    ; if not remove the SlowRamFirst variable
    bne.b .removeSlowRamFirstVariable
    ; otherwise set this variable to '1' (D3 is the length)
    moveq #1,d3
    SET_ENV_VAR SlowRamFirst,#_SlowRamFirstVal,d3
    bra.b .next

.removeSlowRamFirstVariable:
    DELETE_ENV_VAR SlowRamFirst

.next:
    move.l (a3),d0
    bne.b  .traverseMemList

; done with the traversal, set the variables
    SET_NUMERIC_ENV_VAR TotalChipRam,d4
    SET_NUMERIC_ENV_VAR TotalFastRam,d5
    move.l d4,d0
    add.l  d5,d0
    add.l  d6,d0
    SET_NUMERIC_ENV_VAR TotalRam,d0

    tst.l d6
    beq.b .removeSlowRamVariable
    SET_NUMERIC_ENV_VAR TotalSlowRam,d6
    rts

.removeSlowRamVariable
    DELETE_ENV_VAR TotalSlowRam
    rts

    
    section "Strings",CODE

    DEFINE_ENV_VAR TotalRam
    DEFINE_ENV_VAR TotalChipRam
    DEFINE_ENV_VAR TotalFastRam
    DEFINE_ENV_VAR TotalSlowRam
    DEFINE_ENV_VAR SlowRamFirst

_SlowRamFirstVal: dc.b "1"

    endc


******************** bsdsocket.library *********************

    if E_BSDSockLibVer+E_BSDSockLibRev+E_BSDSockLib
    
    section "Code",CODE
;-----------------------------------------------------------
; Checks if bsdsocket.library is available and if so, puts
; its version, revision and identifier into environment
; variables $BSDSockLibVer and $BSDSockLibRev and
; $BSDSockLib.
; If bsdsocket.library is not available the variables are
; set without content
;-----------------------------------------------------------
; IN/OUT: A6 - dos.library reference
;-----------------------------------------------------------
; Potentially overwrites all registers, except A6
;-----------------------------------------------------------
setBSDSockLibEnvVars:
    OPEN_LIBRARY BSDSockLibName,0,a5
    beq .notOpened

    ; Fetch infos
    move.l d0,a4                  ; preserve library ref
    lea    EXEC_O_LIB_VER(a4),a0  ; Get lib version member
    moveq  #0,d5
    moveq  #0,d6
    move.w (a0)+,d5               ; store version in D5
    move.w (a0)+,d6               ; store revision in D6
    move.l (a0),d7                ; store id string in D7

    ; Note: For some reason, under the AROS ROM, SetVar
    ;       cannot access the id string directly, so we must
    ;       copy it to stack first
    move.l sp,a3  ; preserve SP
    move.l d7,a1  ; Arg1 for strlen (id string)
    bsr    strlen
    move.l d0,d4  ; preserve the length for subsequent calls
    ; add one for null terminator and also make the length
    ; in D0 word-aligned
    addq   #2,d0
    andi.b #$fe,d0
    suba.l d0,sp   ; create stack frame

    move.l  sp,a0  ; get start of stack frame into A0
    movea.l d7,a1  ; get id string again into A1 for copy

.copyIdString:
    move.b (a1)+,(a0)+
    bne.b  .copyIdString

    CLOSE_LIBRARY a4,a5
    ; Set variables
    SET_ENV_VAR BSDSockLib,sp,d4
    move.l a3,sp; restore SP
    SET_NUMERIC_ENV_VAR BSDSockLibVer,d5
    SET_NUMERIC_ENV_VAR BSDSockLibRev,d6

    rts

.notOpened:
    ; We try to delete the environment variables
    DELETE_ENV_VAR BSDSockLibVer
    DELETE_ENV_VAR BSDSockLibRev
    DELETE_ENV_VAR BSDSockLib
    rts

    section "Strings",CODE

BSDSockLibName: dc.b "bsdsocket.library",0

    DEFINE_ENV_VAR BSDSockLibVer
    DEFINE_ENV_VAR BSDSockLibRev
    DEFINE_ENV_VAR BSDSockLib

    endc

**************************** UAE ***************************

    if E_UAEMajor+E_UAEMinor+E_UAERev+E_Emulation
    
    section "Code",CODE
;-----------------------------------------------------------
; Writes the hosting UAE's major version, minor version and
; revision into environment variables $UAEMajor, $UAEMinor,
; and $UAERev.
; If UAE is not detected the variables are set without
; content.
;
; Note: Below Kickstart 1.3, UAE cannot be detected via this
;       method.
;-----------------------------------------------------------
; IN/OUT: A6 - dos.library reference
;-----------------------------------------------------------
; Potentially overwrites all registers, except A6
;-----------------------------------------------------------
setUAEEnvVars:
    ; save dos.library pointer
    movea.l a6,a4
    ; get exec.library
    EXECBASE a6

    ; assume no emulation
    moveq #EMU_NONE,d7

; try to open UAE's uae.resource
    moveq #0,d0
    lea .UaeResName,a1
    jsr _LVOOpenResource(a6)
    tst.l d0
    beq.w .notUAE

    ; it's UAE
    moveq #EMU_UAE,d7

; UAE structure embeds a library structure, after that it
; holds three words: major,; minor and revision
    move.l d0,a3                ; addr. of UAE struct in A2
    lea EXEC_LIB_HDR_S(a3),a3   ; add precalculated offset

; Get UAE version information
    lea .UAEVersions,a0
    ; UAE major version
    move.w (a3)+,(a0)+
    ; UAE minor version
    move.w (a3)+,(a0)+
    ; UAE revision
    move.w (a3)+,(a0)+

    bra.w .writeEmuEnvVars

.notUAE:
; try to open Emu68's devicetree.resource
    moveq #0,d0
    lea .Emu68ResName,a1
    jsr _LVOOpenResource(a6)
    tst.l d0
    beq.s .notEmu68

    ; it's Emu68
    moveq #EMU_EMU68,d7
    bra.w .writeEmuEnvVars

.notEmu68:
; try to find Musashi's interaction device
    moveq #0,d0
    lea.l .expansionName,a1
    jsr _LVOOpenLibrary(a6)
    tst.l d0
    ; quit if expansion.library couldn't be opened
    beq.s .writeEmuEnvVars

    ; move expansion.library pointer
    movea.l d0,a6
    suba.l a0,a0
	move.l #musashi_mid,d0
	moveq #musashi_interaction_pid,d1
    jsr _LVOFindConfigDev(a6)
    tst.l d0
    beq.s .closeExpansion

    ; it's Musashi
    moveq #EMU_MUSASHI,d7

.closeExpansion:
    ; get expansion.library pointer
    movea.l a6,a1
    EXECBASE a6
    jsr _LVOCloseLibrary(a6)

.writeEmuEnvVars
    ; restore dos.library pointer
    movea.l a4,a6

    cmp.b #EMU_NONE,d7
    ; no emulation found
    beq.w .deleteUAE

.checkUAE
    cmp.b #EMU_UAE,d7
    bne.w .checkEmu68

    ; write UAE emulation environment variables
    lea .UAEVersions,a3
    moveq #0,d0
    move.w (a3)+,d0
    SET_NUMERIC_ENV_VAR UAEMajor,d0
    moveq #0,d0
    move.w (a3)+,d0
    SET_NUMERIC_ENV_VAR UAEMinor,d0
    moveq #0,d0
    move.w (a3)+,d0
    SET_NUMERIC_ENV_VAR UAERev,d0
    SET_ENV_VAR_CLEN Emulation,#.UAEStr,3
    bra.s .exit

.checkEmu68
    cmp.b #EMU_EMU68,d7
    bne.s .checkMusashi

    ; write Emu68 emulation environment variables
    SET_ENV_VAR_CLEN Emulation,#.Emu68Str,5
    bra.s .deleteUAE

.checkMusashi
    cmp.b #EMU_MUSASHI,d7
    bne.s .deleteUAE

    ; write Musashi emulation environment variables
    SET_ENV_VAR_CLEN Emulation,#.MusashiStr,7
    ; fall through

.deleteUAE:
    DELETE_ENV_VAR UAEMajor
    DELETE_ENV_VAR UAEMinor
    DELETE_ENV_VAR UAERev

.exit
    rts

    section "Strings",CODE
.expansionName:
    dc.b "expansion.library",0
    cnop 0,2
.UaeResName:
    dc.b "uae.resource",0
    cnop 0,2
.Emu68ResName:
    dc.b "devicetree.resource",0
    cnop 0,2
.UAEVersions:
    dcb.w 3,0
.UAEStr:
    dc.b "UAE"
    cnop 0,2
.MusashiStr:
    dc.b "Musashi"
    cnop 0,2
.Emu68Str:
    dc.b "Emu68"
    cnop 0,2

    DEFINE_ENV_VAR Emulation
    DEFINE_ENV_VAR UAEMajor
    DEFINE_ENV_VAR UAEMinor
    DEFINE_ENV_VAR UAERev

    endc

*********************** Math Utils *************************

    section "Code",CODE
;-----------------------------------------------------------
; Divides a 32 bit wide number by 10.
; Implemented following:
; Henry S. Warren, Jr., "Hacker's Delight", Fig. 10-12 
;-----------------------------------------------------------
; IN:  D0.l - Integer to be divided
;      A0   - Return Address
; OUT: D0.l - result (quotient)
;-----------------------------------------------------------
; Overwrites D0, D1, D2
;-----------------------------------------------------------
ldiv10:
    ; Calc q = (n >> 1) + (n >> 2) --> D1
    move.l d0,d1
    move.l d0,d2
    lsr.l  #1,d1 ; n >> 1
    lsr.l  #2,d2 ; n >> 2
    add.l  d2,d1 ; 

    ; Calc q = q + (q >> 4) --> D1
    move.l d1,d2 
    lsr.l  #4,d2
    add.l  d2,d1

    ; Calc q = q + (q >> 8) --> D1
    move.l d1,d2
    lsr.l  #8,d2
    add.l  d2,d1

    ; Calc q = q + (q >> 16) --> D1
    move.l d1,d2
    clr.w  d2
    swap   d2
    add.l  d2,d1

    lsr.l #3,d1

    ; Calc q*10 --> D2
    LMUL10 d1,d2

    sub.l d2,d0 ; r = n - q*10 --> D0

    ; Calc q + ((r + 6) >> 4) --> D0
    addq  #6,d0
    lsr.l #4,d0
    add.l d1,d0

    jmp (a0)


********************** String Utils ************************

    section "Code",CODE
;-----------------------------------------------------------
; Prints a 32 bit wide number and returns the string.
;-----------------------------------------------------------
; IN:  D0.l - 32 bit Integer to be printed
; OUT: A1   - Address to string
;      D0.l - number of characters written
;-----------------------------------------------------------
; Overwrites D0, D1, A0, A1
;-----------------------------------------------------------
printNumber:
    move.l d2,-(sp) ; ldiv10 overwrites D2
    move.l d3,-(sp)

    lea    _PrintedNumberEnd,a1  ; point A1 to end of buffer
    move.l d0,d3

; Generate string from right to left, starting right before
; _PrintedNumberEnd
    lea .retFromDiv(pc),a0
.loop:
    bra.b  ldiv10
.retFromDiv:
    LMUL10 d0,d1
    sub.l  d1,d3    ; get remainder
    addi.b #'0',d3  ; generate ASCII character in D0
    move.b d3,-(a1) ; print from right to left
    move.l d0,d3
    bne.b  .loop    ; until quotient is 0

    move.l #_PrintedNumberEnd,d0 ; calc length
    sub.l  a1,d0

.end:
    move.l (sp)+,d3
    move.l (sp)+,d2
    rts

    section "VariableData",DATA

    ds.b 10  ; 10 chiffres
_PrintedNumberEnd: dc.b 0     ; null terminator


    section "Code",CODE
;-----------------------------------------------------------
; Small strlen implementation.
;-----------------------------------------------------------
; IN   A1   - address of null-terminated string
; OUT: D0.l - length
;      A1   - points to end of string (null terminator)
;-----------------------------------------------------------
; Overwrites D0, A1
;-----------------------------------------------------------
strlen:
    move.l a1,d0  ; preserve the start address
.testNT:
    tst.b (a1)+    ; test character
    bne.b .testNT  ; if not '\0', back to testNT
    subq  #1,a1    ; back to the null terminator
    sub.l a1,d0
    neg.l d0
    rts


;-----------------------------------------------------------
; Puts the path to an environment variable on the stack.
; The path is created by prepending "ENV:" to the
; environment variable name.
; After invocation, SP points to the null terminated path
;-----------------------------------------------------------
; IN   D1.l - address of null-terminated env. var. name
;      A0   - return address
; OUT: SP   - Address to path string
;      D0.l - length of stack frame to be returned by caller
;-----------------------------------------------------------
; Overwrites SP, D0, D1, A1
;-----------------------------------------------------------
GetEnvVarPath:

; 1. get total length of env variable path
    move.l d1,a1   ; arg1 for strlen
    bsr.b  strlen  ; get length in D0
    suba.l d0,a1   ; restore A1 to start of name
    addq.b #5,d0   ; Add 5 (for "ENV:" and '\0')

; 2. Create a 32 bit aligned stack frame
    CREATE_ALIGNED_STACK_FRAME d0 ; stack frame size >= D0
	; D0 now contains actual length of stack frame

; 3. Put env. var. path at the beginning of the stack frame
    move.l a0,d1          ; We'll need A0, so save it to D1
    movea.l sp,a0         ; SP cannot be byte-incremented,
    move.l #"ENV:",(a0)+  ; We can do bec. stack is aligned
.copy:                    ; Copy env. variable name
    move.b (a1)+,(a0)+
    bne.b  .copy

; 4. jump back
    movea.l d1,a0 ; restore return address
    jmp (a0)


**************** SET_ENV_VAR Implementation ****************

;-----------------------------------------------------------
; Resembles the functionality of the setenv Amiga DOS
; command, which means it creates a file with the name of
; the environment variable in ENV: and fills it with the
; given content.
;
; The interface resembles that of SetVar found in
; dos.library v36, except that the flags argument (D4) is
; ignored due to the global nature of setGlobalVar.
;-----------------------------------------------------------
; IN      D1.l - address of null-terminated env. var. name
;         D2.l - address of content string
;         D3.l - Content length, -1 for null-terminated string
; OUT:    D0.l - TRUE (-1) if successful, FALSE (0) if not
; IN/OUT: A6.l - Reference to dos.library
;-----------------------------------------------------------
; Overwrites D0, D1, A0, A1
;-----------------------------------------------------------
setGlobalVar:

_LVOOpen   = -30
_LVOClose  = -36
_LVOWrite  = -48

MODE_NEWFILE = 1006

    movem.l d2-d5/a2,-(sp) ; preserve registers

    lea .createFile(pc),a0  ; return address in A0
    bra.b GetEnvVarPath

.createFile
; 3. Create file at env path
    move.l d0,d5             ; save stack frame size in D5
    move.l sp,d1             ; arg1: name (null terminated)
    move.l d2,a2             ; save content ref. in A2
    move.l #MODE_NEWFILE,d2  ; arg2: overwrite existing    
    jsr    _LVOOpen(a6)
    add.l d5,sp              ; return stack frame
    move.l d0,d4             ; preserve filehandle
    beq.b .error             ; If we moved a 0, open failed

; 4. Write content
    ; D3 is still set from beginning, but maybe 0 (no
    ; content) or -1, which means we must calc. the length
    tst.l d3
    beq.b .closeFile  ; nothing to write
    bpl.b .callWrite  ; we already have a length
    ; We must calculate the length of the content
    move.l a2,a1      ; arg1 for strlen
    bsr.b  strlen
    move.l d0,d3      ; now we have the length in D3

.callWrite:    
    move.l d4,d1       ; arg1: env. var. filehandle
    move.l a2,d2       ; arg2: content ref.
    jsr    _LVOWrite(a6)
    cmp.l  d0,d3
    bne.b  .error

; 5. Close file and return
.closeFile:
    move.l d4,d1           ; restore filehandle
    jsr    _LVOClose(a6)
    moveq  #TRUE,d0        ; return Success
    bra.b  .end

.error:
    moveq #FALSE,d0  ; return Failure

.end:
    movem.l (sp)+,d2-d5/a2  ; restore registers
    rts


;-----------------------------------------------------------
; Set an environment variable on any OS (except 1.0)
;
; This routine checks the version of the dos.library
; (referenced in A6) and either proceeds to SetVar when
; available (dos.library versions >= 36) or to setGlobalVar
;
; Note that the flags argument (D4), which SetVar accepts is
; not passed through. For OS 2.0+, D4 is explicitly set to
; local scope. For OS 1.x, environment variables cannot be
; anything but global, i.e., stored in ENV:
;-----------------------------------------------------------
; IN      D1.l - address of null-terminated env. var. name
;         D2.l - address of content string
;         D3.l - Content length, -1 for null-terminated string
; OUT:    D0.l - TRUE (-1) if successful, FALSE (0) if not
; IN/OUT: A6.l - Reference to dos.library
;-----------------------------------------------------------
; Overwrites D0, D1, A0, A1
;-----------------------------------------------------------
setEnvVar:

_LVODeleteVar = -912

    cmp.w  #36,EXEC_O_LIB_VER(a6)
    bls.b  setGlobalVar
    move.l d4,-(sp)             ; preserve D4
    move.l #GVF_LOCAL_ONLY,d4   ; scope is local to script
    jsr    _LVOSetVar(a6)
    move.l (sp)+,d4             ; restore D4
    tst    d0                   ; restore SR Z/N
    rts


;-----------------------------------------------------------
; Properly delete a global environment variable.
;-----------------------------------------------------------
; IN      D1.l - address of null-terminated env. var. name
; OUT:    D0.l - TRUE (-1) if successful, FALSE (0) if not
; IN/OUT: A6.l - Reference to dos.library
;-----------------------------------------------------------
; Overwrites D0, D1, A0, A1
;-----------------------------------------------------------
deleteGlobalVar:

_LVODeleteFile = -72

    move.l d2,-(sp) ; preserve registers

    lea .deleteFile(pc),a0  ; return address in A0
    bra GetEnvVarPath

.deleteFile
    move.l d0,d2               ; save stack frame size in D2
    move.l sp,d1               ; name (null terminated)
    jsr    _LVODeleteFile(a6)  ; D0 will indicate success

    add.l  d2,sp     ; return stack frame
    move.l (sp)+,d2  ; restore registers
    tst    d0        ; restore SR Z/N
    rts


;-----------------------------------------------------------
; Delete an environment variable on any OS (except 1.0)
;
; This routine checks the version of the dos.library
; (referenced in A6) and either proceeds to DeleteVar when
; available (dos.library versions >= 36) or to
; deleteGlobalVar.
;-----------------------------------------------------------
; IN      D1.l - address of null-terminated env. var. name
; OUT:    D0.l - TRUE (-1) if successful, FALSE (0) if not
; IN/OUT: A6.l - Reference to dos.library
;-----------------------------------------------------------
; Overwrites D0, D1, A0, A1
;-----------------------------------------------------------
deleteEnvVar:
    cmp.w  #36,EXEC_O_LIB_VER(a6)
    bls.b  deleteGlobalVar
    move.l d2,-(sp)             ; preserve D2
    move.l  #GVF_LOCAL_ONLY,d2  ; scope is local to script
    jsr     _LVODeleteVar(a6)
    move.l  (sp)+,d2            ; restore D2
    tst     d0                  ; restore SR N/Z
    rts

**************** SET_ENV_VAR Error Message *****************

    section "Code",CODE

;-----------------------------------------------------------
; Prints a message that shows that an environment variable
; could not be set
;-----------------------------------------------------------
; IN: D1.l - Environment Variable Name Address
;-----------------------------------------------------------
; Overwrites D0, D1, A0, A1
;-----------------------------------------------------------
printErrorMsg:

_LVOOutput = -60

    movem.l d2-d4/a4,-(sp)  ; preserve used registers
    move.l  d1,d2
    jsr     _LVOOutput(a6)  ; obtain stdout in D0
    bne.b   .write
    rts

.write:
    move.l  d0,d4  ; preserve stdout to D4
; 1. get total length of env variable path
    move.l d2,a1   ; Arg1 for strlen
    bsr    strlen  ; get length in D0

    ; Add msg len and 1 for LF
    addi.b #_ErrorMsgPreEnd-_ErrorMsgPre+1,d0

    move.l d0,d3                   ; preserve for Write
    move.l sp,a4                   ; preserve sp
    CREATE_ALIGNED_STACK_FRAME d3
    
    lea  _ErrorMsgPre,a1
    move.l sp,a0

.copyPre:
    move.b (a1)+,(a0)+
    cmp.l  #_ErrorMsgPreEnd,a1
    bne.b .copyPre

    movea.l d2,a1           ; restore A1 to start of name

.copyVarName:
    move.b  (a1)+,(a0)+
    bne.b   .copyVarName
    move.b  #10,-(a0)  
    move.l  d4,d1
    move.l  sp,d2
    jsr     _LVOWrite(a6)
    move.l  a4,sp           ; return stack frame
    movem.l (sp)+,d2-d4/a4  ; restore used registers

.end:
    rts

    section "Strings",CODE
_ErrorMsgPre:     dc.b "Failed to process $"
_ErrorMsgPreEnd:


*************** Set All Environment Variables **************

    section "Code",CODE
; This is where the individual setters are called.
; Extent with new features here!
setAllVariables:
    ifd setKickstartEnvVars
        bsr setKickstartEnvVars
    endc
    ifd setCPUAndFPUEnvVars
        bsr setCPUAndFPUEnvVars
    endc
    ifd setChipsetAndVFreqEnvVars
        bsr setChipsetAndVFreqEnvVars
    endc
    ifd setMemoryEnvVars
        bsr setMemoryEnvVars
    endc
    ifd setBSDSockLibEnvVars
        bsr setBSDSockLibEnvVars
    endc
    ifd setUAEEnvVars
        bsr setUAEEnvVars
    endc
    ifd setVampireEnvVars
        bsr setVampireEnvVars
    endc
    rts

************************** Version *************************

    section "Strings",CODE
    PROGVER
