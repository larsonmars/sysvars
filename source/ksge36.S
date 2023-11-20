************************************************************
*                                                          *
*                       KSGE36 V.1.0                       *
*                                                          *
* SPDX-FileCopyrightText: (c) 2023 Lars Stockmann          *
* SPDX-License-Identifier: 0BSD                            *
*                                                          *
*                                                          *
* SYNOPSIS:                                                *
*                                                          *
* Determines the kickstart version and returns WARN when   *
* it detects an OS below 2.0 (i.e., ver.36)                *
*                                                          *
************************************************************

KS_END            = $1000000
KS_END_OFFSET_LEN = -20
KS_VER_OFFSET     = 12
WARN              = 5
   
    moveq  #0,d0                     ; clear return register
    lea    (KS_END),a0
    sub.l  KS_END_OFFSET_LEN(a0),a0  ; Subtract KS length   
    cmp.w  #36,KS_VER_OFFSET(a0)
    bge    .end
    moveq  #WARN,d0
.end:
    rts

    dc.b 0,"$VER: KSGE36 1.0 (20.11.2023)",0
