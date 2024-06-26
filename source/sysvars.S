************************************************************
*                                                          *
*                      SYSVARS V.0.12                      *
*                                                          *
* SPDX-FileCopyrightText: (c) 2023 Lars Stockmann          *
* SPDX-License-Identifier: MIT                             *
*                                                          *
*                                                          *
* SYNOPSIS:                                                *
*                                                          *
* Puts system information into environment variables       *
*                                                          *
************************************************************

******************** Feature Selection *********************

; Comment out to disable environment variable
; You can also disable them on the command line like so:
; -DDISABLE_CPU
    section Code,code
    section Strings,code
    dc.b 0,"$VER: SYSVARS 0.12 (14.04.2024)",0
    section Code,code

ENABLE: macro
    ifnd DISABLE_\1
E_\1 = 1    
    else
E_\1 = 0
    endif
    endm

    ENABLE KickVer
    ENABLE KickRev

    ENABLE CPU
    ENABLE FPU

    ENABLE Chipset
    ENABLE VFreq

    ENABLE BSDSockLibVer
    ENABLE BSDSockLibRev
    ENABLE BSDSockLib

    ENABLE UAEMajor
    ENABLE UAEMinor
    ENABLE UAERev

********************  Global Constants  ********************

FALSE     =  0
TRUE      = -1

; Global registers and offsets

VPOSR  = $dff004
POTGOR = $dff016

KS_END            = $1000000
KS_END_OFFSET_LEN = -20
KS_VER_OFFSET     = 12

; Exec Constants and _LVOs

EXEC_BASE      =  4
EXEC_Node_SIZE = 14
EXEC_LIB_HDR_S = EXEC_Node_SIZE+20
EXEC_O_LIB_VER = EXEC_Node_SIZE+6

_LVOOpenLibrary  = -552
_LVOCloseLibrary = -414

_LVOSoftVer   = $14
_LVOAttnFlags = $128

; Dos _LVOs

_LVOOutput = -60   
_LVOOpen   = -30
_LVOClose  = -36
_LVOWrite  = -48
_LVOSetVar = -900

; Flags

MODE_NEWFILE   = 1006
GVF_LOCAL_ONLY = $200


************************* Macros  **************************


;-----------------------------------------------------------
; Uses the sysvars naming scheme to generate environment
; variable name string.
;-----------------------------------------------------------
; Macro Arguments:
; 1: Environment variable name (symbolic)
;-----------------------------------------------------------
DEFINE_ENV_VAR_NAME: macro
    if E_\1              ; if not enabled, do not set
    \1EnvVarName: dc.b "\1",0
    endif
    endm

;-----------------------------------------------------------
; Macro to set environment variable
;-----------------------------------------------------------
; Macro Arguments:
;
; 1: long address to null-terminated name string
; 2: long address to content string
; 3: long source for length (register, variable...)
;-----------------------------------------------------------
; Note: There is a dedicated version for short constant
;       length values
;-----------------------------------------------------------
; Potentially overwrites: D0, D1, D2, D3, A0, A1
;-----------------------------------------------------------
SET_ENV_VAR: macro
    if E_\1                     ; if not enabled, do not set
    move.l #\1EnvVarName,d1     ; arg1: name address
    if NARG>1
    move.l \2,d2                ; arg2: content address
        if NARG>2
    move.l \3,d3                ; arg3: content length
        else
    moveq #-1,d3
        endif
    else
    moveq #0,d3
    endif
    bsr    setEnvVar
    bne.b .setVarDone\@
    move.l #\1EnvVarName,d1     ; print error
    bsr   printSetEnvVarErrMsg
    moveq #0,d0                 ; indicate error
.setVarDone\@:
    endif
    endm

;-----------------------------------------------------------
; Macro to set environment variable with a known content
; length < 128
;-----------------------------------------------------------
; Macro Arguments:
;
; 1: long address to null-terminated name string
; 2: long address to content string
; 3: length constant (< 128, -1 for null-terminated content)
;-----------------------------------------------------------
; Potentially overwrites: D0, D1, D2, D3, A0, A1
;-----------------------------------------------------------
SET_ENV_VAR_CLEN: macro
    if E_\1                     ; if not enabled, do not set
    move.l #\1EnvVarName,d1     ; arg1: name address
    ifne \3
    move.l \2,d2                ; arg2: content address
    endif
    moveq  #\3,d3               ; arg3: content length
    bsr    setEnvVar
    bne.b .setVarDone\@
    move.l #\1EnvVarName,d1     ; print error
    bsr   printSetEnvVarErrMsg
    moveq #0,d0                 ; indicate error
