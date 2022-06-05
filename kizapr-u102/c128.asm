;Start of code from C128 ROM
;C128 ROM is $D480-$F6FF

L0810 := $0810
L0A00 := $0A00
L1F0C := $1F0C
L42D0 := $42D0
L42E4 := $42E4
L4307 := $4307
L4825 := $4825
L4AF3 := $4AF3
L4D37 := $4D37
L4D39 := $4D39
L4DCA := $4DCA
L4F4C := $4F4C
L4F7F := $4F7F
L5044 := $5044
L5061 := $5061
L509D := $509D
L51D3 := $51D3
L51F0 := $51F0
L51F5 := $51F5
L53DE := $53DE
L5595 := $5595
L5609 := $5609
L5A79 := $5A79
L5A93 := $5A93
L5A9E := $5A9E
L673E := $673E
L77CB := $77CB
L77DD := $77DD
L78C5 := $78C5
L792A := $792A
L7944 := $7944
L7947 := $7947
L794A := $794A
L794C := $794C
L795A := $795A
L7A73 := $7A73
L7D16 := $7D16
L81F7 := $81F7
L8433 := $8433
L84B0 := $84B0
L84D0 := $84D0
L87F0 := $87F0
L87F3 := $87F3
L8805 := $8805
L880B := $880B
L880E := $880E
L8811 := $8811
L882A := $882A
L882D := $882D
L8841 := $8841
L8844 := $8844
L8959 := $8959
L8A20 := $8A20
L8A23 := $8A23
L8B3C := $8B3C
L8B3F := $8B3F
L8C2B := $8C2B
L8C77 := $8C77
L8CEE := $8CEE
L8E25 := $8E25
L8E35 := $8E35
L8FAA := $8FAA
L8FB4 := $8FB4
L8FED := $8FED
L9079 := $9079
L90C3 := $90C3
L90CB := $90CB
L90D2 := $90D2
L9108 := $9108
L9110 := $9110
L915A := $915A
L9236 := $9236
L9244 := $9244
L924A := $924A
L9256 := $9256
L925C := $925C
L9262 := $9262
L926E := $926E
L9273 := $9273
L9274 := $9274
L9286 := $9286
L92DD := $92DD
L9361 := $9361
L942F := $942F
L944C := $944C
L94A6 := $94A6
L95DA := $95DA
L95ED := $95ED
L9675 := $9675
L96A5 := $96A5
L96A9 := $96A9
L9718 := $9718
L971A := $971A
L9724 := $9724
L9767 := $9767
L977E := $977E
L9792 := $9792
L97EE := $97EE
L97F5 := $97F5
L980F := $980F
L981D := $981D
L9894 := $9894
L989B := $989B
L989E := $989E
L98CD := $98CD
L999A := $999A
L99A2 := $99A2
L99A6 := $99A6
L9AC1 := $9AC1
L9B23 := $9B23
L9BEE := $9BEE
L9C0C := $9C0C
L9C3C := $9C3C
L9CBD := $9CBD
L9EFB := $9EFB
L9F17 := $9F17
L9F1B := $9F1B
L9F30 := $9F30
LA067 := $A067
LA0E6 := $A0E6
LA107 := $A107
LA176 := $A176
LA373 := $A373
LA38F := $A38F
LA452 := $A452
LA4CE := $A4CE
LA53F := $A53F
LA559 := $A559
LA575 := $A575
LA590 := $A590
LB7CE := $B7CE
LB950 := $B950
LB952 := $B952
LC033 := $C033
LD400 := $D400
LD401 := $D401
LD404 := $D404
LF714 := $F714
LF717 := $F717
LF71A := $F71A
LF721 := $F721
LF761 := $F761
LF892 := $F892
LF8A5 := $F8A5
LF8A8 := $F8A8
LF8B4 := $F8B4
LF8C2 := $F8C2
LF8D2 := $F8D2
LF901 := $F901
LF90E := $F90E
LF922 := $F922
LF944 := $F944
LF960 := $F960
C128_FF4A_CLALL   := $FF4A  ;CLALL
C128_FF50_DMACALL := $FF50  ;DMACALL
C128_FF59_LKUPLA  := $FF59  ;LKUPLA
C128_FF5C_LKUPSA  := $FF5C  ;LKUPSA
C128_FF6E_JSRFAR  := $FF6E  ;JSRFAR
C128_FF71_JMPFAR  := $FF71  ;JMPFAR
C128_FF74_INDFET  := $FF74  ;INDFET
C128_FF77_INDSTA  := $FF77  ;INDSTA
C128_FF7A_INDCMP  := $FF7A  ;INDCMP
C128_FF7D_PRIMM   := $FF7D  ;PRIMM

;C128 truncated here
;C128 948A: 83 49 0F DA A2         	; '.i{FLSHON}Z.'

;TODO probably data
        phx                                     ; D480 DA                       .
;; 0.25
        ldx     #$7F                            ; D481 A2 7F                    ..
        brk                                     ; D483 00                       .
        brk                                     ; D484 00                       .
        brk                                     ; D485 00                       .
        brk                                     ; D486 00                       .
; -14.3813907
        ora     $84                             ; D487 05 84                    ..
        inc     $1A                             ; D489 E6 1A                    ..
        and     $861B                           ; D48B 2D 1B 86                 -..
        plp                                     ; D48E 28                       (
        rmb0    $FB                             ; D48F 07 FB                    ..
        sed                                     ; D491 F8                       .
        smb0    $99                             ; D492 87 99                    ..
        pla                                     ; D494 68                       h
        bit     #$01                            ; D495 89 01                    ..
        smb0    $23                             ; D497 87 23                    .#
        and     $DF,x                           ; D499 35 DF                    5.
        sbc     ($86,x)                         ; D49B E1 86                    ..
        lda     $5D                             ; D49D A5 5D                    .]
        smb6    $28                             ; D49F E7 28                    .(
        .byte   $83                             ; D4A1 83                       .
        eor     #$0F                            ; D4A2 49 0F                    I.
        phx                                     ; D4A4 DA                       .
        ldx     #$A5                            ; D4A5 A2 A5                    ..
        pla                                     ; D4A7 68                       h
        pha                                     ; D4A8 48                       H
        bpl     LD4AE                           ; D4A9 10 03                    ..
        jsr     L8FED                           ; D4AB 20 ED 8F                  ..
LD4AE:  lda     $63                             ; D4AE A5 63                    .c
        pha                                     ; D4B0 48                       H
        cmp     #$81                            ; D4B1 C9 81                    ..
        bcc     LD4BC                           ; D4B3 90 07                    ..
        lda     #$98                            ; D4B5 A9 98                    ..
        ldy     #$89                            ; D4B7 A0 89                    ..
        jsr     L8A1A                           ; D4B9 20 1A 8A                  ..
LD4BC:  lda     #$D6                            ; D4BC A9 D6                    ..
        ldy     #$94                            ; D4BE A0 94                    ..
        jsr     L9079                           ; D4C0 20 79 90                  y.
        pla                                     ; D4C3 68                       h
        cmp     #$81                            ; D4C4 C9 81                    ..
        bcc     LD4CF                           ; D4C6 90 07                    ..
        lda     #$78                            ; D4C8 A9 78                    .x
        ldy     #$94                            ; D4CA A0 94                    ..
        jsr     L8A14                           ; D4CC 20 14 8A                  ..
LD4CF:  pla                                     ; D4CF 68                       h
        bpl     LD4D5                           ; D4D0 10 03                    ..
        jmp     L8FED                           ; D4D2 4C ED 8F                 L..
; ----------------------------------------------------------------------------
LD4D5:  rts                                     ; D4D5 60                       `
; ----------------------------------------------------------------------------
;TODO probably data
        .byte   $0B                             ; D4D6 0B                       .
        ror     EAH,x                           ; D4D7 76 B3                    v.
        .byte   $83                             ; D4D9 83                       .
        lda     $79D3,x                         ; D4DA BD D3 79                 ..y
        asl     LA6F4,x                         ; D4DD 1E F4 A6                 ...
        sbc     $7B,x                           ; D4E0 F5 7B                    .{
        .byte   $83                             ; D4E2 83                       .
        .byte   $FC                             ; D4E3 FC                       .
        bcs     LD4F6                           ; D4E4 B0 10                    ..
        jmp     (L1F0C,x)                       ; D4E6 7C 0C 1F                 |..
        rmb6    $CA                             ; D4E9 67 CA                    g.
        jmp     (L53DE,x)                       ; D4EB 7C DE 53                 |.S
        .byte   $CB                             ; D4EE CB                       .
        cmp     ($7D,x)                         ; D4EF C1 7D                    .}
        trb     $64                             ; D4F1 14 64                    .d
        bvs     LD541                           ; D4F3 70 4C                    pL
        .byte   $7D                             ; D4F5 7D                       }
LD4F6:  smb3    $EA                             ; D4F6 B7 EA                    ..
        eor     ($7A),y                         ; D4F8 51 7A                    Qz
        adc     $3063,x                         ; D4FA 7D 63 30                 }c0
        dey                                     ; D4FD 88                       .
        ror     L927E,x                         ; D4FE 7E 7E 92                 ~~.
        .byte   $44                             ; D501 44                       D
        sta     $7E3A,y                         ; D502 99 3A 7E                 .:~
        jmp     L91CC                           ; D505 4C CC 91                 L..
; ----------------------------------------------------------------------------
;TODO probably data
        smb4    $7F                             ; D508 C7 7F                    ..
        tax                                     ; D50A AA                       .
        tax                                     ; D50B AA                       .
        tax                                     ; D50C AA                       .
        .byte   $13                             ; D50D 13                       .
        sta     ($00,x)                         ; D50E 81 00                    ..
        brk                                     ; D510 00                       .
        brk                                     ; D511 00                       .
        brk                                     ; D512 00                       .
        ldx     #$FF                            ; D513 A2 FF                    ..
        stx     stack+54                        ; D515 8E 36 01                 .6.
        jsr     L0380                           ; D518 20 80 03                  ..
        jsr     L77DD                           ; D51B 20 DD 77                  .w
        jsr     L77CB                           ; D51E 20 CB 77                  .w
        lda     $66                             ; D521 A5 66                    .f
        pha                                     ; D523 48                       H
        lda     $67                             ; D524 A5 67                    .g
        pha                                     ; D526 48                       H
        ldy     #$02                            ; D527 A0 02                    ..
LD529:  jsr     L42E4                           ; D529 20 E4 42                  .B
        dey                                     ; D52C 88                       .
        sta     $3F,y                           ; D52D 99 3F 00                 .?.
        bne     LD529                           ; D530 D0 F7                    ..
        jsr     L42E4                           ; D532 20 E4 42                  .B
        sta     stack+53                        ; D535 8D 35 01                 .5.
        tay                                     ; D538 A8                       .
        beq     LD546                           ; D539 F0 0B                    ..
LD53B:  dey                                     ; D53B 88                       .
        jsr     L42D0                           ; D53C 20 D0 42                  .B
        cmp     #$23                            ; D53F C9 23                    .#
LD541:  beq     LD549                           ; D541 F0 06                    ..
        tya                                     ; D543 98                       .
        bne     LD53B                           ; D544 D0 F5                    ..
LD546:  jmp     L795A                           ; D546 4C 5A 79                 LZy
; ----------------------------------------------------------------------------
LD549:  lda     #$3B                            ; D549 A9 3B                    .;
LD54B:  jsr     L794C                           ; D54B 20 4C 79                  Ly
        sty     $77                             ; D54E 84 77                    .w
        sty     stack+35                        ; D550 8C 23 01                 .#.
        jsr     L77DD                           ; D553 20 DD 77                  .w
        bit     $0F                             ; D556 24 0F                    $.
        bpl     LD593                           ; D558 10 39                    .9
        jsr     L9792                           ; D55A 20 92 97                  ..
        jsr     L98E5                           ; D55D 20 E5 98                  ..
        ldx     stack+43                        ; D560 AE 2B 01                 .+.
        beq     LD57A                           ; D563 F0 15                    ..
        ldx     #$00                            ; D565 A2 00                    ..
        sec                                     ; D567 38                       8
        lda     stack+49                        ; D568 AD 31 01                 .1.
        sbc     $78                             ; D56B E5 78                    .x
        bcc     LD57A                           ; D56D 90 0B                    ..
        ldx     #$3D                            ; D56F A2 3D                    .=
        cpx     stack+43                        ; D571 EC 2B 01                 .+.
        bne     LD579                           ; D574 D0 03                    ..
        lsr     a                               ; D576 4A                       J
        adc     #$00                            ; D577 69 00                    i.
LD579:  tax                                     ; D579 AA                       .
LD57A:  ldy     #$00                            ; D57A A0 00                    ..
LD57C:  txa                                     ; D57C 8A                       .
        beq     LD584                           ; D57D F0 05                    ..
        dex                                     ; D57F CA                       .
LD580:  lda     #$20                            ; D580 A9 20                    .
        bne     LD58C                           ; D582 D0 08                    ..
LD584:  cpy     $78                             ; D584 C4 78                    .x
        bcs     LD580                           ; D586 B0 F8                    ..
        jsr     L03B7                           ; D588 20 B7 03                  ..
        iny                                     ; D58B C8                       .
LD58C:  jsr     L98DE                           ; D58C 20 DE 98                  ..
        bne     LD57C                           ; D58F D0 EB                    ..
        beq     LD5BA                           ; D591 F0 27                    .'
LD593:  jsr     L8E35                           ; D593 20 35 8E                  5.
        ldy     #$FF                            ; D596 A0 FF                    ..
LD598:  iny                                     ; D598 C8                       .
        lda     stack,y                         ; D599 B9 00 01                 ...
        bne     LD598                           ; D59C D0 FA                    ..
        tya                                     ; D59E 98                       .
        jsr     $868C                           ; D59F 20 8C 86                  ..
        ldy     #$00                            ; D5A2 A0 00                    ..
        sta     $FF04                           ; D5A4 8D 04 FF                 ...
LD5A7:  lda     stack,y                         ; D5A7 B9 00 01                 ...
        beq     LD5B1                           ; D5AA F0 05                    ..
LD5AC:  sta     ($64),y                         ; D5AC 91 64                    .d
        iny                                     ; D5AE C8                       .
        bne     LD5A7                           ; D5AF D0 F6                    ..
LD5B1:  jsr     L86DF                           ; D5B1 20 DF 86                  ..
        jsr     L9792                           ; D5B4 20 92 97                  ..
        jsr     L95DA                           ; D5B7 20 DA 95                  ..
LD5BA:  jsr     DFLTO                           ; D5BA 20 86 03                  ..
        cmp     #$2C                            ; D5BD C9 2C                    .,
        beq     LD54B                           ; D5BF F0 8A                    ..
        sec                                     ; D5C1 38                       8
        ror     $77                             ; D5C2 66 77                    fw
        jsr     L98E5                           ; D5C4 20 E5 98                  ..
        pla                                     ; D5C7 68                       h
        tay                                     ; D5C8 A8                       .
        pla                                     ; D5C9 68                       h
        jsr     $8781                           ; D5CA 20 81 87                  ..
        jsr     DFLTO                           ; D5CD 20 86 03                  ..
        cmp     #$3B                            ; D5D0 C9 3B                    .;
        beq     LD5D7                           ; D5D2 F0 03                    ..
        jmp     L5595                           ; D5D4 4C 95 55                 L.U
; ----------------------------------------------------------------------------
LD5D7:  jmp     L0380                           ; D5D7 4C 80 03                 L..
; ----------------------------------------------------------------------------
        sta     $FF03                           ; D5DA 8D 03 FF                 ...
        lda     $1204                           ; D5DD AD 04 12                 ...
        sta     stack+51                        ; D5E0 8D 33 01                 .3.
        lda     #$FF                            ; D5E3 A9 FF                    ..
LD5E5:  sta     stack+50                        ; D5E5 8D 32 01                 .2.
        jmp     L95ED                           ; D5E8 4C ED 95                 L..
; ----------------------------------------------------------------------------
LD5EB:  stx     $80                             ; D5EB 86 80                    ..
LD5ED:  cpy     $78                             ; D5ED C4 78                    .x
        beq     LD624                           ; D5EF F0 33                    .3
        lda     stack,y                         ; D5F1 B9 00 01                 ...
        iny                                     ; D5F4 C8                       .
        cmp     #$20                            ; D5F5 C9 20                    .
        beq     LD5ED                           ; D5F7 F0 F4                    ..
        cmp     #$2D                            ; D5F9 C9 2D                    .-
        beq     LD5E5                           ; D5FB F0 E8                    ..
        cmp     #$2E                            ; D5FD C9 2E                    ..
        beq     LD5EB                           ; D5FF F0 EA                    ..
        cmp     #$45                            ; D601 C9 45                    .E
        beq     LD616                           ; D603 F0 11                    ..
        sta     stack,x                         ; D605 9D 00 01                 ...
        stx     stack+36                        ; D608 8E 24 01                 .$.
        inx                                     ; D60B E8                       .
        bit     $80                             ; D60C 24 80                    $.
        bpl     LD5ED                           ; D60E 10 DD                    ..
        inc     stack+42                        ; D610 EE 2A 01                 .*.
        jmp     L95ED                           ; D613 4C ED 95                 L..
; ----------------------------------------------------------------------------
LD616:  lda     stack,y                         ; D616 B9 00 01                 ...
        cmp     #$2D                            ; D619 C9 2D                    .-
        bne     LD620                           ; D61B D0 03                    ..
        ror     stack+40                        ; D61D 6E 28 01                 n(.
LD620:  iny                                     ; D620 C8                       .
        sty     stack+41                        ; D621 8C 29 01                 .).
LD624:  lda     $80                             ; D624 A5 80                    ..
        bpl     LD62A                           ; D626 10 02                    ..
        stx     $80                             ; D628 86 80                    ..
LD62A:  jsr     L98E5                           ; D62A 20 E5 98                  ..
        lda     stack+44                        ; D62D AD 2C 01                 .,.
        cmp     #$FF                            ; D630 C9 FF                    ..
        beq     LD65D                           ; D632 F0 29                    .)
        lda     stack+47                        ; D634 AD 2F 01                 ./.
        beq     LD678                           ; D637 F0 3F                    .?
        lda     stack+41                        ; D639 AD 29 01                 .).
        bne     LD650                           ; D63C D0 12                    ..
        ldx     stack+36                        ; D63E AE 24 01                 .$.
        jsr     L9767                           ; D641 20 67 97                  g.
        dec     stack+2,x                       ; D644 DE 02 01                 ...
        inx                                     ; D647 E8                       .
        stx     stack+41                        ; D648 8E 29 01                 .).
        jsr     L97EE                           ; D64B 20 EE 97                  ..
        beq     LD675                           ; D64E F0 25                    .%
LD650:  ldy     stack+46                        ; D650 AC 2E 01                 ...
        bne     LD66C                           ; D653 D0 17                    ..
        ldy     stack+50                        ; D655 AC 32 01                 .2.
        bmi     LD66C                           ; D658 30 12                    0.
        lda     stack+44                        ; D65A AD 2C 01                 .,.
LD65D:  beq     LD6C9                           ; D65D F0 6A                    .j
        dec     stack+44                        ; D65F CE 2C 01                 .,.
        bne     LD669                           ; D662 D0 05                    ..
        lda     stack+45                        ; D664 AD 2D 01                 .-.
        beq     LD6C9                           ; D667 F0 60                    .`
LD669:  inc     stack+39                        ; D669 EE 27 01                 .'.
LD66C:  jsr     L96E1                           ; D66C 20 E1 96                  ..
        jsr     L97AC                           ; D66F 20 AC 97                  ..
        jsr     L96E1                           ; D672 20 E1 96                  ..
LD675:  jmp     L980F                           ; D675 4C 0F 98                 L..
; ----------------------------------------------------------------------------
LD678:  ldy     stack+41                        ; D678 AC 29 01                 .).
        beq     LD693                           ; D67B F0 16                    ..
        sta     $78                             ; D67D 85 78                    .x
        sec                                     ; D67F 38                       8
        ror     stack+48                        ; D680 6E 30 01                 n0.
        ldy     $80                             ; D683 A4 80                    ..
        lda     stack+40                        ; D685 AD 28 01                 .(.
        bpl     LD690                           ; D688 10 06                    ..
        jsr     L971A                           ; D68A 20 1A 97                  ..
        jmp     L969C_03A0_NOT_DOLLAR                           ; D68D 4C 9C 96                 L..
; ----------------------------------------------------------------------------
LD690:  jsr     L96FB                           ; D690 20 FB 96                  ..
LD693:  ldy     $80                             ; D693 A4 80                    ..
        beq     LD69C                           ; D695 F0 05                    ..
        jsr     L97F2                           ; D697 20 F2 97                  ..
        beq     LD6A2                           ; D69A F0 06                    ..
LD69C:  jsr     L97AC                           ; D69C 20 AC 97                  ..
        jmp     L96A5                           ; D69F 4C A5 96                 L..
; ----------------------------------------------------------------------------
LD6A2:  dec     stack+42                        ; D6A2 CE 2A 01                 .*.
        sec                                     ; D6A5 38                       8
        lda     stack+44                        ; D6A6 AD 2C 01                 .,.
        sbc     stack+42                        ; D6A9 ED 2A 01                 .*.
        bcc     LD6C9                           ; D6AC 90 1B                    ..
        sta     stack+39                        ; D6AE 8D 27 01                 .'.
        ldy     stack+46                        ; D6B1 AC 2E 01                 ...
        bne     LD6D1                           ; D6B4 D0 1B                    ..
        ldy     stack+50                        ; D6B6 AC 32 01                 .2.
        bmi     LD6D1                           ; D6B9 30 16                    0.
        tay                                     ; D6BB A8                       .
        beq     LD6C9                           ; D6BC F0 0B                    ..
        dey                                     ; D6BE 88                       .
        bne     LD6D4                           ; D6BF D0 13                    ..
        lda     stack+45                        ; D6C1 AD 2D 01                 .-.
        ora     stack+42                        ; D6C4 0D 2A 01                 .*.
        bne     LD675                           ; D6C7 D0 AC                    ..
LD6C9:  lda     #$2A                            ; D6C9 A9 2A                    .*
LD6CB:  jsr     L98DE                           ; D6CB 20 DE 98                  ..
        bne     LD6CB                           ; D6CE D0 FB                    ..
        rts                                     ; D6D0 60                       `
; ----------------------------------------------------------------------------
LD6D1:  tay                                     ; D6D1 A8                       .
        beq     LD675                           ; D6D2 F0 A1                    ..
LD6D4:  lda     stack+42                        ; D6D4 AD 2A 01                 .*.
        bne     LD675                           ; D6D7 D0 9C                    ..
        dec     stack+39                        ; D6D9 CE 27 01                 .'.
        inc     $77                             ; D6DC E6 77                    .w
        jmp     L9675                           ; D6DE 4C 75 96                 Lu.
; ----------------------------------------------------------------------------
        sec                                     ; D6E1 38                       8
        lda     stack+44                        ; D6E2 AD 2C 01                 .,.
        sbc     stack+42                        ; D6E5 ED 2A 01                 .*.
        beq     LD723                           ; D6E8 F0 39                    .9
        ldy     $80                             ; D6EA A4 80                    ..
        bcc     LD704                           ; D6EC 90 16                    ..
        sta     $78                             ; D6EE 85 78                    .x
LD6F0:  cpy     stack+36                        ; D6F0 CC 24 01                 .$.
        beq     LD6F7                           ; D6F3 F0 02                    ..
        bcs     LD6F8                           ; D6F5 B0 01                    ..
LD6F7:  iny                                     ; D6F7 C8                       .
LD6F8:  inc     stack+42                        ; D6F8 EE 2A 01                 .*.
        jsr     L9730                           ; D6FB 20 30 97                  0.
        dec     $78                             ; D6FE C6 78                    .x
        bne     LD6F0                           ; D700 D0 EE                    ..
        beq     LD721                           ; D702 F0 1D                    ..
LD704:  eor     #$FF                            ; D704 49 FF                    I.
        adc     #$01                            ; D706 69 01                    i.
        sta     $78                             ; D708 85 78                    .x
LD70A:  cpy     stack+35                        ; D70A CC 23 01                 .#.
        beq     LD716                           ; D70D F0 07                    ..
        dey                                     ; D70F 88                       .
        dec     stack+42                        ; D710 CE 2A 01                 .*.
        jmp     L9718                           ; D713 4C 18 97                 L..
; ----------------------------------------------------------------------------
LD716:  inc     $77                             ; D716 E6 77                    .w
        lda     #$80                            ; D718 A9 80                    ..
        jsr     L9732                           ; D71A 20 32 97                  2.
        dec     $78                             ; D71D C6 78                    .x
        bne     LD70A                           ; D71F D0 E9                    ..
LD721:  sty     $80                             ; D721 84 80                    ..
LD723:  rts                                     ; D723 60                       `
; ----------------------------------------------------------------------------
        bne     LD75F                           ; D724 D0 39                    .9
        eor     #$09                            ; D726 49 09                    I.
        sta     stack,x                         ; D728 9D 00 01                 ...
        dex                                     ; D72B CA                       .
        cpx     stack+41                        ; D72C EC 29 01                 .).
        rts                                     ; D72F 60                       `
; ----------------------------------------------------------------------------
        lda     #$00                            ; D730 A9 00                    ..
        ldx     stack+41                        ; D732 AE 29 01                 .).
        inx                                     ; D735 E8                       .
        bit     stack+48                        ; D736 2C 30 01                 ,0.
        bmi     LD74B                           ; D739 30 10                    0.
        eor     stack+40                        ; D73B 4D 28 01                 M(.
        beq     LD74B                           ; D73E F0 0B                    ..
LD740:  jsr     L9775                           ; D740 20 75 97                  u.
        jsr     L9724                           ; D743 20 24 97                  $.
        bcs     LD740                           ; D746 B0 F8                    ..
        jmp     L8959                           ; D748 4C 59 89                 LY.
; ----------------------------------------------------------------------------
LD74B:  lda     stack,x                         ; D74B BD 00 01                 ...
        dec     stack,x                         ; D74E DE 00 01                 ...
        cmp     #$30                            ; D751 C9 30                    .0
        jsr     L9724                           ; D753 20 24 97                  $.
        bcs     LD74B                           ; D756 B0 F3                    ..
        bit     stack+48                        ; D758 2C 30 01                 ,0.
        bpl     LD762                           ; D75B 10 05                    ..
        sty     $80                             ; D75D 84 80                    ..
LD75F:  pla                                     ; D75F 68                       h
        pla                                     ; D760 68                       h
        rts                                     ; D761 60                       `
