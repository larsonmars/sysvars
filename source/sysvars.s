***********************************************************
*                                                         *
*                      SYSVARS V.0.8                      *
*                                                         *
* SPDX-FileCopyrightText: 2023 Lars Stockmann             *
* SPDX-License-Identifier: MIT                            *
*                                                         *
* SYNOPSIS                                                *
*                                                         *
* Sets the following environment variables:               *
* - CPU     = "680*0", where * is 0, 1, 2, 3, 4, 6, or 8  *
* - FPU     = "" (empty), "internal" | "6881" | "6882"    *
* - Chipset = "OCS" | "ECS" | "AGA" | "???" (unknown)     *
* - VFreq   = "50" (PAL) | "60" (NTSC)                    *
* - UAE     = "" (empty) | <UAE Version string>           *
***********************************************************


********************  Global Constants  *******************

EXEC_BASE = 4

LVOOpenLibrary  = -552
LVOCloseLibrary = -414

LVOOutput = -60   
LVOWrite  = -48 

VPOSR = $dff004

    section CODE,code

    section Constants,code

WrongOsMsg:     dc.b "Requires Amiga OS 2.0+",10  
DosLibName:     dc.b "dos.library",0
WrongOsMsgLen = DosLibName-WrongOsMsg
UaeResName:     dc.b "uae.resource",0

    section CODE,code

*************************  Macros  ************************

GetContentAndSetVar: macro
    section Constants,code
    \1EnvVarName:     dc.b "\1",0
    section CODE,code
    jsr     Get\1VarContent   ; get variable content
    move.l  #\1EnvVarName,d1  ; arg1: variable name
    move.l  #\1EnvVarCont,d2  ; arg2: variable content
    jsr     LVOSetVar(a6)     ; A5 holds dosLib ref
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
    movea.l a6,a1
    movea.l EXEC_BASE,a6          ; get exec base in A6
    jsr     LVOCloseLibrary(a6)    
    endm

**************************  Main  *************************

Main:

    OpenDosLib 36     ; version 36 is Kick 2.0
    bne.s   .setVars  ; Check success

; Failed to load dosLib. Print error & exit with retcode 20
    OpenDosLib 0                ; any version
    jsr     LVOOutput(a6)       ; obtain stdout in D0
    move.l  d0,d1               ; Arg1 stdout
    beq.s   .exitError
    move.l  #WrongOsMsg,d2      ; Arg2 error message
    move.l  #WrongOsMsgLen,d3   ; Arg3 error message length
    jsr     LVOWrite(a6)
    CloseCurrentLibrary         ; close dosLib
.exitError
    moveq   #20,d0              ; return code 20
    rts

.setVars

LVOSetVar       = -900
GVF_LOCAL_ONLY   = $200

; prepare registers D3 and D4 for all GetContentAndSetVar calls
    moveq   #-1,d3                 ; strings end with \0 
    move.l  #GVF_LOCAL_ONLY,d4     ; scope

    GetContentAndSetVar CPU
    GetContentAndSetVar FPU
    GetContentAndSetVar Chipset
    GetContentAndSetVar VFreq
    GetContentAndSetVar UAE

    CloseCurrentLibrary ; close dosLib
    moveq   #0,d0       ; return code 0
    rts
    

************************  Chipset  ************************

GetChipsetVarContent:
; We use VPOSR to detect Agnus/Alice
    move.b  VPOSR,d0   ; get VPOSR bits
    andi.b  #$7f,d0    ; mask out LOF
; D1 is used to create the chipset string.
    move.l  #"OCS",d1
    cmpi.b  #10,d0
    bls.s   .store_chipset
    move.l  #"ECS",d1
    andi.b  #$F,d0
    cmpi.b  #1,d0
    bls.s   .store_chipset
    move.l  #"AGA",d1
    cmpi.b  #3,d0
;    bls.s   .store_chipset
; TODO SAGA...
    
.store_chipset:
    lsl.l   #8,d1                   ; zero-terminate
    move.l  d1,ChipsetEnvVarCont	
	rts
    
    section EnvVarContPreInit,data
ChipsetEnvVarCont: dc.b "???",0
    section CODE,code

*************************  VFreq  *************************

GetVFreqVarContent:
; We use again VPOSR to detect PAL/NTSC
    move.b  VPOSR,d0               ; get VPOSR bits
    andi.b  #$7f,d0                ; mask out LOF
; PAL or NTSC shall result in "5" or "6" in D1
    lsr.b   #4,d0
    andi.b  #1,d0                ; 0 (PAL) 1 (NTSC)
    addi.b  #"5",d0              ; "5" (PAL) "6" (NTSC)
    move.b  d0,VFreqEnvVarCont  ; store digit in var

    rts

    section EnvVarContPreInit,data