.setVarDone\@:
    endif
    endm

;-----------------------------------------------------------
; Macro to set an environment variable to hold a version
; number.
;-----------------------------------------------------------
; Macro Arguments:
;
; 1: name symbol
; 2: source for number
;-----------------------------------------------------------
; Potentially overwrites: D0, D1, D2, D3, A0, A1
;-----------------------------------------------------------
SET_VERSION_ENV_VAR: macro
    if E_\1            ; if not enabled, do not set
    move.w \2,d1
    bsr    versionToString
    SET_ENV_VAR \1,a1,d0
    endif
    endm

;-----------------------------------------------------------
; Macro that creates a stack frame that is guaranteed to be
; long word aligned so you can copy in 32bit
;-----------------------------------------------------------
; Macro Arguments:
;
; 1: source of desired size
;-----------------------------------------------------------
; After invocation, D0 will hold the actual size of the
; stack frame.
;-----------------------------------------------------------
CREATE_ALIGNED_STACK_FRAME: macro
    ifnc "\1",d0
    move.l \1,d0
    endif
    neg.l   d0
    add.l   sp,d0
    asr.b   #2,d0  ; shift 2 right and then left rounds to
    asl.b   #2,d0  ;   the next multiple of 4 when negative
    sub.l   sp,d0
    neg.l   d0
    sub.l   d0,sp    
    endm

;-----------------------------------------------------------
; Macro to conveniently open the library with the given
; name.
;-----------------------------------------------------------
; Macro Arguments:
;
; 1: Library name 
; 2: Minimum Version of Library
; 3 (opt.): place used to preserve A6. Don't use a scratch
;           register as it will be overwritten!
;-----------------------------------------------------------
; Potentially overwrites: D0, D1, A0, A1
; Overwrites A6 if no 3. argument is given to preserve it
;-----------------------------------------------------------
OPEN_LIBRARY: macro 
    move.l  \1,a1   ; library name
    moveq   #\2,d0  ; version is macro param

    if NARG>2
        ifc "\3","d0"
            fail "Do not use scratch register D0!"
        endif
        ifc "\3","d1"
            fail "Do not use scratch register D1!"
        endif
        ifc "\3","a0"
            fail "Do not use scratch register A0!"
        endif
        ifc "\3","a1"
            fail "Do not use scratch register A1!"
        endif
    movea.l a6,\3
    endif

    movea.l EXEC_BASE,a6         ; get exec base in A6
    jsr     _LVOOpenLibrary(a6)
    if NARG>2
    movea.l \3,a6
    endif
    tst.l   d0
    endm
;-----------------------------------------------------------
; Macro to conveniently close a library
;-----------------------------------------------------------
; Macro Arguments:
;
; 1: lbrary reference
; 2 (opt.): place used to preserve A6. Don't use a scratch
;           register!
;-----------------------------------------------------------
; Potentially overwrites: D0, D1, A0, A1
; Overwrites A6 if no 3. argument is given to preserve it
;-----------------------------------------------------------
CLOSE_LIBRARY: macro
    if NARG>0
        IFNC "\1","a1"
    move.l  \1,a1       ; library pointer
        endif
    endif

    if NARG>1
        ifc "\2","d0"
            fail "Do not use scratch register D0!"
        endif
        ifc "\2","d1"
            fail "Do not use scratch register D1!"
        endif
        ifc "\2","a0"
            fail "Do not use scratch register A0!"
        endif
        ifc "\2","a1"
            fail "Do not use scratch register A1!"
        endif
    movea.l a6,\2
    endif

    movea.l EXEC_BASE,a6          ; get exec base in A6
    jsr     _LVOCloseLibrary(a6)
    if NARG>1
    movea.l \2,a6
    endif
    endm

*********************** Main Entry  ************************
    section Code,code