; ----------------------------------------------------------------------------
LD762:  lda     stack+40                        ; D762 AD 28 01                 .(.
        eor     #$80                            ; D765 49 80                    I.
        sta     stack+40                        ; D767 8D 28 01                 .(.
        lda     #$30                            ; D76A A9 30                    .0
        sta     stack+1,x                       ; D76C 9D 01 01                 ...
        lda     #$31                            ; D76F A9 31                    .1
        sta     stack+2,x                       ; D771 9D 02 01                 ...
        rts                                     ; D774 60                       `
; ----------------------------------------------------------------------------
        lda     stack,x                         ; D775 BD 00 01                 ...
        inc     stack,x                         ; D778 FE 00 01                 ...
        cmp     #$39                            ; D77B C9 39                    .9
        rts                                     ; D77D 60                       `
; ----------------------------------------------------------------------------
        clc                                     ; D77E 18                       .
        iny                                     ; D77F C8                       .
        beq     LD787                           ; D780 F0 05                    ..
        cpy     stack+53                        ; D782 CC 35 01                 .5.
        bcc     LD78B                           ; D785 90 04                    ..
LD787:  ldy     $77                             ; D787 A4 77                    .w
        bne     LD75F                           ; D789 D0 D4                    ..
LD78B:  jsr     L42D0                           ; D78B 20 D0 42                  .B
        inc     stack+49                        ; D78E EE 31 01                 .1.
        rts                                     ; D791 60                       `
; ----------------------------------------------------------------------------
        jsr     $877D                           ; D792 20 7D 87                  }.
        sta     $78                             ; D795 85 78                    .x
        ldx     #$0A                            ; D797 A2 0A                    ..
        lda     #$00                            ; D799 A9 00                    ..
LD79B:  sta     stack+39,x                      ; D79B 9D 27 01                 .'.
        dex                                     ; D79E CA                       .
        bpl     LD79B                           ; D79F 10 FA                    ..
        stx     stack+38                        ; D7A1 8E 26 01                 .&.
        stx     $80                             ; D7A4 86 80                    ..
        stx     stack+37                        ; D7A6 8E 25 01                 .%.
        tax                                     ; D7A9 AA                       .
        tay                                     ; D7AA A8                       .
        rts                                     ; D7AB 60                       `
; ----------------------------------------------------------------------------
        clc                                     ; D7AC 18                       .
        lda     $80                             ; D7AD A5 80                    ..
        adc     stack+45                        ; D7AF 6D 2D 01                 m-.
        bcs     LD7ED                           ; D7B2 B0 39                    .9
        sec                                     ; D7B4 38                       8
        sbc     $77                             ; D7B5 E5 77                    .w
        bcc     LD7ED                           ; D7B7 90 34                    .4
        cmp     stack+36                        ; D7B9 CD 24 01                 .$.
        beq     LD7C0                           ; D7BC F0 02                    ..
        bcs     LD7ED                           ; D7BE B0 2D                    .-
LD7C0:  cmp     stack+35                        ; D7C0 CD 23 01                 .#.
        bcc     LD7ED                           ; D7C3 90 28                    .(
        tax                                     ; D7C5 AA                       .
        lda     stack,x                         ; D7C6 BD 00 01                 ...
        cmp     #$35                            ; D7C9 C9 35                    .5
        bcc     LD7ED                           ; D7CB 90 20                    .
LD7CD:  cpx     stack+35                        ; D7CD EC 23 01                 .#.
        beq     LD7DC                           ; D7D0 F0 0A                    ..
        dex                                     ; D7D2 CA                       .
        jsr     L9775                           ; D7D3 20 75 97                  u.
        stx     stack+36                        ; D7D6 8E 24 01                 .$.
        beq     LD7CD                           ; D7D9 F0 F2                    ..
        rts                                     ; D7DB 60                       `
; ----------------------------------------------------------------------------
LD7DC:  lda     #$31                            ; D7DC A9 31                    .1
        sta     stack,x                         ; D7DE 9D 00 01                 ...
        inx                                     ; D7E1 E8                       .
        stx     $80                             ; D7E2 86 80                    ..
        dec     $77                             ; D7E4 C6 77                    .w
        bpl     LD7ED                           ; D7E6 10 05                    ..
        inc     $77                             ; D7E8 E6 77                    .w
        inc     stack+42                        ; D7EA EE 2A 01                 .*.
LD7ED:  rts                                     ; D7ED 60                       `
; ----------------------------------------------------------------------------
        ldy     $80                             ; D7EE A4 80                    ..
        beq     LD809                           ; D7F0 F0 17                    ..
        ldy     stack+35                        ; D7F2 AC 23 01                 .#.
        lda     stack,y                         ; D7F5 B9 00 01                 ...
        cmp     #$30                            ; D7F8 C9 30                    .0
        rts                                     ; D7FA 60                       `
; ----------------------------------------------------------------------------
LD7FB:  inc     $80                             ; D7FB E6 80                    ..
        jsr     L9730                           ; D7FD 20 30 97                  0.
        inc     stack+35                        ; D800 EE 23 01                 .#.
        cpy     stack+36                        ; D803 CC 24 01                 .$.
        beq     LD7ED                           ; D806 F0 E5                    ..
        iny                                     ; D808 C8                       .
LD809:  jsr     L97F5                           ; D809 20 F5 97                  ..
        beq     LD7FB                           ; D80C F0 ED                    ..
        rts                                     ; D80E 60                       `
; ----------------------------------------------------------------------------
        lda     stack+37                        ; D80F AD 25 01                 .%.
        bmi     LD816                           ; D812 30 02                    0.
        inc     $77                             ; D814 E6 77                    .w
LD816:  ldx     stack+35                        ; D816 AE 23 01                 .#.
        dex                                     ; D819 CA                       .
        ldy     stack+52                        ; D81A AC 34 01                 .4.
        jsr     L42D0                           ; D81D 20 D0 42                  .B
        iny                                     ; D820 C8                       .
        cmp     #$2C                            ; D821 C9 2C                    .,
        bne     LD839                           ; D823 D0 14                    ..
        bit     stack+38                        ; D825 2C 26 01                 ,&.
        bmi     LD833                           ; D828 30 09                    0.
        sta     $FF03                           ; D82A 8D 03 FF                 ...
        lda     $1205                           ; D82D AD 05 12                 ...
        jmp     L989E                           ; D830 4C 9E 98                 L..
; ----------------------------------------------------------------------------
LD833:  lda     stack+51                        ; D833 AD 33 01                 .3.
        jmp     L989E                           ; D836 4C 9E 98                 L..
; ----------------------------------------------------------------------------
LD839:  cmp     #$2E                            ; D839 C9 2E                    ..
        bne     LD846                           ; D83B D0 09                    ..
        sta     $FF03                           ; D83D 8D 03 FF                 ...
        lda     $1206                           ; D840 AD 06 12                 ...
        jmp     L989E                           ; D843 4C 9E 98                 L..
; ----------------------------------------------------------------------------
LD846:  cmp     #$2B                            ; D846 C9 2B                    .+
        beq     LD885                           ; D848 F0 3B                    .;
        cmp     #$2D                            ; D84A C9 2D                    .-
        beq     LD880                           ; D84C F0 32                    .2
        cmp     #$5E                            ; D84E C9 5E                    .^
        bne     LD8BB                           ; D850 D0 69                    .i
        lda     #$45                            ; D852 A9 45                    .E
        jsr     L98DE                           ; D854 20 DE 98                  ..
        ldy     stack+41                        ; D857 AC 29 01                 .).
        jsr     L97F5                           ; D85A 20 F5 97                  ..
        bne     LD865                           ; D85D D0 06                    ..
        iny                                     ; D85F C8                       .
        jsr     L97F5                           ; D860 20 F5 97                  ..
        beq     LD86C                           ; D863 F0 07                    ..
LD865:  lda     #$2D                            ; D865 A9 2D                    .-
        bit     stack+40                        ; D867 2C 28 01                 ,(.
        bmi     LD86E                           ; D86A 30 02                    0.
LD86C:  lda     #$2B                            ; D86C A9 2B                    .+
LD86E:  jsr     L98DE                           ; D86E 20 DE 98                  ..
        ldx     stack+41                        ; D871 AE 29 01                 .).
        lda     stack,x                         ; D874 BD 00 01                 ...
        jsr     L98DE                           ; D877 20 DE 98                  ..
        ldy     stack+54                        ; D87A AC 36 01                 .6.
        jmp     L9894                           ; D87D 4C 94 98                 L..
; ----------------------------------------------------------------------------
LD880:  lda     stack+50                        ; D880 AD 32 01                 .2.
        bmi     LD833                           ; D883 30 AE                    0.
LD885:  lda     stack+50                        ; D885 AD 32 01                 .2.
        jmp     L989E                           ; D888 4C 9E 98                 L..
; ----------------------------------------------------------------------------
LD88B:  lda     $77                             ; D88B A5 77                    .w
        bne     LD8A7                           ; D88D D0 18                    ..
        cpx     stack+36                        ; D88F EC 24 01                 .$.
        beq     LD899                           ; D892 F0 05                    ..
        inx                                     ; D894 E8                       .
        lda     stack,x                         ; D895 BD 00 01                 ...
        .byte   $2C                             ; D898 2C                       ,
LD899:  lda     #$30                            ; D899 A9 30                    .0
        lsr     stack+38                        ; D89B 4E 26 01                 N&.
        jsr     L98DE                           ; D89E 20 DE 98                  ..
        beq     LD8A6                           ; D8A1 F0 03                    ..
        jmp     L981D                           ; D8A3 4C 1D 98                 L..
; ----------------------------------------------------------------------------
LD8A6:  rts                                     ; D8A6 60                       `
; ----------------------------------------------------------------------------
LD8A7:  dec     $77                             ; D8A7 C6 77                    .w
        lda     stack+37                        ; D8A9 AD 25 01                 .%.
        bmi     LD899                           ; D8AC 30 EB                    0.
        sec                                     ; D8AE 38                       8
        ror     stack+37                        ; D8AF 6E 25 01                 n%.
        sta     $FF03                           ; D8B2 8D 03 FF                 ...
        lda     $1207                           ; D8B5 AD 07 12                 ...
        jmp     L989B                           ; D8B8 4C 9B 98                 L..
; ----------------------------------------------------------------------------
LD8BB:  lda     stack+39                        ; D8BB AD 27 01                 .'.
        beq     LD88B                           ; D8BE F0 CB                    ..
        dec     stack+39                        ; D8C0 CE 27 01                 .'.
LD8C3:  beq     LD8C8                           ; D8C3 F0 03                    ..
        jmp     L9833                           ; D8C5 4C 33 98                 L3.
; ----------------------------------------------------------------------------
LD8C8:  lda     stack+46                        ; D8C8 AD 2E 01                 ...
        bmi     LD8C3                           ; D8CB 30 F6                    0.
        jsr     L42D0                           ; D8CD 20 D0 42                  .B
        cmp     #$2C                            ; D8D0 C9 2C                    .,
        bne     LD880                           ; D8D2 D0 AC                    ..
        lda     stack+51                        ; D8D4 AD 33 01                 .3.
        jsr     L98DE                           ; D8D7 20 DE 98                  ..
        iny                                     ; D8DA C8                       .
        jmp     L98CD                           ; D8DB 4C CD 98                 L..
; ----------------------------------------------------------------------------
        jsr     L5609                           ; D8DE 20 09 56                  .V
        dec     stack+49                        ; D8E1 CE 31 01                 .1.
        rts                                     ; D8E4 60                       `
; ----------------------------------------------------------------------------
        ldy     stack+54                        ; D8E5 AC 36 01                 .6.
        jsr     L977E                           ; D8E8 20 7E 97                  ~.
        jsr     L999A                           ; D8EB 20 9A 99                  ..
        bne     LD904                           ; D8EE D0 14                    ..
        sty     stack+52                        ; D8F0 8C 34 01                 .4.
        bcc     LD90F                           ; D8F3 90 1A                    ..
        tax                                     ; D8F5 AA                       .
LD8F6:  jsr     L977E                           ; D8F6 20 7E 97                  ~.
        bcs     LD900                           ; D8F9 B0 05                    ..
        jsr     L99A2                           ; D8FB 20 A2 99                  ..
        beq     LD90A                           ; D8FE F0 0A                    ..
LD900:  ldy     stack+52                        ; D900 AC 34 01                 .4.
        txa                                     ; D903 8A                       .
LD904:  jsr     L5609                           ; D904 20 09 56                  .V
        jmp     L98E8                           ; D907 4C E8 98                 L..
; ----------------------------------------------------------------------------
LD90A:  bcs     LD8F6                           ; D90A B0 EA                    ..
        ldy     stack+52                        ; D90C AC 34 01                 .4.
LD90F:  ldx     $77                             ; D90F A6 77                    .w
        bne     LD98D                           ; D911 D0 7A                    .z
        stx     stack+49                        ; D913 8E 31 01                 .1.
        dey                                     ; D916 88                       .
LD917:  dec     stack+49                        ; D917 CE 31 01                 .1.
LD91A:  jsr     L977E                           ; D91A 20 7E 97                  ~.
        bcs     LD993                           ; D91D B0 74                    .t
        cmp     #$2C                            ; D91F C9 2C                    .,
        beq     LD91A                           ; D921 F0 F7                    ..
        jsr     V1541_ERROR_WORDS                           ; D923 20 71 99                  q.
        bcc     LD917                           ; D926 90 EF                    ..
        cmp     #$2E                            ; D928 C9 2E                    ..
        bne     LD934                           ; D92A D0 08                    ..
        inx                                     ; D92C E8                       .
        cpx     #$02                            ; D92D E0 02                    ..
        bcc     LD91A                           ; D92F 90 E9                    ..
LD931:  jmp     L795A                           ; D931 4C 5A 79                 LZy
; ----------------------------------------------------------------------------
LD934:  jsr     L99A6                           ; D934 20 A6 99                  ..
        bne     LD944                           ; D937 D0 0B                    ..
        bcc     LD93E                           ; D939 90 03                    ..
        sta     stack+43                        ; D93B 8D 2B 01                 .+.
LD93E:  inc     stack+44,x                      ; D93E FE 2C 01                 .,.
        jmp     L991A                           ; D941 4C 1A 99                 L..
; ----------------------------------------------------------------------------
LD944:  cmp     #'$'                            ; D944 C9 24                    .$
        bne     LD957                           ; D946 D0 0F                    ..
        bit     stack+37                        ; D948 2C 25 01                 ,%.
        bpl     LD93E                           ; D94B 10 F1                    ..
        clc                                     ; D94D 18                       .
        ror     stack+37                        ; D94E 6E 25 01                 n%.
        dec     stack+44                        ; D951 CE 2C 01                 .,.
        jmp     L993E                           ; D954 4C 3E 99                 L>.
; ----------------------------------------------------------------------------
LD957:  cmp     #$5E                            ; D957 C9 5E                    .^
        bne     LD971                           ; D959 D0 16                    ..
        ldx     #$02                            ; D95B A2 02                    ..
LD95D:  jsr     L977E                           ; D95D 20 7E 97                  ~.
        bcs     LD931                           ; D960 B0 CF                    ..
        cmp     #$5E                            ; D962 C9 5E                    .^
        bne     LD931                           ; D964 D0 CB                    ..
        dex                                     ; D966 CA                       .
        bpl     LD95D                           ; D967 10 F4                    ..
        inc     stack+47                        ; D969 EE 2F 01                 ./.
        jsr     L977E                           ; D96C 20 7E 97                  ~.
        bcs     LD993                           ; D96F B0 22                    ."
LD971:  cmp     #$2B                            ; D971 C9 2B                    .+
        bne     LD98E                           ; D973 D0 19                    ..
        lda     stack+50                        ; D975 AD 32 01                 .2.
        bpl     LD97F                           ; D978 10 05                    ..
        lda     #$2B                            ; D97A A9 2B                    .+
        sta     stack+50                        ; D97C 8D 32 01                 .2.
LD97F:  lda     stack+46                        ; D97F AD 2E 01                 ...
        bne     LD931                           ; D982 D0 AD                    ..
        ror     stack+46                        ; D984 6E 2E 01                 n..
        sty     stack+54                        ; D987 8C 36 01                 .6.
        inc     stack+49                        ; D98A EE 31 01                 .1.
LD98D:  rts                                     ; D98D 60                       `
; ----------------------------------------------------------------------------
LD98E:  cmp     #'-'                            ; D98E C9 2D                    .-
        beq     LD97F                           ; D990 F0 ED                    ..
        sec                                     ; D992 38                       8
LD993:  sty     stack+54                        ; D993 8C 36 01                 .6.
        dec     stack+54                        ; D996 CE 36 01                 .6.
        rts                                     ; D999 60                       `
; ----------------------------------------------------------------------------
        cmp     #'+'                            ; D99A C9 2B                    .+
        beq     LD9B3                           ; D99C F0 15                    ..
        cmp     #'-'                            ; D99E C9 2D                    .-
        beq     LD9B3                           ; D9A0 F0 11                    ..
        cmp     #'.'                            ; D9A2 C9 2E                    ..
        beq     LD9B3                           ; D9A4 F0 0D                    ..
        cmp     #'='                            ; D9A6 C9 3D                    .=
        beq     LD9B3                           ; D9A8 F0 09                    ..
        cmp     #'>'                            ; D9AA C9 3E                    .>
        beq     LD9B3                           ; D9AC F0 05                    ..
        cmp     #'#'                            ; D9AE C9 23                    .#
        bne     LD9B3                           ; D9B0 D0 01                    ..
        clc                                     ; D9B2 18                       .
LD9B3:  rts                                     ; D9B3 60                       `
; ----------------------------------------------------------------------------
        lda     $66                             ; D9B4 A5 66                    .f
        sta     $03D6                           ; D9B6 8D D6 03                 ...
        lda     $67                             ; D9B9 A5 67                    .g
        sta     $03D7                           ; D9BB 8D D7 03                 ...
        jsr     L77DD                           ; D9BE 20 DD 77                  .w
        jsr     L77CB                           ; D9C1 20 CB 77                  .w
        lda     $66                             ; D9C4 A5 66                    .f
        sta     $03D8                           ; D9C6 8D D8 03                 ...
        lda     $67                             ; D9C9 A5 67                    .g
        sta     $03D9                           ; D9CB 8D D9 03                 ...
        ldx     #$01                            ; D9CE A2 01                    ..
        stx     $67                             ; D9D0 86 67                    .g
        jsr     DFLTO                           ; D9D2 20 86 03                  ..
        cmp     #')'                            ; D9D5 C9 29                    .)
        beq     LD9DC                           ; D9D7 F0 03                    ..
        jsr     L8805                           ; D9D9 20 05 88                  ..
LD9DC:  jsr     L7944                           ; D9DC 20 44 79                  Dy
        ldx     $67                             ; D9DF A6 67                    .g
        bne     LD9E6                           ; D9E1 D0 03                    ..
        jmp     L7D16                           ; D9E3 4C 16 7D                 L.}
; ----------------------------------------------------------------------------
LD9E6:  dex                                     ; D9E6 CA                       .
        stx     $63                             ; D9E7 86 63                    .c
        ldx     #$03                            ; D9E9 A2 03                    ..
LD9EB:  lda     $03D6,x                         ; D9EB BD D6 03                 ...
        sta     $59,x                           ; D9EE 95 59                    .Y
        dex                                     ; D9F0 CA                       .
        bpl     LD9EB                           ; D9F1 10 F8                    ..
        ldy     #$02                            ; D9F3 A0 02                    ..
LD9F5:  lda     #$59                            ; D9F5 A9 59                    .Y
        jsr     L03AB                           ; D9F7 20 AB 03                  ..
        sta     $5D,y                           ; D9FA 99 5D 00                 .].
        lda     #$5B                            ; D9FD A9 5B                    .[
        jsr     L03AB                           ; D9FF 20 AB 03                  ..
        sta     $60,y                           ; DA02 99 60 00                 .`.
        dey                                     ; DA05 88                       .
        bpl     LD9F5                           ; DA06 10 ED                    ..
        lda     $60                             ; DA08 A5 60                    .`
        beq     LDA47                           ; DA0A F0 3B                    .;
LDA0C:  lda     #$00                            ; DA0C A9 00                    ..
        sta     $64                             ; DA0E 85 64                    .d
        clc                                     ; DA10 18                       .
        lda     $60                             ; DA11 A5 60                    .`
        adc     $63                             ; DA13 65 63                    ec
        bcs     LDA47                           ; DA15 B0 30                    .0
        cmp     $5D                             ; DA17 C5 5D                    .]
        bcc     LDA1D                           ; DA19 90 02                    ..
        bne     LDA47                           ; DA1B D0 2A                    .*
LDA1D:  ldy     $64                             ; DA1D A4 64                    .d
        cpy     $60                             ; DA1F C4 60                    .`
        beq     LDA42                           ; DA21 F0 1F                    ..
        tya                                     ; DA23 98                       .
        clc                                     ; DA24 18                       .
        adc     $63                             ; DA25 65 63                    ec
        tay                                     ; DA27 A8                       .
        lda     #$5E                            ; DA28 A9 5E                    .^
        jsr     L03AB                           ; DA2A 20 AB 03                  ..
        sta     $79                             ; DA2D 85 79                    .y
        ldy     $64                             ; DA2F A4 64                    .d
        lda     #$61                            ; DA31 A9 61                    .a
        jsr     L03AB                           ; DA33 20 AB 03                  ..
        cmp     $79                             ; DA36 C5 79                    .y
        beq     LDA3E                           ; DA38 F0 04                    ..
        inc     $63                             ; DA3A E6 63                    .c
        bne     LDA0C                           ; DA3C D0 CE                    ..
LDA3E:  inc     $64                             ; DA3E E6 64                    .d
        bne     LDA1D                           ; DA40 D0 DB                    ..
LDA42:  inc     $63                             ; DA42 E6 63                    .c
        lda     $63                             ; DA44 A5 63                    .c
        .byte   $2C                             ; DA46 2C                       ,
LDA47:  lda     #$00                            ; DA47 A9 00                    ..
        sta     $FF03                           ; DA49 8D 03 FF                 ...
        pha                                     ; DA4C 48                       H
        lda     $03D8                           ; DA4D AD D8 03                 ...
        ldy     $03D9                           ; DA50 AC D9 03                 ...
        jsr     $8781                           ; DA53 20 81 87                  ..
        sta     $FF03                           ; DA56 8D 03 FF                 ...
        lda     $03D6                           ; DA59 AD D6 03                 ...
        ldy     $03D7                           ; DA5C AC D7 03                 ...
        jsr     $8781                           ; DA5F 20 81 87                  ..
        pla                                     ; DA62 68                       h
        tay                                     ; DA63 A8                       .
        jmp     L84D0                           ; DA64 4C D0 84                 L..
; ----------------------------------------------------------------------------
        jsr     L9D82                           ; DA67 20 82 9D                  ..
        ldx     #$00                            ; DA6A A2 00                    ..
LDA6C:  inx                                     ; DA6C E8                       .
        sec                                     ; DA6D 38                       8
        sbc     #$5A                            ; DA6E E9 5A                    .Z
        bcs     LDA6C                           ; DA70 B0 FA                    ..
        dey                                     ; DA72 88                       .
        bpl     LDA6C                           ; DA73 10 F7                    ..
        stx     $1149                           ; DA75 8E 49 11                 .I.
        pha                                     ; DA78 48                       H
        adc     #$5A                            ; DA79 69 5A                    iZ
        jsr     L9A87                           ; DA7B 20 87 9A                  ..
        pla                                     ; DA7E 68                       h
        clc                                     ; DA7F 18                       .
        eor     #$FF                            ; DA80 49 FF                    I.
        adc     #$01                            ; DA82 69 01                    i.
        dec     $1149                           ; DA84 CE 49 11                 .I.
        ldx     #$FF                            ; DA87 A2 FF                    ..
LDA89:  inx                                     ; DA89 E8                       .
        sec                                     ; DA8A 38                       8
        sbc     #$0A                            ; DA8B E9 0A                    ..
        bcs     LDA89                           ; DA8D B0 FA                    ..
        adc     #$0A                            ; DA8F 69 0A                    i.
        sta     $8E                             ; DA91 85 8E                    ..
        txa                                     ; DA93 8A                       .
        asl     a                               ; DA94 0A                       .
        tax                                     ; DA95 AA                       .
        lda     L9F1C+1,x                       ; DA96 BD 1D 9F                 ...
        ldy     L9F1C,x                         ; DA99 BC 1C 9F                 ...
LDA9C:  clc                                     ; DA9C 18                       .
        dec     $8E                             ; DA9D C6 8E                    ..
        bmi     LDAAD                           ; DA9F 30 0C                    0.
        adc     L9F31,x                         ; DAA1 7D 31 9F                 }1.
        pha                                     ; DAA4 48                       H
        tya                                     ; DAA5 98                       .
        adc     L9F30,x ; Conv Words Hi                        ; DAA6 7D 30 9F                 }0.
        tay                                     ; DAA9 A8                       .
        pla                                     ; DAAA 68                       h
        bcc     LDA9C                           ; DAAB 90 EF                    ..
LDAAD:  pha                                     ; DAAD 48                       H
        ldx     #$00                            ; DAAE A2 00                    ..
        lda     $1149                           ; DAB0 AD 49 11                 .I.
        lsr     a      ; Conv Words Lo                         ; DAB3 4A                       J
        bcs     LDAB8                           ; DAB4 B0 02                    ..
        ldx     #$02                            ; DAB6 A2 02                    ..
LDAB8:  pla                                     ; DAB8 68                       h
        sta     $114A,x                         ; DAB9 9D 4A 11                 .J.
        tya                                     ; DABC 98                       .
        sta     $114B,x                         ; DABD 9D 4B 11                 .K.
        rts                                     ; DAC0 60                       `
; ----------------------------------------------------------------------------
; ?
        ldy     #$19                            ; DAC1 A0 19                    ..
        bcc     LDAC7                           ; DAC3 90 02                    ..
        ldy     #$1B                            ; DAC5 A0 1B                    ..
LDAC7:  lda     $1149                           ; DAC7 AD 49 11                 .I.
        adc     #$02                            ; DACA 69 02                    i.
        lsr     a                               ; DACC 4A                       J
        lsr     a                               ; DACD 4A                       J
        php                                     ; DACE 08                       .
        jsr     L9D82                           ; DACF 20 82 9D                  ..
        cpy     #$FF                            ; DAD2 C0 FF                    ..
        bcc     LDADD                           ; DAD4 90 07                    ..
        txa                                     ; DAD6 8A                       .
        tay                                     ; DAD7 A8                       .
        jsr     L9D82   ; Read Current X Position to A/Y                        ; DAD8 20 82 9D                  ..
        bcs     LDAE0                           ; DADB B0 03                    ..
LDADD:  jsr     L9DA1   ; Read Current X Position to A/Y                        ; DADD 20 A1 9D                  ..
LDAE0:  plp                                     ; DAE0 28                       (
        bcs     LDAFE                           ; DAE1 B0 1B                    ..
        jmp     L9D91                           ; DAE3 4C 91 9D                 L..
; ----------------------------------------------------------------------------

; ?
        sta     $114E                           ; DAE6 8D 4E 11                 .N.
        ldx     #$23                            ; DAE9 A2 23                    .#
LDAEB:  asl     $114E                           ; DAEB 0E 4E 11                 .N.
        jsr     L9AC1                           ; DAEE 20 C1 9A                  ..
        sta     $1131,x                         ; DAF1 9D 31 11                 .1.
        tya                                     ; DAF4 98                       .
        sta     $1132,x                         ; DAF5 9D 32 11                 .2.
        inx                                     ; DAF8 E8                       .
        inx                                     ; DAF9 E8                       .
        cpx     #$2B                            ; DAFA E0 2B                    .+
        bcc     LDAEB                           ; DAFC 90 ED                    ..
LDAFE:  rts                                     ; DAFE 60                       `
; ----------------------------------------------------------------------------

; Evaluate <rdot>
        jsr     L87F3                           ; DAFF 20 F3 87                  ..
        cpx     #$02                            ; DB02 E0 02                    ..
        bcc     LDB16                           ; DB04 90 10                    ..
        beq     LDB0B                           ; DB06 F0 03                    ..
        jmp     L7D16     ; Print 'illegal quantity'                    ; DB08 4C 16 7D                 L.}
; ----------------------------------------------------------------------------
LDB0B:  jsr     L9C3C     ; Examine Pixel                      ; DB0B 20 3C 9C                  <.
        tay                                     ; DB0E A8                       .
        bcc     LDB13                           ; DB0F 90 02                    ..
        ldy     #$00                            ; DB11 A0 00                    ..
LDB13:  jmp     L84D0     ; Byte To Float                      ; DB13 4C D0 84                 L..
; ----------------------------------------------------------------------------
LDB16:  txa                                     ; DB16 8A                       .
        asl     a                               ; DB17 0A                       .
        tax                                     ; DB18 AA                       .
        lda     $1131,x                         ; DB19 BD 31 11                 .1.
        tay                                     ; DB1C A8                       .
        lda     $1132,x                         ; DB1D BD 32 11                 .2.
LDB20:  jmp     L792A     ; Fixed-Float                      ; DB20 4C 2A 79                 L*y
; ----------------------------------------------------------------------------

; Draw Line
        ldx     #$02                            ; DB23 A2 02                    ..
        ldy     #$06                            ; DB25 A0 06                    ..
LDB27:  lda     #$00                            ; DB27 A9 00                    ..
        sta     $113D,x                         ; DB29 9D 3D 11                 .=.
        sta     $113E,x                         ; DB2C 9D 3E 11                 .>.
        jsr     L9D8C                           ; DB2F 20 8C 9D                  ..
        bpl     LDB3C                           ; DB32 10 08                    ..
        dec     $113D,x                         ; DB34 DE 3D 11                 .=.
        dec     $113E,x                         ; DB37 DE 3E 11                 .>.
        bne     LDB47                           ; DB3A D0 0B                    ..
LDB3C:  cmp     #$00                            ; DB3C C9 00                    ..
        bne     LDB44                           ; DB3E D0 04                    ..
        cpy     #$00                            ; DB40 C0 00                    ..
        beq     LDB47                           ; DB42 F0 03                    ..
LDB44:  inc     $113D,x                         ; DB44 FE 3D 11                 .=.
LDB47:  sta     $1139,x                         ; DB47 9D 39 11                 .9.
        asl     a                               ; DB4A 0A                       .
        sta     $1141,x                         ; DB4B 9D 41 11                 .A.
        tya                                     ; DB4E 98                       .
        sta     $113A,x                         ; DB4F 9D 3A 11                 .:.
        rol     a                               ; DB52 2A                       *
        sta     $1142,x                         ; DB53 9D 42 11                 .B.
        dex                                     ; DB56 CA                       .
        dex                                     ; DB57 CA                       .
        ldy     #$04                            ; DB58 A0 04                    ..
        cpx     #$00                            ; DB5A E0 00                    ..
        beq     LDB27                           ; DB5C F0 C9                    ..
        ldx     #$0A                            ; DB5E A2 0A                    ..
        ldy     #$08                            ; DB60 A0 08                    ..
        jsr     L9D6F                           ; DB62 20 6F 9D                  o.
        lda     #$00                            ; DB65 A9 00                    ..
        rol     a                               ; DB67 2A                       *
        rol     a                               ; DB68 2A                       *
        sta     $1147                           ; DB69 8D 47 11                 .G.
        eor     #$02                            ; DB6C 49 02                    I.
        sta     $1148                           ; DB6E 8D 48 11                 .H.
        clc                                     ; DB71 18                       .
        lda     #$10                            ; DB72 A9 10                    ..
        adc     $1147                           ; DB74 6D 47 11                 mG.
        tay                                     ; DB77 A8                       .
        pha                                     ; DB78 48                       H
        eor     #$02                            ; DB79 49 02                    I.
        tax                                     ; DB7B AA                       .
        jsr     L9D6F                           ; DB7C 20 6F 9D                  o.
        sta     $1131,x                         ; DB7F 9D 31 11                 .1.
        tya                                     ; DB82 98                       .
        sta     $1132,x                         ; DB83 9D 32 11                 .2.
        pla                                     ; DB86 68                       h
        tay                                     ; DB87 A8                       .
        clc                                     ; DB88 18                       .
        lda     #$08                            ; DB89 A9 08                    ..
        adc     $1148                           ; DB8B 6D 48 11                 mH.
        tax                                     ; DB8E AA                       .
        jsr     L9D6F                           ; DB8F 20 6F 9D                  o.
        sta     $1145                           ; DB92 8D 45 11                 .E.
        sty     $1146                           ; DB95 8C 46 11                 .F.
LDB98:  jsr     L9BEE                           ; DB98 20 EE 9B                  ..
        ldy     $1148                           ; DB9B AC 48 11                 .H.
        sec                                     ; DB9E 38                       8
        lda     $1139,y                         ; DB9F B9 39 11                 .9.
        sbc     #$01                            ; DBA2 E9 01                    ..
        sta     $1139,y                         ; DBA4 99 39 11                 .9.
        bcs     LDBB4                           ; DBA7 B0 0B                    ..
        lda     $113A,y                         ; DBA9 B9 3A 11                 .:.
        sbc     #$00                            ; DBAC E9 00                    ..
        sta     $113A,y                         ; DBAE 99 3A 11                 .:.
        .byte   $B0                             ; DBB1 B0                       .
LDBB2:  ora     ($60,x)                         ; DBB2 01 60                    .`
LDBB4:  ldx     $1147                           ; DBB4 AE 47 11                 .G.
        lda     $1146                           ; DBB7 AD 46 11                 .F.
        bmi     LDBC2                           ; DBBA 30 06                    0.
        jsr     L9BDD                           ; DBBC 20 DD 9B                  ..
        ldx     $1148                           ; DBBF AE 48 11                 .H.
LDBC2:  clc                                     ; DBC2 18                       .
        lda     $1145                           ; DBC3 AD 45 11                 .E.
        adc     $1141,x                         ; DBC6 7D 41 11                 }A.
        sta     $1145                           ; DBC9 8D 45 11                 .E.
        lda     $1146                           ; DBCC AD 46 11                 .F.
        adc     $1142,x                         ; DBCF 7D 42 11                 }B.
        sta     $1146                           ; DBD2 8D 46 11                 .F.
        ldx     $1148                           ; DBD5 AE 48 11                 .H.
        jsr     L9BDD                           ; DBD8 20 DD 9B                  ..
        beq     LDB98                           ; DBDB F0 BB                    ..
        ldy     #$02                            ; DBDD A0 02                    ..
        clc                                     ; DBDF 18                       .
