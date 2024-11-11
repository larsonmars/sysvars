************************************************************
*                                                          *
*                      probevar V.1.0                      *
*                                                          *
* SPDX-FileCopyrightText: (c) 2024 Lars Stockmann          *
* SPDX-License-Identifier: MIT                             *
*                                                          *
*                                                          *
* SYNOPSIS:                                                *
*                                                          *
* Checks if a local (global on KS < 2.0) environment       *
* variable exists.                                         *
* Can be made resident                                     *
*                                                          *
************************************************************

EXEC_BASE =  4

SUCCESS = 0
WARN    = 5
ERROR   = 10
FAIL    = 20

_LVOOpenLibrary  = -552
_LVOCloseLibrary = -414

_LVOOpen    = -30
_LVOClose   = -36
_LVOFindVar = -918

MAX_NAME_LEN = 103   ; max path length is 107 - "ENV:"
MODE_OLDFILE = 1005  ; constant to open existing file

main:

    movea.l a0,a5      ; preserve args string in A5
    move.l d0,d5       ; preserve args string length in D5
    subq #1,d5         ; length includes LF
    beq .error         ; if length is 0, return error
    move.b #0,(a0,d5)  ; remove LF (0xa)

    movea.l EXEC_BASE,a6         ; get exec base in A6
    lea     DosLibName,a1        ; library name
    moveq   #36,d0               ; version 36
    jsr     _LVOOpenLibrary(a6)
    move.l  d0,a6
    beq.b   .getGlobalVar

    move.l a5,d1
    moveq #0,d2
    jsr _LVOFindVar(a6)
    tst.l d0
    beq .notFound

.found:
    moveq #SUCCESS,d0
    rts

.notFound:
    moveq #WARN,d0
    rts

.error:
    moveq #ERROR,d0
    rts

.failure:
    moveq #FAIL,d0
    rts     

.getGlobalVar:

    cmpi.l #MAX_NAME_LEN,d5
    bhi .error

    addq    #6,d5  ; Add 5 for "ENV:\0", 1 for word boundary
    lsr.b   #1,d5  ; can calc with bytes (see MAX_NAME_LEN)
    add.b   d5,d5
    suba    d5,sp  ; allocate stack
    movea.l sp,a0

    move.w #"EN",(a0)+
    move.w #"V:",(a0)+

.copyVarName:
    move.b (a5)+,(a0)+
    bne .copyVarName

; Open dos library (any version)
    movea.l EXEC_BASE,a6         ; get exec base in A6
    lea     DosLibName,a1        ; library name
    moveq   #0,d0                ; any version
    jsr     _LVOOpenLibrary(a6)  ; open dos.library
    move.l  d0,a6
    beq.b   .failure             ; This should never happen

; Try to open variable file (close it if successful)
    move.l sp,d1             ; name is on the stack
    move.l #MODE_OLDFILE,d2
    jsr    _LVOOpen(a6)
    adda   d5,sp             ; return stack
    move.l d0,d1
    beq    .notFound
    jsr    _LVOClose(a6)
    bra.s  .found
    ; Note: Close has no return value prior v36   


DosLibName:
    dc.b "dos.library",0

    dc.b 0,"$VER: probevar 1.0",0