main:


    ; A6 is assumed to point to dos.library throughout the
    ; program. A6 = 0 indicates that dos.library is not
    ; loaded
    move.l #0,a6
    OPEN_LIBRARY #DosLibName,0
    move.l d0,a6

    bsr setAllVariables

    CLOSE_LIBRARY a6  ; close dos.library
    moveq   #0,d0     ; return code 0
    rts

    section Strings,code

DosLibName: dc.b "dos.library",0

************************ Kickstart *************************

    if E_KickVer+E_KickRev
    
    section Code,code
;-----------------------------------------------------------
; Determines the kickstart version and revision and puts
; them into environment variabes $KickVer and $KickRev
;
; Note: Below Kickstart 1.2, the revision cannot be
;       determined and the respective environment variable
;       is set without content.
;
; IN/OUT: A6 - dos.library reference
;
;-----------------------------------------------------------
; Potentially overwrites all registers, except A6
;-----------------------------------------------------------
setKickstartEnvVars:
    lea    (KS_END),a0
    sub.l  KS_END_OFFSET_LEN(a0),a0  ; Subtract KS length
    add.w  #KS_VER_OFFSET,a0
    move.w (a0)+,d5                  ; Version
    move.w (a0),d6                   ; Revision
    ; On KS < 1.2, this mechanism will not work and both
    ; KickVer and KickRev are $ffff (-1).
    bpl.b .setEnvVar      ; test sign of last move

    ; On KS < 1.2, we detect that here and fetch the version
    ; via _LVOSoftVer of EXEC.
    movea.l EXEC_BASE,a0            ; get exec base in A0
    move.w  _LVOSoftVer(a0),d5      ; get KS version
    SET_VERSION_ENV_VAR KickVer,d5
    SET_ENV_VAR KickRev
    rts

.setEnvVar:
    SET_VERSION_ENV_VAR KickVer,d5
    SET_VERSION_ENV_VAR KickRev,d6
    rts

    section Strings,code

    DEFINE_ENV_VAR_NAME KickVer
    DEFINE_ENV_VAR_NAME KickRev

    endif

************************ CPUAndFPU *************************

    if E_CPU+E_FPU
    
    section Code,code
;-----------------------------------------------------------
; Determines the CPU and FPU type and writes it into
; environment variables $CPU and $FPU.
;
; 68080 detection according to
; http://adevnoo.wikidot.com/detect-080-code
;
; Note: Below Kickstart 2.0, CPUs > 68020 are recognized as
;       68020 and all FPUs are recognized as 68881
;
;
; IN/OUT: A6 - dos.library reference
;
;-----------------------------------------------------------
; Potentially overwrites all registers, except A6
;-----------------------------------------------------------
setCPUAndFPUEnvVars:
; Test bits of second AttnFlags byte
    movea.l EXEC_BASE,a0           ; get exec base in A0
    move.w  _LVOAttnFlags(a0),d5  ; get cpu info in D0

; D1 gets the CPU version as ASCII character that replaces
; the "?" in "680?0"
    moveq   #"8",d1    ; assume 68080
    btst    #10,d5
    bne.b   .storeCPU
    moveq   #"6",d1    ; assume 68060
    btst    #7,d5
    bne.b   .storeCPU
    moveq   #"4",d1    ; assume 68040
    btst    #3,d5
    bne.b   .storeCPU
    moveq   #"3",d1    ; assume 68030
    btst    #2,d5
    bne.b   .storeCPU
    moveq   #"2",d1    ; assume 68020
    btst    #1,d5
    bne.b   .storeCPU
    moveq   #"1",d1    ; assume 68010
    btst    #0,d5
    bne.b   .storeCPU
    moveq   #"0",d1    ; it must be 68000    
    
.storeCPU:
    move.b  d1,CPUStr+3             ; store digit in var
    SET_ENV_VAR_CLEN CPU,#CPUStr,5

; Get FPU    
; We lshift D0 by 1 (via add.b d0,d0) until it is negative
    lea.l FPUStr,a0
    add.b   d5,d5
    bmi.b   .storeInternal
    add.b   d5,d5
    bmi.b   .store68882
    add.b   d5,d5
    bmi.b   .store68881
; nothing to store
    moveq   #0,d3
    bra.b .setFPUEnvVar
