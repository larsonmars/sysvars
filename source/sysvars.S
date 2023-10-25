************************************************************
*                                                          *
*                      SYSVARS V.0.9.0                     *
*                                                          *
* SPDX-FileCopyrightText: 2023 Lars Stockmann              *
* SPDX-License-Identifier: MIT                             *
*                                                          *
* SYNOPSIS                                                 *
*                                                          *
* Sets the following environment variables:                *
* - CPU     = "680*0", where * is 0, 1, 2, 3, 4, 6, or 8   *
* - FPU     = "" (empty), "internal" | "6881" | "6882"     *
* - Chipset = "OCS" | "ECS" | "AGA" | "???" (unknown)      *
* - VFreq   = "50" (PAL) | "60" (NTSC)                     *
* - UAE     = "" (empty) | <UAE Version string>            *
************************************************************


********************  Global Constants  ********************
; Global Constants
FALSE     =  0
TRUE      = -1
EXEC_BASE =  4

; Exec LVOs
LVOOpenLibrary  = -552
LVOCloseLibrary = -414

LVOAttnFlags = $128

; Dos LVOs
LVOOutput = -60   
LVOOpen   = -30
LVOClose  = -36
LVOWrite  = -48
LVOSetVar = -900

; Global registers
VPOSR = $dff004

; Flags
MODE_NEWFILE   = 1006
GVF_LOCAL_ONLY = $200


    section Code,code ; We use explicitely named sections

*************************  Macros  *************************

GetContentAndSetVar: macro
    bsr     Get\1VarContent   ; get variable content
    move.l  #.\1EnvVarName,d1 ; arg1: variable name
    move.l  #\1EnvVarCont,d2  ; arg2: variable content
    move.l  d0,d3             ; arg3: content length
    jsr     (a5)              ; A5 must hold SetVar funcptr
    beq.s   .error
    section Strings,code
.\1EnvVarName:     dc.b "\1",0
    section Code,code
    endm

OpenDosLib: macro
    movea.l EXEC_BASE,a6        ; get exec base in A6
; load dos.library
    lea     DosLibName,a1       ; "dos.library"
    moveq   #\1,d0              ; version is macro param
    jsr     LVOOpenLibrary(a6)
    move.l  d0,a6               ; store dosLib ref in A6
    endm

CloseCurrentLibrary: macro
    movea.l a6,a1                ; arg1: current lib from A6
    movea.l EXEC_BASE,a6         ; get exec base in A6
    jsr     LVOCloseLibrary(a6)    
    endm
   

**************************  Main  **************************

Main:
    OpenDosLib 36         ; version 36 is OS 2.0
    bne.s .prepareSetVar

; Failed to load dos.library. Use our own impl. of SetVar
    OpenDosLib 0               ; any version
    movea.l #SetVarFor1_3,a5   ; A5 used GetContentAndSetVar
    bra.s   .setupEnvironment

.prepareSetVar
    lea.l  LVOSetVar(a6),a5  ; A5 used GetContentAndSetVar

    ; prepare register D4 for all SetVar calls
    move.l  #GVF_LOCAL_ONLY,d4  ; scope is local to script

.setupEnvironment:
    GetContentAndSetVar CPU
    GetContentAndSetVar FPU
    GetContentAndSetVar Chipset
    GetContentAndSetVar VFreq
    GetContentAndSetVar UAE

    CloseCurrentLibrary  ; close dos.library
    moveq   #0,d0        ; return code 0
    rts

.error:
    jsr     LVOOutput(a6)         ; obtain stdout in D0
    move.l  d0,d1                 ; Arg1 stdout
    beq.s   .exitError
    move.l  #ErrMsg,d2            ; Arg2 error message
    moveq   #ErrMsgEnd-ErrMsg,d3  ; Arg3 error message length
    jsr     LVOWrite(a6)

.exitError
    CloseCurrentLibrary  ; close dosLib
    moveq   #20,d0       ; return code 20
    rts

    section Strings,code

; Library names
DosLibName:  dc.b "dos.library",0
UaeResName:  dc.b "uae.resource",0

; Error strings
ErrMsg:  dc.b "Could not set environment variables.",10  
ErrMsgEnd:


************************  Chipset  *************************