VFreqEnvVarCont:   dc.b "?0",0
    section CODE,code
    
**************************  CPU  **************************

GetCPUVarContent:

LVOAttnFlags = $128

; Test bits of second AttnFlags byte
    movea.l EXEC_BASE,a0          ; get exec base in A0
    move.w  LVOAttnFlags(a0),d0  ; get cpu info in D0
    
; D1 gets the CPU version as ASCII character that replaces
; the "?" in "680?0"
    moveq   #"8",d1     ; assume 68080 (untested)
    btst    #11,d0
    bne.s   .store_cpu
    moveq   #"6",d1     ; assume 68060
    btst    #7,d0
    bne.s   .store_cpu
    moveq   #"4",d1     ; assume 68040
    btst    #3,d0
    bne.s   .store_cpu
    moveq   #"3",d1     ; assume 68030
    btst    #2,d0
    bne.s   .store_cpu
    moveq   #"2",d1     ; assume 68020
    btst    #1,d0
    bne.s   .store_cpu
    moveq   #"1",d1     ; assume 68010
    btst    #0,d0
    bne.s   .store_cpu
    moveq   #"0",d1     ; it must be 68000
    
.store_cpu:
    move.b  d1,CPUEnvVarCont+3  ; store digit in var
    rts
	
    section EnvVarContPreInit,data
CPUEnvVarCont:     dc.b "680?0",0
    section CODE,code

**************************  FPU  **************************
GetFPUVarContent:
    lea FPUEnvVarCont,a0       ; get content ref in A0
    movea.l EXEC_BASE,a1         ; get exec base in A1
    move.w  LVOAttnFlags(a1),d0  ; get processor info
; We lshift D0 (via add.b d0,d0) until it is negative
; D1 holds the pointer to the respective string
    add.b   d0,d0
    bmi.s   .store_internal
    add.b   d0,d0
    bmi.s   .store_68882
    add.b   d0,d0
    bmi.s   .store_68881
    move.b  #0,(a0)         ; null-terminate (no FPU)
    rts

.store_internal
    move.l  #"inte",(a0)  ; "internal"
    rts
.store_68882
    move.w  #"2"<<8,4(a0)
    rts
.store_68881
    move.w  #"1"<<8,4(a0) ; store pointer in var
    rts
    
    section EnvVarContPreInit,data
    cnop 0,4
FPUEnvVarCont      dc.b "6888rnal",0
    section CODE,code

************************  Memory  *************************

; TODO
;LVOMaxLocMem    = $3e
;LVOMaxExtMem    = $4e
;Get_memory_envvars_cont:
;
;    movea.l EXEC_BASE,a0           ; get exec base in A6
;    move.l LVOMaxLocMem(a0),d1   ; Chip Mem End Address
;    lea    LVOMaxExtMem(a0),a1   ; 0 if none
;    move   $200000,d2


**************************  UAE  **************************

GetUAEVarContent:

LVOResourceList = $150
LVOFindName     = -276

; UAE structure embeds a library structure, which
; embeds a node structure. At offset 34 it holds three
; words: major, minor and revision

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
    moveq   #0,d0              ; clean D0
    adda    #34,a2             ; add precalculated offset
    lea     UAEEnvVarCont,a0 ; get dest string addr. in A0    
    move.w  (a2)+,d0           ; get major version in D0
    bsr.s   PrintPositiveInt   ; D0 and A0 are parameters
; A0 is now at end of printed string
    move.b  #".",(a0)+         ; print '.' and increment A0    
    move.w  (a2)+,d0           ; get minor version in D0
    bsr.s   PrintPositiveInt
; A0 is now at end of printed string    
    move.b  #".",(a0)+         ; print '.' and increment A0
    move.w  (a2),d0            ; get revision version in D0
    bsr.s   PrintPositiveInt

.end:
    move.l (sp)+,a6 ; restore A6
    move.l (sp)+,a2 ; restore A2
    rts

    section EnvVarCont,bss    
UAEEnvVarCont:     ds.b 16
    section CODE,code

************************  Helpers  ************************

; Expects number in D0 and address to string in A0
; Sets A0 to the end of the string
PrintPositiveInt
    move.l sp,a1
    move.l d0,d1
.loop	
    divu   #10,d1
    move.w d1,d0
    lsr.l  #8,d1
    lsr.l  #8,d1  
    move.b d1,-(sp)
    move.l d0,d1    
    bne.s    .loop
.make_digits
    move.b (sp)+,d0
    add    #"0",d0
    move.b d0,(a0)+
    cmpa.l sp,a1
    bne.s  .make_digits

    rts