.storeInternal
    move.l  #"inte",(a0)    ; "internal"
    moveq   #8,d3
    bra.b .setFPUEnvVar
.store68882
    move.b  #"2",4(a0)
    moveq   #5,d3
    bra.b .setFPUEnvVar
.store68881
    move.b  #"1",4(a0)
    moveq   #5,d3
.setFPUEnvVar
    SET_ENV_VAR FPU,#FPUStr,d3
    rts

    section PreInitializedData,data
CPUStr: dc.b "680?0"
; The string for the FPU is composed using a long  move.
; Thus the target string must be aligned accordingly
    cnop 0,4
FPUStr: dc.b "6888rnal"
    
    section Strings,code

    DEFINE_ENV_VAR_NAME CPU
    DEFINE_ENV_VAR_NAME FPU

    endif

********************* ChipsetAndVFreq **********************

    if E_Chipset+E_VFreq

    section Code,code
;-----------------------------------------------------------
; Determines the availble chipset (OCS, ECS, AGA, SAGA) and
; the vertical frequency (50/60) in Hz and fills the
; environment variables $Chipset and $VFreq
;
; SAGA detection according to
; http://adevnoo.wikidot.com/detect-080-code
;
;
; IN/OUT: A6 - dos.library reference
;
;-----------------------------------------------------------
; Potentially overwrites all registers, except A6
;-----------------------------------------------------------
setChipsetAndVFreqEnvVars:
; Check SAGA via chip ID of POTGOR register
    move.l  #"SAGA",d5
    move.w  POTGOR,d0
    andi.w  #$fe,d0      ; mask chip ID (bits 1-7)
    bne     .storeChipset

; We use VPOSR to detect Agnus/Alice
    move.b  VPOSR,d1  ; get VPOSR bits
    andi.b  #$7f,d1   ; mask out LOF
    move.b d1,d0      ; bits in D0

; D5 is used to create the chipset string.
    move.l  #"OCS_"-"_",d5
    cmpi.b  #10,d0
    bls.b   .storeChipset
    move.l  #"ECS_"-"_",d5
    andi.b  #$F,d0
    cmpi.b  #1,d0
    bls.b   .storeChipset
    move.l  #"AGA_"-"_",d5
    cmpi.b  #3,d0
    bhi.b   .getVFreq

.storeChipset:
    move.l  d5,ChipsetStr                  

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

    
    section PreInitializedData,data

    ; Note: ChipsetStr is cmposed using a long  move. Thus
    ;       the target string must be aligned
    cnop 0,4
ChipsetStr: dc.b "?",0,0,0,0
VFreqStr:   dc.b "?0"

    section Strings,code

    DEFINE_ENV_VAR_NAME Chipset
    DEFINE_ENV_VAR_NAME VFreq

    endif

************************ BSDSockLib ************************

    if E_BSDSockLibVer+E_BSDSockLibRev+E_BSDSockLib
    
    section Code,code
;-----------------------------------------------------------
; Checks if bsdsocket.library is available and if so, puts
; its version, revision and identifier into environment
; variables $BSDSockLibVer and $BSDSockLibRev and
; $BSDSockLib.
; If bsdsocket.library is not available the variables are
; set without content
;
;
; IN/OUT: A6 - dos.library reference
;
;-----------------------------------------------------------
; Potentially overwrites all registers, except A6
;-----------------------------------------------------------
setBSDSockLibEnvVars:
    OPEN_LIBRARY #BSDSockLibName,0,a5
    beq  .notOpened

    ; Fetch infos
    move.l d0,a4                 ; preserve bsdsocketLib ref
    lea.l EXEC_O_LIB_VER(a4),a0  ; Get lib version member
    move.w (a0)+,d5              ; store version in D5
    move.w (a0)+,d6              ; store revision in D6
    move.l (a0),d7               ; store id string in D7

    ; Note: For some reason, under the AROS ROM, SetVar
    ;       cannot access the id string directly, so we must
    ;       copy it to stack first
    move.l sp,a3  ; preserver SP
    move.l d7,a1  ; Arg1 for strlen (id string)
    bsr strlen
    move.l d0,d4  ; preserve the length for subsequent calls
    ; make the length in D0 word-aligned
    neg.l d0
    asr.l #1,d0
    add.l d0,d0
    add.l d0,sp   ; create stack frame
    move.l sp,a0  ; get start of stack frame into A0
    move.l d7,a1  ; get id string again into A1 for copy