* GetChipsetVarContent
*
* Writes either "OCS\0", "ECS\0" or a "AGA\0" to
* ChipsetEnvVarCont
*
* Note: The string is cmposed using a long move. Thus the
*       target string must be aligned*
*
* IN: -
* OUT: D0.l - Length of string in ChipsetEnvVarCont, which
*             is always 3

    section Code,code
GetChipsetVarContent:
; We use VPOSR to detect Agnus/Alice
    move.b  VPOSR,d0  ; get VPOSR bits
    andi.b  #$7f,d0   ; mask out LOF

; D1 is used to create the chipset string.
    move.l  #"OCS",d1
    cmpi.b  #10,d0
    bls.s   .storeChipset
    move.l  #"ECS",d1
    andi.b  #$F,d0
    cmpi.b  #1,d0
    bls.s   .storeChipset
    move.l  #"AGA",d1
    cmpi.b  #3,d0
;    bls.s   .storeChipset
; TODO SAGA...
    
.storeChipset:
    lsl.l   #8,d1                 ; zero-terminate
    move.l  d1,ChipsetEnvVarCont
    moveq   #3,d0	
	rts
    
    section EnvVarContPreInit,data

    cnop 0,4  ; align, because we write to it using a long
ChipsetEnvVarCont: dc.b "???",0


*************************  VFreq  **************************

* GetVFreqVarContent
*
* Writes either a '5' or a '6' depending on the vertical
* frequency of the native chipset at the beginning of
* VFreqEnvVarCont, which is expected to be preinitialized
* with "?0"
*
* IN: -
* OUT: D0.l - Length of string in GetCPUVarContent, which is
*             always 2

    section Code,code
GetVFreqVarContent:
; We use again VPOSR to detect PAL/NTSC
    move.b  VPOSR,d0 ; get VPOSR bits
    andi.b  #$7f,d0  ; mask out LOF

; PAL or NTSC shall result in "5" or "6" in D1
    lsr.b   #4,d0
    andi.b  #1,d0               ; 0 (PAL) 1 (NTSC)
    addi.b  #"5",d0             ; "5" (PAL) "6" (NTSC)
    move.b  d0,VFreqEnvVarCont  ; store digit in var
    moveq   #2,d0

    rts

    section EnvVarContPreInit,data
VFreqEnvVarCont:   dc.b "?0",0


**************************  CPU  ***************************

* GetCPUVarContent
*
* Writes the significant character of the CPU into position
* 3 (starting at 0) of GetCPUVarContent. The content must be
* preinitialized with "680?0"
*
* Note: OS 1.3 will only set the bits for 68030 in AttnFlags
*       even for higher CPUs. Thus, detection does not work
*       properly here.
*
* IN: -
* OUT: D0.l - Length of string in GetCPUVarContent, which is
*             always 5


    section Code,code
GetCPUVarContent:
; Test bits of second AttnFlags byte
    movea.l EXEC_BASE,a0         ; get exec base in A0
    move.w  LVOAttnFlags(a0),d0  ; get cpu info in D0
    
; D1 gets the CPU version as ASCII character that replaces
; the "?" in "680?0"
    moveq   #"8",d1    ; assume 68080 (untested)
    btst    #11,d0
    bne.s   .storeCPU
    moveq   #"6",d1    ; assume 68060
    btst    #7,d0
    bne.s   .storeCPU
    moveq   #"4",d1    ; assume 68040
    btst    #3,d0
    bne.s   .storeCPU
    moveq   #"3",d1    ; assume 68030
    btst    #2,d0
    bne.s   .storeCPU
    moveq   #"2",d1    ; assume 68020
    btst    #1,d0
    bne.s   .storeCPU
    moveq   #"1",d1    ; assume 68010
    btst    #0,d0
    bne.s   .storeCPU
    moveq   #"0",d1    ; it must be 68000
    
.storeCPU:
    move.b  d1,CPUEnvVarCont+3  ; store digit in var
    moveq   #5,d0
    rts
	
    section EnvVarContPreInit,data
CPUEnvVarCont:     dc.b "680?0",0


**************************  FPU  ***************************