LDBE0:  lda     $1131,x                         ; DBE0 BD 31 11                 .1.
        adc     $113D,x                         ; DBE3 7D 3D 11                 }=.
        sta     $1131,x                         ; DBE6 9D 31 11                 .1.
        inx                                     ; DBE9 E8                       .
        dey                                     ; DBEA 88                       .
        bne     LDBE0                           ; DBEB D0 F3                    ..
        rts                                     ; DBED 60                       `
; ----------------------------------------------------------------------------

; Plot Pixel
        lda     $116C    ; Box Fill Flag                       ; DBEE AD 6C 11                 .l.
        ora     $116B    ; Double Width Flag                       ; DBF1 0D 6B 11                 .k.
        beq     LDC0C                           ; DBF4 F0 16                    ..
        inc     $1131                           ; DBF6 EE 31 11                 .1.
        bne     LDBFE                           ; DBF9 D0 03                    ..
        inc     $1132                           ; DBFB EE 32 11                 .2.
LDBFE:  jsr     L9C0C                           ; DBFE 20 0C 9C                  ..
        ldx     $1131                           ; DC01 AE 31 11                 .1.
        bne     LDC09                           ; DC04 D0 03                    ..
        dec     $1132                           ; DC06 CE 32 11                 .2.
LDC09:  dec     $1131                           ; DC09 CE 31 11                 .1.

; Examine Pixel
LDC0C:  jsr     L9D17   ;Position Pixel                         ; DC0C 20 17 9D                  ..
        bcs     LDC35                           ; DC0F B0 24                    .$
        jsr     L9C63                           ; DC11 20 63 9C                  c.
        jsr     L9CDB                           ; DC14 20 DB 9C                  ..
        sta     $116D                           ; DC17 8D 6D 11                 .m.
        lda     ($8C),y                         ; DC1A B1 8C                    ..
        ora     $116D                           ; DC1C 0D 6D 11                 .m.
        bit     $D8                             ; DC1F 24 D8                    $.
        bpl     LDC36                           ; DC21 10 13                    ..
        pha                                     ; DC23 48                       H
        ldx     $83                             ; DC24 A6 83                    ..
        lda     $116D                           ; DC26 AD 6D 11                 .m.
        and     L9F18,x                         ; DC29 3D 18 9F                 =..
        sta     $116D                           ; DC2C 8D 6D 11                 .m.
        pla                                     ; DC2F 68                       h
LDC30:  eor     $116D                           ; DC30 4D 6D 11                 Mm.
LDC33:  sta     ($8C),y                         ; DC33 91 8C                    ..
LDC35:  rts                                     ; DC35 60                       `
; ----------------------------------------------------------------------------
LDC36:  ldx     $83                             ; DC36 A6 83                    ..
        bne     LDC33                           ; DC38 D0 F9                    ..
        beq     LDC30                           ; DC3A F0 F4                    ..
        jsr     L9CD6                           ; DC3C 20 D6 9C                  ..
        bcs     LDC62                           ; DC3F B0 21                    .!
        sta     $116D                           ; DC41 8D 6D 11                 .m.
        lda     ($8C),y                         ; DC44 B1 8C                    ..
        and     $116D                           ; DC46 2D 6D 11                 -m.
LDC49:  rol     a                               ; DC49 2A                       *
        dex                                     ; DC4A CA                       .
        bpl     LDC49                           ; DC4B 10 FC                    ..
        rol     a                               ; DC4D 2A                       *
        bit     $8B                             ; DC4E 24 8B                    $.
        bmi     LDC58                           ; DC50 30 06                    0.
        and     #$03                            ; DC52 29 03                    ).
        cmp     $83                             ; DC54 C5 83                    ..
        clc                                     ; DC56 18                       .
        rts                                     ; DC57 60                       `
; ----------------------------------------------------------------------------
LDC58:  clc                                     ; DC58 18                       .
        and     #$03                            ; DC59 29 03                    ).
        beq     LDC60                           ; DC5B F0 03                    ..
        ldx     #$00                            ; DC5D A2 00                    ..
        rts                                     ; DC5F 60                       `
; ----------------------------------------------------------------------------
LDC60:  ldx     #$FF                            ; DC60 A2 FF                    ..
LDC62:  rts                                     ; DC62 60                       `
; ----------------------------------------------------------------------------

; Set Hi-Res Color Cell
        lda     LC033,x      ; Screen Address Low                   ; DC63 BD 33 C0                 .3.
        sta     $8C                             ; DC66 85 8C                    ..
        lda     L9CBD,x      ; Video Matrix Lines Hi                   ; DC68 BD BD 9C                 ...
        sta     $8D                             ; DC6B 85 8D                    ..
        lda     $83                             ; DC6D A5 83                    ..
        bne     LDC79                           ; DC6F D0 08                    ..
        lda     $03E2                           ; DC71 AD E2 03                 ...
        bit     $D8        ; Graphics mode code (BIT765: 000=0, 001=1, 011=2, 101=3, 111=4)                     ; DC74 24 D8                    $.
        bpl     LDC80                           ; DC76 10 08                    ..
        rts                                     ; DC78 60                       `
; ----------------------------------------------------------------------------
LDC79:  cmp     #$02                            ; DC79 C9 02                    ..
        bne     LDC8D                           ; DC7B D0 10                    ..
        lda     $03E3                           ; DC7D AD E3 03                 ...
LDC80:  and     #$0F                            ; DC80 29 0F                    ).
        sta     $77                             ; DC82 85 77                    .w
        lda     ($8C),y                         ; DC84 B1 8C                    ..
        and     #$F0                            ; DC86 29 F0                    ).
        ora     $77                             ; DC88 05 77                    .w
        sta     ($8C),y                         ; DC8A 91 8C                    ..
        rts                                     ; DC8C 60                       `
; ----------------------------------------------------------------------------
LDC8D:  bcs     LDC9F                           ; DC8D B0 10                    ..
        lda     $03E2                           ; DC8F AD E2 03                 ...
        and     #$F0                            ; DC92 29 F0                    ).
        sta     $77                             ; DC94 85 77                    .w
        lda     ($8C),y                         ; DC96 B1 8C                    ..
        and     #$0F                            ; DC98 29 0F                    ).
        ora     $77                             ; DC9A 05 77                    .w
        sta     ($8C),y                         ; DC9C 91 8C                    ..
        rts                                     ; DC9E 60                       `
; ----------------------------------------------------------------------------
LDC9F:  lda     $8D                             ; DC9F A5 8D                    ..
        and     #$03                            ; DCA1 29 03                    ).
        ora     #$D8                            ; DCA3 09 D8                    ..
        sta     $8D                             ; DCA5 85 8D                    ..
        lda     #$00                            ; DCA7 A9 00                    ..
        sta     MMU_KERN_WINDOW   ; MMU Configuration Register              ; DCA9 8D 00 FF                 ...
        sei                                     ; DCAC 78                       x
        lda     $01                             ; DCAD A5 01                    ..
        pha                                     ; DCAF 48                       H
        and     #$FE                            ; DCB0 29 FE                    ).
        sta     $01                             ; DCB2 85 01                    ..
        lda     $85     ; Multicolor 2 (2)                        ; DCB4 A5 85                    ..
        sta     ($8C),y                         ; DCB6 91 8C                    ..
        pla                                     ; DCB8 68                       h
        sta     $01                             ; DCB9 85 01                    ..
        cli                                     ; DCBB 58                       X
        rts                                     ; DCBC 60                       `
; ----------------------------------------------------------------------------

; Video Matrix Lines Hi
;TODO probably data
        trb     $1C1C                           ; DCBD 1C 1C 1C                 ...
        trb     $1C1C                           ; DCC0 1C 1C 1C                 ...
        trb     $1D1D                           ; DCC3 1C 1D 1D                 ...
        ora     $1D1D,x                         ; DCC6 1D 1D 1D                 ...
        ora     $1E1E,x                         ; DCC9 1D 1E 1E                 ...
        asl     $1E1E,x                         ; DCCC 1E 1E 1E                 ...
        asl     $1F1E,x                         ; DCCF 1E 1E 1F                 ...
        bbr1    $1F,LDCF4                       ; DCD2 1F 1F 1F                 ...

; Position Pixel
;TODO incorrect disassembly, should be jsr
        bbr1    $20,LDCEF                       ; DCD5 1F 20 17                 . .
        sta     $33B0,x                         ; DCD8 9D B0 33                 ..3

        tya                                     ; DCDB 98                       .
        clc                                     ; DCDC 18                       .
        adc     LC033,x   ; Screen Address Low                      ; DCDD 7D 33 C0                 }3.
        sta     $8C                             ; DCE0 85 8C                    ..
        lda     LC04C,x   ; Screen Address High                      ; DCE2 BD 4C C0                 .L.
        adc     #$00                            ; DCE5 69 00                    i.
        asl     $8C                             ; DCE7 06 8C                    ..
        rol     a                               ; DCE9 2A                       *
        asl     $8C                             ; DCEA 06 8C                    ..
        rol     a                               ; DCEC 2A                       *
        asl     $8C                             ; DCED 06 8C                    ..
LDCEF:  rol     a                               ; DCEF 2A                       *
        sta     $8D                             ; DCF0 85 8D                    ..
        .byte   $AD                             ; DCF2 AD                       .
        .byte   $33                             ; DCF3 33                       3
LDCF4:  ora     ($29),y                         ; DCF4 11 29                    .)
        rmb0    INSRT                           ; DCF6 07 A8                    ..
        lda     $1131                           ; DCF8 AD 31 11                 .1.
        bit     $D8      ; Graphics mode code (BIT765: 000=0, 001=1, 011=2, 101=3, 111=4)                      ; DCFB 24 D8                    $.
        php                                     ; DCFD 08                       .
        bpl     LDD01                           ; DCFE 10 01                    ..
        asl     a                               ; DD00 0A                       .
LDD01:  and     #$07                            ; DD01 29 07                    ).
        tax                                     ; DD03 AA                       .
        lda     L9D0F,x                         ; DD04 BD 0F 9D                 ...
        plp                                     ; DD07 28                       (
        bpl     LDD0E     ; Bit Masks                      ; DD08 10 04                    ..
        inx                                     ; DD0A E8                       .
        ora     L9D0F,x   ; Bit Masks                      ; DD0B 1D 0F 9D                 ...
LDD0E:  rts                                     ; DD0E 60                       `
; ----------------------------------------------------------------------------

; Bit Masks
;TODO data
        bra     LDD51                           ; DD0F 80 40                    .@
        jsr     L0810                           ; DD11 20 10 08                  ..
        tsb     $02                             ; DD14 04 02                    ..
;TODO incorrect disassembly
; Calc Hi-Res Row/Column
        ora     (MODKEY,x)                      ; DD16 01 AD                    ..
        and     ($11)                           ; DD18 32 11                    2.
        lsr     a                               ; DD1A 4A                       J
        bne     LDD3B                           ; DD1B D0 1E                    ..
        lda     $1131                           ; DD1D AD 31 11                 .1.
        ror     a                               ; DD20 6A                       j
        lsr     a                               ; DD21 4A                       J
        bit     $D8                             ; DD22 24 D8                    $.
        bmi     LDD27                           ; DD24 30 01                    0.
        lsr     a                               ; DD26 4A                       J
LDD27:  tay                                     ; DD27 A8                       .
        cpy     #$28                            ; DD28 C0 28                    .(
        bcs     LDD3B                           ; DD2A B0 0F                    ..
        lda     $1134                           ; DD2C AD 34 11                 .4.
        bne     LDD3B                           ; DD2F D0 0A                    ..
        lda     $1133                           ; DD31 AD 33 11                 .3.
        lsr     a                               ; DD34 4A                       J
        lsr     a                               ; DD35 4A                       J
        lsr     a                               ; DD36 4A                       J
        tax                                     ; DD37 AA                       .
        cmp     #$19                            ; DD38 C9 19                    ..
        rts                                     ; DD3A 60                       `
; ----------------------------------------------------------------------------
LDD3B:  sec                                     ; DD3B 38                       8
        rts                                     ; DD3C 60                       `
; ----------------------------------------------------------------------------
        lda     $116A                           ; DD3D AD 6A 11                 .j.
        beq     LDD59                           ; DD40 F0 17                    ..
        lda     $87                             ; DD42 A5 87                    ..
        ldy     $88                             ; DD44 A4 88                    ..
        jsr     L9D4D                           ; DD46 20 4D 9D                  M.
        lda     $89                             ; DD49 A5 89                    ..
        ldy     $8A                             ; DD4B A4 8A                    ..

; Add Graphics Coordinate
        jsr     L9DA1   ; Read Current X Position to A/Y                        ; DD4D 20 A1 9D                  ..
;TODO incorrect disassembly
        .byte   $9D                             ; DD50 9D                       .
LDD51:  and     ($11),y                         ; DD51 31 11                    1.
        tya                                     ; DD53 98                       .
        inx                                     ; DD54 E8                       .
        sta     $1131,x                         ; DD55 9D 31 11                 .1.
        inx                                     ; DD58 E8                       .
LDD59:  rts                                     ; DD59 60                       `
; ----------------------------------------------------------------------------

; Subtract Graphics Coordinate
        bcc     LDD63                           ; DD5A 90 07                    ..
        bcs     LDD72                           ; DD5C B0 14                    ..
        bcs     LDD6F                           ; DD5E B0 0F                    ..
        jsr     L9D82                           ; DD60 20 82 9D                  ..
LDD63:  clc                                     ; DD63 18                       .
        adc     $1131,x                         ; DD64 7D 31 11                 }1.
        pha                                     ; DD67 48                       H
        tya                                     ; DD68 98                       .
        adc     $1132,x                         ; DD69 7D 32 11                 }2.
        tay                                     ; DD6C A8                       .
        pla                                     ; DD6D 68                       h
        rts                                     ; DD6E 60                       `