.copyIdString
    move.b (a1)+,(a0)+
    bne.s .copyIdString

    CLOSE_LIBRARY a4,a5

    ; Set variables
    SET_VERSION_ENV_VAR BSDSockLibVer,d5
    SET_VERSION_ENV_VAR BSDSockLibRev,d6
    SET_ENV_VAR BSDSockLib,sp,d4

    move.l a3,sp; restore SP
    rts

.notOpened
    ; We set the environment variables without content
    SET_ENV_VAR BSDSockLibVer
    SET_ENV_VAR BSDSockLibRev
    SET_ENV_VAR BSDSockLib
    rts

    section Strings,code

BSDSockLibName: dc.b "bsdsocket.library",0

    DEFINE_ENV_VAR_NAME BSDSockLibVer
    DEFINE_ENV_VAR_NAME BSDSockLibRev
    DEFINE_ENV_VAR_NAME BSDSockLib

    endif

************************** Memory **************************
; TODO
;_LVOMaxLocMem    = $3e
;_LVOMaxExtMem    = $4e
;Get_memory_envvars_cont:
;
;    movea.l EXEC_BASE,a0        ; get exec base in A6
;    move.l _LVOMaxLocMem(a0),d1  ; Chip Mem End Address
;    lea    _LVOMaxExtMem(a0),a1  ; 0 if none
;    move   $200000,d2


**************************** UAE ***************************

    if E_UAEMajor+E_UAEMinor+E_UAERev
    
    section Code,code
;-----------------------------------------------------------
; Writes the hosting UAE's major version, minor version and
; revision into environment variables $UAEMajor, $UAEMinor,
; and $UAERev.
; If UAE is not detected the variables are set without
; content.
;
; Note: Below Kickstart 1.3, UAE cannot be detected via this
;       method.
;
;
; IN/OUT: A6 - dos.library reference
;
;-----------------------------------------------------------
; Potentially overwrites all registers, except A6
;-----------------------------------------------------------
setUAEEnvVars:

_LVOResourceList = $150
_LVOFindName     = -276

; UAE structure embeds a library structure, after that it
; holds three words: major,; minor and revision

    movea.l a6,a4 ; preserve A6 (needed for SysBase)   
    movea.l EXEC_BASE,a6             ; get exec base in A6
    lea     _LVOResourceList(a6),a0  ; arg1 resource list
    lea     UaeResName,a1           ; arg2 resource name
    jsr     _LVOFindName(a6)         ; call FindName
    movea.l a4,a6 ; restore A6

; Test whether UAE was detected
    tst.l d0
    beq   .notFound

; Store version as string in UAEEnvVarCont    
    move.l  d0,a3               ; addr. of UAE struct in A2
    adda    #EXEC_LIB_HDR_S,a3  ; add precalculated offset

    SET_VERSION_ENV_VAR UAEMajor,(a3)+
    SET_VERSION_ENV_VAR UAEMinor,(a3)+
    SET_VERSION_ENV_VAR UAERev,(a3)
    rts

.notFound:
    SET_ENV_VAR UAEMajor
    SET_ENV_VAR UAEMinor
    SET_ENV_VAR UAERev
    rts

    section Strings,code

UaeResName: dc.b "uae.resource",0

    DEFINE_ENV_VAR_NAME UAEMajor
    DEFINE_ENV_VAR_NAME UAEMinor
    DEFINE_ENV_VAR_NAME UAERev

    endif

*********************  String Utils  ***********************

    section Code,code
;-----------------------------------------------------------
; Prints a version number [0...9999] and returns the string.
;
; IN:  D1.w - Integer to be printed
; OUT: A1   - Address to string
;      D0   - number of characters written
;-----------------------------------------------------------
; Potentially overwrites D0, D1, A0, A1
;-----------------------------------------------------------
versionToString:
    movem.l d2/d3,-(sp) ; preserve D2 and D3

    moveq  #0,d0  ; clean D0 (used to calc. & gen. char)
    moveq  #0,d2  ; clean D2 (holds chars)
    moveq  #0,d3  ; clean D3 (char count)
    move.w d1,d0  ; put initial uint16 in D0