* GetFPUVarContent
*
* Ensures that GetFPUVarContent holds the correct FPU
* identifier. It expects GetFPUVarContent pre-filled with
* "6888rnal" and will either put a null-terminator at the
* beginning (no FPU), a "1\0" or "2\0" at pos. 4, or §inte"
* at the beginning so the content reads "intenal"
*
* Note: The string is cmposed using a long move. Thus the
*       target string must be aligned.
*
* IN: -
* OUT: D0.l - Length of string in GetFPUVarContent

    section Code,code
GetFPUVarContent:
    lea FPUEnvVarCont,a0         ; get content ref in A0
    movea.l EXEC_BASE,a1         ; get exec base in A1
    move.w  LVOAttnFlags(a1),d0  ; get processor info

; We lshift D0 (via add.b d0,d0) until it is negative
; D1 holds the pointer to the respective string
    add.b   d0,d0
    bmi.s   .storeInternal
    add.b   d0,d0
    bmi.s   .store68882
    add.b   d0,d0
    bmi.s   .store68881
    move.b  #0,(a0)
    moveq   #0,d0
    rts

.storeInternal
    move.l  #"inte",(a0)  ; "internal"
    moveq   #8,d0
    rts

.store68882
    move.b  #"2",4(a0)
    moveq   #5,d0
    rts

.store68881
    move.b  #"1",4(a0)
    moveq   #5,d0
    rts

    section EnvVarContPreInit,data
    cnop 0,4  ; align, because we write to it using a long
FPUEnvVarCont: dc.b "6888rnal",0


*************************  Memory  *************************

; TODO
;LVOMaxLocMem    = $3e
;LVOMaxExtMem    = $4e
;Get_memory_envvars_cont:
;
;    movea.l EXEC_BASE,a0        ; get exec base in A6
;    move.l LVOMaxLocMem(a0),d1  ; Chip Mem End Address
;    lea    LVOMaxExtMem(a0),a1  ; 0 if none
;    move   $200000,d2


**************************  UAE  ***************************

* GetUAEVarContent
*
* Writes a UAE version string into UAEEnvVarCont.
*
* IN: -
* OUT: D0.l - Length of string in UAEEnvVarCont


    section Code,code
GetUAEVarContent:

LVOResourceList = $150
LVOFindName     = -276

; UAE structure embeds a library structure, which embeds a
; node structure. At offset 34 it holds three words: major,
; minor and revision

    move.l a2,-(sp) ; preserve A2 (needed for UAE struct)
    move.l a6,-(sp) ; preserve A6 (needed for SysBase)
    
    movea.l EXEC_BASE,a6            ; get exec base in A6
    lea     LVOResourceList(a6),a0  ; arg1 resource list
    lea     UaeResName,a1           ; arg2 resource name
    jsr     LVOFindName(a6)         ; call FindName    
; Test whether UAE was detected    
    beq.s   .end

; Store version as string in UAEEnvVarCont    
    move.l  d0,a2              ; address of uae struct in A2
    adda    #34,a2             ; add precalculated offset
    lea     UAEEnvVarCont,a1   ; get dest string ptr in A1
    moveq   #0,d1              ; clear D1
    move.w  (a2)+,d1           ; get major version in D1
    bsr.s   UI16ToStr          ; D1 and A1 are parameters
; A1 is now at end of printed string
    move.b  #".",(a1)+         ; print '.' and increment A0    
    move.w  (a2)+,d1           ; get minor version in D0
    bsr.s   UI16ToStr
; A1 is now at end of printed string    
    move.b  #".",(a1)+         ; print '.' and increment A0
    move.w  (a2),d1            ; get revision version in D0
    bsr.s   UI16ToStr
    suba.l  #UAEEnvVarCont,a1  ; Get printed length
    move.l  a1,d0              ; length is expected in D0

.end:
    move.l (sp)+,a6  ; restore A6
    move.l (sp)+,a2  ; restore A2
    rts

    section EnvVarCont,bss
; ensure no overflow, even for if registers hold a stupid
; value of 0xFFFF, which would yield "65535.65535.65535"
UAEEnvVarCont: ds.b 5*3+2


************************  Helpers  *************************

* UI16ToStr
*
* Prints an unsigned short
*
* IN:  D1.w - Integer to be printed
*      A1.l - Address to string
* OUT: A0.l - End of the written string

    section Code,code
UI16ToStr:
    move.l sp,a0        ; preserve current stack addr. in A0
    moveq  #0,d0        ; clean D0
    move.w d1,d0        ; put initial uint16 in D0