; ----------------------------------------------------------------------------
LDD6F:  jsr     L9D82  ; Read Current X Position to A/Y                         ; DD6F 20 82 9D                  ..
LDD72:  sec                                     ; DD72 38                       8
        sbc     $1131,x                         ; DD73 FD 31 11                 .1.
        sta     $59                             ; DD76 85 59                    .Y
        tya                                     ; DD78 98                       .
        sbc     $1132,x                         ; DD79 FD 32 11                 .2.
        tay                                     ; DD7C A8                       .
        php                                     ; DD7D 08                       .
        lda     $59                             ; DD7E A5 59                    .Y
        plp                                     ; DD80 28                       (
        rts                                     ; DD81 60                       `
; ----------------------------------------------------------------------------

; Read Current X Position to A/Y
        lda     $1131,y                         ; DD82 B9 31 11                 .1.
        pha                                     ; DD85 48                       H
        lda     $1132,y                         ; DD86 B9 32 11                 .2.
        tay                                     ; DD89 A8                       .
        pla                                     ; DD8A 68                       h
        rts                                     ; DD8B 60                       `
; ----------------------------------------------------------------------------

; ?
        jsr     L9D6F   ; Subtract Graphics Coordinate                        ; DD8C 20 6F 9D                  o.
        bpl     LDDA0                           ; DD8F 10 0F                    ..
        php                                     ; DD91 08                       .
        clc                                     ; DD92 18                       .
        eor     #$FF                            ; DD93 49 FF                    I.
        adc     #$01                            ; DD95 69 01                    i.
        pha                                     ; DD97 48                       H
        tya                                     ; DD98 98                       .
        eor     #$FF                            ; DD99 49 FF                    I.
        adc     #$00                            ; DD9B 69 00                    i.
        tay                                     ; DD9D A8                       .
        pla                                     ; DD9E 68                       h
        plp                                     ; DD9F 28                       (
LDDA0:  rts                                     ; DDA0 60                       `
; ----------------------------------------------------------------------------

; ?
        sty     $8E                             ; DDA1 84 8E                    ..
        sta     $8F                             ; DDA3 85 8F                    ..
        lda     $1131,x                         ; DDA5 BD 31 11                 .1.
        ldy     $1132,x                         ; DDA8 BC 32 11                 .2.
        php                                     ; DDAB 08                       .
        jsr     L9D8F                           ; DDAC 20 8F 9D                  ..
        sta     $1131,x                         ; DDAF 9D 31 11                 .1.
        tya                                     ; DDB2 98                       .
        sta     $1132,x                         ; DDB3 9D 32 11                 .2.
        lda     #$00                            ; DDB6 A9 00                    ..
        sta     $1177                           ; DDB8 8D 77 11                 .w.
        ldy     #$10                            ; DDBB A0 10                    ..
LDDBD:  lsr     $8E                             ; DDBD 46 8E                    F.
        ror     $8F                             ; DDBF 66 8F                    f.
        bcc     LDDD2                           ; DDC1 90 0F                    ..
        clc                                     ; DDC3 18                       .
        adc     $1131,x                         ; DDC4 7D 31 11                 }1.
        pha                                     ; DDC7 48                       H
        lda     $1177                           ; DDC8 AD 77 11                 .w.
        adc     $1132,x                         ; DDCB 7D 32 11                 }2.
        sta     $1177                           ; DDCE 8D 77 11                 .w.
        pla                                     ; DDD1 68                       h
LDDD2:  lsr     $1177                           ; DDD2 4E 77 11                 Nw.
        ror     a                               ; DDD5 6A                       j
        dey                                     ; DDD6 88                       .
        bne     LDDBD                           ; DDD7 D0 E4                    ..
        adc     #$00                            ; DDD9 69 00                    i.
        ldy     $1177                           ; DDDB AC 77 11                 .w.
        bcc     LDDE1                           ; DDDE 90 01                    ..
        iny                                     ; DDE0 C8                       .
LDDE1:  plp                                     ; DDE1 28                       (
        jmp     L9D8F                           ; DDE2 4C 8F 9D                 L..
; ----------------------------------------------------------------------------

; Restore Pixel Cursor
        ldy     #$00                            ; DDE5 A0 00                    ..
        jsr     L9DEC                           ; DDE7 20 EC 9D                  ..
        ldy     #$02                            ; DDEA A0 02                    ..
        lda     $1135,y                         ; DDEC B9 35 11                 .5.
        sta     $1131,y                         ; DDEF 99 31 11                 .1.
        lda     $1136,y                         ; DDF2 B9 36 11                 .6.
        sta     $1132,y                         ; DDF5 99 32 11                 .2.
        rts                                     ; DDF8 60                       `
; ----------------------------------------------------------------------------
; Check Optional Float/Fixed Parameter
        jsr     DFLTO    ; CHRGOT entry                       ; DDF9 20 86 03                  ..
        beq     LDE0A                           ; DDFC F0 0C                    ..
        jsr     L794A    ; -Check Comma                       ; DDFE 20 4A 79                  Jy
        cmp     #$2C                            ; DE01 C9 2C                    .,
        beq     LDE0A                           ; DE03 F0 05                    ..
        jsr     L880E    ; -Input Float/Fixed Value                       ; DE05 20 0E 88                  ..
        sec                                     ; DE08 38                       8
        rts                                     ; DE09 60                       `
LDE0A:  lda     #$00                            ; DE0A A9 00                    ..
        tay                                     ; DE0C A8                       .
LDE0D:  clc                                     ; DE0D 18                       .
        rts                                     ; DE0E 60                       `
; ----------------------------------------------------------------------------

; Input Optional Byte Parameter   -Check Byte Parameter in List
        ldx     #$00                            ; DE0F A2 00                    ..
        jsr     DFLTO   ; CHRGOT entry                        ; DE11 20 86 03                  ..
        beq     LDE0D                           ; DE14 F0 F7                    ..
        jsr     L794A                           ; DE16 20 4A 79                  Jy
        cmp     #$2C    ; -Check Comma                        ; DE19 C9 2C                    .,
        beq     LDE0D                           ; DE1B F0 F0                    ..
        jsr     L87F0   ; -Eval Byte Parameter                        ; DE1D 20 F0 87                  ..
        sec                                     ; DE20 38                       8
        rts                                     ; DE21 60                       `
; ----------------------------------------------------------------------------

; Parse Graphics Command

        jsr     LA067                           ; DE22 20 67 A0                  g.

; Get Color Source Param
        ldx     #$01                            ; DE25 A2 01                    ..
        jsr     DFLTO   ; CHRGOT entry                        ; DE27 20 86 03                  ..
        beq     LDE3F                           ; DE2A F0 13                    ..
        cmp     #$2C                            ; DE2C C9 2C                    .,
        beq     LDE3F                           ; DE2E F0 0F                    ..
        jsr     L87F0    ; -Eval Byte Parameter                       ; DE30 20 F0 87                  ..
        cpx     #$04                            ; DE33 E0 04                    ..
        bcs     LDE42                           ; DE35 B0 0B                    ..
        cpx     #$02                            ; DE37 E0 02                    ..
        bit     $D8      ; Graphics mode code (BIT765: 000=0, 001=1, 011=2, 101=3, 111=4)                       ; DE39 24 D8                    $.
        bmi     LDE3F                           ; DE3B 30 02                    0.
        bcs     LDE42                           ; DE3D B0 03                    ..
LDE3F:  stx     $83                             ; DE3F 86 83                    ..
        rts                                     ; DE41 60                       `
; ----------------------------------------------------------------------------
LDE42:  jmp     L7D16     ; Print 'illegal quantity'                      ; DE42 4C 16 7D                 L.}
; ----------------------------------------------------------------------------
        jsr     DFLTO     ; CHRGOT entry                      ; DE45 20 86 03                  ..
        beq     LDE51                           ; DE48 F0 07                    ..
        jsr     L794A     ; -Check Comma                      ; DE4A 20 4A 79                  Jy
        cmp     #$2C                            ; DE4D C9 2C                    .,
        bne     LDE63                           ; DE4F D0 12                    ..
LDE51:  ldy     #$00                            ; DE51 A0 00                    ..
LDE53:  lda     $1131,y                         ; DE53 B9 31 11                 .1.
        sta     $1131,x                         ; DE56 9D 31 11                 .1.
        inx                                     ; DE59 E8                       .
        iny                                     ; DE5A C8                       .
        cpy     #$04                            ; DE5B C0 04                    ..
        bne     LDE53                           ; DE5D D0 F4                    ..
        rts                                     ; DE5F 60                       `
; ----------------------------------------------------------------------------
;TODO jsr
        .byte   $20       ; -Check Comma                      ; DE60 20
LDE61:  lsr     a                               ; DE61 4A                       J
        .byte   $79                             ; DE62 79                       y
LDE63:  stx     $1178                           ; DE63 8E 78 11                 .x.
        jsr     L9EFB                           ; DE66 20 FB 9E                  ..
        jsr     DFLTO     ; CHRGOT entry                      ; DE69 20 86 03                  ..
        cmp     #$2C                            ; DE6C C9 2C                    .,
        beq     LDEC6                           ; DE6E F0 56                    .V
        cmp     #$3B                            ; DE70 C9 3B                    .;
        beq     LDE77                           ; DE72 F0 03                    ..
        jmp     L795A     ; Syntax Error                      ; DE74 4C 5A 79                 LZy
; ----------------------------------------------------------------------------
LDE77:  jsr     L0380     ; CHRGET                      ; DE77 20 80 03                  ..
        jsr     L880E     ; -Input Float/Fixed Value                      ; DE7A 20 0E 88                  ..
        sta     $77                             ; DE7D 85 77                    .w
        tya                                     ; DE7F 98                       .
        ldy     $77                             ; DE80 A4 77                    .w
        jsr     L9A6A                           ; DE82 20 6A 9A                  j.
        ldx     $1178                           ; DE85 AE 78 11                 .x.
        lda     $1131,x                         ; DE88 BD 31 11                 .1.
        sta     $1133,x                         ; DE8B 9D 33 11                 .3.
        lda     $1132,x                         ; DE8E BD 32 11                 .2.
        sta     $1134,x                         ; DE91 9D 34 11                 .4.
        jsr     L9D3D                           ; DE94 20 3D 9D                  =.
        lda     #$0E                            ; DE97 A9 0E                    ..
        sta     $1179                           ; DE99 8D 79 11                 .y.
        clc                                     ; DE9C 18                       .
        ldx     $1178                           ; DE9D AE 78 11                 .x.
LDEA0:  jsr     L9AC1                           ; DEA0 20 C1 9A                  ..
        sta     $1131,x                         ; DEA3 9D 31 11                 .1.
        tya                                     ; DEA6 98                       .
        sta     $1132,x                         ; DEA7 9D 32 11                 .2.
        ldy     #$00                            ; DEAA A0 00                    ..
        lsr     $1179                           ; DEAC 4E 79 11                 Ny.
        bcc     LDEB3                           ; DEAF 90 02                    ..
        .byte   $A0                             ; DEB1 A0                       .
LDEB2:  .byte   $02                             ; DEB2 02                       .
LDEB3:  jsr     L9D5E                           ; DEB3 20 5E 9D                  ^.
        sta     $1131,x                         ; DEB6 9D 31 11                 .1.
        tya                                     ; DEB9 98                       .
        sta     $1132,x                         ; DEBA 9D 32 11                 .2.
        inx                                     ; DEBD E8                       .
        inx                                     ; DEBE E8                       .
        lsr     $1179                           ; DEBF 4E 79 11                 Ny.
        bne     LDEA0                           ; DEC2 D0 DC                    ..
        clc                                     ; DEC4 18                       .
        rts                                     ; DEC5 60                       `
; ----------------------------------------------------------------------------
LDEC6:  jsr     L0380    ; CHRGET                       ; DEC6 20 80 03                  ..
        inc     $1178                           ; DEC9 EE 78 11                 .x.
        inc     $1178                           ; DECC EE 78 11                 .x.
        jsr     L9EFB                           ; DECF 20 FB 9E                  ..
        ldx     $1178                           ; DED2 AE 78 11                 .x.
        dex                                     ; DED5 CA                       .
        dex                                     ; DED6 CA                       .
        jsr     L9D3D                           ; DED7 20 3D 9D                  =.
        ldy     #$02                            ; DEDA A0 02                    ..
        ldx     $1178                           ; DEDC AE 78 11                 .x.
        inx                                     ; DEDF E8                       .
        inx                                     ; DEE0 E8                       .
LDEE1:  dex                                     ; DEE1 CA                       .
        dex                                     ; DEE2 CA                       .
        lsr     $1179                           ; DEE3 4E 79 11                 Ny.
        bcc     LDEF2                           ; DEE6 90 0A                    ..
        jsr     L9D60     ; Add Graphics Coordinate                      ; DEE8 20 60 9D                  `.
        sta     $1131,x                         ; DEEB 9D 31 11                 .1.
        tya                                     ; DEEE 98                       .
        sta     $1132,x                         ; DEEF 9D 32 11                 .2.
LDEF2:  ldy     #$00                            ; DEF2 A0 00                    ..
        cpx     $1178                           ; DEF4 EC 78 11                 .x.
        beq     LDEE1                           ; DEF7 F0 E8                    ..
        clc                                     ; DEF9 18                       .
        rts                                     ; DEFA 60                       `
; ----------------------------------------------------------------------------
        jsr     DFLTO    ; CHRGOT entry                       ; DEFB 20 86 03                  ..
        cmp     #$AA                            ; DEFE C9 AA                    ..
        beq     LDF07                           ; DF00 F0 05                    ..
;incorrect disassembly
LDF02:  .byte   $C9                             ; DF02 C9                       .
LDF03:  .byte   $AB                             ; DF03 AB                       .
LDF04:  .byte   $F0                             ; DF04 F0                       .
LDF05:  .byte   $01                             ; DF05 01                       .
LDF06:  clc                                     ; DF06 18                       .
LDF07:  .byte   $2E                             ; DF07 2E                       .
LDF08:  adc     $2011,y                         ; DF08 79 11 20                 y.
        asl     $AE88                           ; DF0B 0E 88 AE                 ...
        sei                                     ; DF0E 78                       x
        ora     ($9D),y                         ; DF0F 11 9D                    ..
        and     ($11)                           ; DF11 32 11                    2.
        tya                                     ; DF13 98                       .
        sta     $1131,x                         ; DF14 9D 31 11                 .1.
        rts                                     ; DF17 60                       `
; ----------------------------------------------------------------------------
;TODO data
; Multicolor Pixel Masks
        bbs7    $AA,LDF70                       ; DF18 FF AA 55                 ..U
        brk                                     ; DF1B 00                       .
        brk                                     ; DF1C 00                       .
        brk                                     ; DF1D 00                       .

; Conv Words Hi
        bit     $5771                           ; DF1E 2C 71 57                 ,qW
        sta     a:$80                           ; DF21 8D 80 00                 ...
        ldy     $8F                             ; DF24 A4 8F                    ..
        cpy     $19                             ; DF26 C4 19                    ..
        .byte   $DD                             ; DF28 DD                       .
LDF29:  lda     ($F0)                           ; DF29 B2 F0                    ..
        bcc     LDF29                           ; DF2B 90 FC                    ..
; Unused (the two FFs)
        trb     IRQ_VECTOR+1                    ; DF2D 1C FF FF                 ...
; Conv Words Lo
        tsb     $72                             ; DF30 04 72                    .r
        tsb     $50                             ; DF32 04 50                    .P
        tsb     $0B                             ; DF34 04 0B                    ..
        .byte   $03                             ; DF36 03                       .
        tay                                     ; DF37 A8                       .
        .byte   $03                             ; DF38 03                       .
        plp                                     ; DF39 28                       (
        .byte   $02                             ; DF3A 02                       .
        bcc     LDF3E                           ; DF3B 90 01                    ..
        .byte   $E3                             ; DF3D E3                       .
LDF3E:  ora     ($28,x)                         ; DF3E 01 28                    .(
        brk                                     ; DF40 00                       .
        .byte   $63                             ; DF41 63                       c


; Allocate 9K Graphics Area for graphic/sprdef

        lda     $76       ; Graphics flag: FF = Graphics allocated                      ; DF42 A5 76                    .v
        beq     LDF47                           ; DF44 F0 01                    ..
        rts                                     ; DF46 60                       `
; ----------------------------------------------------------------------------
LDF47:  lda     $1211                           ; DF47 AD 11 12                 ...
        clc                                     ; DF4A 18                       .
        adc     #$24                            ; DF4B 69 24                    i$
        bcs     LDF5D                           ; DF4D B0 0E                    ..
        sta     $62                             ; DF4F 85 62                    .b
        cmp     $1213                           ; DF51 CD 13 12                 ...
        bcc     LDF60                           ; DF54 90 0A                    ..
        bne     LDF5D                           ; DF56 D0 05                    ..
        cpy     $1212                           ; DF58 CC 12 12                 ...
        bcc     LDF60                           ; DF5B 90 03                    ..
LDF5D:  jmp     L4D37                           ; DF5D 4C 37 4D                 L7M
; ----------------------------------------------------------------------------
LDF60:  dec     $76                             ; DF60 C6 76                    .v
        lda     $1210                           ; DF62 AD 10 12                 ...
        sta     $24                             ; DF65 85 24                    .$
        lda     $62                             ; DF67 A5 62                    .b
        sta     $25                             ; DF69 85 25                    .%
        ldx     $1210                           ; DF6B AE 10 12                 ...
        stx     $26                             ; DF6E 86 26                    .&
LDF70:  lda     $1211                           ; DF70 AD 11 12                 ...
        sta     $27                             ; DF73 85 27                    .'
        sec                                     ; DF75 38                       8
        sbc     #$1C                            ; DF76 E9 1C                    ..
        tay                                     ; DF78 A8                       .
        txa                                     ; DF79 8A                       .
        eor     #$FF                            ; DF7A 49 FF                    I.
        sta     $50                             ; DF7C 85 50                    .P
        tya                                     ; DF7E 98                       .
        eor     #$FF                            ; DF7F 49 FF                    I.
        sta     $51                             ; DF81 85 51                    .Q
        ldy     #$00                            ; DF83 A0 00                    ..
        inc     $50                             ; DF85 E6 50                    .P
        bne     LDF8D                           ; DF87 D0 04                    ..
        inc     $51                             ; DF89 E6 51                    .Q
        beq     LDFA5                           ; DF8B F0 18                    ..
LDF8D:  lda     $24                             ; DF8D A5 24                    .$
        bne     LDF93                           ; DF8F D0 02                    ..
        dec     $25                             ; DF91 C6 25                    .%
LDF93:  dec     $24                             ; DF93 C6 24                    .$
        lda     $26                             ; DF95 A5 26                    .&
        bne     LDF9B                           ; DF97 D0 02                    ..
        dec     $27                             ; DF99 C6 27                    .'
LDF9B:  dec     $26                             ; DF9B C6 26                    .&
        jsr     L03C0                           ; DF9D 20 C0 03                  ..
        sta     ($24),y                         ; DFA0 91 24                    .$
        jmp     L9F85                           ; DFA2 4C 85 9F                 L..
; ----------------------------------------------------------------------------
LDFA5:  clc                                     ; DFA5 18                       .
        lda     $1211                           ; DFA6 AD 11 12                 ...
        adc     #$24                            ; DFA9 69 24                    i$
        sta     $1211                           ; DFAB 8D 11 12                 ...
        lda     $2E                             ; DFAE A5 2E                    ..
        adc     #$24                            ; DFB0 69 24                    i$
        sta     $2E                             ; DFB2 85 2E                    ..
        lda     $44                             ; DFB4 A5 44                    .D
        adc     #$24                            ; DFB6 69 24                    i$
        sta     $44                             ; DFB8 85 44                    .D
        jsr     L4F4C                           ; DFBA 20 4C 4F                  LO
        jsr     L4F7F                           ; DFBD 20 7F 4F                  .O
        bit     $7F                             ; DFC0 24 7F                    $.
        bpl     LDFF1                           ; DFC2 10 2D                    .-
        ldx     #$24                            ; DFC4 A2 24                    .$
        bit     $76                             ; DFC6 24 76                    $v
        bmi     LDFCC                           ; DFC8 30 02                    0.
        ldx     #$DC                            ; DFCA A2 DC                    ..
LDFCC:  txa                                     ; DFCC 8A                       .
        clc                                     ; DFCD 18                       .
        adc     $3E                             ; DFCE 65 3E                    e>
        sta     $3E                             ; DFD0 85 3E                    .>
        txa                                     ; DFD2 8A                       .
        clc                                     ; DFD3 18                       .
        adc     $1203                           ; DFD4 6D 03 12                 m..
        sta     $1203                           ; DFD7 8D 03 12                 ...
        txa                                     ; DFDA 8A                       .
        clc                                     ; DFDB 18                       .
        adc     $120F                           ; DFDC 6D 0F 12                 m..
        sta     $120F                           ; DFDF 8D 0F 12                 ...
        jsr     L5044                           ; DFE2 20 44 50                  DP
LDFE5:  lda     $3F                             ; DFE5 A5 3F                    .?
        cmp     #$FF                            ; DFE7 C9 FF                    ..
        bne     LDFF2                           ; DFE9 D0 07                    ..
        lda     $40                             ; DFEB A5 40                    .@
        cmp     #$09                            ; DFED C9 09                    ..
        bne     LDFF2                           ; DFEF D0 01                    ..
LDFF1:  rts                                     ; DFF1 60                       `
; ----------------------------------------------------------------------------
LDFF2:  ldy     #$00                            ; DFF2 A0 00                    ..
        lda     ($3F),y                         ; DFF4 B1 3F                    .?
        cmp     #$81                            ; DFF6 C9 81                    ..
        bne     LE003                           ; DFF8 D0 09                    ..
        ldy     #$10                            ; DFFA A0 10                    ..
        jsr     LA055                           ; DFFC 20 55 A0                  U.
        lda     #$12                            ; DFFF A9 12                    ..
        bne     LE00A                           ; E001 D0 07                    ..
LE003:  ldy     #$04                            ; E003 A0 04                    ..
        jsr     LA055                           ; E005 20 55 A0                  U.
        lda     #$05                            ; E008 A9 05                    ..
LE00A:  clc                                     ; E00A 18                       .
        adc     $3F                             ; E00B 65 3F                    e?
        sta     $3F                             ; E00D 85 3F                    .?
        bcc     LDFE5                           ; E00F 90 D4                    ..
        inc     $40                             ; E011 E6 40                    .@
        bne     LDFE5                           ; E013 D0 D0                    ..

; Move Basic to $1c01

        lda     $76      ; Graphics flag: FF = Graphics allocated                       ; E015 A5 76                    .v
        bne     LE01A                           ; E017 D0 01                    ..
        rts                                     ; E019 60                       `
; ----------------------------------------------------------------------------
LE01A:  ldy     #$00                            ; E01A A0 00                    ..
        sty     $76       ; Graphics flag: FF = Graphics allocated                      ; E01C 84 76                    .v
        sty     $24                             ; E01E 84 24                    .$
        sty     $26                             ; E020 84 26                    .&
        lda     #$1C                            ; E022 A9 1C                    ..
        sta     $25                             ; E024 85 25                    .%
        lda     #$40                            ; E026 A9 40                    .@
        sta     $27                             ; E028 85 27                    .'

LE02A:  jsr     L03C0     ; Index2 Indirect Fetch From RAM Bank 0                      ; E02A 20 C0 03                  ..
        sta     ($24),y                         ; E02D 91 24                    .$
        iny                                     ; E02F C8                       .
        bne     LE02A                           ; E030 D0 F8                    ..
        inc     $25                             ; E032 E6 25                    .%
        inc     $27                             ; E034 E6 27                    .'
        lda     $1211                           ; E036 AD 11 12                 ...
        cmp     $27                             ; E039 C5 27                    .'
        bcs     LE02A                           ; E03B B0 ED                    ..
        sec                                     ; E03D 38                       8
        lda     $2E                             ; E03E A5 2E                    ..
        sbc     #$24                            ; E040 E9 24                    .$
        sta     $2E                             ; E042 85 2E                    ..
        lda     $1211                           ; E044 AD 11 12                 ...
        sbc     #$24                            ; E047 E9 24                    .$
        sta     $1211                           ; E049 8D 11 12                 ...
        lda     $44                             ; E04C A5 44                    .D
        sbc     #$24                            ; E04E E9 24                    .$
        sta     $44                             ; E050 85 44                    .D
        jmp     L9FBA                           ; E052 4C BA 9F                 L..
; ----------------------------------------------------------------------------
        lda     ($3F),y                         ; E055 B1 3F                    .?
        bit     $76     ; Graphics flag: FF = Graphics allocated                        ; E057 24 76                    $v
        bne     LE061                           ; E059 D0 06                    ..
        sec                                     ; E05B 38                       8
        sbc     #$24                            ; E05C E9 24                    .$
        sta     ($3F),y                         ; E05E 91 3F                    .?
        rts                                     ; E060 60                       `
; ----------------------------------------------------------------------------
LE061:  clc                                     ; E061 18                       .
        adc     #$24                            ; E062 69 24                    i$
        sta     ($3F),y                         ; E064 91 3F                    .?
        rts                                     ; E066 60                       `
; ----------------------------------------------------------------------------
        lda     $76     ; Graphics flag: FF = Graphics allocated                        ; E067 A5 76                    .v
        beq     LE06C                           ; E069 F0 01                    ..
        rts                                     ; E06B 60                       `
; ----------------------------------------------------------------------------
LE06C:  ldx     #$23                            ; E06C A2 23                    .#
        jmp     L4D39   ; Error                        ; E06E 4C 39 4D                 L9M
; ----------------------------------------------------------------------------

; Perform [catalog/directory]
        jsr     LA396                           ; E071 20 96 A3                  ..
        lda     $80                             ; E074 A5 80                    ..
        and     #$E6                            ; E076 29 E6                    ).
        beq     LE07D                           ; E078 F0 03                    ..
        jmp     L795A        ; Syntax Error                   ; E07A 4C 5A 79                 LZy
; ----------------------------------------------------------------------------

LE07D:  ldy     #$01                            ; E07D A0 01                    ..
        ldx     #$01                            ; E07F A2 01                    ..
        lda     $80                             ; E081 A5 80                    ..
        and     #$11                            ; E083 29 11                    ).
        beq     LE08D                           ; E085 F0 06                    ..
        lsr     a                               ; E087 4A                       J
        bcc     LE08C                           ; E088 90 02                    ..
        inx                                     ; E08A E8                       .
        inx                                     ; E08B E8                       .

LE08C:  inx                                     ; E08C E8                       .

LE08D:  txa                                     ; E08D 8A                       .
        jsr     LA63C                           ; E08E 20 3C A6                  <.
        lda     #$00                            ; E091 A9 00                    ..
        tax                                     ; E093 AA                       .
        jsr     L927A                           ; E094 20 7A 92                  z.
        ldy     #$60                            ; E097 A0 60                    .`
        ldx     stack+28                        ; E099 AE 1C 01                 ...
        lda     #$00                            ; E09C A9 00                    ..
        jsr     L924A                           ; E09E 20 4A 92                  J.
        sec                                     ; E0A1 38                       8
        jsr     L90CB                           ; E0A2 20 CB 90                  ..
        bcc     LE0B0                           ; E0A5 90 09                    ..
        pha                                     ; E0A7 48                       H
        jsr     LA107                           ; E0A8 20 07 A1                  ..
        pla                                     ; E0AB 68                       h
        tax                                     ; E0AC AA                       .
        jmp     L4D39                           ; E0AD 4C 39 4D                 L9M
; ----------------------------------------------------------------------------
LE0B0:  ldx     #$00                            ; E0B0 A2 00                    ..
        jsr     LA81A                           ; E0B2 20 1A A8                  ..
        jsr     LFFC6_CHKIN                     ; E0B5 20 C6 FF                  ..
        ldy     #$03                            ; E0B8 A0 03                    ..
LE0BA:  sty     $1174                           ; E0BA 8C 74 11                 .t.
LE0BD:  jsr     L9256                           ; E0BD 20 56 92                  V.
        sta     $1175                           ; E0C0 8D 75 11                 .u.
        jsr     L9244                           ; E0C3 20 44 92                  D.
        bne     LE107                           ; E0C6 D0 3F                    .?
        jsr     L9256                           ; E0C8 20 56 92                  V.
        sta     $1176                           ; E0CB 8D 76 11                 .v.
        jsr     L9244                           ; E0CE 20 44 92                  D.
        bne     LE107                           ; E0D1 D0 34                    .4
        dec     $1174                           ; E0D3 CE 74 11                 .t.
        bne     LE0BD                           ; E0D6 D0 E5                    ..
        ldx     $1175                           ; E0D8 AE 75 11                 .u.
        lda     $1176                           ; E0DB AD 76 11                 .v.
        jsr     L8E25                           ; E0DE 20 25 8E                  %.
        lda     #$20                            ; E0E1 A9 20                    .
        jsr     L925C                           ; E0E3 20 5C 92                  \.
        jsr     L9256                           ; E0E6 20 56 92                  V.
        pha                                     ; E0E9 48                       H
        jsr     L9244                           ; E0EA 20 44 92                  D.
        bne     LE106                           ; E0ED D0 17                    ..
        pla                                     ; E0EF 68                       h
        beq     LE0F8                           ; E0F0 F0 06                    ..
        jsr     L925C                           ; E0F2 20 5C 92                  \.
        jmp     LA0E6                           ; E0F5 4C E6 A0                 L..
; ----------------------------------------------------------------------------
LE0F8:  lda     #$0D                            ; E0F8 A9 0D                    ..
        jsr     L925C                           ; E0FA 20 5C 92                  \.
        jsr     L9286                           ; E0FD 20 86 92                  ..
        beq     LE107                           ; E100 F0 05                    ..
        ldy     #$02                            ; E102 A0 02                    ..
        bne     LE0BA                           ; E104 D0 B4                    ..
LE106:  pla                                     ; E106 68                       h
LE107:  jsr     L9262                           ; E107 20 62 92                  b.
        lda     #$00                            ; E10A A9 00                    ..
        clc                                     ; E10C 18                       .
        jmp     L9268                           ; E10D 4C 68 92                 Lh.
; ----------------------------------------------------------------------------

; Perform [dopen]
        lda     #$22                            ; E110 A9 22                    ."
        jsr     LA398                           ; E112 20 98 A3                  ..
        jsr     LA744                           ; E115 20 44 A7                  D.
        jsr     LA14A                           ; E118 20 4A A1                  J.
        ldy     #$05                            ; E11B A0 05                    ..
        ldx     #$04                            ; E11D A2 04                    ..
        bit     $80                             ; E11F 24 80                    $.
        bvc     LE136                           ; E121 50 13                    P.
        ldx     #$08                            ; E123 A2 08                    ..
        bne     LE136                           ; E125 D0 0F                    ..

; Perform [append]
        lda     #$E2                            ; E127 A9 E2                    ..
        jsr     LA398                           ; E129 20 98 A3                  ..
        jsr     LA744                           ; E12C 20 44 A7                  D.
        jsr     LA14A                           ; E12F 20 4A A1                  J.
        ldy     #$16                            ; E132 A0 16                    ..
        ldx     #$05                            ; E134 A2 05                    ..
LE136:  txa                                     ; E136 8A                       .
        jsr     LA63C                           ; E137 20 3C A6                  <.
        jsr     L9262                           ; E13A 20 62 92                  b.
        lda     #$00                            ; E13D A9 00                    ..
        tax                                     ; E13F AA                       .
        jsr     L927A                           ; E140 20 7A 92                  z.
        jsr     L90CB                           ; E143 20 CB 90                  ..
        sec                                     ; E146 38                       8
        jmp     L9268                           ; E147 4C 68 92                 Lh.
; ----------------------------------------------------------------------------

; Find Spare SA
        ldy     #$61                            ; E14A A0 61                    .a
LE14C:  iny                                     ; E14C C8                       .
        cpy     #$6F                            ; E14D C0 6F                    .o
        beq     LE15D                           ; E14F F0 0C                    ..
        jsr     LA81A                           ; E151 20 1A A8                  ..
        jsr     C128_FF5C_LKUPSA                           ; E154 20 5C FF                  \.
        bcc     LE14C                           ; E157 90 F3                    ..
        sty     stack+29                        ; E159 8C 1D 01                 ...
        rts                                     ; E15C 60                       `
; ----------------------------------------------------------------------------
LE15D:  ldx     #$01                            ; E15D A2 01                    ..
        jmp     L4D39                           ; E15F 4C 39 4D                 L9M
; ----------------------------------------------------------------------------

; Perform [dclose]
        lda     #$F3                            ; E162 A9 F3                    ..
        jsr     LA398                           ; E164 20 98 A3                  ..
        jsr     LA7E2                           ; E167 20 E2 A7                  ..
        lda     $80                             ; E16A A5 80                    ..
        and     #$04                            ; E16C 29 04                    ).
        beq     LE176                           ; E16E F0 06                    ..
        lda     stack+27                        ; E170 AD 1B 01                 ...
        jmp     L9268                           ; E173 4C 68 92                 Lh.
; ----------------------------------------------------------------------------
LE176:  lda     stack+28                        ; E176 AD 1C 01                 ...
        jsr     LA81A                           ; E179 20 1A A8                  ..
        jmp     C128_FF4A_CLALL                           ; E17C 4C 4A FF                 LJ.
; ----------------------------------------------------------------------------

; Perform [dsave]
        lda     #$66                            ; E17F A9 66                    .f
        jsr     LA398                           ; E181 20 98 A3                  ..
        jsr     LA725                           ; E184 20 25 A7                  %.
        ldy     #$05                            ; E187 A0 05                    ..
        lda     #$04                            ; E189 A9 04                    ..
        jsr     LA63C                           ; E18B 20 3C A6                  <.
        lda     #$00                            ; E18E A9 00                    ..
        tax                                     ; E190 AA                       .
        jsr     L927A                           ; E191 20 7A 92                  z.
        jmp     L9108                           ; E194 4C 08 91                 L..
; ----------------------------------------------------------------------------

; Perform [dverify]
        lda     #$01                            ; E197 A9 01                    ..

; Perform [dload]
;TODO incorrect disassembly
        bit     a:$A9                           ; E199 2C A9 00                 ,..
        sta     $0C                             ; E19C 85 0C                    ..
        lda     #$E6                            ; E19E A9 E6                    ..
        jsr     LA398                           ; E1A0 20 98 A3                  ..
        jsr     LA725                           ; E1A3 20 25 A7                  %.
        lda     #$00                            ; E1A6 A9 00                    ..
        sta     stack+29                        ; E1A8 8D 1D 01                 ...
        ldy     #$05                            ; E1AB A0 05                    ..
        lda     #$04                            ; E1AD A9 04                    ..
        jsr     LA63C                           ; E1AF 20 3C A6                  <.
        lda     #$00                            ; E1B2 A9 00                    ..
        tax                                     ; E1B4 AA                       .
        jsr     L927A                           ; E1B5 20 7A 92                  z.
        jmp     L9126                           ; E1B8 4C 26 91                 L&.
; ----------------------------------------------------------------------------

; Perform [bsave]
        lda     #$66                            ; E1BB A9 66                    .f
        ldx     #$F8                            ; E1BD A2 F8                    ..
        jsr     LA39A                           ; E1BF 20 9A A3                  ..
        jsr     LA725                           ; E1C2 20 25 A7                  %.
        lda     L0081                           ; E1C5 A5 81                    ..
        and     #$06                            ; E1C7 29 06                    ).
        cmp     #$06                            ; E1C9 C9 06                    ..
        beq     LE1D0                           ; E1CB F0 03                    ..
        jmp     L795A                           ; E1CD 4C 5A 79                 LZy
; ----------------------------------------------------------------------------
LE1D0:  ldy     #$05                            ; E1D0 A0 05                    ..
        lda     #$04                            ; E1D2 A9 04                    ..
        jsr     LA63C                           ; E1D4 20 3C A6                  <.
        lda     stack+31                        ; E1D7 AD 1F 01                 ...
        ldx     #$00                            ; E1DA A2 00                    ..
        jsr     L927A                           ; E1DC 20 7A 92                  z.
        ldx     stack+23                        ; E1DF AE 17 01                 ...
        ldy     stack+24                        ; E1E2 AC 18 01                 ...
        lda     #$5A                            ; E1E5 A9 5A                    .Z
        stx     $5A                             ; E1E7 86 5A                    .Z
        sty     $5B                             ; E1E9 84 5B                    .[
        ldx     stack+25                        ; E1EB AE 19 01                 ...
        ldy     stack+26                        ; E1EE AC 1A 01                 ...
        jmp     L9110                           ; E1F1 4C 10 91                 L..
; ----------------------------------------------------------------------------

; Perform [bload]
        lda     #$E6                            ; E1F4 A9 E6                    ..
        ldx     #$FC                            ; E1F6 A2 FC                    ..
        jsr     LA39A                           ; E1F8 20 9A A3                  ..
        jsr     LA725                           ; E1FB 20 25 A7                  %.
        ldx     stack+23                        ; E1FE AE 17 01                 ...
        ldy     stack+24                        ; E201 AC 18 01                 ...
        lda     #$00                            ; E204 A9 00                    ..
        cpx     #$FF                            ; E206 E0 FF                    ..
        bne     LE210                           ; E208 D0 06                    ..
        cpy     #$FF                            ; E20A C0 FF                    ..
        bne     LE210                           ; E20C D0 02                    ..
        lda     #$FF                            ; E20E A9 FF                    ..
LE210:  sta     stack+29                        ; E210 8D 1D 01                 ...
        ldy     #$05                            ; E213 A0 05                    ..
        lda     #$04                            ; E215 A9 04                    ..
        jsr     LA63C                           ; E217 20 3C A6                  <.
        lda     stack+31                        ; E21A AD 1F 01                 ...
        ldx     #$00                            ; E21D A2 00                    ..
        jsr     L927A                           ; E21F 20 7A 92                  z.
        lda     #$00                            ; E222 A9 00                    ..
        ldx     stack+23                        ; E224 AE 17 01                 ...
        ldy     stack+24                        ; E227 AC 18 01                 ...
        jsr     LOAD                            ; E22A 20 D5 FF                  ..
        php                                     ; E22D 08                       .
        jsr     L9236                           ; E22E 20 36 92                  6.
        plp                                     ; E231 28                       (
        bcc     LE237                           ; E232 90 03                    ..
        jmp     L90C3                           ; E234 4C C3 90                 L..
; ----------------------------------------------------------------------------
LE237:  jsr     L9244                           ; E237 20 44 92                  D.
        and     #$BF                            ; E23A 29 BF                    ).
        beq     LE241                           ; E23C F0 03                    ..
        jmp     L915A                           ; E23E 4C 5A 91                 LZ.
; ----------------------------------------------------------------------------
LE241:  clc                                     ; E241 18                       .
        rts                                     ; E242 60                       `
; ----------------------------------------------------------------------------
        jsr     LA396                           ; E243 20 96 A3                  ..
        jsr     LA71E                           ; E246 20 1E A7                  ..
        and     #$01                            ; E249 29 01                    ).
        cmp     #$01                            ; E24B C9 01                    ..
        bne     LE2B0                           ; E24D D0 61                    .a
        jsr     L926E                           ; E24F 20 6E 92                  n.
        jsr     LA7B6                           ; E252 20 B6 A7                  ..
        bne     LE27C                           ; E255 D0 25                    .%
        ldy     #$1B                            ; E257 A0 1B                    ..
        lda     #$04                            ; E259 A9 04                    ..
        ldx     stack+32                        ; E25B AE 20 01                 . .
        beq     LE262                           ; E25E F0 02                    ..
        lda     #$06                            ; E260 A9 06                    ..

; Perform [header]
LE262:  jsr     LA373                           ; E262 20 73 A3                  s.
        jsr     LA74D                           ; E265 20 4D A7                  M.
        bit     $7F                             ; E268 24 7F                    $.
        bmi     LE27C                           ; E26A 30 10                    0.
        ldy     #$00                            ; E26C A0 00                    ..
        lda     #$7B                            ; E26E A9 7B                    .{
        jsr     L03AB                           ; E270 20 AB 03                  ..
        cmp     #$32                            ; E273 C9 32                    .2
        bcc     LE27C                           ; E275 90 05                    ..
        ldx     #$24                            ; E277 A2 24                    .$
        jmp     L4D39                           ; E279 4C 39 4D                 L9M
; ----------------------------------------------------------------------------
LE27C:  rts                                     ; E27C 60                       `
; ----------------------------------------------------------------------------

; Perform [scratch]
        jsr     LA396                           ; E27D 20 96 A3                  ..
        jsr     LA71E                           ; E280 20 1E A7                  ..
        jsr     LA7B6                           ; E283 20 B6 A7                  ..
        bne     LE2AF                           ; E286 D0 27                    .'
        ldy     #$37                            ; E288 A0 37                    .7
        lda     #$04                            ; E28A A9 04                    ..
        jsr     LA373                           ; E28C 20 73 A3                  s.
        jsr     LA74D                           ; E28F 20 4D A7                  M.
        bit     $7F                             ; E292 24 7F                    $.
        bmi     LE2AF                           ; E294 30 19                    0.
        lda     #$0D                            ; E296 A9 0D                    ..
        jsr     L925C                           ; E298 20 5C 92                  \.
        ldy     #$00                            ; E29B A0 00                    ..
LE29D:  lda     #$7B                            ; E29D A9 7B                    .{
        jsr     L03AB                           ; E29F 20 AB 03                  ..
        beq     LE2AA                           ; E2A2 F0 06                    ..
        jsr     L925C                           ; E2A4 20 5C 92                  \.
        iny                                     ; E2A7 C8                       .
        bne     LE29D                           ; E2A8 D0 F3                    ..
LE2AA:  lda     #$0D                            ; E2AA A9 0D                    ..
        jsr     L90D2                           ; E2AC 20 D2 90                  ..
LE2AF:  rts                                     ; E2AF 60                       `
; ----------------------------------------------------------------------------
LE2B0:  jmp     L795A                           ; E2B0 4C 5A 79                 LZy
; ----------------------------------------------------------------------------

; Perform [record]

        lda     #$23                            ; E2B3 A9 23                    .#
        jsr     L794C                           ; E2B5 20 4C 79                  Ly
        jsr     L87F0                           ; E2B8 20 F0 87                  ..
        cpx     #$00                            ; E2BB E0 00                    ..
        beq     LE2F6                           ; E2BD F0 37                    .7
        stx     stack+27                        ; E2BF 8E 1B 01                 ...
        jsr     L880B                           ; E2C2 20 0B 88                  ..
        ldx     #$01                            ; E2C5 A2 01                    ..
        jsr     L9E11                           ; E2C7 20 11 9E                  ..
        cpx     #$00                            ; E2CA E0 00                    ..
        beq     LE2F6                           ; E2CC F0 28                    .(
        cpx     #$FF                            ; E2CE E0 FF                    ..
        beq     LE2F6                           ; E2D0 F0 24                    .$
        stx     stack+30                        ; E2D2 8E 1E 01                 ...
        lda     stack+27                        ; E2D5 AD 1B 01                 ...
        jsr     LA81A                           ; E2D8 20 1A A8                  ..
        jsr     C128_FF59_LKUPLA                           ; E2DB 20 59 FF                  Y.
        bcs     LE2F9                           ; E2DE B0 19                    ..
        sty     $11ED                           ; E2E0 8C ED 11                 ...
        stx     stack+28                        ; E2E3 8E 1C 01                 ...
        lda     #$00                            ; E2E6 A9 00                    ..
        sta     stack+27                        ; E2E8 8D 1B 01                 ...
        lda     #$6F                            ; E2EB A9 6F                    .o
        sta     stack+29                        ; E2ED 8D 1D 01                 ...
        ldy     #$3B                            ; E2F0 A0 3B                    .;
        lda     #$04                            ; E2F2 A9 04                    ..
        bne     LE373                           ; E2F4 D0 7D                    .}
LE2F6:  jmp     L7D16                           ; E2F6 4C 16 7D                 L.}
; ----------------------------------------------------------------------------
LE2F9:  ldx     #$04                            ; E2F9 A2 04                    ..
        jmp     L4D39                           ; E2FB 4C 39 4D                 L9M
; ----------------------------------------------------------------------------

; Perform [dclear]
        jsr     LA396                           ; E2FE 20 96 A3                  ..
        ldy     #$FF                            ; E301 A0 FF                    ..
        lda     #$02                            ; E303 A9 02                    ..
        jsr     LA373                           ; E305 20 73 A3                  s.
        jmp     LA176                           ; E308 4C 76 A1                 Lv.
; ----------------------------------------------------------------------------
; Perform [collect]
        jsr     LA396                           ; E30B 20 96 A3                  ..
        jsr     LA730                           ; E30E 20 30 A7                  0.
        jsr     L926E                           ; E311 20 6E 92                  n.
        ldy     #$21                            ; E314 A0 21                    .!
        ldx     #$01                            ; E316 A2 01                    ..
        lda     $80                             ; E318 A5 80                    ..
        and     #$10                            ; E31A 29 10                    ).
        beq     LE31F                           ; E31C F0 01                    ..
        inx                                     ; E31E E8                       .
LE31F:  txa                                     ; E31F 8A                       .
        bne     LE373                           ; E320 D0 51                    .Q

; Perform [copy]
        jsr     LA396                           ; E322 20 96 A3                  ..
        and     #$30                            ; E325 29 30                    )0
        cmp     #$30                            ; E327 C9 30                    .0
        bne     LE331                           ; E329 D0 06                    ..
        lda     $80                             ; E32B A5 80                    ..
        and     #$C7                            ; E32D 29 C7                    ).
        beq     LE338                           ; E32F F0 07                    ..