; Generate string in D2 (max. 4 characters)
.loop    
    divu   #10,d0   ; Divide by 10
    move.w d0,d1    ; put quotient (first 16bits) in D0
    swap   d0       ; get remainder by swapping 16 bit
    add.b  #'0',d0  ; generate ASCII character in D0
    and.l  #$ff,d0  ; clear everything except the lower byte
    ror.l  #8,d0    ; put the byte to front
    addq   #1,d3    ; increment char count
    lsr.l  #8,d2    ; make space for next character

    add.l  d0,d2    ; put next character in D2
    moveq  #0,d0    ; clean D0
    move.w d1,d0    ; continue with quotient
    bne.b  .loop    ; until quotient is 0

; Put characters into string buffer, return
    lea.l VerNumStrBuff,a1
    move.l d2,(a1)           ; Put all 4 characters at once
    move.b d3,d0             ; char count returned in D0
    movem.l (sp)+,d2/d3      ; restore D2 and D3

    rts

    section PreinitializedData,data
    cnop 0,4
VerNumStrBuff: dc.b 0,0,0,0,0


    section Code,code
;-----------------------------------------------------------
; Small strlen implementation.
;
; IN   A1.l - address of null-terminated string
; OUT: D0.l - length
;      A1.l - points to end of string (null terminator)
;-----------------------------------------------------------
; No additional overwrites
;-----------------------------------------------------------
strlen:
    move.l a1,d0  ; preserve the start address
    tst.b  (a1)+  ; test character
    bne.b  *-2    ; if not '\0', back to test
    subq   #1,a1  ; back to the null terminator
    suba.l d0,a1
    move.l a1,d0
    rts

**************** SET_ENV_VAR Implementation ****************

    section Code,code
;-----------------------------------------------------------
; Set environment variables on any OS (except 1.0)
;
; This routine checks the version of the dos.library
; (referenced in A6) and either proceeds to SetVar when
; available (dos.library versions >= 36) or to setenv
;
; Note that the flags argument (D4), which SetVar accepts is
; not passed through. For OS 2.0+ D4 is explicitly set to
; local scope. For OS 1.x, environment variables cannot be
; anything but global, i.e., stored in ENV:
;
;
; IN      D1 - address of null-terminated env. var. name
;         D2 - address of content string
;         D3 - Content length, -1 for null-terminated string
; OUT:    D0 - TRUE (-1) if successful, FALSE (0) if not
; IN/OUT: D6 - Reference to dos.library
;-----------------------------------------------------------
; Potentially overwrites D0, D1, A0, A1
;-----------------------------------------------------------
setEnvVar:
    cmp.w #36,EXEC_O_LIB_VER(a6)
    bls.b setenv
    move.l d4,-(sp)             ; preserve D4
    move.l  #GVF_LOCAL_ONLY,d4  ; scope is local to script
    jsr _LVOSetVar(a6)
    move.l (sp)+,d4             ; restore D4
    move d0,d0                  ; restore SR
    rts

    section Code,code
;-----------------------------------------------------------
; Resembles the functionality of the setenv Amiga DOS
; command, which means it creates a file with the name of
; the environment variable in ENV: and fills it with the
; given content.
;
; The interface resembles that of SetVar found in
; dos.library v36, except that the flags argument (D4) is
; ignored due to the global nature of setenv.
;
;
; IN      D1 - address of null-terminated env. var. name
;         D2 - address of content string
;         D3 - Content length, -1 for null-terminated string
; OUT:    D0 - TRUE (-1) if successful, FALSE (0) if not
; IN/OUT: D6 - Reference to dos.library
;
;-----------------------------------------------------------
; Potentially overwrites D0, D1, A0, A1
;-----------------------------------------------------------
setenv:
.PRESERVED_REGS: REG d2-d4/a3/a4
    movem .PRESERVED_REGS,-(sp) ; preserve registers

; 1. get total length of env variable path
    move.l  d1,a1   ; arg1 for strlen
    bsr     strlen  ; get length in D0
    movea.l d1,a1   ; restore A! to start of name
    addq.b  #5,d0   ; Add 5 (for "ENV:" and '\0')

    move.l sp,a4                   ; preserve sp
    CREATE_ALIGNED_STACK_FRAME d0