.loop	
    divu   #10,d0       ; Divide by 10
    move.w d0,d1        ; put quotient (first 16bits) in D0
    swap   d0           ; get remainder by swapping 16 bit
    move.b d0,-(sp)     ; put remainder on stack
    move.w d1,d0        ; continue with quotient
    bne.s    .loop      ; until quotient is 0
.makeDigits
    move.b (sp)+,d1     ; get back the remainders from stack
    addi.b #"0",d1      ; make ASCII character
    move.b d1,(a1)+     ; store char to target address
    cmpa.l sp,a0        ; check against preseved stack ptr
    bne.s  .makeDigits

    rts

* SetVarFor1_3
*
* This effectively implements setenv. It creates a file with
* the name of the environment variable in ENV: and fills it
* with the given content.
*
* The interface resembles that of SetVar found in
* dos.library v36, except that the flags argument (D4) is
* ignored, because environment variables cannot be anything
* but global (stored in ENV:)
*
* IN   D1.l - address of null-terminated env. var. name
*      D2.l - address of Content string
*      D3.l - Content length, -1 for null-terminated content
* OUT: D0 - TRUE if successful, FALSE if not
*
* Note: Just as the original SetVar call, we expect A6 to
*       hold a dos.library reference

    section Code,code
SetVarFor1_3:

SetVarRegs: REG d2-d4/a2-a3
    movem SetVarRegs,-(sp) ; preserve registers
; 1. get total length ov env variable path
    move.l  d1,a2  ; preserve name
    move.l  d1,a1  ; arg1 for strlen
    bsr.s   strlen ; get length in D0
    movea.l a2,a1  ; restore a1
    addq.b  #5,d0  ; Add 5 (for "ENV:" and '\0')
    neg.l   d0     ; negate so we can align easily
    asr.l   #1,d0  ; shift 1 left and then right rounds to
    asl.l   #1,d0  ;   the next multiple of 2 when negative
    movea.l sp,a2  ; preserve current SP
    add.l   d0,sp  ; create our stack frame

; 2. Put envvar path at the beginning of the stack frame
    movea.l sp,a0       ; SP cannot be byte-incremented
    ; Start by putting "ENV:"
    move.b #"E",(a0)+
    move.b #"N",(a0)+
    move.b #"V",(a0)+
    move.b #":",(a0)+    
.copy                   ; copy env. variable name  
    move.b (a1)+,(a0)+
    bne.s  .copy

; 3. Create file at env path
    move.l  sp,d1             ; arg1: name (null terminated)
    move.l  d2,a3             ; save ptr to content in A3
    move.l  #MODE_NEWFILE,d2  ; arg2: overwrite existing    
    jsr     LVOOpen(a6)
    movea.l a2,sp             ; return our name stack frame
    move.l  d0,d4             ; preserve env.var filehandle
    beq.s  .error             ; If D0 was 0, open failed

; 4. Write content
    ; d3 is still set from beginning, but maybe -1, which
    ; means we must calc the length
    cmpi.l #-1,d3
    bne.s .callWrite
    ; We must calculate the length of the content
    move.l a3,a1      ; arg1 for strlen
    bsr.s  strlen
    move.l d0,d3      ; now we have the length in D3
.callWrite    
    move.l d4,d1      ; arg1: env.var filehandle
    move.l a3,d2      ; arg2: pointer to content
    jsr LVOWrite(a6)
    cmp.l d0,d3
    bne.s .error

    ; 4. Close file and return
    move.l d4,d1             ; D1 has been overwritten
    jsr    LVOClose(a6)
    movem  (sp)+,SetVarRegs  ; restore registers
    moveq  #TRUE,D0          ; return Success
    rts

.error:
    movem (sp)+,SetVarRegs  ; restore registers
    moveq #FALSE,d0         ; return Failure
    rts

* strlen
*
* This is a small strlen function.
*
* IN   A1.l - address of null-terminated string
* OUT: D0 - length

; A1 is expected to hold address of string
; Length is returned in D0 
strlen:
    move.l a1,d0  ; preserve the start address
    tst.b  (a1)+  ; test character
    bne.s  *-2    ; if not '\0', back to test
    suba.l d0,a1
    move.l a1,d0
    subq   #1,d0
    rts