LE331:  lda     $80                             ; E331 A5 80                    ..
        jsr     LA735                           ; E333 20 35 A7                  5.
        lda     $80                             ; E336 A5 80                    ..
LE338:  ldy     #$27                            ; E338 A0 27                    .'
        lda     #$08                            ; E33A A9 08                    ..
        bne     LE373                           ; E33C D0 35                    .5


; Perform [concat]
        jsr     LA396                           ; E33E 20 96 A3                  ..
        jsr     LA735                           ; E341 20 35 A7                  5.
        ldy     #$0D                            ; E344 A0 0D                    ..
        lda     #$0C                            ; E346 A9 0C                    ..
        bne     LE373                           ; E348 D0 29                    .)



; Perform [rename]
        lda     #$E4                            ; E34A A9 E4                    ..
        jsr     LA398                           ; E34C 20 98 A3                  ..
        jsr     LA73B                           ; E34F 20 3B A7                  ;.
        ldy     #$2F                            ; E352 A0 2F                    ./
        lda     #$08                            ; E354 A9 08                    ..
        bne     LE373                           ; E356 D0 1B                    ..


; Perform [backup]
        lda     #$C7                            ; E358 A9 C7                    ..
        jsr     LA398                           ; E35A 20 98 A3                  ..
        and     #$30                            ; E35D 29 30                    )0
        cmp     #$30                            ; E35F C9 30                    .0
        beq     LE366                           ; E361 F0 03                    ..
        jmp     L795A                           ; E363 4C 5A 79                 LZy
; ----------------------------------------------------------------------------
LE366:  jsr     LA7B6                           ; E366 20 B6 A7                  ..
        bne     LE36C                           ; E369 D0 01                    ..
        rts                                     ; E36B 60                       `
; ----------------------------------------------------------------------------
LE36C:  jsr     LA176                           ; E36C 20 76 A1                  v.
        ldy     #$23                            ; E36F A0 23                    .#
        lda     #$04                            ; E371 A9 04                    ..
LE373:  jsr     LA63C                           ; E373 20 3C A6                  <.
        jsr     L9262                           ; E376 20 62 92                  b.
        lda     #$00                            ; E379 A9 00                    ..
        tax                                     ; E37B AA                       .
        jsr     L927A                           ; E37C 20 7A 92                  z.
        sec                                     ; E37F 38                       8
        jsr     L90CB                           ; E380 20 CB 90                  ..
        bcc     LE388                           ; E383 90 03                    ..
        jmp     L90C3                           ; E385 4C C3 90                 L..
; ----------------------------------------------------------------------------
LE388:  lda     stack+27                        ; E388 AD 1B 01                 ...
        sec                                     ; E38B 38                       8
        jmp     L9268       ; I/O Error Message ; E38C 4C 68 92                 Lh.
; ----------------------------------------------------------------------------

; Default DOS Disk Unit (U8 D0)
        .byte   $FF                             ; E38F FF                       .
        .byte   $FF                             ; E390 FF                       .
LE391:  .byte $ff, $ff

        ;dos logical address
        .byte $00                     ; E391 FF FF 00                 ...


        ; DOS Physical Address
        php                                     ; E394 08                       .

        ;dos secondary address
        ;.byte 6f

; Parse DOS Commands
;TODO incorrect assembly
; should be 6f, then LDA #$00
        bbr6    $A9,LE398                       ; E395 6F A9 00                 o..
LE398:  ldx     #$FF                            ; E398 A2 FF                    ..
        pha                                     ; E39A 48                       H
        txa                                     ; E39B 8A                       .
        pha                                     ; E39C 48                       H


LE39D:  lda     #$00                            ; E39D A9 00                    ..
        sta     $80                             ; E39F 85 80                    ..
        sta     L0081                           ; E3A1 85 81                    ..
        ldx     #$22                            ; E3A3 A2 22                    ."
LE3A5:  sta     stack,x                         ; E3A5 9D 00 01                 ...
        dex                                     ; E3A8 CA                       .
        bne     LE3A5                           ; E3A9 D0 FA                    ..
        ldx     #$06                            ; E3AB A2 06                    ..

LE3AD:  lda     LA38F,x      ; Default DOS Disk Unit (U8 D0)                   ; E3AD BD 8F A3                 ...
        sta     stack+23,x                      ; E3B0 9D 17 01                 ...
        dex                                     ; E3B3 CA                       .
        bpl     LE3AD                           ; E3B4 10 F7                    ..
        ldx     $03D5        ; Current Bank For SYS, POKE, PEEK                   ; E3B6 AE D5 03                 ...
        stx     stack+31                        ; E3B9 8E 1F 01                 ...
        jsr     DFLTO        ; CHRGOT entry                   ; E3BC 20 86 03                  ..
        bne     LE3CF                           ; E3BF D0 0E                    ..
        pla                                     ; E3C1 68                       h
        and     L0081                           ; E3C2 25 81                    %.
        bne     LE431                           ; E3C4 D0 6B                    .k

        pla                                     ; E3C6 68                       h
        jsr     LA5F2                           ; E3C7 20 F2 A5                  ..
        lda     $80                             ; E3CA A5 80                    ..
        ldx     L0081                           ; E3CC A6 81                    ..
        rts                                     ; E3CE 60                       `
; ----------------------------------------------------------------------------
;c128 dissm A3F8
LE3CF:  cmp     #$23                            ; E3CF C9 23                    .#
        beq     LE41E                           ; E3D1 F0 4B                    .K
        cmp     #$57                            ; E3D3 C9 57                    .W
        beq     LE434                           ; E3D5 F0 5D                    .]
        cmp     #$4C                            ; E3D7 C9 4C                    .L
        beq     LE434                           ; E3D9 F0 59                    .Y
        cmp     #$52                            ; E3DB C9 52                    .R
        beq     LE408                           ; E3DD F0 29                    .)
        cmp     #$44                            ; E3DF C9 44                    .D
        beq     LE456                           ; E3E1 F0 73                    .s
        cmp     #$91                            ; E3E3 C9 91                    ..
        beq     LE40E                           ; E3E5 F0 27                    .'
        cmp     #$42                            ; E3E7 C9 42                    .B
        beq     LE419                           ; E3E9 F0 2E                    ..
        cmp     #$55                            ; E3EB C9 55                    .U
        beq     LE414                           ; E3ED F0 25                    .%
        cmp     #$50                            ; E3EF C9 50                    .P
        bne     LE3F6                           ; E3F1 D0 03                    ..
        jmp     LA48B                           ; E3F3 4C 8B A4                 L..
; ----------------------------------------------------------------------------
LE3F6:  cmp     #$49                            ; E3F6 C9 49                    .I
        beq     LE46F                           ; E3F8 F0 75                    .u
        cmp     #$22                            ; E3FA C9 22                    ."
        beq     LE405                           ; E3FC F0 07                    ..
        cmp     #$28                            ; E3FE C9 28                    .(
        beq     LE405                           ; E400 F0 03                    ..
        jmp     L795A                           ; E402 4C 5A 79                 LZy
; ----------------------------------------------------------------------------
LE405:  jmp     LA4B3                           ; E405 4C B3 A4                 L..
; ----------------------------------------------------------------------------
LE408:  jsr     L0380                           ; E408 20 80 03                  ..
        jmp     LA4D2                           ; E40B 4C D2 A4                 L..
; ----------------------------------------------------------------------------
LE40E:  jsr     LA559                           ; E40E 20 59 A5                  Y.
LE411:  jmp     LA4CE                           ; E411 4C CE A4                 L..
; ----------------------------------------------------------------------------
;get device number
LE414:  jsr     LA564                           ; E414 20 64 A5                  d.
        bne     LE411                           ; E417 D0 F8                    ..

;get bank number
LE419:  jsr     LA575                           ; E419 20 75 A5                  u.
        beq     LE411                           ; E41C F0 F3                    ..

;get filenumber
LE41E:  lda     #$04                            ; E41E A9 04                    ..
        jsr     LA5F2                           ; E420 20 F2 A5                  ..
        jsr     LA5C7                           ; E423 20 C7 A5                  ..
        cpx     #$00                            ; E426 E0 00                    ..
        beq     LE46C                           ; E428 F0 42                    .B
        stx     stack+27                        ; E42A 8E 1B 01                 ...
        lda     #$04                            ; E42D A9 04                    ..
        bne     LE411                           ; E42F D0 E0                    ..
LE431:  jmp     L795A                           ; E431 4C 5A 79                 LZy
; ----------------------------------------------------------------------------
; get record length, write mode
LE434:  tax                                     ; E434 AA                       .
        lda     #$40                            ; E435 A9 40                    .@
        jsr     LA5F2                           ; E437 20 F2 A5                  ..
        cpx     #$57                            ; E43A E0 57                    .W
        bne     LE444                           ; E43C D0 06                    ..
        jsr     L0380                           ; E43E 20 80 03                  ..
        jmp     LA452                           ; E441 4C 52 A4                 LR.
; ----------------------------------------------------------------------------
LE444:  jsr     LA5C7                           ; E444 20 C7 A5                  ..
        cpx     #$00                            ; E447 E0 00                    ..
        beq     LE46C                           ; E449 F0 21                    .!
        cpx     #$FF                            ; E44B E0 FF                    ..
        beq     LE46C                           ; E44D F0 1D                    ..
        stx     stack+30                        ; E44F 8E 1E 01                 ...
        lda     #$40                            ; E452 A9 40                    .@
        bne     LE46A                           ; E454 D0 14                    ..

;get drive
LE456:  lda     #$10                            ; E456 A9 10                    ..
        jsr     LA5F2                           ; E458 20 F2 A5                  ..
        jsr     LA5C7                           ; E45B 20 C7 A5                  ..
        cpx     #$02                            ; E45E E0 02                    ..
        bcs     LE46C                           ; E460 B0 0A                    ..
        stx     stack+18                        ; E462 8E 12 01                 ...
        stx     stack+20                        ; E465 8E 14 01                 ...
        lda     #$10                            ; E468 A9 10                    ..
LE46A:  bne     LE4CE                           ; E46A D0 62                    .b
LE46C:  jmp     L7D16                           ; E46C 4C 16 7D                 L.}
; ----------------------------------------------------------------------------
;get format ID
LE46F:  lda     stack+34                        ; E46F AD 22 01                 .".
        bne     LE431                           ; E472 D0 BD                    ..
        jsr     L0380                           ; E474 20 80 03                  ..
        sta     stack+32                        ; E477 8D 20 01                 . .
        jsr     L0380                           ; E47A 20 80 03                  ..
        sta     stack+33                        ; E47D 8D 21 01                 .!.
        lda     #$FF                            ; E480 A9 FF                    ..
        sta     stack+34                        ; E482 8D 22 01                 .".
        jsr     L0380                           ; E485 20 80 03                  ..
        jmp     LA4D2                           ; E488 4C D2 A4                 L..
; ----------------------------------------------------------------------------
;get address
        lda     #$02                            ; E48B A9 02                    ..
        jsr     LA5F7       ; check extented parameter                    ; E48D 20 F7 A5                  ..
        jsr     LA5DA        ; get value                   ; E490 20 DA A5                  ..
        sty     stack+23     ; 16-bit address                   ; E493 8C 17 01                 ...
        sta     stack+24                        ; E496 8D 18 01                 ...
        lda     #$02        ; mark extented parameter                    ; E499 A9 02                    ..
LE49B:  ora     L0081                           ; E49B 05 81                    ..
        sta     L0081                           ; E49D 85 81                    ..
        bne     LE4D2       ; continue parsing                    ; E49F D0 31                    .1
LE4A1:  lda     #$04                            ; E4A1 A9 04                    ..
        jsr     LA5F7       ; check extented parameter                    ; E4A3 20 F7 A5                  ..
        jsr     LA5DA       ; get value                    ; E4A6 20 DA A5                  ..
        sty     stack+25                        ; E4A9 8C 19 01                 ...
        sta     stack+26                        ; E4AC 8D 1A 01                 ...
        lda     #$04                            ; E4AF A9 04                    ..
        bne     LE49B       ; mark extented parameter                    ; E4B1 D0 E8                    ..
        lda     #$01                            ; E4B3 A9 01                    ..
        jsr     LA590      ; get string                     ; E4B5 20 90 A5                  ..
        sta     stack+17   ; save string length                     ; E4B8 8D 11 01                 ...
        ldy     #$00                            ; E4BB A0 00                    ..
LE4BD:  jsr     L03B7     ; Index1 Indirect Fetch From RAM Bank 1 ($24),Y                      ; E4BD 20 B7 03                  ..
        sta     $FF03                           ; E4C0 8D 03 FF                 ...
        sta     $12B7,y    ; copy filename string                     ; E4C3 99 B7 12                 ...
        iny                                     ; E4C6 C8                       .
        cpy     stack+17   ; until length reached                     ; E4C7 CC 11 01                 ...
        bcc     LE4BD                           ; E4CA 90 F1                    ..
        lda     #$01       ; mark parameter                     ; E4CC A9 01                    ..
LE4CE:  ora     $80                             ; E4CE 05 80                    ..
        sta     $80                             ; E4D0 85 80                    ..
LE4D2:  jsr     DFLTO                           ; E4D2 20 86 03                  ..
        bne     LE4F0                           ; E4D5 D0 19                    ..
LE4D7:  jmp     LA3C1                           ; E4D7 4C C1 A3                 L..
; ----------------------------------------------------------------------------
LE4DA:  cmp     #$91                            ; E4DA C9 91                    ..
        bne     LE4E1                           ; E4DC D0 03                    ..
        jmp     LA40E                           ; E4DE 4C 0E A4                 L..
; ----------------------------------------------------------------------------
LE4E1:  cmp     #$A4                            ; E4E1 C9 A4                    ..
        beq     LE4E7                           ; E4E3 F0 02                    ..
        bne     LE554                           ; E4E5 D0 6D                    .m
LE4E7:  jsr     L0380                           ; E4E7 20 80 03                  ..
        cmp     #$50                            ; E4EA C9 50                    .P
        bne     LE4FD                           ; E4EC D0 0F                    ..
        beq     LE4A1                           ; E4EE F0 B1                    ..
LE4F0:  cmp     #$2C                            ; E4F0 C9 2C                    .,
        bne     LE4DA                           ; E4F2 D0 E6                    ..
        jsr     L0380                           ; E4F4 20 80 03                  ..
        jmp     LA3CF                           ; E4F7 4C CF A3                 L..
; ----------------------------------------------------------------------------
LE4FA:  jsr     L0380                           ; E4FA 20 80 03                  ..

;get next parameter
LE4FD:  cmp     #$44                            ; E4FD C9 44                    .D
        beq     LE511                           ; E4FF F0 10                    ..
        cmp     #$91                            ; E501 C9 91                    ..
        beq     LE524                           ; E503 F0 1F                    ..
        cmp     #$55                            ; E505 C9 55                    .U
        beq     LE52A                           ; E507 F0 21                    .!
        cmp     #$22                            ; E509 C9 22                    ."
        beq     LE52F                           ; E50B F0 22                    ."
        cmp     #$28                            ; E50D C9 28                    .(
        beq     LE52F                           ; E50F F0 1E                    ..

;get destination drive
LE511:  lda     #$20                            ; E511 A9 20                    .
        jsr     LA5F2                           ; E513 20 F2 A5                  ..
        jsr     LA5C7                           ; E516 20 C7 A5                  ..
        cpx     #$02                            ; E519 E0 02                    ..
        bcs     LE556                           ; E51B B0 39                    .9
        stx     stack+20                        ; E51D 8E 14 01                 ...
        lda     #$20                            ; E520 A9 20                    .
        bne     LE53F                           ; E522 D0 1B                    ..
LE524:  jsr     LA559                           ; E524 20 59 A5                  Y.
        jmp     LA53F                           ; E527 4C 3F A5                 L?.
; ----------------------------------------------------------------------------
LE52A:  jsr     LA564                           ; E52A 20 64 A5                  d.
        bne     LE53F                           ; E52D D0 10                    ..
LE52F:  lda     #$02                            ; E52F A9 02                    ..
        jsr     LA590                           ; E531 20 90 A5                  ..
        sta     stack+19                        ; E534 8D 13 01                 ...
        stx     stack+21                        ; E537 8E 15 01                 ...
        sty     stack+22                        ; E53A 8C 16 01                 ...
        lda     #$02                            ; E53D A9 02                    ..
LE53F:  ora     $80                             ; E53F 05 80                    ..
        sta     $80                             ; E541 85 80                    ..
        jsr     DFLTO                           ; E543 20 86 03                  ..
        beq     LE4D7                           ; E546 F0 8F                    ..
        cmp     #$2C                            ; E548 C9 2C                    .,
        beq     LE4FA                           ; E54A F0 AE                    ..
        cmp     #$91                            ; E54C C9 91                    ..
        beq     LE524                           ; E54E F0 D4                    ..
        cmp     #$55                            ; E550 C9 55                    .U
        beq     LE52A                           ; E552 F0 D6                    ..
LE554:  bne     LE58D                           ; E554 D0 37                    .7
LE556:  jmp     L7D16                           ; E556 4C 16 7D                 L.}
; ----------------------------------------------------------------------------
        jsr     L0380                           ; E559 20 80 03                  ..
        cmp     #$42                            ; E55C C9 42                    .B
        beq     LE575                           ; E55E F0 15                    ..
        cmp     #$55                            ; E560 C9 55                    .U
        bne     LE58D                           ; E562 D0 29                    .)
        jsr     LA5C7                           ; E564 20 C7 A5                  ..
        cpx     #$1F                            ; E567 E0 1F                    ..
        bcs     LE5BE                           ; E569 B0 53                    .S
        cpx     #$04                            ; E56B E0 04                    ..
        bcc     LE5BE                           ; E56D 90 4F                    .O
        stx     stack+28                        ; E56F 8E 1C 01                 ...
        lda     #$08                            ; E572 A9 08                    ..
        rts                                     ; E574 60                       `
; ----------------------------------------------------------------------------
LE575:  lda     #$01                            ; E575 A9 01                    ..
        jsr     LA5F7                           ; E577 20 F7 A5                  ..
        jsr     LA5C7                           ; E57A 20 C7 A5                  ..
        cpx     #$10                            ; E57D E0 10                    ..
        bcs     LE556                           ; E57F B0 D5                    ..
        stx     stack+31                        ; E581 8E 1F 01                 ...
        lda     #$01                            ; E584 A9 01                    ..
        ora     L0081                           ; E586 05 81                    ..
        sta     L0081                           ; E588 85 81                    ..
        lda     #$00                            ; E58A A9 00                    ..
        rts                                     ; E58C 60                       `
; ----------------------------------------------------------------------------
LE58D:  jmp     L795A                           ; E58D 4C 5A 79                 LZy
; ----------------------------------------------------------------------------

;get string (filename)
        jsr     LA5F2                           ; E590 20 F2 A5                  ..
        jsr     $8777                           ; E593 20 77 87                  w.
        tax                                     ; E596 AA                       .
        beq     LE556                           ; E597 F0 BD                    ..
        ldy     #$00                            ; E599 A0 00                    ..
        jsr     L03B7                           ; E59B 20 B7 03                  ..
        cmp     #$40                            ; E59E C9 40                    .@
        bne     LE5B4                           ; E5A0 D0 12                    ..
        lda     #$80                            ; E5A2 A9 80                    ..
        jsr     LA5F2                           ; E5A4 20 F2 A5                  ..
        lda     $80                             ; E5A7 A5 80                    ..
        ora     #$80                            ; E5A9 09 80                    ..
        sta     $80                             ; E5AB 85 80                    ..
        dex                                     ; E5AD CA                       .
        inc     $24                             ; E5AE E6 24                    .$
        bne     LE5B4                           ; E5B0 D0 02                    ..
        inc     $25                             ; E5B2 E6 25                    .%
LE5B4:  txa                                     ; E5B4 8A                       .
        cmp     #$11                            ; E5B5 C9 11                    ..
        bcs     LE5C2                           ; E5B7 B0 09                    ..
        ldx     $24                             ; E5B9 A6 24                    .$
        ldy     $25                             ; E5BB A4 25                    .%
        rts                                     ; E5BD 60                       `
; ----------------------------------------------------------------------------

;Print 'missing file name'
;TODO in c128 disasm, not in this one

;Print 'illegal device number'
;TODO does not match c128 disasm exactls

LE5BE:  ldx     #$09                            ; E5BE A2 09                    ..
        bne     LE5C4                           ; E5C0 D0 02                    ..

;Print 'string too long'

LE5C2:  ldx     #$17                            ; E5C2 A2 17                    ..
LE5C4:  jmp     L4D39                           ; E5C4 4C 39 4D                 L9M
; ----------------------------------------------------------------------------
        jsr     L0380                           ; E5C7 20 80 03                  ..
        beq     LE58D                           ; E5CA F0 C1                    ..
        bcc     LE5D7                           ; E5CC 90 09                    ..
        jsr     L7947                           ; E5CE 20 47 79                  Gy
        jsr     L87F0                           ; E5D1 20 F0 87                  ..
        jmp     L7944                           ; E5D4 4C 44 79                 LDy
; ----------------------------------------------------------------------------
LE5D7:  jmp     L87F0                           ; E5D7 4C F0 87                 L..
; ----------------------------------------------------------------------------
        jsr     L0380                           ; E5DA 20 80 03                  ..
        beq     LE58D                           ; E5DD F0 AE                    ..
        bcc     LE5EF                           ; E5DF 90 0E                    ..
        jsr     L7947                           ; E5E1 20 47 79                  Gy
        jsr     L880E                           ; E5E4 20 0E 88                  ..
        jsr     L7944                           ; E5E7 20 44 79                  Dy
        ldy     $16                             ; E5EA A4 16                    ..
        lda     $17                             ; E5EC A5 17                    ..
        rts                                     ; E5EE 60                       `
; ----------------------------------------------------------------------------
LE5EF:  jmp     L880E                           ; E5EF 4C 0E 88                 L..
; ----------------------------------------------------------------------------
        and     $80                             ; E5F2 25 80                    %.
        bne     LE58D                           ; E5F4 D0 97                    ..
        rts                                     ; E5F6 60                       `
; ----------------------------------------------------------------------------
        and     L0081                           ; E5F7 25 81                    %.
        bne     LE58D                           ; E5F9 D0 92                    ..
        rts                                     ; E5FB 60                       `
; ----------------------------------------------------------------------------
; DOS Command Masks
;this is data
        eor     #$D1                            ; E5FC 49 D1                    I.
        bit     $D1                             ; E5FE 24 D1                    $.
        dec     a                               ; E600 3A                       :
        sbc     ($F0),y                         ; E601 F1 F0                    ..
        cmp     ($3A),y                         ; E603 D1 3A                    .:
        sbc     ($2C),y                         ; E605 F1 2C                    .,
        sbc     ($2C,x)                         ; E607 E1 2C                    .,
        cpx     #$43                            ; E609 E0 43                    .C
LE60B:  cmp     ($3A)                           ; E60B D2 3A                    .:
        sbc     ($3D)                           ; E60D F2 3D                    .=
        cmp     ($3A)                           ; E60F D2 3A                    .:
        sbc     ($2C)                           ; E611 F2 2C                    .,
        cmp     ($3A),y                         ; E613 D1 3A                    .:
        sbc     ($2C),y                         ; E615 F1 2C                    .,
        eor     (L004E,x)                       ; E617 41 4E                    AN
        cmp     ($3A),y                         ; E619 D1 3A                    .:
        sbc     ($2C),y                         ; E61B F1 2C                    .,
        bne     LE675                           ; E61D D0 56                    .V
        cmp     ($44),y                         ; E61F D1 44                    .D
        cmp     ($3D)                           ; E621 D2 3D                    .=
        cmp     ($43),y                         ; E623 D1 43                    .C
        cmp     ($3A)                           ; E625 D2 3A                    .:
        sbc     ($3D)                           ; E627 F2 3D                    .=
        cmp     ($3A),y                         ; E629 D1 3A                    .:
        sbc     ($52),y                         ; E62B F1 52                    .R
        cmp     ($3A),y                         ; E62D D1 3A                    .:
        sbc     ($3D)                           ; E62F F2 3D                    .=
        cmp     ($3A),y                         ; E631 D1 3A                    .:
        sbc     ($53),y                         ; E633 F1 53                    .S
        cmp     ($3A),y                         ; E635 D1 3A                    .:
        sbc     ($50),y                         ; E637 F1 50                    .P
        .byte   $C2                             ; E639 C2                       .
        .byte   $E2                             ; E63A E2                       .
;incorrect disassembly here
;see $a667 in c128 disasm
; Set DOS Parameters
        cpx     #$8D                            ; E63B E0 8D                    ..
        bpl     LE640                           ; E63D 10 01                    ..
        tya                                     ; E63F 98                       .
LE640:  pha                                     ; E640 48                       H
        jsr     LA7E2                           ; E641 20 E2 A7                  ..
        ldx     #$00                            ; E644 A2 00                    ..
LE646:  pla                                     ; E646 68                       h
        dec     stack+16                        ; E647 CE 10 01                 ...
        bmi     LE694                           ; E64A 30 48                    0H
        tay                                     ; E64C A8                       .
        iny                                     ; E64D C8                       .
        tya                                     ; E64E 98                       .
        pha                                     ; E64F 48                       H
        lda     LA5FC,y                         ; E650 B9 FC A5                 ...
        bpl     LE68C                           ; E653 10 37                    .7
        cmp     #$C2                            ; E655 C9 C2                    ..
        beq     LE6AB                           ; E657 F0 52                    .R
        cmp     #$D0                            ; E659 C9 D0                    ..
        beq     LE6BA                           ; E65B F0 5D                    .]
        cmp     #$E2                            ; E65D C9 E2                    ..
        beq     LE6D8                           ; E65F F0 77                    .w
        cmp     #$E1                            ; E661 C9 E1                    ..
        beq     LE6C6                           ; E663 F0 61                    .a
        cmp     #$F0                            ; E665 C9 F0                    ..
        beq     LE6B0                           ; E667 F0 47                    .G
        cmp     #$F1                            ; E669 C9 F1                    ..
        beq     LE6E2                           ; E66B F0 75                    .u
        cmp     #$F2                            ; E66D C9 F2                    ..
        beq     LE692                           ; E66F F0 21                    .!
        cmp     #$E0                            ; E671 C9 E0                    ..
        bne     LE67A                           ; E673 D0 05                    ..
LE675:  lda     stack+30                        ; E675 AD 1E 01                 ...
        bne     LE68C                           ; E678 D0 12                    ..
LE67A:  cmp     #$D1                            ; E67A C9 D1                    ..
        bne     LE683                           ; E67C D0 05                    ..
        lda     stack+18                        ; E67E AD 12 01                 ...
        bpl     LE68A                           ; E681 10 07                    ..
LE683:  cmp     #$D2                            ; E683 C9 D2                    ..
        bne     LE646                           ; E685 D0 BF                    ..
        lda     stack+20                        ; E687 AD 14 01                 ...
LE68A:  ora     #$30                            ; E68A 09 30                    .0
LE68C:  sta     $1100,x                         ; E68C 9D 00 11                 ...
        inx                                     ; E68F E8                       .
        bne     LE646                           ; E690 D0 B4                    ..
LE692:  beq     LE6F8                           ; E692 F0 64                    .d

; setup file parameters
LE694:  txa                                     ; E694 8A                       .
        pha                                     ; E695 48                       H
        ldx     #$00                            ; E696 A2 00                    ..
        ldy     #$11                            ; E698 A0 11                    ..
        jsr     L9250                           ; E69A 20 50 92                  P.
        lda     stack+27                        ; E69D AD 1B 01                 ...
        ldx     stack+28                        ; E6A0 AE 1C 01                 ...
        ldy     stack+29                        ; E6A3 AC 1D 01                 ...
        jsr     L924A                           ; E6A6 20 4A 92                  J.
        pla                                     ; E6A9 68                       h
        rts                                     ; E6AA 60                       `
; ----------------------------------------------------------------------------
;Placeholder expand actions

LE6AB:  lda     $11ED                           ; E6AB AD ED 11                 ...
        bne     LE68C                           ; E6AE D0 DC                    ..
LE6B0:  bit     $80                             ; E6B0 24 80                    $.
        bmi     LE6B6                           ; E6B2 30 02                    0.
        bpl     LE646                           ; E6B4 10 90                    ..
LE6B6:  lda     #$40                            ; E6B6 A9 40                    .@
        bne     LE68C                           ; E6B8 D0 D2                    ..
LE6BA:  lda     stack+32                        ; E6BA AD 20 01                 . .
        sta     $1100,x                         ; E6BD 9D 00 11                 ...
        inx                                     ; E6C0 E8                       .
        lda     stack+33                        ; E6C1 AD 21 01                 .!.
        bne     LE68C                           ; E6C4 D0 C6                    ..
LE6C6:  lda     stack+30                        ; E6C6 AD 1E 01                 ...
        beq     LE6CF                           ; E6C9 F0 04                    ..
        lda     #$4C                            ; E6CB A9 4C                    .L
        bne     LE68C                           ; E6CD D0 BD                    ..
LE6CF:  lda     #$53                            ; E6CF A9 53                    .S
        sta     stack+30                        ; E6D1 8D 1E 01                 ...
        lda     #$57                            ; E6D4 A9 57                    .W
        bne     LE68C                           ; E6D6 D0 B4                    ..
LE6D8:  lda     $16                             ; E6D8 A5 16                    ..
        sta     $1100,x                         ; E6DA 9D 00 11                 ...
        lda     $17                             ; E6DD A5 17                    ..
        inx                                     ; E6DF E8                       .
        bne     LE68C                           ; E6E0 D0 AA                    ..
LE6E2:  ldy     stack+17                        ; E6E2 AC 11 01                 ...
        beq     LE71A                           ; E6E5 F0 33                    .3
        ldy     #$00                            ; E6E7 A0 00                    ..
LE6E9:  lda     $12B7,y                         ; E6E9 B9 B7 12                 ...
        sta     $1100,x                         ; E6EC 9D 00 11                 ...
        inx                                     ; E6EF E8                       .
        iny                                     ; E6F0 C8                       .
        cpy     stack+17                        ; E6F1 CC 11 01                 ...
        bne     LE6E9                           ; E6F4 D0 F3                    ..
        beq     LE71B                           ; E6F6 F0 23                    .#
LE6F8:  lda     stack+21                        ; E6F8 AD 15 01                 ...
        sta     $24                             ; E6FB 85 24                    .$
        lda     stack+22                        ; E6FD AD 16 01                 ...
        sta     $25                             ; E700 85 25                    .%
        ldy     stack+19                        ; E702 AC 13 01                 ...
        beq     LE71A                           ; E705 F0 13                    ..
        ldy     #$00                            ; E707 A0 00                    ..
LE709:  jsr     L03B7                           ; E709 20 B7 03                  ..
        sta     $FF03                           ; E70C 8D 03 FF                 ...
        sta     $1100,x                         ; E70F 9D 00 11                 ...
        inx                                     ; E712 E8                       .
        iny                                     ; E713 C8                       .
        cpy     stack+19                        ; E714 CC 13 01                 ...
        bne     LE709                           ; E717 D0 F0                    ..
        .byte   $24                             ; E719 24                       $
LE71A:  dex                                     ; E71A CA                       .
LE71B:  jmp     LA646                           ; E71B 4C 46 A6                 LF.
; ----------------------------------------------------------------------------
        and     #$E6                            ; E71E 29 E6                    ).
        beq     LE725                           ; E720 F0 03                    ..
LE722:  jmp     L795A                           ; E722 4C 5A 79                 LZy
; ----------------------------------------------------------------------------

;check for filename given

LE725:  lda     $80                             ; E725 A5 80                    ..
        and     #$01                            ; E727 29 01                    ).
        cmp     #$01                            ; E729 C9 01                    ..
        bne     LE722                           ; E72B D0 F5                    ..
        lda     $80                             ; E72D A5 80                    ..
        rts                                     ; E72F 60                       `