; 2. Put env. var. path at the beginning of the stack frame
    movea.l sp,a0  ; SP cannot be byte-incremented, use A0
    ; Start by putting "ENV:" in string
    move.l #"ENV:",(a0)+  ; stack frame must be aligned to 4    
.copy                     ; copy env. variable name  
    move.b (a1)+,(a0)+
    bne.b  .copy

; 3. Create file at env path
    move.l  sp,d1             ; arg1: name (null terminated)
    move.l  d2,a3             ; save content ref. in A3
    move.l  #MODE_NEWFILE,d2  ; arg2: overwrite existing    
    jsr     _LVOOpen(a6)
    move.l  a4,sp             ; return stack frame
    move.l  d0,d4             ; preserve filehandle
    beq.b  .error             ; If we moved a 0, open failed

; 4. Write content
    ; D3 is still set from beginning, but maybe 0 (no
    ; content) or -1, which means we must calc. the length
    tst.l d3
    beq.b .closeFile  ; nothing to write
    bpl.b .callWrite  ; we already have a length
    ; We must calculate the length of the content
    move.l a3,a1      ; arg1 for strlen
    bsr    strlen
    move.l d0,d3      ; now we have the length in D3

.callWrite    
    move.l d4,d1       ; arg1: env. var. filehandle
    move.l a3,d2       ; arg2: content ref.
    jsr _LVOWrite(a6)
    cmp.l d0,d3
    bne.b .error

; 5. Close file and return
.closeFile:
    move.l d4,d1           ; restore filehandle
    jsr    _LVOClose(a6)
    moveq  #TRUE,D0        ; return Success
    bra.b  .end

.error:
    moveq #FALSE,d0  ; return Failure

.end:
    movem (sp)+,.PRESERVED_REGS  ; restore registers
    rts

**************** SET_ENV_VAR Error Message *****************

    section Code,code
;-----------------------------------------------------------
; Prints a message that shows that SET_ENV_VAR has failed
; for an environment variable name
;
; IN: D1 - Environment Variable Name Address
printSetEnvVarErrMsg:
    movem.l d2-d4/a4,-(sp)  ; preserve used registers
    move.l  d1,d2
    jsr     _LVOOutput(a6)  ; obtain stdout in D0
    bne.b   .write
    rts

.write
    move.l  d0,d4  ; preserve stdout to D4
; 1. get total length of env variable path
    move.l d2,a1   ; Arg1 for strlen
    bsr    strlen  ; get length in D0

    ; Add msg len and 1 for LF
    addi.b  #MsgPreEnd-MsgPre+1,d0

    move.l d0,d3                   ; preserve for Write
    move.l sp,a4                   ; preserve sp
    CREATE_ALIGNED_STACK_FRAME d3
    
    move.l #MsgPre,a1
    move.l sp,a0
.copyPre
    move.b (a1)+,(a0)+
    cmp.l  #MsgPreEnd,a1
    bne.b .copyPre

    movea.l d2,a1           ; restore A1 to start of name
.copyVarName
    move.b (a1)+,(a0)+
    bne.b .copyVarName
    move.b #10,-(a0)  
    move.l d4,d1
    move.l sp,d2
    jsr    _LVOWrite(a6)
    move.l a4,sp            ; give back aligned stack frame
    movem.l (sp)+,d2-d4/a4  ; restore used registers
.end
    rts

    section Strings,code
MsgPre: dc.b "Failed to set $"
MsgPreEnd


*************** Set All Environment Variables **************

    section Code,code
; This is where the individual setters are called.
; Extent with new features here!
setAllVariables:
    ifd setKickstartEnvVars
    bsr   setKickstartEnvVars
    endif
    ifd setCPUAndFPUEnvVars
    bsr   setCPUAndFPUEnvVars
    endif
    ifd setChipsetAndVFreqEnvVars
    bsr   setChipsetAndVFreqEnvVars
    endif
    ifd setBSDSockLibEnvVars
    bsr   setBSDSockLibEnvVars
    endif
    ifd setUAEEnvVars
    bsr   setUAEEnvVars
    endif
    rts