; ----------------------------------------------------------------------------
        and     #$E7                            ; E730 29 E7                    ).
        bne     LE722                           ; E732 D0 EE                    ..
        rts                                     ; E734 60                       `
; ----------------------------------------------------------------------------
        and     #$C4                            ; E735 29 C4                    ).
        bne     LE722                           ; E737 D0 E9                    ..
        lda     $80                             ; E739 A5 80                    ..
        and     #$03                            ; E73B 29 03                    ).
        cmp     #$03                            ; E73D C9 03                    ..
        bne     LE722                           ; E73F D0 E1                    ..
        lda     $80                             ; E741 A5 80                    ..
        rts                                     ; E743 60                       `
; ----------------------------------------------------------------------------
        and     #$05                            ; E744 29 05                    ).
        cmp     #$05                            ; E746 C9 05                    ..
        bne     LE722                           ; E748 D0 D8                    ..
        lda     $80                             ; E74A A5 80                    ..
        rts                                     ; E74C 60                       `
; ----------------------------------------------------------------------------

; Get floppy error channel

        lda     $7A                             ; E74D A5 7A                    .z
        bne     LE76A                           ; E74F D0 19                    ..
        lda     #$28                            ; E751 A9 28                    .(
        sta     $7A                             ; E753 85 7A                    .z
        jsr     L928C                           ; E755 20 8C 92                  ..
        stx     $7B                             ; E758 86 7B                    .{
        sty     $7C                             ; E75A 84 7C                    .|
        ldy     #$28                            ; E75C A0 28                    .(
        sta     $FF04                           ; E75E 8D 04 FF                 ...
        lda     #$7A                            ; E761 A9 7A                    .z
        sta     ($7B),y                         ; E763 91 7B                    .{
        iny                                     ; E765 C8                       .
        lda     #$00                            ; E766 A9 00                    ..
        sta     ($7B),y                         ; E768 91 7B                    .{
LE76A:  ldx     stack+28                        ; E76A AE 1C 01                 ...
        bne     LE774                           ; E76D D0 05                    ..
        ldx     #$08                            ; E76F A2 08                    ..
        stx     stack+28                        ; E771 8E 1C 01                 ...
LE774:  lda     #$00                            ; E774 A9 00                    ..
        ldy     #$6F                            ; E776 A0 6F                    .o
        jsr     L924A                           ; E778 20 4A 92                  J.
        lda     #$00                            ; E77B A9 00                    ..
        jsr     L9250                           ; E77D 20 50 92                  P.
        jsr     L90CB                           ; E780 20 CB 90                  ..
        ldx     #$00                            ; E783 A2 00                    ..
        jsr     LFFC6_CHKIN                           ; E785 20 C6 FF                  ..
        bcs     LE7AA                           ; E788 B0 20                    .
        ldy     #$FF                            ; E78A A0 FF                    ..
LE78C:  iny                                     ; E78C C8                       .
        jsr     L9256                           ; E78D 20 56 92                  V.
        sta     $FF04                           ; E790 8D 04 FF                 ...
        cmp     #$0D                            ; E793 C9 0D                    ..
        beq     LE79D                           ; E795 F0 06                    ..
        sta     ($7B),y                         ; E797 91 7B                    .{
        cpy     #$28                            ; E799 C0 28                    .(
        bcc     LE78C                           ; E79B 90 EF                    ..
LE79D:  lda     #$00                            ; E79D A9 00                    ..
        sta     ($7B),y                         ; E79F 91 7B                    .{
        jsr     L9262                           ; E7A1 20 62 92                  b.
        lda     #$00                            ; E7A4 A9 00                    ..
        sec                                     ; E7A6 38                       8
        jmp     L9268                           ; E7A7 4C 68 92                 Lh.
; ----------------------------------------------------------------------------
LE7AA:  pha                                     ; E7AA 48                       H
        jsr     LA79D                           ; E7AB 20 9D A7                  ..
        jsr     LA7E2                           ; E7AE 20 E2 A7                  ..
        pla                                     ; E7B1 68                       h
        tax                                     ; E7B2 AA                       .
        jmp     L4D39                           ; E7B3 4C 39 4D                 L9M
; ----------------------------------------------------------------------------

; Print 'are you sure'

        bit     $7F                             ; E7B6 24 7F                    $.
        bmi     LE7DF                           ; E7B8 30 25                    0%
        jsr     L9274                           ; E7BA 20 74 92                  t.
        .byte   "ARE YOU SURE?"                 ; E7BD 41 52 45 20 59 4F 55 20  ARE YOU
                                                ; E7C5 53 55 52 45 3F           SURE?
        .byte   $00                             ; E7CA 00                       .
; ----------------------------------------------------------------------------
        jsr     L9262                           ; E7CB 20 62 92                  b.
        jsr     L9256                           ; E7CE 20 56 92                  V.
        pha                                     ; E7D1 48                       H
LE7D2:  cmp     #$0D                            ; E7D2 C9 0D                    ..
        beq     LE7DB                           ; E7D4 F0 05                    ..
        jsr     L9256                           ; E7D6 20 56 92                  V.
        bne     LE7D2                           ; E7D9 D0 F7                    ..
LE7DB:  pla                                     ; E7DB 68                       h
        cmp     #$59                            ; E7DC C9 59                    .Y
        rts                                     ; E7DE 60                       `
; ----------------------------------------------------------------------------
LE7DF:  lda     #$00                            ; E7DF A9 00                    ..
        rts                                     ; E7E1 60                       `
; ----------------------------------------------------------------------------
        tya                                     ; E7E2 98                       .
        pha                                     ; E7E3 48                       H
        lda     $7A                             ; E7E4 A5 7A                    .z
        beq     LE7F5                           ; E7E6 F0 0D                    ..
        ldy     #$28                            ; E7E8 A0 28                    .(
        tya                                     ; E7EA 98                       .
        sta     $FF04                           ; E7EB 8D 04 FF                 ...
        sta     ($7B),y                         ; E7EE 91 7B                    .{
        iny                                     ; E7F0 C8                       .
        lda     #$FF                            ; E7F1 A9 FF                    ..
        sta     ($7B),y                         ; E7F3 91 7B                    .{
LE7F5:  lda     #$00                            ; E7F5 A9 00                    ..
        sta     $FF03                           ; E7F7 8D 03 FF                 ...
        sta     $7A                             ; E7FA 85 7A                    .z
        pla                                     ; E7FC 68                       h
        tay                                     ; E7FD A8                       .
        rts                                     ; E7FE 60                       `
; ----------------------------------------------------------------------------
        bit     $2030                           ; E7FF 2C 30 20                 ,0
        eor     $4B45,y                         ; E802 59 45 4B                 YEK
        tax                                     ; E805 AA                       .
        tya                                     ; E806 98                       .
        pha                                     ; E807 48                       H
        lda     #$00                            ; E808 A9 00                    ..
        jsr     L8E25                           ; E80A 20 25 8E                  %.
        pla                                     ; E80D 68                       h
        tay                                     ; E80E A8                       .
        rts                                     ; E80F 60                       `
; ----------------------------------------------------------------------------
        sta     $3C                             ; E810 85 3C                    .<
        dey                                     ; E812 88                       .
        tax                                     ; E813 AA                       .
        inx                                     ; E814 E8                       .
        bne     LE819                           ; E815 D0 02                    ..
        stx     $7F                             ; E817 86 7F                    ..
LE819:  rts                                     ; E819 60                       `
; ----------------------------------------------------------------------------
        pha                                     ; E81A 48                       H
        lda     #$00                            ; E81B A9 00                    ..
        sta     MMU_KERN_WINDOW                 ; E81D 8D 00 FF                 ...
        pla                                     ; E820 68                       h
        rts                                     ; E821 60                       `
; ----------------------------------------------------------------------------
        ldx     #$10                            ; E822 A2 10                    ..
LE824:  lda     $11D6,x                         ; E824 BD D6 11                 ...
        sta     LD000,x                         ; E827 9D 00 D0                 ...
        dex                                     ; E82A CA                       .
        bpl     LE824                           ; E82B 10 F7                    ..
        ldy     #$07                            ; E82D A0 07                    ..
LE82F:  lda     LD015                           ; E82F AD 15 D0                 ...
        and     $6CA0,y                         ; E832 39 A0 6C                 9.l
        beq     LE86F                           ; E835 F0 38                    .8
        ldx     $6DC6,y                         ; E837 BE C6 6D                 ..m
        lda     $117E,x                         ; E83A BD 7E 11                 .~.
        beq     LE86F                           ; E83D F0 30                    .0
        sta     $117F,x                         ; E83F 9D 7F 11                 ...
LE842:  tya                                     ; E842 98                       .
        asl     a                               ; E843 0A                       .
        tay                                     ; E844 A8                       .
        lda     $1180,x                         ; E845 BD 80 11                 ...
        sec                                     ; E848 38                       8
        sbc     #$01                            ; E849 E9 01                    ..
        inx                                     ; E84B E8                       .
        inx                                     ; E84C E8                       .
        iny                                     ; E84D C8                       .
        jsr     LA9BA                           ; E84E 20 BA A9                  ..
        dex                                     ; E851 CA                       .
        dex                                     ; E852 CA                       .
        dey                                     ; E853 88                       .
        lda     $1180,x                         ; E854 BD 80 11                 ...
        jsr     LA9BA                           ; E857 20 BA A9                  ..
        php                                     ; E85A 08                       .
        tya                                     ; E85B 98                       .
        lsr     a                               ; E85C 4A                       J
        tay                                     ; E85D A8                       .
        plp                                     ; E85E 28                       (
        bcc     LE86A                           ; E85F 90 09                    ..
        lda     $11E6                           ; E861 AD E6 11                 ...
        eor     $6CA0,y                         ; E864 59 A0 6C                 Y.l
        sta     $11E6                           ; E867 8D E6 11                 ...
LE86A:  dec     $117F,x                         ; E86A DE 7F 11                 ...
        bne     LE842                           ; E86D D0 D3                    ..
LE86F:  dey                                     ; E86F 88                       .
        bpl     LE82F                           ; E870 10 BD                    ..
        lda     LD019                           ; E872 AD 19 D0                 ...
        sta     LD019                           ; E875 8D 19 D0                 ...
        and     #$0E                            ; E878 29 0E                    ).
        beq     LE8C0                           ; E87A F0 44                    .D
        lsr     a                               ; E87C 4A                       J
        ldy     #$01                            ; E87D A0 01                    ..
LE87F:  lsr     a                               ; E87F 4A                       J
        bcc     LE8A2                           ; E880 90 20                    .
        pha                                     ; E882 48                       H
        lda     LD01E,y                         ; E883 B9 1E D0                 ...
        ora     $11E7,y                         ; E886 19 E7 11                 ...
        sta     $11E7,y                         ; E889 99 E7 11                 ...
        lda     #$00                            ; E88C A9 00                    ..
        sta     LD01E,y                         ; E88E 99 1E D0                 ...
        lda     $127F                           ; E891 AD 7F 12                 ...
        cpy     #$00                            ; E894 C0 00                    ..
        beq     LE899                           ; E896 F0 01                    ..
        lsr     a                               ; E898 4A                       J
LE899:  lsr     a                               ; E899 4A                       J
        bcc     LE8A1                           ; E89A 90 05                    ..
        lda     #$FF                            ; E89C A9 FF                    ..
        sta     $1276,y                         ; E89E 99 76 12                 .v.
LE8A1:  pla                                     ; E8A1 68                       h
LE8A2:  dey                                     ; E8A2 88                       .
        bpl     LE87F                           ; E8A3 10 DA                    ..
        lsr     a                               ; E8A5 4A                       J
        bcc     LE8C0                           ; E8A6 90 18                    ..
        lda     LD013                           ; E8A8 AD 13 D0                 ...
        sta     $11E9                           ; E8AB 8D E9 11                 ...
        lda     LD014                           ; E8AE AD 14 D0                 ...
        sta     $11EA                           ; E8B1 8D EA 11                 ...
        lda     $127F                           ; E8B4 AD 7F 12                 ...
        and     #$04                            ; E8B7 29 04                    ).
        beq     LE8C0                           ; E8B9 F0 05                    ..
        lda     #$FF                            ; E8BB A9 FF                    ..
        sta     $1278                           ; E8BD 8D 78 12                 .x.
LE8C0:  ldx     #$00                            ; E8C0 A2 00                    ..
LE8C2:  lda     $1224,x                         ; E8C2 BD 24 12                 .$.
        bmi     LE8EE                           ; E8C5 30 27                    0'
        lda     $1223,x                         ; E8C7 BD 23 12                 .#.
        sec                                     ; E8CA 38                       8
        sbc     $1222                           ; E8CB ED 22 12                 .".
        sta     $1223,x                         ; E8CE 9D 23 12                 .#.
        bcs     LE8EE                           ; E8D1 B0 1B                    ..
        lda     $1224,x                         ; E8D3 BD 24 12                 .$.
        sbc     #$00                            ; E8D6 E9 00                    ..
        sta     $1224,x                         ; E8D8 9D 24 12                 .$.
        bcs     LE8EE                           ; E8DB B0 11                    ..
        txa                                     ; E8DD 8A                       .
        lsr     a                               ; E8DE 4A                       J
        tay                                     ; E8DF A8                       .
        lda     $1230,y                         ; E8E0 B9 30 12                 .0.
        and     #$FE                            ; E8E3 29 FE                    ).
        pha                                     ; E8E5 48                       H
        lda     $7026,y                         ; E8E6 B9 26 70                 .&p
        tay                                     ; E8E9 A8                       .
        pla                                     ; E8EA 68                       h
        sta     LD404,y                         ; E8EB 99 04 D4                 ...
LE8EE:  inx                                     ; E8EE E8                       .
        inx                                     ; E8EF E8                       .
        cpx     #$06                            ; E8F0 E0 06                    ..
        bne     LE8C2                           ; E8F2 D0 CE                    ..
        ldy     #$02                            ; E8F4 A0 02                    ..
LE8F6:  lda     $1285,y                         ; E8F6 B9 85 12                 ...
        bpl     LE8FF                           ; E8F9 10 04                    ..
        dey                                     ; E8FB 88                       .
        bpl     LE8F6                           ; E8FC 10 F8                    ..
        rts                                     ; E8FE 60                       `
; ----------------------------------------------------------------------------
LE8FF:  clc                                     ; E8FF 18                       .
        lda     $129D,y                         ; E900 B9 9D 12                 ...
        adc     $1297,y                         ; E903 79 97 12                 y..
        sta     $129D,y                         ; E906 99 9D 12                 ...
        lda     $12A0,y                         ; E909 B9 A0 12                 ...
        adc     $129A,y                         ; E90C 79 9A 12                 y..
        sta     $12A0,y                         ; E90F 99 A0 12                 ...
        lda     $1294,y                         ; E912 B9 94 12                 ...
        tax                                     ; E915 AA                       .
        and     #$01                            ; E916 29 01                    ).
        beq     LE948                           ; E918 F0 2E                    ..
        bcc     LE92B                           ; E91A 90 0F                    ..
        sec                                     ; E91C 38                       8
        lda     $129D,y                         ; E91D B9 9D 12                 ...
        sbc     $128E,y                         ; E920 F9 8E 12                 ...
        lda     $12A0,y                         ; E923 B9 A0 12                 ...
        sbc     $1291,y                         ; E926 F9 91 12                 ...
        bcs     LE978                           ; E929 B0 4D                    .M
LE92B:  cpx     #$02                            ; E92B E0 02                    ..
        bcc     LE939                           ; E92D 90 0A                    ..
        jsr     LA9A4                           ; E92F 20 A4 A9                  ..
        lda     #$02                            ; E932 A9 02                    ..
        sta     $1294,y                         ; E934 99 94 12                 ...
        bne     LE96C                           ; E937 D0 33                    .3
LE939:  lda     $1288,y                         ; E939 B9 88 12                 ...
        sta     $129D,y                         ; E93C 99 9D 12                 ...
        lda     $128B,y                         ; E93F B9 8B 12                 ...
        sta     $12A0,y                         ; E942 99 A0 12                 ...
        jmp     LA978                           ; E945 4C 78 A9                 Lx.
; ----------------------------------------------------------------------------
LE948:  bcs     LE95E                           ; E948 B0 14                    ..
        lda     $12A0,y                         ; E94A B9 A0 12                 ...
        cmp     $128B,y                         ; E94D D9 8B 12                 ...
        bcc     LE978                           ; E950 90 26                    .&
        bne     LE95E                           ; E952 D0 0A                    ..
        lda     $129D,y                         ; E954 B9 9D 12                 ...
        cmp     $1288,y                         ; E957 D9 88 12                 ...
        bcc     LE978                           ; E95A 90 1C                    ..
        beq     LE978                           ; E95C F0 1A                    ..
LE95E:  cpx     #$02                            ; E95E E0 02                    ..
        bcc     LE96C                           ; E960 90 0A                    ..
        jsr     LA9A4                           ; E962 20 A4 A9                  ..
        lda     #$03                            ; E965 A9 03                    ..
        sta     $1294,y                         ; E967 99 94 12                 ...
        bne     LE939                           ; E96A D0 CD                    ..
LE96C:  lda     $128E,y                         ; E96C B9 8E 12                 ...
        sta     $129D,y                         ; E96F 99 9D 12                 ...
        lda     $1291,y                         ; E972 B9 91 12                 ...
        sta     $12A0,y                         ; E975 99 A0 12                 ...
LE978:  ldx     $7026,y                         ; E978 BE 26 70                 .&p
        lda     $129D,y                         ; E97B B9 9D 12                 ...
        sta     LD400,x                         ; E97E 9D 00 D4                 ...
        lda     $12A0,y                         ; E981 B9 A0 12                 ...
        sta     LD401,x                         ; E984 9D 01 D4                 ...
        tya                                     ; E987 98                       .
        tax                                     ; E988 AA                       .
        lda     $1282,x                         ; E989 BD 82 12                 ...
        bne     LE991                           ; E98C D0 03                    ..
        dec     $1285,x                         ; E98E DE 85 12                 ...
LE991:  dec     $1282,x                         ; E991 DE 82 12                 ...
        lda     $1285,x                         ; E994 BD 85 12                 ...
        bpl     LE9A1                           ; E997 10 08                    ..
        lda     #$08                            ; E999 A9 08                    ..
        ldx     $7026,y                         ; E99B BE 26 70                 .&p
        sta     LD404,x                         ; E99E 9D 04 D4                 ...
LE9A1:  jmp     LA8FB                           ; E9A1 4C FB A8                 L..
; ----------------------------------------------------------------------------
        lda     $1297,y                         ; E9A4 B9 97 12                 ...
        eor     #$FF                            ; E9A7 49 FF                    I.
        clc                                     ; E9A9 18                       .
        adc     #$01                            ; E9AA 69 01                    i.
        sta     $1297,y                         ; E9AC 99 97 12                 ...
        lda     $129A,y                         ; E9AF B9 9A 12                 ...
        eor     #$FF                            ; E9B2 49 FF                    I.
        adc     #$00                            ; E9B4 69 00                    i.
        sta     $129A,y                         ; E9B6 99 9A 12                 ...
        rts                                     ; E9B9 60                       `
; ----------------------------------------------------------------------------
        pha                                     ; E9BA 48                       H
        clc                                     ; E9BB 18                       .
        lda     $1181,x                         ; E9BC BD 81 11                 ...
        adc     $1185,x                         ; E9BF 7D 85 11                 }..
        sta     $1185,x                         ; E9C2 9D 85 11                 ...
        lda     $1182,x                         ; E9C5 BD 82 11                 ...
        adc     $1186,x                         ; E9C8 7D 86 11                 }..
        sta     $1186,x                         ; E9CB 9D 86 11                 ...
        pla                                     ; E9CE 68                       h
        bcc     LE9E4                           ; E9CF 90 13                    ..
        lsr     a                               ; E9D1 4A                       J
        lsr     a                               ; E9D2 4A                       J
        lda     $11D6,y                         ; E9D3 B9 D6 11                 ...
        bcs     LE9DD                           ; E9D6 B0 05                    ..
        adc     #$01                            ; E9D8 69 01                    i.
        jmp     LA9E1                           ; E9DA 4C E1 A9                 L..
; ----------------------------------------------------------------------------
LE9DD:  sbc     #$01                            ; E9DD E9 01                    ..
        cmp     #$FF                            ; E9DF C9 FF                    ..
        sta     $11D6,y                         ; E9E1 99 D6 11                 ...
LE9E4:  rts                                     ; E9E4 60                       `
; ----------------------------------------------------------------------------
        lda     #$84                            ; E9E5 A9 84                    ..
        jmp     LA9F1                           ; E9E7 4C F1 A9                 L..
; ----------------------------------------------------------------------------
        lda     #$85                            ; E9EA A9 85                    ..
        jmp     LA9F1                           ; E9EC 4C F1 A9                 L..
; ----------------------------------------------------------------------------
        lda     #$86                            ; E9EF A9 86                    ..
        pha                                     ; E9F1 48                       H
        jsr     L880E                           ; E9F2 20 0E 88                  ..
        jsr     LA81A                           ; E9F5 20 1A A8                  ..
        sty     LDF07                           ; E9F8 8C 07 DF                 ...
        sta     LDF08                           ; E9FB 8D 08 DF                 ...
        jsr     L880B                           ; E9FE 20 0B 88                  ..
        jsr     LA81A                           ; EA01 20 1A A8                  ..
        sty     LDF02                           ; EA04 8C 02 DF                 ...
        sta     LDF03                           ; EA07 8D 03 DF                 ...
        jsr     L880B                           ; EA0A 20 0B 88                  ..
        jsr     LA81A                           ; EA0D 20 1A A8                  ..
        sty     LDF04                           ; EA10 8C 04 DF                 ...
        sta     LDF05                           ; EA13 8D 05 DF                 ...
        jsr     L8805                           ; EA16 20 05 88                  ..
        cpx     #$10                            ; EA19 E0 10                    ..
        bcs     LEA2B                           ; EA1B B0 0E                    ..
        jsr     LA81A                           ; EA1D 20 1A A8                  ..
        stx     LDF06                           ; EA20 8E 06 DF                 ...
        pla                                     ; EA23 68                       h
        tay                                     ; EA24 A8                       .
        ldx     $03D5                           ; EA25 AE D5 03                 ...
        jmp     C128_FF50_DMACALL               ; EA28 4C 50 FF                 LP.
; ----------------------------------------------------------------------------
LEA2B:  jmp     L7D16                           ; EA2B 4C 16 7D                 L.}
; ----------------------------------------------------------------------------
;Unused
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EA2E FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EA36 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EA3E FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EA46 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EA4E FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EA56 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EA5E FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EA66 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EA6E FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EA76 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EA7E FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EA86 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EA8E FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EA96 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EA9E FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EAA6 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EAAE FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EAB6 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EABE FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EAC6 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EACE FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EAD6 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EADE FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF                 ; EAE6 FF FF FF FF              ....
LEAEA:  .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EAEA FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EAF2 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EAFA FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EB02 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EB0A FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EB12 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EB1A FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EB22 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EB2A FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EB32 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EB3A FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EB42 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EB4A FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EB52 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EB5A FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EB62 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EB6A FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EB72 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EB7A FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EB82 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EB8A FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EB92 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EB9A FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EBA2 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EBAA FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EBB2 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EBBA FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EBC2 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EBCA FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EBD2 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EBDA FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EBE2 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EBEA FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EBF2 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EBFA FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EC02 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EC0A FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EC12 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EC1A FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EC22 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EC2A FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EC32 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EC3A FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EC42 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EC4A FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EC52 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EC5A FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EC62 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EC6A FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EC72 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EC7A FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EC82 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EC8A FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EC92 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EC9A FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; ECA2 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; ECAA FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; ECB2 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; ECBA FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; ECC2 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; ECCA FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; ECD2 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; ECDA FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; ECE2 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; ECEA FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; ECF2 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; ECFA FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; ED02 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; ED0A FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; ED12 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; ED1A FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; ED22 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; ED2A FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; ED32 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; ED3A FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; ED42 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; ED4A FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; ED52 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; ED5A FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; ED62 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; ED6A FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; ED72 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; ED7A FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; ED82 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; ED8A FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; ED92 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; ED9A FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EDA2 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EDAA FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EDB2 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EDBA FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EDC2 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EDCA FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EDD2 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EDDA FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EDE2 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EDEA FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EDF2 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EDFA FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EE02 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EE0A FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EE12 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EE1A FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EE22 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EE2A FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EE32 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EE3A FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EE42 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EE4A FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EE52 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EE5A FF FF FF FF FF FF FF FF  ........
        .byte   $FF

        ;Encryption key
        .byte   $7B

        ;Encrypted message
        .byte   $E9,$77,$6A,$5F,$5E,$5D ; EE62 FF 7B E9 77 6A 5F 5E 5D  .{.wj_^]
        .byte   $BE,$21,$3D,$24,$37,$3F,$22,$55 ; EE6A BE 21 3D 24 37 3F 22 55  .!=$7?"U
        .byte   $20,$24,$4A,$30,$27,$3A,$4E,$2F ; EE72 20 24 4A 30 27 3A 4E 2F   $J0':N/
        .byte   $35,$4D,$4C,$4F,$40,$47,$46,$68 ; EE7A 35 4D 4C 4F 40 47 46 68  5MLO@GFh
        .byte   $69,$88,$15,$1F,$0C,$08,$1F,$0F ; EE82 69 88 15 1F 0C 08 1F 0F  i.......
        .byte   $19,$69,$5F,$71,$96,$05,$13,$11 ; EE8A 19 69 5F 71 96 05 13 11  .i_q....
        .byte   $74,$89,$05,$1E,$0D,$01,$43,$6D ; EE92 74 89 05 1E 0D 01 43 6D  t.....Cm
        .byte   $98,$06,$10,$13,$19,$67,$94,$1C ; EE9A 98 06 10 13 19 67 94 1C  .....g..
        .byte   $05,$75,$37,$19,$EE,$70,$70,$1D ; EEA2 05 75 37 19 EE 70 70 1D  .u7..pp.
        .byte   $F9,$61,$66,$66,$79,$79,$73,$38 ; EEAA F9 61 66 66 79 79 73 38  .affyys8
        .byte   $39,$E3,$6F,$7B,$6C,$78,$6F,$7F ; EEB2 39 E3 6F 7B 6C 78 6F 7F  9.o{lxo.
        .byte   $69,$19,$2F,$01,$E2,$6E,$6A,$05 ; EEBA 69 19 2F 01 E2 6E 6A 05  i./..nj.
        .byte   $EC,$5E,$48,$5D,$15,$3F,$DA,$5C ; EEC2 EC 5E 48 5D 15 3F DA 5C  .^H].?.\
        .byte   $4A,$56,$32,$D9,$51,$4E,$58,$5C ; EECA 4A 56 32 D9 51 4E 58 5C  JV2.QNX\
        .byte   $51,$06,$2A,$CF,$5A,$4E,$40,$46 ; EED2 51 06 2A CF 5A 4E 40 46  Q.*.ZN@F
        .byte   $2C,$D3,$43,$4D,$41,$4E,$47,$08 ; EEDA 2C D3 43 4D 41 4E 47 08  ,.CMANG.
        .byte   $09,$E9,$36,$B0,$B6,$B4,$DE,$BC ; EEE2 09 E9 36 B0 B6 B4 DE BC  ..6.....
        .byte   $AE,$BE,$A1,$DD,$B4,$B8,$B8,$D2 ; EEEA AE BE A1 DD B4 B8 B8 D2  ........
        .byte   $A0,$CB,$A7,$A8,$A3,$AA,$CE,SAH ; EEF2 A0 CB A7 A8 A3 AA CE B9  ........
        .byte   $A4,$A6,$AF,$CF,$ED,$E7         ; EEFA A4 A6 AF CF ED E7        ......
; ----------------------------------------------------------------------------
        ; Convert F.P. to Integer
        jmp     L84B0                           ; EF00 4C B0 84                 L..
; ----------------------------------------------------------------------------
        ; Convert Integer to F.P.
        jmp     L792A                           ; EF03 4C 2A 79                 L*y
; ----------------------------------------------------------------------------
        ; Float to Ascii
        jmp     L8E35_27_CHECKSUM_ERROR_IN_HEADER                           ; EF06 4C 35 8E                 L5.
; ----------------------------------------------------------------------------
        ; String to Float
        jmp     L8052                           ; EF09 4C 52 80                 LR.
; ----------------------------------------------------------------------------
        ; Float/Fixed
        jmp     L8811                           ; EF0C 4C 11 88                 L..
; ----------------------------------------------------------------------------
        ; Fixed-Float
        jmp     L8C68                           ; EF0F 4C 68 8C                 Lh.
; ----------------------------------------------------------------------------
        ; Subtract From Memory
        jmp     L882A                           ; EF12 4C 2A 88                 L*.
; ----------------------------------------------------------------------------
        ; Evaluate <subtract>
        jmp     L882D                           ; EF15 4C 2D 88                 L-.
; ----------------------------------------------------------------------------
        ; Add Memory
        jmp     L8841                           ; EF18 4C 41 88                 LA.
; ----------------------------------------------------------------------------
        ; Evaluate <add>
        jmp     L8844                           ; EF1B 4C 44 88                 LD.
; ----------------------------------------------------------------------------
        ; Multiply By Memory
        jmp     L8A20                           ; EF1E 4C 20 8A                 L .
; ----------------------------------------------------------------------------
        ; Evaluate <multiply>
        jmp     L8A23                           ; EF21 4C 23 8A                 L#.
; ----------------------------------------------------------------------------
        ; Divide Into Memory
        jmp     L8B3C                           ; EF24 4C 3C 8B                 L<.
; ----------------------------------------------------------------------------
        ; Evaluate <divide>
        jmp     L8B3F                           ; EF27 4C 3F 8B                 L?.
; ----------------------------------------------------------------------------
        ; Evaluate <log>
        jmp     L89C6                           ; EF2A 4C C6 89                 L..
; ----------------------------------------------------------------------------
        ; Evaluate <int>
        jmp     L8CEE                           ; EF2D 4C EE 8C                 L..
; ----------------------------------------------------------------------------
        ; Evaluate <sqr>
        jmp     L8FAA                           ; EF30 4C AA 8F                 L..
; ----------------------------------------------------------------------------
        ; Evaluate <negate>
        jmp     L8FED                           ; EF33 4C ED 8F                 L..
; ----------------------------------------------------------------------------
        ; Raise to Memory Power
        jmp     L8FB1                           ; EF36 4C B1 8F                 L..
; ----------------------------------------------------------------------------
        ; Evaluate <power>
        jmp     L8FB4                           ; EF39 4C B4 8F                 L..
; ----------------------------------------------------------------------------
        ; Evaluate <exp>
        jmp     L9026                           ; EF3C 4C 26 90                 L&.
; ----------------------------------------------------------------------------
        ; Evaluate <cos>
        jmp     L93FC                           ; EF3F 4C FC 93                 L..
; ----------------------------------------------------------------------------
        ; Evaluate <sin>
        jmp     L9403                           ; EF42 4C 03 94                 L..
; ----------------------------------------------------------------------------
        ; Evaluate <tan>
        jmp     L944C                           ; EF45 4C 4C 94                 LL.
; ----------------------------------------------------------------------------
        ; Evaluate <atn>
        jmp     L94A6                           ; EF48 4C A6 94                 L..
; ----------------------------------------------------------------------------
        ; Round FAC#1
        jmp     L8C3A                           ; EF4B 4C 3A 8C                 L:.
; ----------------------------------------------------------------------------
        ; Evaluate <abs>
        jmp     L8C77                           ; EF4E 4C 77 8C                 Lw.
; ----------------------------------------------------------------------------
        ; Get Sign
        jmp     L8C4A                           ; EF51 4C 4A 8C                 LJ.
; ----------------------------------------------------------------------------
        ; Compare FAC#1 to Memory
        jmp     L8C7A                           ; EF54 4C 7A 8C                 Lz.
; ----------------------------------------------------------------------------
        ; Generate Random F.P. Number
        jmp     L8433                           ; EF57 4C 33 84                 L3.
; ----------------------------------------------------------------------------
        ; Unpack RAM1 to FAC#2
        jmp     L8AAF                           ; EF5A 4C AF 8A                 L..
; ----------------------------------------------------------------------------
        ; Unpack ROM to FAC#2
        jmp     L8A84                           ; EF5D 4C 84 8A                 L..
; ----------------------------------------------------------------------------
        ; Unpack RAM1 to FAC#1
        jmp     L7A73                           ; EF60 4C 73 7A                 Lsz
; ----------------------------------------------------------------------------
        ; Unpack ROM to FAC#1
        jmp     L8BC7_73_DOS_MISMATCH                           ; EF63 4C C7 8B                 L..
; ----------------------------------------------------------------------------
        ; Pack FAC#1 to RAM1
        jmp     L8BF3                           ; EF66 4C F3 8B                 L..
; ----------------------------------------------------------------------------
        ; FAC#2 to FAC#1
        jmp     L8C1B                           ; EF69 4C 1B 8C                 L..
; ----------------------------------------------------------------------------
        ; FAC#1 to FAC#2
        jmp     L8C2B                           ; EF6C 4C 2B 8C                 L+.
; ----------------------------------------------------------------------------
        ; Defunct Vectors
        jmp     L4825                           ; EF6F 4C 25 48                 L%H
; ----------------------------------------------------------------------------
        ; Draw Line
        jmp     L9B23                           ; EF72 4C 23 9B                 L#.
; ----------------------------------------------------------------------------
        ; Plot Pixel
        jmp     L9BEE                           ; EF75 4C EE 9B                 L..
; ----------------------------------------------------------------------------
        ; Draw Circle
        jmp     L673E                           ; EF78 4C 3E 67                 L>g
; ----------------------------------------------------------------------------
        ; Perform [run]
        jmp     L5A93                           ; EF7B 4C 93 5A                 L.Z
; ----------------------------------------------------------------------------
        ; Set Up Run
        jmp     L51F0                           ; EF7E 4C F0 51                 L.Q
; ----------------------------------------------------------------------------
        ; Perform [clr]
        jmp     L51F5                           ; EF81 4C F5 51                 L.Q
; ----------------------------------------------------------------------------
        ; Perform [new]
        jmp     L51D3                           ; EF84 4C D3 51                 L.Q
; ----------------------------------------------------------------------------
        ; Rechain Lines
        jmp     L4F4C                           ; EF87 4C 4C 4F                 LLO
; ----------------------------------------------------------------------------
        ; Crunch Tokens
        jmp     L4307                           ; EF8A 4C 07 43                 L.C
; ----------------------------------------------------------------------------
        ; Find Basic Line
        jmp     L5061                           ; EF8D 4C 61 50                 LaP
; ----------------------------------------------------------------------------
        ; ?
        jmp     L4AF3                           ; EF90 4C F3 4A                 L.J
; ----------------------------------------------------------------------------
        ; Evaluate Item
        jmp     L78C5                           ; EF93 4C C5 78                 L.x
; ----------------------------------------------------------------------------
        ; Evaluate Expression
        jmp     L77DD                           ; EF96 4C DD 77                 L.w
; ----------------------------------------------------------------------------
        ; ?
        jmp     L5A9E                           ; EF99 4C 9E 5A                 L.Z
; ----------------------------------------------------------------------------
        ; ?
        jmp     L5A79                           ; EF9C 4C 79 5A                 LyZ
; ----------------------------------------------------------------------------
        ; Get Fixed Pt Number
        jmp     L509D                           ; EF9F 4C 9D 50                 L.P
; ----------------------------------------------------------------------------
        ; Garbage Collection
        jmp     L92DD                           ; EFA2 4C DD 92                 L..
; ----------------------------------------------------------------------------
        ; ?
        jmp     L4DCA                           ; EFA5 4C CA 4D                 L.M
; ----------------------------------------------------------------------------
;Unused
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EFA8 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EFB0 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EFB8 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EFC0 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EFC8 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EFD0 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EFD8 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EFE0 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EFE8 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EFF0 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; EFF8 FF FF FF FF FF FF FF FF  ........
; ----------------------------------------------------------------------------

        ; Perform [monitor]
        jmp     LF021-$4000                     ; F000 4C 21 B0                 L!.
; ----------------------------------------------------------------------------
        ; -brk- monitor entry
        jmp     LF009-$4000                     ; F003 4C 09 B0                 L..
; ----------------------------------------------------------------------------
        ; Monitor command entry
        jmp     LF0B2-$4000                     ; F006 4C B2 B0                 L..
; ----------------------------------------------------------------------------

; Break Entry

LF009:  jsr     C128_FF7D_PRIMM
        .byte   $0d,"BREAK",$07,0
        pla                                     ; F014 68                       h
        sta     $02                             ; F015 85 02                    ..
        ldx     #$05                            ; F017 A2 05                    ..
LF019:  pla                                     ; F019 68                       h
        sta     $03,x                           ; F01A 95 03                    ..
        dex                                     ; F01C CA                       .
        bpl     LF019                           ; F01D 10 FA                    ..
        bmi     LF046                           ; F01F 30 25                    0%

; Print 'call' entry

LF021:  lda     #$00                            ; F021 A9 00                    ..
        sta     MMU_KERN_WINDOW                 ; F023 8D 00 FF                 ...
        sta     $06                             ; F026 85 06                    ..
        sta     $07                             ; F028 85 07                    ..
        sta     $08                             ; F02A 85 08                    ..
        sta     $05                             ; F02C 85 05                    ..
        lda     #$00                            ; F02E A9 00                    ..
        ldy     #$B0                            ; F030 A0 B0                    ..
        sta     $04                             ; F032 85 04                    ..
        sty     $03                             ; F034 84 03                    ..
        lda     #$0F                            ; F036 A9 0F                    ..
        sta     $02                             ; F038 85 02                    ..

; Print 'monitor'

        jsr     C128_FF7D_PRIMM
        .byte   $0d,"MONITOR",0
LF046:  cld                                     ; F046 D8                       .
        tsx                                     ; F047 BA                       .
        stx     $09                             ; F048 86 09                    ..
        lda     #$C0                            ; F04A A9 C0                    ..
        jsr     SetMsg                          ; F04C 20 90 FF                  ..
        cli                                     ; F04F 58                       X
; ----------------------------------------------------------------------------
; Perform [r]
;Registers command
LF050:
        jsr     C128_FF7D_PRIMM
        .byte   $0D,"    PC  SR AC XR YR SP"
        .byte   $0d,"; ",$1b,"Q",0
        lda     $02                             ; F070 A5 02                    ..
        jsr     LF8D2-$4000                     ; F072 20 D2 B8                  ..
        txa                                     ; F075 8A                       .
        jsr     LFFD2_CHROUT                    ; F076 20 D2 FF                  ..
        lda     $03                             ; F079 A5 03                    ..
        jsr     LF8C2-$4000                     ; F07B 20 C2 B8                  ..
        ldy     #$02                            ; F07E A0 02                    ..
LF080:  lda     $02,y                           ; F080 B9 02 00                 ...
        jsr     LF8A5-$4000                     ; F083 20 A5 B8                  ..
        iny                                     ; F086 C8                       .
        cpy     #$08                            ; F087 C0 08                    ..
        bcc     LF080                           ; F089 90 F5                    ..

; Get Command

LF08B:  jsr     LF8B4-$4000                     ; F08B 20 B4 B8                  ..
        ldx     #$00                            ; F08E A2 00                    ..
        stx     $7A                             ; F090 86 7A                    .z
        jsr     LFFCF_CHRIN ;BASIN              ; F092 20 CF FF                  ..
        sta     $0200,x                         ; F095 9D 00 02                 ...
        inx                                     ; F098 E8                       .
        cpx     #$A1                            ; F099 E0 A1                    ..
        bcs     LF0BC                           ; F09B B0 1F                    ..
        cmp     #$0D                            ; F09D C9 0D                    ..
        bne     $f092
        lda     #0
        sta     $01FF,x                         ; F0A3 9D FF 01                 ...
LF0A6:  jsr     LB8E9                           ; F0A6 20 E9 B8                  ..
        beq     LF08B                           ; F0A9 F0 E0                    ..
        cmp     #$20                            ; F0AB C9 20                    .
        beq     LF0A6                           ; F0AD F0 F7                    ..
        jmp     (RAMVEC_WTF)                    ; F0AF 6C 2E 03                 l..
; ----------------------------------------------------------------------------

; Monitor command

LF0B2:  ldx     #$15                            ; F0B2 A2 15                    ..
LF0B4:  cmp     LB0E7-1,x                       ; F0B4 DD E6 B0                 ...
        beq     LF0C5                           ; F0B7 F0 0C                    ..
        dex                                     ; F0B9 CA                       .
        bpl     LF0B4                           ; F0BA 10 F8                    ..

; Error

LF0BC:  jsr     C128_FF7D_PRIMM
        .byte   $1D,"?",0
        jmp     LF08B-$4000                     ; F0C2 4C 8B B0                 L..
; ----------------------------------------------------------------------------
LF0C5:  cpx     #$13                            ; F0C5 E0 13                    ..
        bcs     LF0DB                           ; F0C7 B0 12                    ..
        cpx     #$0F                            ; F0C9 E0 0F                    ..
        bcs     LF0E0                           ; F0CB B0 13                    ..
        txa                                     ; F0CD 8A                       .
        asl     a                               ; F0CE 0A                       .
        tax                                     ; F0CF AA                       .
        lda     LB0FC+1,x                       ; F0D0 BD FD B0                 ...
        pha                                     ; F0D3 48                       H
        lda     LB0FC,x                         ; F0D4 BD FC B0                 ...
        pha                                     ; F0D7 48                       H
        jmp     LB7A7                           ; F0D8 4C A7 B7                 L..
; ----------------------------------------------------------------------------
LF0DB:  sta     $93                             ; F0DB 85 93                    ..
        jmp     LF337-$4000                     ; F0DD 4C 37 B3                 L7.
; ----------------------------------------------------------------------------
LF0E0:  jmp     LB9B1                           ; F0E0 4C B1 B9                 L..
; ----------------------------------------------------------------------------

; Perform [x]

LF0E3:  jmp     (L0A00)       ; Restart System (BASIC Warm) [4000]                  ; F0E3 6C 00 0A                 l..
; ----------------------------------------------------------------------------

; Commands

        .byte "A" ;Assemble                     ; F0E6  -> B0E6
        .byte "C" ;Compare                      ; F0E7
        .byte "D" ;Disassemble                  ; F0E8
        .byte "F" ;Fill                         ; F0E9
        .byte "G" ;Go                           ; F0EA
        .byte "H" ;Hunt                         ; F0EB
        .byte "J" ;Jump to Subroutine           ; F0EC
        .byte "M" ;Memory                       ; F0ED
        .byte "R" ;Registers                    ; F0EE
        .byte "T" ;Transfer                     ; F0EF
        .byte "X" ;Exit                         ; F0F0
        .byte "@" ;DOS                          ; F0F1
        .byte "." ;Alias for Assemble           ; F0F2
        .byte ">" ;Modify Memory                ; F0F3
        .byte ";" ;Modify Registers             ; F0F4
        .byte "$" ;Hex value prefix             ; F0F5
        .byte "+" ;Decimal value prefix         ; F0F6
        .byte "&" ;Octal value prefix           ; F0F7
        .byte "%" ;Binary value prefix          ; F0F8
        .byte "L" ;Load                         ; F0F9
        .byte "S" ;Save                         ; F0FA
        .byte "V" ;Verify                       ; F0FB
; ----------------------------------------------------------------------------

; Vectors

        .word LF406-$4000-1 ;Assemble
        .word LF231-$4000-1 ;Compare
        .word LF599-$4000-1 ;Disassemble
        .word LF3DB-$4000-1 ;Fill
        .word LF1D6-$4000-1 ;Go
        .word LF2CE-$4000-1 ;Hunt
        .word LF1DF-$4000-1 ;Jump to Subroutine
        .word LF152-$4000-1 ;Memory
        .word LF050-$4000-1 ;Registers
        .word LF234-$4000-1 ;Transfer
        .word LF0E3-$4000-1 ;Exit
        .word $ba90-1       ;DOS (would be $FA90)
        .word LF406-$4000-1 ;Alias for Assemble
        .word LF1AB-$4000-1 ;Modify Memory
        .word LF194-$4000-1 ;Modify Registers
; ----------------------------------------------------------------------------

; Read Banked Memory

LF11A:  stx     $0AB2
        ldx     $68
        lda     #$66                            ; F11F A9 66                    .f
        sei                                     ; F121 78                       x
        jsr     C128_FF74_INDFET                           ; F122 20 74 FF                  t.
        cli                                     ; F125 58                       X
        ldx     $0AB2                           ; F126 AE B2 0A                 ...
        rts                                     ; F129 60                       `
; ----------------------------------------------------------------------------

; Write Banked Memory

LF12A:  stx     $0AB2                           ; F12A 8E B2 0A                 ...
        ldx     #$66                            ; F12D A2 66                    .f
        stx     $02B9                           ; F12F 8E B9 02                 ...
        ldx     $68                             ; F132 A6 68                    .h
        sei                                     ; F134 78                       x
        jsr     C128_FF77_INDSTA ; F135 20 77 FF                  w.
        cli                                     ; F138 58                       X
        ldx     $0AB2                           ; F139 AE B2 0A                 ...
        rts                                     ; F13C 60                       `
; ----------------------------------------------------------------------------

; Compare Banked Memory

        stx     $0AB2                           ; F13D 8E B2 0A                 ...
        ldx     #$66                            ; F140 A2 66                    .f
LF142:  stx     $02C8                           ; F142 8E C8 02                 ...
        ldx     $68                             ; F145 A6 68                    .h
        sei                                     ; F147 78                       x
        jsr     C128_FF7A_INDCMP                           ; F148 20 7A FF                  z.
        cli                                     ; F14B 58                       X
        php                                     ; F14C 08                       .
        ldx     $0AB2                           ; F14D AE B2 0A                 ...
        plp                                     ; F150 28                       (
        rts                                     ; F151 60                       `
; ----------------------------------------------------------------------------

; Perform [m]

;Memory command
LF152:  bcs     LF15C                           ; F152 B0 08                    ..
        jsr     LF901-$4000                     ; F154 20 01 B9                  ..
        jsr     LB7A7                           ; F157 20 A7 B7                  ..
        bcc     LF162                           ; F15A 90 06                    ..
LF15C:  lda     #$0B                            ; F15C A9 0B                    ..
        sta     $60                             ; F15E 85 60                    .`
        bne     LF177                           ; F160 D0 15                    ..
LF162:  jsr     LF90E-$4000                     ; F162 20 0E B9                  ..
        bcc     LF191                           ; F165 90 2A                    .*
        ldx     #$03                            ; F167 A2 03                    ..
        bit     $D7                             ; F169 24 D7                    $.
        bpl     LF16E                           ; F16B 10 01                    ..
        inx                                     ; F16D E8                       .
LF16E:  lsr     $62                             ; F16E 46 62                    Fb
        ror     $61                             ; F170 66 61                    fa
        ror     $60                             ; F172 66 60                    f`
        dex                                     ; F174 CA                       .
        bne     LF16E                           ; F175 D0 F7                    ..
LF177:  jsr     LFFE1_STOP                      ; F177 20 E1 FF                  ..
        beq     LF18E                           ; F17A F0 12                    ..
        jsr     LF1E8-$4000                     ; F17C 20 E8 B1                  ..
        lda     #$08                            ; F17F A9 08                    ..
        bit     $D7                             ; F181 24 D7                    $.
        bpl     LF186                           ; F183 10 01                    ..
        asl     a                               ; F185 0A                       .
LF186:  jsr     LB952                           ; F186 20 52 B9                  R.
        jsr     LB922_PLY_PLX_RTS               ; F189 20 22 B9                  ".
        bcs     LF177                           ; F18C B0 E9                    ..
LF18E:  jmp     LF08B-$4000                     ; F18E 4C 8B B0                 L..
; ----------------------------------------------------------------------------
LF191:  jmp     LF0BC-$4000                     ; F191 4C BC B0                 L..
; ----------------------------------------------------------------------------

; Perform [:]

;Modify registers command
LF194:  jsr     LB974                           ; F194 20 74 B9                  t.
        ldy     #$00                            ; F197 A0 00                    ..
LF199:  jsr     LB7A7                           ; F199 20 A7 B7                  ..
        bcs     LF1A8                           ; F19C B0 0A                    ..
        lda     $60                             ; F19E A5 60                    .`
        sta     $05,y                           ; F1A0 99 05 00                 ...
        iny                                     ; F1A3 C8                       .
        cpy     #$05                            ; F1A4 C0 05                    ..
        bcc     LF199                           ; F1A6 90 F1                    ..
LF1A8:  jmp     LF08B-$4000                     ; F1A8 4C 8B B0                 L..
; ----------------------------------------------------------------------------


; Perform [>]
;Modify memory command
LF1AB:  bcs     LF1C9                           ; F1AB B0 1C                    ..
        jsr     LF901-$4000                     ; F1AD 20 01 B9                  ..
        ldy     #$00                            ; F1B0 A0 00                    ..
LF1B2:  jsr     LB7A7                           ; F1B2 20 A7 B7                  ..
        bcs     LF1C9                           ; F1B5 B0 12                    ..
        lda     $60                             ; F1B7 A5 60                    .`
        jsr     LF12A-$4000                     ; F1B9 20 2A B1                  *.
        iny                                     ; F1BC C8                       .
        bit     $D7                             ; F1BD 24 D7                    $.
        bpl     LF1C5                           ; F1BF 10 04                    ..
        cpy     #$10                            ; F1C1 C0 10                    ..
        bcc     LF1B2                           ; F1C3 90 ED                    ..
LF1C5:  cpy     #$08                            ; F1C5 C0 08                    ..
        bcc     LF1B2                           ; F1C7 90 E9                    ..

; Print 'esc-o-up'
LF1C9:  jsr     C128_FF7D_PRIMM
        .byte   $1B,"O",$91,0
        jsr     LF1E8-$4000                     ; F1D0 20 E8 B1                  ..
        jmp     LF08B-$4000                     ; F1D3 4C 8B B0                 L..
; ----------------------------------------------------------------------------

; Perform [g]
;Go command
LF1D6:  jsr     LB974                           ; F1D6 20 74 B9                  t.
        ldx     $09                             ; F1D9 A6 09                    ..
        txs                                     ; F1DB 9A                       .
        jmp     C128_FF71_JMPFAR                ; F1DC 4C 71 FF                 Lq.
; ----------------------------------------------------------------------------

; Perform [j]
;Jump to subroutine command
LF1DF:  jsr     LB974                           ; F1DF 20 74 B9                  t.
        jsr     C128_FF6E_JSRFAR               ; F1E2 20 6E FF                  n.
        jmp     LF08B-$4000                     ; F1E5 4C 8B B0                 L..
; ----------------------------------------------------------------------------


; Display Memory
LF1E8:  jsr     LF8B4-$4000                     ; F1E8 20 B4 B8                  ..
        lda     #$3E                            ; F1EB A9 3E                    .>
        jsr     LFFD2_CHROUT                    ; F1ED 20 D2 FF                  ..
        jsr     LF892-$4000                     ; F1F0 20 92 B8                  ..
        ldy     #$00                            ; F1F3 A0 00                    ..
        beq     LF1FA                           ; F1F5 F0 03                    ..
LF1F7:  jsr     LF8A8-$4000                     ; F1F7 20 A8 B8                  ..
LF1FA:  jsr     LF11A-$4000                     ; F1FA 20 1A B1                  ..
        jsr     LF8C2-$4000                     ; F1FD 20 C2 B8                  ..
        iny                                     ; F200 C8                       .
        cpy     #$08                            ; F201 C0 08                    ..
        bit     $D7                             ; F203 24 D7                    $.
        bpl     LF209                           ; F205 10 02                    ..
        cpy     #$10                            ; F207 C0 10                    ..
LF209:  bcc     LF1F7                           ; F209 90 EC                    ..


; Print ':<rvs-on>'
        jsr     C128_FF7D_PRIMM
        .byte   ":",$12,0
        ldy     #$00                            ; F211 A0 00                    ..
LF213:  jsr     LF11A-$4000                     ; F213 20 1A B1                  ..
        pha                                     ; F216 48                       H
        and     #$7F                            ; F217 29 7F                    ).
        cmp     #$20                            ; F219 C9 20                    .
        pla                                     ; F21B 68                       h
        bcs     LF220                           ; F21C B0 02                    ..
        lda     #$2E                            ; F21E A9 2E                    ..
LF220:  jsr     LFFD2_CHROUT                    ; F220 20 D2 FF                  ..
        iny                                     ; F223 C8                       .
        bit     $D7                             ; F224 24 D7                    $.
        bpl     LF22C                           ; F226 10 04                    ..
        cpy     #$10                            ; F228 C0 10                    ..
        bcc     LF213                           ; F22A 90 E7                    ..
LF22C:  cpy     #$08                            ; F22C C0 08                    ..
        bcc     LF213                           ; F22E 90 E3                    ..
        rts                                     ; F230 60                       `
; ----------------------------------------------------------------------------

; Perform [c]

;Compare command
LF231:  lda     #$00                            ; F231 A9 00                    ..
        .byte $2c
        ;Fall through
; ----------------------------------------------------------------------------

; Perform [t]

;Transfer command
LF234:  lda     #$80
        sta     $93                             ; F236 85 93                    ..
        lda     #$00                            ; F238 A9 00                    ..
        sta     $0AB3                           ; F23A 8D B3 0A                 ...
        jsr     LB983                           ; F23D 20 83 B9                  ..
        bcs     LF247                           ; F240 B0 05                    ..
        jsr     LB7A7                           ; F242 20 A7 B7                  ..
        bcc     LF24A                           ; F245 90 03                    ..
LF247:  jmp     LF0BC-$4000                     ; F247 4C BC B0                 L..
; ----------------------------------------------------------------------------
LF24A:  bit     $93                             ; F24A 24 93                    $.
        bpl     LF27A                           ; F24C 10 2C                    .,
        sec                                     ; F24E 38                       8
        lda     $66                             ; F24F A5 66                    .f
        sbc     $60                             ; F251 E5 60                    .`
        lda     $67                             ; F253 A5 67                    .g
        sbc     $61                             ; F255 E5 61                    .a
        bcs     LF27A                           ; F257 B0 21                    .!
        lda     $63                             ; F259 A5 63                    .c
        adc     $60                             ; F25B 65 60                    e`
        sta     $60                             ; F25D 85 60                    .`
        lda     $64                             ; F25F A5 64                    .d
        adc     $61                             ; F261 65 61                    ea
        sta     $61                             ; F263 85 61                    .a
        lda     $65                             ; F265 A5 65                    .e
        adc     $62                             ; F267 65 62                    eb
        sta     $62                             ; F269 85 62                    .b
        ldx     #$02                            ; F26B A2 02                    ..
LF26D:  lda     $0AB7,x                         ; F26D BD B7 0A                 ...
        sta     $66,x                           ; F270 95 66                    .f
        dex                                     ; F272 CA                       .
        bpl     LF26D                           ; F273 10 F8                    ..
        lda     #$80                            ; F275 A9 80                    ..
        sta     $0AB3                           ; F277 8D B3 0A                 ...
LF27A:  jsr     LF8B4-$4000                           ; F27A 20 B4 B8                  ..
        ldy     #$00                            ; F27D A0 00                    ..
LF27F:  jsr     LFFE1_STOP                           ; F27F 20 E1 FF                  ..
        beq     LF2CB                           ; F282 F0 47                    .G
        jsr     LF11A-$4000                     ; F284 20 1A B1                  ..
        ldx     #$60                            ; F287 A2 60                    .`
        stx     $02B9                           ; F289 8E B9 02                 ...
        stx     $02C8                           ; F28C 8E C8 02                 ...
        ;Fall through
; ----------------------------------------------------------------------------
;Unknown command
LF28F:  ldx     $62                             ; F28F A6 62                    .b
        sei                                     ; F291 78                       x
        bit     $93                             ; F292 24 93                    $.
        bpl     LF299                           ; F294 10 03                    ..
        jsr     C128_FF77_INDSTA                           ; F296 20 77 FF                  w.
LF299:  ldx     $62                             ; F299 A6 62                    .b
        jsr     C128_FF7A_INDCMP                           ; F29B 20 7A FF                  z.
        cli                                     ; F29E 58                       X
        beq     LF2AA                           ; F29F F0 09                    ..
        jsr     LF892-$4000                     ; F2A1 20 92 B8                  ..
        jsr     LF8A8-$4000                     ; F2A4 20 A8 B8                  ..
        jsr     LF8A8-$4000                     ; F2A7 20 A8 B8                  ..
LF2AA:  bit     $0AB3                           ; F2AA 2C B3 0A                 ,..
        bmi     LF2BA                           ; F2AD 30 0B                    0.
        inc     $60                             ; F2AF E6 60                    .`
        bne     LF2C3                           ; F2B1 D0 10                    ..
        inc     $61                             ; F2B3 E6 61                    .a
        bne     LF2C3                           ; F2B5 D0 0C                    ..
        jmp     LF0BC-$4000                     ; F2B7 4C BC B0                 L..
; ----------------------------------------------------------------------------
LF2BA:
        jsr     LF922-$4000                     ; F2BA 20 22 B9                  ".
        jsr     LF960-$4000                     ; F2BD 20 60 B9                  `.
        jmp     LF2C6-$4000                     ; F2C0 4C C6 B2                 L..
; ----------------------------------------------------------------------------

; Add 1 to Op 3
LF2C3:  jsr     LB950                           ; F2C3 20 50 B9                  P.

; Do Next Address
LF2C6:  jsr     LB93C                           ; F2C6 20 3C B9                  <.
        bcs     LF27F                           ; F2C9 B0 B4                    ..
LF2CB:  jmp     LF08B-$4000                     ; F2CB 4C 8B B0                 L..
; ----------------------------------------------------------------------------

; Perform [h]
;Hunt command
LF2CE:  jsr     LB983                           ; F2CE 20 83 B9                  ..
        bcs     LF334                           ; F2D1 B0 61                    .a
        ldy     #$00                            ; F2D3 A0 00                    ..
        jsr     LB8E9                           ; F2D5 20 E9 B8                  ..
        cmp     #$27                            ; F2D8 C9 27                    .'
        bne     LF2F2                           ; F2DA D0 16                    ..
        jsr     LB8E9                           ; F2DC 20 E9 B8                  ..
        cmp     #$00                            ; F2DF C9 00                    ..
        beq     LF334                           ; F2E1 F0 51                    .Q
LF2E3:  sta     $0A80,y                         ; F2E3 99 80 0A                 ...
        iny                                     ; F2E6 C8                       .
        jsr     LB8E9                           ; F2E7 20 E9 B8                  ..
        beq     LF307                           ; F2EA F0 1B                    ..
        cpy     #$20                            ; F2EC C0 20                    .
        bne     LF2E3                           ; F2EE D0 F3                    ..
        beq     LF307                           ; F2F0 F0 15                    ..
LF2F2:  sty     stack                           ; F2F2 8C 00 01                 ...
        jsr     LB7A5                           ; F2F5 20 A5 B7                  ..
LF2F8:  lda     $60                             ; F2F8 A5 60                    .`
        sta     $0A80,y                         ; F2FA 99 80 0A                 ...
        iny                                     ; F2FD C8                       .
        jsr     LB7A7                           ; F2FE 20 A7 B7                  ..
        bcs     LF307                           ; F301 B0 04                    ..
        cpy     #$20                            ; F303 C0 20                    .
        bne     LF2F8                           ; F305 D0 F1                    ..
LF307:  sty     $93                             ; F307 84 93                    ..
        jsr     LF8B4-$4000                     ; F309 20 B4 B8                  ..
LF30C:  ldy     #$00                            ; F30C A0 00                    ..
LF30E:  jsr     LF11A-$4000                     ; F30E 20 1A B1                  ..
        cmp     $0A80,y                         ; F311 D9 80 0A                 ...
        bne     LF324                           ; F314 D0 0E                    ..
        iny                                     ; F316 C8                       .
        cpy     $93                             ; F317 C4 93                    ..
        bne     LF30E                           ; F319 D0 F3                    ..
        jsr     LF892-$4000                     ; F31B 20 92 B8                  ..
        jsr     LF8A8-$4000                     ; F31E 20 A8 B8                  ..
        jsr     LF8A8-$4000                     ; F321 20 A8 B8                  ..
LF324:  jsr     LFFE1_STOP                      ; F324 20 E1 FF                  ..
        beq     LF331                           ; F327 F0 08                    ..
        jsr     LB950                           ; F329 20 50 B9                  P.
        jsr     LB93C                           ; F32C 20 3C B9                  <.
        bcs     LF30C                           ; F32F B0 DB                    ..
LF331:  jmp     LF08B-$4000                     ; F331 4C 8B B0                 L..
; ----------------------------------------------------------------------------
LF334:  jmp     LF0BC-$4000                     ; F334 4C BC B0                 L..
; ----------------------------------------------------------------------------

; Perform [lsv]
LF337:  ldy     #$01                            ; F337 A0 01                    ..
        sty     SATUS                           ; F339 84 BA                    ..
        sty     SAH                             ; F33B 84 B9                    ..
        dey                                     ; F33D 88                       .
        sty     LA                              ; F33E 84 C6                    ..
        sty     STAH                            ; F340 84 B7                    ..
        sty     $C7                             ; F342 84 C7                    ..
        sty     $90                             ; F344 84 90                    ..
        lda     #$0A                            ; F346 A9 0A                    ..
        sta     $BC                             ; F348 85 BC                    ..
        lda     #$80                            ; F34A A9 80                    ..
        sta     $BB                             ; F34C 85 BB                    ..
LF34E:  jsr     LB8E9                           ; F34E 20 E9 B8                  ..
        beq     LF3AB                           ; F351 F0 58                    .X
        cmp     #' '                            ; F353 C9 20                    .
        beq     LF34E                           ; F355 F0 F7                    ..
        cmp     #'"'                            ; F357 C9 22                    ."
        bne     LF370                           ; F359 D0 15                    ..
        ldx     $7A                             ; F35B A6 7A                    .z
LF35D:  lda     $0200,x                         ; F35D BD 00 02                 ...
        beq     LF3AB                           ; F360 F0 49                    .I
        inx                                     ; F362 E8                       .
        cmp     #'"'                            ; F363 C9 22                    ."
        beq     LF373                           ; F365 F0 0C                    ..
        sta     ($BB),y                         ; F367 91 BB                    ..
        inc     STAH                            ; F369 E6 B7                    ..
        iny                                     ; F36B C8                       .
        cpy     #$11                            ; F36C C0 11                    ..
        bcc     LF35D                           ; F36E 90 ED                    ..
LF370:  jmp     LF0BC-$4000                     ; F370 4C BC B0                 L..
; ----------------------------------------------------------------------------
LF373:  stx     $7A                             ; F373 86 7A                    .z
        jsr     LB8E9                           ; F375 20 E9 B8                  ..
        beq     LF3AB                           ; F378 F0 31                    .1
        jsr     LB7A7                           ; F37A 20 A7 B7                  ..
        bcs     LF3AB                           ; F37D B0 2C                    .,
        lda     $60                             ; F37F A5 60                    .`
        sta     SATUS                             ; F381 85 BA                    ..
        jsr     LB7A7                           ; F383 20 A7 B7                  ..
        bcs     LF3AB                           ; F386 B0 23                    .#
        jsr     LF901-$4000                     ; F388 20 01 B9                  ..
        sta     LA                              ; F38B 85 C6                    ..
        jsr     LB7A7                           ; F38D 20 A7 B7                  ..
        bcs     LF3D1                           ; F390 B0 3F                    .?
        jsr     LF8B4-$4000                           ; F392 20 B4 B8                  ..
        ldx     $60                             ; F395 A6 60                    .`
        ldy     $61                             ; F397 A4 61                    .a
        lda     $93                             ; F399 A5 93                    ..
        cmp     #$53                            ; F39B C9 53                    .S
        bne     LF370                           ; F39D D0 D1                    ..
        lda     #$00                            ; F39F A9 00                    ..
        sta     SAH                             ; F3A1 85 B9                    ..
        lda     #$66                            ; F3A3 A9 66                    .f
        jsr     SAVE                            ; F3A5 20 D8 FF                  ..
LF3A8:  jmp     LF08B-$4000                           ; F3A8 4C 8B B0                 L..
; ----------------------------------------------------------------------------
LF3AB:  lda     $93                             ; F3AB A5 93                    ..
        cmp     #'V'                            ; F3AD C9 56                    .V
        beq     LF3B7                           ; F3AF F0 06                    ..
        cmp     #'L'                            ; F3B1 C9 4C                    .L
        bne     LF370                           ; F3B3 D0 BB                    ..
        lda     #$00                            ; F3B5 A9 00                    ..
LF3B7:  jsr     LOAD                            ; F3B7 20 D5 FF                  ..
        lda     $90                             ; F3BA A5 90                    ..
        and     #$10                            ; F3BC 29 10                    ).
        beq     LF3A8                           ; F3BE F0 E8                    ..
        lda     $93                             ; F3C0 A5 93                    ..
        beq     LF370                           ; F3C2 F0 AC                    ..

; Print 'error'

        jsr     C128_FF7D_PRIMM
        .byte   " ERROR",0
        jmp     LF08B-$4000                           ; F3CE 4C 8B B0                 L..
; ----------------------------------------------------------------------------
LF3D1:  ldx     $66                             ; F3D1 A6 66                    .f
        ldy     $67                             ; F3D3 A4 67                    .g
        lda     #$00                            ; F3D5 A9 00                    ..
        sta     SAH                             ; F3D7 85 B9                    ..
        beq     LF3AB                           ; F3D9 F0 D0                    ..

; Perform [f]

;Fill command
LF3DB:  jsr     LB983                           ; F3DB 20 83 B9                  ..
        bcs     LF403                           ; F3DE B0 23                    .#
        lda     $68                             ; F3E0 A5 68                    .h
        cmp     $0AB9                           ; F3E2 CD B9 0A                 ...
        bne     LF403                           ; F3E5 D0 1C                    ..
        jsr     LB7A7                           ; F3E7 20 A7 B7                  ..
        bcs     LF403                           ; F3EA B0 17                    ..
        ldy     #$00                            ; F3EC A0 00                    ..
LF3EE:  lda     $60                             ; F3EE A5 60                    .`
        jsr     ESC_A_AUTOINSERT_ON             ; F3F0 20 2A B1                  *.
        jsr     LFFE1_STOP                      ; F3F3 20 E1 FF                  ..
        beq     LF400                           ; F3F6 F0 08                    ..
        jsr     LB950                           ; F3F8 20 50 B9                  P.
        jsr     LB93C                           ; F3FB 20 3C B9                  <.
        bcs     LF3EE                           ; F3FE B0 EE                    ..
LF400:  jmp     LF08B-$4000                     ; F400 4C 8B B0                 L..
; ----------------------------------------------------------------------------
LF403:  jmp     LF0BC-$4000                     ; F403 4C BC B0                 L..
; ----------------------------------------------------------------------------

; Perform [a]
;Assemble command
LF406:  bcs     LF442                           ; F406 B0 3A                    .:
        jsr     LF901-$4000                     ; F408 20 01 B9                  ..
LF40B:  ldx     #$00                            ; F40B A2 00                    ..
        stx     $0AA1                           ; F40D 8E A1 0A                 ...
        stx     $0AB4                           ; F410 8E B4 0A                 ...
LF413:  jsr     LB8E9                           ; F413 20 E9 B8                  ..
        bne     LF41F                           ; F416 D0 07                    ..
        cpx     #$00                            ; F418 E0 00                    ..
        bne     LF41F                           ; F41A D0 03                    ..
        jmp     LF08B-$4000                     ; F41C 4C 8B B0                 L..
; ----------------------------------------------------------------------------
LF41F:  cmp     #$20                            ; F41F C9 20                    .
        beq     LF40B                           ; F421 F0 E8                    ..
        sta     $0AAC,x                         ; F423 9D AC 0A                 ...
        inx                                     ; F426 E8                       .
        cpx     #$03                            ; F427 E0 03                    ..
        bne     LF413                           ; F429 D0 E8                    ..
LF42B:  dex                                     ; F42B CA                       .
        bmi     LF445                           ; F42C 30 17                    0.
        lda     $0AAC,x                         ; F42E BD AC 0A                 ...
        sec                                     ; F431 38                       8
        sbc     #$3F                            ; F432 E9 3F                    .?
        ldy     #$05                            ; F434 A0 05                    ..
LF436:  lsr     a                               ; F436 4A                       J
        ror     $0AA1                           ; F437 6E A1 0A                 n..
        ror     $0AA0                           ; F43A 6E A0 0A                 n..
        dey                                     ; F43D 88                       .
        bne     LF436                           ; F43E D0 F6                    ..
        beq     LF42B                           ; F440 F0 E9                    ..
LF442:  jmp     LF0BC-$4000                     ; F442 4C BC B0                 L..
; ----------------------------------------------------------------------------
LF445:  ldx     #$02                            ; F445 A2 02                    ..
LF447:  lda     $0AB4                           ; F447 AD B4 0A                 ...
        bne     LF47C                           ; F44A D0 30                    .0
        jsr     LB7CE                           ; F44C 20 CE B7                  ..
        beq     LF47A                           ; F44F F0 29                    .)
        bcs     LF442                           ; F451 B0 EF                    ..
        lda     #$24                            ; F453 A9 24                    .$
        sta     $0AA0,x                         ; F455 9D A0 0A                 ...
        inx                                     ; F458 E8                       .
        lda     $62                             ; F459 A5 62                    .b
        bne     LF442                           ; F45B D0 E5                    ..
        ldy     #$04                            ; F45D A0 04                    ..
        lda     $0AB6                           ; F45F AD B6 0A                 ...
        cmp     #$08                            ; F462 C9 08                    ..
        bcc     LF46B                           ; F464 90 05                    ..
        cpy     $0AB4                           ; F466 CC B4 0A                 ...
        .byte   $F0                             ; F469 F0                       .
LF46A:  .byte   $06                             ; F46A 06                       .
LF46B:  lda     $61                             ; F46B A5 61                    .a
        bne     LF471                           ; F46D D0 02                    ..
        ldy     #$02                            ; F46F A0 02                    ..
LF471:  lda     #$30                            ; F471 A9 30                    .0
LF473:  sta     $0AA0,x                         ; F473 9D A0 0A                 ...
        inx                                     ; F476 E8                       .
        dey                                     ; F477 88                       .
        bne     LF473                           ; F478 D0 F9                    ..
LF47A:  dec     $7A                             ; F47A C6 7A                    .z
LF47C:  jsr     LB8E9                           ; F47C 20 E9 B8                  ..
        beq     LF48F                           ; F47F F0 0E                    ..
        cmp     #$20                            ; F481 C9 20                    .
        beq     LF447                           ; F483 F0 C2                    ..
        sta     $0AA0,x                         ; F485 9D A0 0A                 ...
        inx                                     ; F488 E8                       .
        cpx     #$0A                            ; F489 E0 0A                    ..
        bcc     LF447                           ; F48B 90 BA                    ..
        bcs     LF442                           ; F48D B0 B3                    ..
LF48F:  stx     $63                             ; F48F 86 63                    .c
        ldx     #$00                            ; F491 A2 00                    ..
        stx     $0AB1                           ; F493 8E B1 0A                 ...
LF496:  ldx     #$00                            ; F496 A2 00                    ..
        stx     $9F                             ; F498 86 9F                    ..
        lda     $0AB1                           ; F49A AD B1 0A                 ...
        jsr     LF659-$4000
        ldx     $0aaa
        stx     $64                             ; F4A3 86 64                    .d
        tax                                     ; F4A5 AA                       .
        lda     LF761-$4000,x                         ; F4A6 BD 61 B7                 .a.
        jsr     LF57F-$4000                     ; F4A9 20 7F B5                  ..
        lda     LF721-$4000,x                   ; F4AC BD 21 B7                 .!.
        jsr     LF57F-$4000                     ; F4AF 20 7F B5                  ..
        ldx     #$06                            ; F4B2 A2 06                    ..
LF4B4:  cpx     #$03                            ; F4B4 E0 03                    ..
        bne     LF4CC                           ; F4B6 D0 14                    ..
        ldy     $0AAB                           ; F4B8 AC AB 0A                 ...
        beq     LF4CC                           ; F4BB F0 0F                    ..
LF4BD:  lda     $0AAA                           ; F4BD AD AA 0A                 ...
        cmp     #$E8                            ; F4C0 C9 E8                    ..
        lda     #$30                            ; F4C2 A9 30                    .0
        bcs     LF4E4                           ; F4C4 B0 1E                    ..
        jsr     LF57C-$4000                     ; F4C6 20 7C B5                  |.
        dey                                     ; F4C9 88                       .
        bne     LF4BD                           ; F4CA D0 F1                    ..
LF4CC:  asl     $0AAA                           ; F4CC 0E AA 0A                 ...
        bcc     LF4DF                           ; F4CF 90 0E                    ..
        lda     LF714-$4000,x                   ; F4D1 BD 14 B7                 ...
        jsr     LF57F-$4000                     ; F4D4 20 7F B5                  ..
        lda     LF71A-$4000,x                         ; F4D7 BD 1A B7                 ...
        beq     LF4DF                           ; F4DA F0 03                    ..
        jsr     LF57F-$4000                     ; F4DC 20 7F B5                  ..
LF4DF:  dex                                     ; F4DF CA                       .
        bne     LF4B4                           ; F4E0 D0 D2                    ..
        beq     LF4EA                           ; F4E2 F0 06                    ..
LF4E4:  jsr     LF57C-$4000                     ; F4E4 20 7C B5                  |.
        jsr     LF57C-$4000                     ; F4E7 20 7C B5                  |.
LF4EA:  lda     $63                             ; F4EA A5 63                    .c
        cmp     $9F                             ; F4EC C5 9F                    ..
        beq     LF4F3                           ; F4EE F0 03                    ..
        jmp     LF58B-$4000                     ; F4F0 4C 8B B5                 L..
; ----------------------------------------------------------------------------
LF4F3:  ldy     $0AAB                           ; F4F3 AC AB 0A                 ...
        beq     LF52A                           ; F4F6 F0 32                    .2
        lda     $64                             ; F4F8 A5 64                    .d
        cmp     #$9D                            ; F4FA C9 9D                    ..
        bne     LF521                           ; F4FC D0 23                    .#
        lda     $60                             ; F4FE A5 60                    .`
        sbc     $66                             ; F500 E5 66                    .f
        tax                                     ; F502 AA                       .
        lda     $61                             ; F503 A5 61                    .a
        sbc     $67                             ; F505 E5 67                    .g
        bcc     LF511                           ; F507 90 08                    ..
        bne     LF579                           ; F509 D0 6E                    .n
        cpx     #$82                            ; F50B E0 82                    ..
        bcs     LF579                           ; F50D B0 6A                    .j
        bcc     LF519                           ; F50F 90 08                    ..
LF511:  tay                                     ; F511 A8                       .
        iny                                     ; F512 C8                       .
        bne     LF579                           ; F513 D0 64                    .d
        cpx     #$82                            ; F515 E0 82                    ..
        bcc     LF579                           ; F517 90 60                    .`
LF519:  dex                                     ; F519 CA                       .
        dex                                     ; F51A CA                       .
        txa                                     ; F51B 8A                       .
        ldy     $0AAB                           ; F51C AC AB 0A                 ...
        bne     LF524                           ; F51F D0 03                    ..
LF521:  lda     $5F,y                           ; F521 B9 5F 00                 ._.
LF524:  jsr     LF12A-$4000                     ; F524 20 2A B1                  *.
        dey                                     ; F527 88                       .
        bne     LF521                           ; F528 D0 F7                    ..
LF52A:  lda     $0AB1                           ; F52A AD B1 0A                 ...
        jsr     LF12A-$4000                     ; F52D 20 2A B1                  *.
        jsr     LB8AD_8D_SHIFT_RETURN                           ; F530 20 AD B8                  ..

; Print 'space<esc-q>'
        jsr     C128_FF7D_PRIMM
        .byte   "A ",$1b,"Q",0
        jsr     LF5DC-$4000
        inc     $0AAB
        lda     $0AAB
        jsr     LB952
        lda     #$41
        sta     GO_RAM_LOAD_GO_KERN
        lda     #$20
        sta     $034B
        sta     $0351
        lda     $68
        jsr     LF8D2-$4000
        stx     $034C
        lda     $67
        jsr     LF8D2-$4000
        sta     GO_NOWHERE_LOAD_GO_KERN
        stx     SINNER
        lda     $66
        jsr     LF8D2-$4000
        sta     $034F
        stx     $0350
        lda     #$08
        sta     $D0
        jmp     LF08B-$4000
; ----------------------------------------------------------------------------
LF579:  jmp     LF0BC-$4000
; ----------------------------------------------------------------------------

; Check 2 A-Matches
LF57C:  jsr     LF57F-$4000                     ; F57C 20 7F B5                  ..

; Check A-Match
LF57F:  stx     $0AAF                           ; F57F 8E AF 0A                 ...
        ldx     $9F                             ; F582 A6 9F                    ..
        cmp     $0AA0,x                         ; F584 DD A0 0A                 ...
        beq     LF593                           ; F587 F0 0A                    ..
        pla                                     ; F589 68                       h
        pla                                     ; F58A 68                       h

; Try Next Op Code
LF58B:  inc     $0AB1                           ; F58B EE B1 0A                 ...
        beq     LF579                           ; F58E F0 E9                    ..
        jmp     LF496-$4000                     ; F590 4C 96 B4                 L..
; ----------------------------------------------------------------------------
LF593:  inc     $9F                             ; F593 E6 9F                    ..
        ldx     $0AAF                           ; F595 AE AF 0A                 ...
        rts                                     ; F598 60                       `
; ----------------------------------------------------------------------------
; Perform [d]
;Disassemble command
LF599:  bcs     LF5A3                           ; F599 B0 08                    ..
        jsr     LF901-$4000                     ; F59B 20 01 B9                  ..
        jsr     LB7A7                           ; F59E 20 A7 B7                  ..
        bcc     LF5A9                           ; F5A1 90 06                    ..
LF5A3:  lda     #$14                            ; F5A3 A9 14                    ..
        sta     $60                             ; F5A5 85 60                    .`
        bne     LF5AE                           ; F5A7 D0 05                    ..
LF5A9:  jsr     LF90E-$4000                     ; F5A9 20 0E B9                  ..
        bcc     LF5D1                           ; F5AC 90 23                    .#

; Print '<cr><esc-q>'
LF5AE:  jsr     C128_FF7D_PRIMM
        .byte   $0D,$1B,"Q",0
        jsr     LFFE1_STOP                      ; F5B5 20 E1 FF                  ..
        beq     LF5CE                           ; F5B8 F0 14                    ..
        jsr     LF5D4-$4000                     ; F5BA 20 D4 B5                  ..
        inc     $0AAB                           ; F5BD EE AB 0A                 ...
        lda     $0AAB                           ; F5C0 AD AB 0A                 ...
        jsr     LB952                           ; F5C3 20 52 B9                  R.
        lda     $0AAB                           ; F5C6 AD AB 0A                 ...
        jsr     LB924_RTS                       ; F5C9 20 24 B9                  $.
        bcs     LF5AE                           ; F5CC B0 E0                    ..
LF5CE:  jmp     LF08B-$4000                     ; F5CE 4C 8B B0                 L..
; ----------------------------------------------------------------------------
LF5D1:  jmp     LF0BC-$4000                     ; F5D1 4C BC B0                 L..
; ----------------------------------------------------------------------------

; Display Instruction
LF5D4:  lda     #$2E                            ; F5D4 A9 2E                    ..
        jsr     LFFD2_CHROUT                    ; F5D6 20 D2 FF                  ..
        jsr     LF8A8-$4000                     ; F5D9 20 A8 B8                  ..
LF5DC:  jsr     LF892-$4000
        jsr     LF8A8-$4000                     ; F5DF 20 A8 B8                  ..
        ldy     #$00                            ; F5E2 A0 00                    ..
        jsr     LF11A-$4000                     ; F5E4 20 1A B1                  ..
        jsr     LF659-$4000                     ; F5E7 20 59 B6                  Y.
        pha                                     ; F5EA 48                       H
        ldx     $0AAB                           ; F5EB AE AB 0A                 ...
        inx                                     ; F5EE E8                       .
LF5EF:  dex                                     ; F5EF CA                       .
        bpl     LF5FC                           ; F5F0 10 0A                    ..
        jsr     C128_FF7D_PRIMM
        .byte   "   ",0
        jmp     LF602-$4000                     ; F5F9 4C 02 B6                 L..
; ----------------------------------------------------------------------------

; Print '<3 spaces>'
LF5FC:  jsr     LF11A-$4000                     ; F5FC 20 1A B1                  ..
        jsr     LF8A5-$4000                     ; F5FF 20 A5 B8                  ..
LF602:  iny                                     ; F602 C8                       .
        cpy     #$03                            ; F603 C0 03                    ..
        bcc     LF5EF                           ; F605 90 E8                    ..
        pla                                     ; F607 68                       h
        ldx     #$03                            ; F608 A2 03                    ..
        jsr     LB6A1                           ; F60A 20 A1 B6                  ..
        ldx     #$06                            ; F60D A2 06                    ..
LF60F:  cpx     #$03                            ; F60F E0 03                    ..
        bne     LF62A                           ; F611 D0 17                    ..
        ldy     $0AAB                           ; F613 AC AB 0A                 ...
        beq     LF62A                           ; F616 F0 12                    ..
LF618:  lda     $0AAA                           ; F618 AD AA 0A                 ...
        cmp     #$E8                            ; F61B C9 E8                    ..
        php                                     ; F61D 08                       .
        jsr     LF11A-$4000                     ; F61E 20 1A B1                  ..
        plp                                     ; F621 28                       (
        bcs     LF641                           ; F622 B0 1D                    ..
        jsr     LF8C2-$4000                           ; F624 20 C2 B8                  ..
        dey                                     ; F627 88                       .
        bne     LF618                           ; F628 D0 EE                    ..
LF62A:  asl     $0AAA                           ; F62A 0E AA 0A                 ...
        bcc     LF63D                           ; F62D 90 0E                    ..
        lda     LF714-$4000,x                   ; F62F BD 14 B7                 ...
        jsr     LFFD2_CHROUT                    ; F632 20 D2 FF                  ..
        lda     LF71A-$4000,x                   ; F635 BD 1A B7                 ...
        beq     LF63D                           ; F638 F0 03                    ..
        jsr     LFFD2_CHROUT                    ; F63A 20 D2 FF                  ..
LF63D:  dex                                     ; F63D CA                       .
        bne     LF60F                           ; F63E D0 CF                    ..
        rts                                     ; F640 60                       `
; ----------------------------------------------------------------------------
LF641:  jsr     LF64D-$4000                     ; F641 20 4D B6                  M.
        clc                                     ; F644 18                       .
        adc     #$01                            ; F645 69 01                    i.
        bne     LF64A                           ; F647 D0 01                    ..
        inx                                     ; F649 E8                       .
LF64A:  jmp     LB89F                           ; F64A 4C 9F B8                 L..
; ----------------------------------------------------------------------------

; ?
LF64D:  ldx     $67                             ; F64D A6 67                    .g
        tay                                     ; F64F A8                       .
        bpl     LF653                           ; F650 10 01                    ..
        dex                                     ; F652 CA                       .
LF653:  adc     $66                             ; F653 65 66                    ef
        bcc     LF658                           ; F655 90 01                    ..
        inx                                     ; F657 E8                       .
LF658:  rts                                     ; F658 60                       `
; ----------------------------------------------------------------------------


; Classify Op Code

LF659:  tay                                     ; F659 A8                       .
        lsr     a                               ; F65A 4A                       J
        bcc     LF668                           ; F65B 90 0B                    ..
        lsr     a                               ; F65D 4A                       J
        bcs     LF677                           ; F65E B0 17                    ..
        cmp     #$22                            ; F660 C9 22                    ."
        beq     LF677                           ; F662 F0 13                    ..
        and     #$07                            ; F664 29 07                    ).
        ora     #$80                            ; F666 09 80                    ..
LF668:  lsr     a                               ; F668 4A                       J
        tax                                     ; F669 AA                       .
        lda     LF6C3-$4000,x  ;Mod Tables                 ; F66A BD C3 B6                 ...
        bcs     LF673                           ; F66D B0 04                    ..
        lsr     a                               ; F66F 4A                       J
        lsr     a                               ; F670 4A                       J
        lsr     a                               ; F671 4A                       J
        lsr     a                               ; F672 4A                       J
LF673:  and     #$0F                            ; F673 29 0F                    ).
LF675:  bne     LF67B                           ; F675 D0 04                    ..
LF677:  ldy     #$80                            ; F677 A0 80                    ..
        lda     #$00                            ; F679 A9 00                    ..
LF67B:  tax                                     ; F67B AA                       .
        .byte   $BD                             ; F67C BD                       .
LF67D:  rmb0    STAH                            ; F67D 07 B7                    ..
        sta     $0AAA                           ; F67F 8D AA 0A                 ...
        and     #$03                            ; F682 29 03                    ).
        sta     $0AAB                           ; F684 8D AB 0A                 ...
        tya                                     ; F687 98                       .
        and     #$8F                            ; F688 29 8F                    ).
        tax                                     ; F68A AA                       .
        tya                                     ; F68B 98                       .
        ldy     #$03                            ; F68C A0 03                    ..
        cpx     #$8A                            ; F68E E0 8A                    ..
        beq     LF69D                           ; F690 F0 0B                    ..
LF692:  lsr     a                               ; F692 4A                       J
        bcc     LF69D                           ; F693 90 08                    ..
        lsr     a                               ; F695 4A                       J
LF696:  lsr     a                               ; F696 4A                       J
        ora     #$20                            ; F697 09 20                    .
        dey                                     ; F699 88                       .
        bne     LF696                           ; F69A D0 FA                    ..
        iny                                     ; F69C C8                       .
LF69D:  dey                                     ; F69D 88                       .
        bne     LF692                           ; F69E D0 F2                    ..
        rts                                     ; F6A0 60                       `
; ----------------------------------------------------------------------------
; Get Mnemonic Char
        tay                                     ; F6A1 A8                       .
        lda     LF721-$4000,y  ; Compacted Mnemonics                       ; F6A2 B9 21 B7                 .!.
        sta     $63                             ; F6A5 85 63                    .c
        lda     LF761-$4000,y                         ; F6A7 B9 61 B7                 .a.
        sta     $64                             ; F6AA 85 64                    .d
LF6AC:  lda     #$00                            ; F6AC A9 00                    ..
        ldy     #$05                            ; F6AE A0 05                    ..
LF6B0:  asl     $64                             ; F6B0 06 64                    .d
        rol     $63                             ; F6B2 26 63                    &c
        rol     a                               ; F6B4 2A                       *
        dey                                     ; F6B5 88                       .
        bne     LF6B0                           ; F6B6 D0 F8                    ..
        adc     #$3F                            ; F6B8 69 3F                    i?
        jsr     LFFD2_CHROUT                           ; F6BA 20 D2 FF                  ..
        dex                                     ; F6BD CA                       .
        bne     LF6AC                           ; F6BE D0 EC                    ..
        jmp     LF8A8-$4000                     ; F6C0 4C A8 B8                 L..
; ----------------------------------------------------------------------------

; Mode Tables
LF6C3:  .byte $40, $02, $45, $03, $d0, $08, $40, $09  ;B6C3
        .byte $30, $22, $45, $33, $d0, $08, $40, $09  ;B6CB
        .byte $40, $02, $45, $33, $d0, $08, $40, $09  ;B6D3
        .byte $40, $02, $45, $b3, $d0, $08, $40, $09  ;B6DB
        .byte $00, $22, $44, $33, $d0, $8c, $44, $00  ;B6E3
        .byte $11, $22, $44, $33, $d0, $8c, $44, $9a  ;B6EB
        .byte $10, $22, $44, $33, $d0, $08, $40, $09  ;B6F3
        .byte $10, $22, $44, $33, $d0 ;$08, $40, $09  ;B6FB <truncated>
             ;$62, $13, $78, $A9                      ;B703 <truncated>

; ----------------------------------------------------------------------------

;
;End of the second machine language monitor
;End of code from C128 ROM
;C128 ROM is $D480-F6FF
;
