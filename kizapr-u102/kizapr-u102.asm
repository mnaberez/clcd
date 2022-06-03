;============================================================================
;                  Commodore LCD Kernal ROM Disassembly
;============================================================================
; Taken from an EPROM labelled "kizapr-u102.bin" on Prototype CLCD
;
; Based on this disassembly by Gábor Lénárt:
; https://web.archive.org/web/20170419205827/http://commodore-lcd.lgb.hu/sk/

;=============================================================================
; Memory Map
;=============================================================================
; The machine has an 18-bit address space from $00000 to $3FFFF.
; The CPU only sees $00000 to $0FFFF.
; The MMU can map memory from the upper address space into the CPU space.
; The MMU always maps in the TOP of the KERNAL ROM and the bottom of RAM so
; that the normal reset vectors and KERNAL Jump table is available to handle
; Interupts and KERNAL calls, and the Zero Page and system RAM are always
; available to KERNAL and applications.
; The KERNAL calls map in any resources that it needs and restores the
; state so that the applications can function. The MMU manages READ/WRITE to
; the address space allowing the LCD and MMU registers to hide under the
; fixed KERNAL space. The IO space is always mapped in. The CPU address space
; is divided into KERNAL, four Application Windows, and the System RAM.
; The four Application Windows can contain ROM or RAM from any location in
; the extended address space.

; ADDRESS       SIZE    TYPE                    CONTENTS
; -------       ----    ----                    --------
; 30000-3FFFF   64K     ROM                     KERNAL, Character Set, Monitor
; 20000-2FFFF   64K     ROM                     Applications
; 10000-1FFFF   64K     Expansion RAM
; 00000-0FFFF   64K     Built-in RAM

; The CPU Address Space:
;                               /------------------------- MODES ------------------------\
; ADDRESS       SIZE    TYPE    RAM             APPL            KERN            TEST           NOTES
; -------       ----    ----    ---             ----            ----            ----           -----
; 0FA00-0FFFF   1.5K    Fixed   3FA00-3FFFF     3FA00-3FFFF     3FA00-3FFFF     3FA00-3FFFF    Top of KERNAL. Read from ROM, Write to LCD or MMU
; 0F800-0F9FF   0.5K    I/O     0F800-0F9FF     0F800-0F9FF     0F800-0F9FF     0F800-0F9FF    Fixed I/O (VIAs, ACIA, EXP)
; 0C000-0F7FF   14K     Banked  0C000-0F7FF     Appl Window#4   3C000-3F7FF     Offset 4/5     Configured via MMU
; 08000-0BFFF   16K     Banked  08000-0BFFF     Appl Window#3   38000-3BFFF     Offset 3       Configured via MMU
; 04000-07FFF   16K     Banked  04000-07FFF     Appl Window#2   Kernal Window   Offset 2       Configured via MMU
; 01000-03FFF   12K     Banked  01000-03FFF     Appl window#1   01000-03FFF     Offset 1       Configured via MMU
; 00000-00FFF   4K      Fixed   00000-00FFF     00000-00FFF     00000-00FFF     00000-00FFF    Always fixed

; LCD, MMU, IO Address:

; ADDRESS RANGE TYPE    ADDRESS DESCRIPTION                             NOTES
; ------------- ----    ------- -----------                             -----
; 0FF80-0FFFF   LCD     Custom Gate Array
;                       FF80    [0-6] X-Scroll
;                       FF81    [0-7] Y-Scroll
;                       FF82    [1] Graphics Enable, [0] Chararcter Select
;                       FF83    [5] Test Mode, [4] SS40, [3] CS80, [2] Chr Width

; 0FA00-0FFFF   MMU     Custom Gate Array
;                       FF00    KERN window offset      (write only)    * Sets a pointer to any 1K boundary in the extended address range.
;                       FE80    APPL window#4 offset    (write only)      The top 8 bits (A10-A17) of the extended address are written to
;                       FE00    APPL window#3 offset    (write only)      any of the 5 offset registers (KERNAL or Applcation window).
;                       FD80    APPL window#2 offset    (write only)
;                       FD00    APPL window#1 offset    (write only)

;                       FC80    Select TEST mode        (dummywrite     * Writing ANYTHING to these registers triggers the selected MODE
;                       FC00    Save current mode       (dummywrite)      (see above) or does a SAVE or RECALL operation.
;                       FB80    Recall saved mode       (dummywrite)
;                       FB00    Select RAM mode         (dummywrite)
;                       FA80    Select APPL mode        (dummywrite)
;                       FA00    Select KERN mode        (dummywrite)

; 0F800-0F9FF   I/O     IO Chips and Expansion via rear connector
;                       F980    I/O#4   ACIA            RS-232, Modem
;                       F900    I/O#3   External Expansion
;                       F880    I/O#2   VIA#2           Centronics, RTC, RS-232, Modem, Beeper, Barcode Reader
;                       F800    I/O#1   VIA#1           Keyboard, Battery Level, Alarm, RTC Enable, Power, IEC

; ----------------------------------------------------------------------------

        .setcpu "65C02"

        .org $8000

; ----------------------------------------------------------------------------
L0015           := $0015
L0041           := $0041
L004E           := $004E
L0081           := $0081
VidMemHi        := $00A0
CursorX         := $00A1
CursorY         := $00A2
WIN_TOP_LEFT_X  := $00A3
WIN_BTM_RGHT_X  := $00A4
WIN_TOP_LEFT_Y  := $00A5
WIN_BTM_RGHT_Y  := $00A6
QTSW            := $00A7  ;Quote mode flag (0=quote mode off, nonzero=on)
INSRT           := $00A8  ;Number of chars to insert (1 for each time SHIFT-INS/DEL is pressed)
INSFLG          := $00A9  ;Auto-insert mode flag (0=auto-insert off, nonzero=on)
MODKEY          := $00AD  ;"Modifier" key byte read directly from keyboard shift register
FNADR           := $00AE
EAL             := $00B2
EAH             := $00B3
STAL            := $00B6
STAH            := $00B7
SAL             := $00B8
SAH             := $00B9
SATUS           := $00BA
VidPtrLo        := $00C1
VidPtrHi        := $00C2
SA              := $00C4
FA              := $00C5
LA              := $00C6
LENGTH          := $00CF
V1541_FNADR     := $00E2  ;2 bytes
V1541_DEFAULT_CHAN := $00E6
V1541_ACTIV_FLAGS := $00E7  ; \
V1541_ACTIV_E8    := $00E8  ;  Active Channel
V1541_ACTIV_E9    := $00E9  ;  4 bytes
V1541_ACTIV_EA    := $00EA  ; /
BLNCT             := $00EF  ;Counter for cursor blink
stack             := $0100
ROM_ENV_A         := $0204
ROM_ENV_X         := $0205
ROM_ENV_Y         := $0206
V1541_DATA_BUF    := $0218 ;basic line for dir listing, other unknown uses
V1541_CHAN_BUF    := $024D ;71 bytes, all data for all channels, see V1541_SELECT_CHANNEL_A
V1541_CMD_BUF     := $0295 ;command sent to command channel
V1541_CMD_LEN     := $02d5
V1541_02D6      := $02d6
V1541_02D7      := $02d7
LAT             := $02DB
SAT             := $02F3
FAT             := $02E7
L0300           := $0300
RAMVEC_IRQ      := $0314
RAMVEC_BRK      := $0316
RAMVEC_NMI      := $0318
RAMVEC_OPEN     := $031A
RAMVEC_CLOSE    := $031C
RAMVEC_CHKIN    := $031E
RAMVEC_CHKOUT   := $0320
RAMVEC_CLRCHN   := $0322
RAMVEC_CHRIN    := $0324
RAMVEC_CHROUT   := $0326
RAMVEC_STOP     := $0328
RAMVEC_GETIN    := $032A
RAMVEC_CLALL    := $032C
RAMVEC_WTF      := $032E
RAMVEC_LOAD     := $0330
RAMVEC_SAVE     := $0332
L0334           := $0334
L0336           := $0336
GO_RAM_LOAD_GO_APPL       := $0338  ;
GO_RAM_STORE_GO_APPL      := $0341  ; RAM-resident code loaded from:
GO_RAM_LOAD_GO_KERN       := $034A  ; MMU_HELPER_ROUTINES
GO_NOWHERE_LOAD_GO_KERN   := $034D  ;
SINNER                    := $034E  ; "SINNER" name is from TED-series KERNAL,
GO_APPL_LOAD_GO_KERN      := $0353  ; where similar RAM-resident code is
GO_RAM_STORE_GO_KERN      := $035C  ; modified at runtime.
GO_NOWHERE_STORE_GO_KERN  := $035F  ;
REVERSE         := $036C  ;0=Reverse Off, 0x80=Reverse On
BLNOFF          := $036F  ;0=Cursor Blink On, 0x80=Cursor Blink Off
TABMAP          := $0370
SETUP_LCD_A     := $037A
SETUP_LCD_X     := $037B
SETUP_LCD_Y     := $037C
CurMaxY         := $037E
L0380           := $0380
CurMaxX         := $0381
MSGFLG          := $0383
DFLTN           := $0385
DFLTO           := $0386
FNLEN           := $0387
JIFFIES         := $038F
TOD_SECS        := $0390
TOD_MINS        := $0391
TOD_HOURS       := $0392
ALARM_SECS      := $0393
ALARM_MINS      := $0394
ALARM_HOURS     := $0395
UNKNOWN_SECS    := $0396
UNKNOWN_MINS    := $0397
MemBotLoByte    := $0398
MemBotHiByte    := $0399
MemTopLoByte    := $039A
MemTopHiByte    := $039B
V1541_BYTE_TO_WRITE := $039E
V1541_FNLEN     := $039F
MON_MMU_MODE    := $03A1  ;0=MMU_MODE_RAM, 1=MMU_MODE_APPL, 2=MMU_MODE_KERN
V1541_FILE_MODE := $03A3
V1541_FILE_TYPE := $03A4
L03AB           := $03AB
L03AC           := $03AC
SXREG           := $039D
L03B7           := $03B7
L03C0           := $03C0
LSTP            := $03E8
LSXP            := $03E9
SavedCursorX    := $03EA
SavedCursorY    := $03EB
KEYD            := $03EC
SWITCH_COUNT    := $03FB  ;Counts down to debounce switching upper/lowercase on Shift-Commodore
CAPS_FLAGS      := $03FC
LDTND           := $0405
VERCHK          := $0406
WRBASE          := $0407  ;Temp storage (was low byte of tape write pointer in other CBMs)
BSOUR           := $0408
BSOUR1          := $0409
R2D2            := $040A
C3P0            := $040B
IECCNT          := $040C
RTC_IDX         := $0411
L0450           := $0450
L0470           := $0470
L066A           := $066A
L0810           := $0810
L0A00           := $0A00
L11A0           := $11A0
L1F0C           := $1F0C
L2020           := $2020
L2E6A           := $2E6A
L42D0           := $42D0
L42E4           := $42E4
L4307           := $4307
L4825           := $4825
L4AF3           := $4AF3
L4D37           := $4D37
L4D39           := $4D39
L4DCA           := $4DCA
L4F4C           := $4F4C
L4F7F           := $4F7F
L5044           := $5044
L5061           := $5061
L509D           := $509D
L51D3           := $51D3
L51F0           := $51F0
L51F5           := $51F5
L53DE           := $53DE
L5595           := $5595
L5609           := $5609
L5653           := $5653
L5A79           := $5A79
L5A93           := $5A93
L5A9E           := $5A9E
L673E           := $673E
L6E6E           := $6E6E
L77CB           := $77CB
L77DD           := $77DD
L78C5           := $78C5
L792A           := $792A
L7944           := $7944
L7947           := $7947
L794A           := $794A
L794C           := $794C
L795A           := $795A
L7A73           := $7A73
L7D16           := $7D16
L7E6A           := $7E6A

;Equates

;Used to test MODKEY
MOD_BIT_7  = 128 ;Unknown
MOD_BIT_6  = 64  ;Unknown
MOD_BIT_5  = 32  ;Unknown
MOD_CBM    = 16
MOD_CTRL   = 8
MOD_SHIFT  = 4
MOD_CAPS   = 2
MOD_STOP   = 1

;CBM DOS error codes
doserr_20_read_err        = $14 ;20 read error (block header not found)
doserr_25_write_err       = $19 ;25 write error (write-verify error)
doserr_26_write_prot_on   = $1a ;26 write protect on
doserr_27_read_error      = $1b ;27 read error (checksum error in header)
doserr_31_invalid_cmd     = $1f ;31 invalid command
doserr_32_syntax_err      = $20 ;32 syntax error (long line)
doserr_33_syntax_err      = $21 ;33 syntax error (invalid filename)
doserr_34_syntax_err      = $22 ;34 syntax error (no file given)
doserr_60_write_file_open = $3c ;60 write file open
doserr_61_file_not_open   = $3d ;61 file not open
doserr_62_file_not_found  = $3e ;62 file not found
doserr_63_file_exists     = $3f ;63 file exists
doserr_64_file_type_mism  = $40 ;64 file type mismatch
doserr_67_illegal_sys_ts  = $43 ;67 illegal system t or s
doserr_70_no_channel      = $46 ;70 no channel
doserr_71_dir_error       = $47 ;71 directory error
doserr_72_disk_full       = $48 ;72 disk full
doserr_73_dos_mismatch    = $49 ;73 power-on message

doschan_14_cmd_app   = $0e ;14 unknown channel, seems to be used by "command.cmd" app
doschan_15_command   = $0f ;15 normal cbm dos command channel
doschan_16_directory = $10 ;16 directory channel
doschan_17_unknown   = $11 ;17 unknown channel

;Virtual 1541 file types and modes
ftype_p_prg     = 'P'   ;Program
ftype_s_seq     = 'S'   ;Sequential
fmode_r_read    = 'R'   ;Read
fmode_w_write   = 'W'   ;Write
fmode_a_append  = 'A'   ;Append
fmode_m_modify  = 'M'   ;Modify

; ----------------------------------------------------------------------------
; At offset 4: this byte tells the number of Kbytes to be checked by the ROM
; checksum routine. I don't know the purpose of the other bytes though.
        .byte   $00,$00,$FF,$FF,$10,$DD,$DD,$DD

; ----------------------------------------------------------------------------
Commodore_LCD:
; Every ROM images begins with this "identification" string. This one is also
; used to compare with the searched ones by the ROM scanning routine.
        .byte   "Commodore LCD"

; ----------------------------------------------------------------------------
; Every ROM contains a "directory" with the "applications" to be found.
;
;  - Apps can be displayed on the menu or hidden from it.  An app that is
;    hidden can still be run by typing its name.
;
;  - An app can optionally have a file extension associated with it.  If a
;    period follows the name, the characters that follow are the extension.
;    The menu will then use the app to open files with that extension.  All
;    extensions are 3 characters in the LCD ROMs but this is not required.
;    The extension is part of a regular 16-character CBM filename and can be
;    longer or shorter than 3 characters.
ROM_DIR_START := *

ROM_DIR_ENTRY_MONITOR:
        .byte ROM_DIR_ENTRY_MONITOR_SIZE
        .byte $10               ;$01=show on menu, $10=hidden
        .byte $20               ;unknown
        .byte $00               ;unknown
        .word ROM_ENTRY_MONITOR ;entry point
        .byte "MONITOR"         ;menu name
        .byte ".MON"            ;associated file extension
        ROM_DIR_ENTRY_MONITOR_SIZE = * - ROM_DIR_ENTRY_MONITOR

ROM_DIR_ENTRY_COMMAND:
        .byte ROM_DIR_ENTRY_COMMAND_SIZE
        .byte $01               ;$01=show on menu, $10=hidden
        .byte $20               ;unknown
        .byte $00               ;unknown
        .word ROM_ENTRY_COMMAND ;entry point
        .byte "COMMAND"         ;menu name
        .byte ".CMD"            ;associated file extension
        ROM_DIR_ENTRY_COMMAND_SIZE = * - ROM_DIR_ENTRY_COMMAND

ROM_DIR_END:
        .byte 0
; ----------------------------------------------------------------------------
ROM_ENTRY_MONITOR:
        cpx     #$0E
        bne     L8040
        clc
        jmp     L84FA_MAYBE_SHUTDOWN
L8040:  cpx     #$06
        beq     JMP_MON_START
        cpx     #$04
        beq     JMP_MON_START
        rts
JMP_MON_START:
        jmp     MON_START
; ----------------------------------------------------------------------------
ROM_ENTRY_COMMAND:
        cpx     #$08
        bne     L8066

        lda     #$7E                  ;A = Logical file number (126)
L8052:  ldx     #$01                  ;X = Device 1 (Virtual 1541)
        ldy     #doschan_14_cmd_app   ;Y = Channel 14
        jsr     SETLFS_

        lda     $0423       ;A = Filename length
        ldx     #<$0424     ;XY = Filename
        ldy     #>$0424
        jsr     SETNAM_
        jsr     Open_
L8066:  rts
; ----------------------------------------------------------------------------
L8067:  txa
        tay
        lda     #$FF
L806B:  phy
        ldx     #$00
        phx
        pha
        phy
        cld
        ldx     #$08
L8074:  stx     L03C0
L8077:  dec     L03C0
        ldx     L03C0
        bpl     L8082
        sec
        bra     L80BB
L8082:  lda     ROM_ENV_A
        and     PowersOfTwo,x
        beq     L8077
        lda     ROM_MMU_values,x
        sta     MMU_KERN_WINDOW
        lda     #$40
        sta     $DC
        stz     $DB
        lda     #$15
        .byte   $2C
L8099:  lda     ($DB)
        clc
        adc     $DB
        sta     $DB
        bcc     L80A4
        inc     $DC
L80A4:  lda     ($DB)
        beq     L8077
        tsx
L80A9:  inc     stack+3,x
        ldy     #$01
        lda     ($DB),y
        and     stack+2,x
        beq     L8099
        dec     stack+1,x
        bne     L8099
        clc
L80BB:  ply
        ply
        plx
        ply
        bcc     L80C3
        ldx     #$00
L80C3:  cpx     #$00
        rts
; ----------------------------------------------------------------------------
L80C6:  pha
        ldy     #$01
        phy
L80CA:  ply
        lda     #$07
        jsr     L806B
        beq     L80DC
        pla
        pha
        phy
        ldy     #$03
        eor     ($DB),y
        bne     L80CA
        ply
L80DC:  ply
        cpx     #$00
        rts
; ----------------------------------------------------------------------------
L80E0_DRAW_FKEY_BAR_AND_WAIT_FOR_FKEY_OR_RETURN:
        and     #$3F
        sta     $03BC
        ldx     #$04
        jsr     LD230_JMP_LD233_PLUS_X  ;-> LD255_X_04
        stz     $03BD
        lda     $03BC
        ldy     #$01
        jsr     L806B
        beq     L8148
        lda     #$05
        sta     $03BF
        ldx     #$07
        lda     $03BC
L8101:  cmp     PowersOfTwo,x
        beq     L810B
        dex
        bpl     L8101
        bra     L8115
L810B:  ldy     #$08
        jsr     L806B
        bne     L8115
        inc     $03BF
L8115:  jsr     L815E_DRAW_FKEY_BAR

L8118_WAIT_FOR_FKEY_OR_RETURN_LOOP:
        jsr     LB6DF_GET_KEY_BLOCKING

        ldx     #$09
L811D_FIND_KEY_LOOP:
        cmp     L8154_KEYCODES_FKEYS_AND_RETURNS,x
        beq     L8127_FOUND_KEY
        dex
        bpl     L811D_FIND_KEY_LOOP

        bra     L8118_WAIT_FOR_FKEY_OR_RETURN_LOOP

L8127_FOUND_KEY:
        txa             ;A = 0=F1,1=F2,2=F3,3=F4,4=F5,5=F6,6=F7,7=F8,8=RETURN,9=SHIFT-RETURN
        cmp     #$07
        bcs     L8148
        cmp     #$06    ;F7
        bne     L813A
        cmp     $03BF
        beq     L813A
        jsr     L815E_DRAW_FKEY_BAR
        bra     L8118_WAIT_FOR_FKEY_OR_RETURN_LOOP

L813A:  clc
        adc     $03BE
        tay
        lda     $03BD
        jsr     L806B
        beq     L8118_WAIT_FOR_FKEY_OR_RETURN_LOOP
        .byte   $2C
L8148:  ldx     #$00
        phx
        pha
        ldx     #$06
        jsr     LD230_JMP_LD233_PLUS_X  ;-> LD297_X_06
        pla
        plx
        rts

L8154_KEYCODES_FKEYS_AND_RETURNS:
        .byte   $85 ;F1
        .byte   $89 ;F2
        .byte   $86 ;F3
        .byte   $8A ;F4
        .byte   $87 ;F5
        .byte   $8B ;F6
        .byte   $88 ;F7
        .byte   $8C ;F8
        .byte   $0D ;RETURN
        .byte   $8D ;SHIFT-RETURN
; ----------------------------------------------------------------------------
L815E_DRAW_FKEY_BAR:
        sec
        cld
        lda     $03BF
        adc     $03BE
        sta     $03BE
L8169:  ldy     $03BE
        lda     $03BD
        jsr     L806B
        bne     L818A
        ldy     #$01
        sty     $03BE
L8179:  lda     $03BD
        asl     a
        bne     L8180
        inc     a
L8180:  sta     $03BD
        bit     $03BC
        beq     L8179
        bra     L8169

L818A:
        ldx     #$00
L818C_OUTER_LOOP:
        phx
        phy
        jsr     L81E0_PUT_CHAR_IN_FKEY_BAR
        lda     #<MORE_EXIT
        sta     $DB
        lda     #>MORE_EXIT
        sta     $DC
        tsx
        lda     stack+2,x
        ldy     #$07 ;0-7 for F1-F8
        cmp     #$07
        beq     L81B8_INNER_LOOP
        ldy     #$00
        dec     a
        cmp     $03BF
        beq     L81B8_INNER_LOOP
        ldy     stack+1,x
        lda     $03BD
        jsr     L806B
        beq     L81C5_PERIOD

        ldy     #$06
L81B8_INNER_LOOP:
        lda     ($DB),y
        cmp     #'.'
        beq     L81C5_PERIOD
        clc
        jsr     LB6F9_MAYBE_PUT_CHAR_IN_FKEY_BAR_SLOT
        iny
        bra     L81B8_INNER_LOOP

L81C5_PERIOD:
        lda     #$0D
        clc
        jsr     LB6F9_MAYBE_PUT_CHAR_IN_FKEY_BAR_SLOT
        ply
        plx
        iny
        inx
        cpx     #$08 ;0-7 for F1-F8
        bne     L818C_OUTER_LOOP
        rts
MORE_EXIT:
        .byte   "<MORE>."
        .byte   "EXIT."
; ----------------------------------------------------------------------------
L81E0_PUT_CHAR_IN_FKEY_BAR:
        ldy     L81F3_FKEY_COLUMNS,x
        ldx     $039C
        lda     #$89
        sec
        jsr     LB6F9_MAYBE_PUT_CHAR_IN_FKEY_BAR_SLOT
        lda     #$67
        ldy     #$09
        sta     ($BD),y
        rts

L81F7 := *+4
L81F3_FKEY_COLUMNS:
        ;      F1,F2,F3,F4,F5,F6,F7,F8
        .byte   0,10,20,30,40,50,60,70  ;Starting column on bottom screen line
; ----------------------------------------------------------------------------
L81FB:  stz     $0450
        jsr     L806B
        beq     L821C
        phx
        pha
        phy
        ldx     #$00
        ldy     #$06
L820A:  lda     ($DB),y
        sta     $0450,x
        inx
        iny
        tya
        cmp     ($DB)
        bne     L820A
        stz     $0450,x
        ply
        pla
        plx
L821C:  rts
; ----------------------------------------------------------------------------
L821D:  lda     #FNADR
        sta     SINNER
        ldx     FNLEN
        beq     L826E
        ldy     #$01
L8229:  lda     #$7F
        jsr     L806B
        beq     L826E
        pha
        phx
        phy
        ldx     FNLEN
        beq     L826E
        lda     ($DB)
        tay
L823B:  dey
        dex
        bmi     L824D
        jsr     L826F
        cmp     ($DB),y
        bne     L824D
        cmp     #$2E
        bne     L823B
        clc
        bra     L826B
L824D:  ldy     #$06
        ldx     #$00
L8251:  jsr     L826F
        cmp     ($DB),y
        bne     L8265
        inx
        iny
        cpx     FNLEN
        bne     L8251
        lda     ($DB),y
        cmp     #'.'
        beq     L826B
L8265:  ply
        plx
        pla
        iny
        bra     L8229
L826B:  ply
        plx
        pla
L826E:  rts
; ----------------------------------------------------------------------------
L826F:  phy
        txa
        tay
        jsr     GO_RAM_LOAD_GO_KERN
        ply
        rts
; ----------------------------------------------------------------------------
; Interesting, though I don't know the purpose of the given ZP locations. It
; seems, $FD00, $FD80, $FE00, $FE80 are used some kind of MMU purpose, based
; on value CMP'd with constants which suggests memory is divided into parts
; (high byte only): $00-$3F, $40-$7F, $80-$BF, $C0-$F7, $F8-$FF.
L8277:  sei
        phx
        ldx     L03C0
        lda     ROM_MMU_values,x
        clc
        adc     #$10
        ldy     #$02
        sec
        sbc     ($DB),y
        tax
        ldy     #$05
        lda     ($DB),y
        cmp     #$F8
        bcs     L82B1
        stz     MMU_APPL_WINDOW1
        stz     MMU_APPL_WINDOW2
        stz     MMU_APPL_WINDOW3
        cmp     #$C0
        bcs     L82AE_WINDOW4
        cmp     #$80
        bcs     L82AB_WINDOW3
        cmp     #$40
        bcs     L82A8_WINDOW2
        stx     MMU_APPL_WINDOW1
L82A8_WINDOW2:
        stx     MMU_APPL_WINDOW2
L82AB_WINDOW3:
        stx     MMU_APPL_WINDOW3
L82AE_WINDOW4:
        stx     MMU_APPL_WINDOW4
L82B1:  pha
        dey
        lda     ($DB),y
        ply
        cmp     #$00
        bne     L82BB
        dey
L82BB:  dec     a
        plx
        rts
; ----------------------------------------------------------------------------
L82BE_CHECK_ROM_ENV:
        jsr     ScanROMs
        sta     ROM_ENV_A
        stx     ROM_ENV_X
        sty     ROM_ENV_Y
        rts
; ----------------------------------------------------------------------------
ROM_MMU_values:
; The 'ScanROMs' routine uses this table to write values to $FF00 to check
; for ROMs.
        .byte   $70,$80,$90,$A0,$B0,$C0,$D0,$E0
; ----------------------------------------------------------------------------
ScanROMs:
; This routine seems to scan ROMs, searching for the "Commodore LCD" string.
; This is done by using register at $FF00 which seems to tell the memory
; mapping at CPU address $4000. So I think $FF00 tells what is mapped to
; $4000.
        lda     #$00
        pha
        pha
        pha
        ldy     #$07
L82DA:  lda     ROM_MMU_values,y
        sta     MMU_KERN_WINDOW
        phy
        ldx     #$0C
L82E3:  lda     $4008,x
        cmp     Commodore_LCD,x
        bne     L8315
        dex
        bpl     L82E3
        ply
        phy
        lda     ROM_MMU_values,y
; $4004 is the paged-in ROM, where the id string would be ($FF00 controls
; what can you see from $4000), it's compared with the kernal's image's id
; string ("Commodore LCD").
        ldx     $4004
        pha
        jsr     RomCheckSum
        ply
        sty     MMU_KERN_WINDOW
L82FE:  phx
        tsx
        clc
        adc     stack+4,x
        sta     stack+4,x
; Hmm, it seems to be a bug for me, it should be 'pla', otherwise X is messed
; up to be used to address byte on the stack.
        plx
        adc     stack+5,x
        sta     stack+5,x
        ply
        phy
        jsr     PrintRomSumChkByPassed
        sec
        .byte   $24 ;skip 1 byte
L8315:  clc
        ply
        tsx
        rol     stack+1,x
        dey
        bpl     L82DA
        pla
        ply
        plx
        cmp     ROM_ENV_A
        bne     L832E_RTS
        cpx     ROM_ENV_X
        bne     L832E_RTS
        cpy     ROM_ENV_Y
L832E_RTS:
        rts
; ----------------------------------------------------------------------------
PrintRomSumChkByPassed:
; Push Y onto the stack. Write "ROMSUM ...." text, then take the value from
; the stack, "covert" into an ASCII number (ORA), and print it, followed by
; the " INSTALLED" text.
        phy
        jsr     PRIMM
        .byte   "ROMSUM CHECK BYPASSED, ROM #",0
        pla
        ora     #$30
        jsr     KR_ShowChar_
        jsr     PRIMM
        .byte   "  INSTALLED",$0d,0
        rts
; ----------------------------------------------------------------------------
RomCheckSum:
; Creates checksum on ROMs.
; Input:
;        A = value of $FF00 reg to start at
;        X = number of Kbytes to check
; Output:
;        X/A = 16 bit checksum (simple addition, X is the high byte)
        sta     $03C2
        stx     $03C1
        lda     #$00
        tax
        cld
L8371:  ldy     $03C2
        sty     MMU_KERN_WINDOW
        ldy     #$00
        clc
L837A:  adc     $4000,y
        bcc     L8381
        clc
        inx
L8381:  adc     $4100,y
        bcc     L8388
        clc
        inx
L8388:  adc     $4200,y
        bcc     L838F
        clc
        inx
L838F:  adc     $4300,y
        bcc     L8396
        clc
        inx
L8396:  iny
        bne     L837A
        inc     $03C2
        dec     $03C1
        bne     L8371
        rts
; ----------------------------------------------------------------------------
L83A2:  lda     $DD                             ; 83A2 A5 DD                    ..
        ldx     $DE                             ; 83A4 A6 DE                    ..
        ldy     $DF                             ; 83A6 A4 DF                    ..
        pha                                     ; 83A8 48                       H
        phx                                     ; 83A9 DA                       .
        phy                                     ; 83AA 5A                       Z
        lda     #$0F                            ; 83AB A9 0F                    ..
        sta     $DE                             ; 83AD 85 DE                    ..
        lda     #$00                            ; 83AF A9 00                    ..
        sta     $DD                             ; 83B1 85 DD                    ..
        sta     $DF                             ; 83B3 85 DF                    ..
        pha                                     ; 83B5 48                       H
        pha                                     ; 83B6 48                       H
        tay                                     ; 83B7 A8                       .
        tsx                                     ; 83B8 BA                       .
        cld                                     ; 83B9 D8                       .
L83BA:  clc                                     ; 83BA 18                       .
        adc     ($DD),y                         ; 83BB 71 DD                    q.
        bcc     L83C7                           ; 83BD 90 08                    ..
        inc     stack+1,x                       ; 83BF FE 01 01                 ...
        bne     L83C7                           ; 83C2 D0 03                    ..
        inc     stack+2,x                       ; 83C4 FE 02 01                 ...
L83C7:  iny                                     ; 83C7 C8                       .
        bne     L83BA                           ; 83C8 D0 F0                    ..
        dec     $DE                             ; 83CA C6 DE                    ..
        dec     $DE                             ; 83CC C6 DE                    ..
        beq     L83BA                           ; 83CE F0 EA                    ..
        inc     $DE                             ; 83D0 E6 DE                    ..
        bpl     L83BA                           ; 83D2 10 E6                    ..
        plx                                     ; 83D4 FA                       .
        ply                                     ; 83D5 7A                       z
        sta     $DD                             ; 83D6 85 DD                    ..
        stx     $DE                             ; 83D8 86 DE                    ..
        sty     $DF                             ; 83DA 84 DF                    ..
        ply                                     ; 83DC 7A                       z
        plx                                     ; 83DD FA                       .
        pla                                     ; 83DE 68                       h
        cmp     $DD                             ; 83DF C5 DD                    ..
        bne     L83EB                           ; 83E1 D0 08                    ..
        cpx     $DE                             ; 83E3 E4 DE                    ..
        bne     L83EB                           ; 83E5 D0 04                    ..
        cpy     $DF                             ; 83E7 C4 DF                    ..
        beq     L83EC                           ; 83E9 F0 01                    ..
L83EB:  clc                                     ; 83EB 18                       .
L83EC:  rts                                     ; 83EC 60                       `
; ----------------------------------------------------------------------------
L83ED:  lda     #$02                            ; 83ED A9 02                    ..
        .byte   $2C                             ; 83EF 2C                       ,
L83F0:  lda     #$00                            ; 83F0 A9 00                    ..
        bit     $10A9                           ; 83F2 2C A9 10                 ,..
        ldx     #$01                            ; 83F5 A2 01                    ..
L83F7:  phx                                     ; 83F7 DA                       .
        pha                                     ; 83F8 48                       H
        jsr     L840F                           ; 83F9 20 0F 84                  ..
        bcs     L8407                           ; 83FC B0 09                    ..
        jsr     KL_RESTOR                       ; 83FE 20 96 C6                  ..
        plx                                     ; 8401 FA                       .
        phx                                     ; 8402 DA                       .
        jsr     L8420                           ; 8403 20 20 84                   .
        clc                                     ; 8406 18                       .
L8407:  pla                                     ; 8407 68                       h
        plx                                     ; 8408 FA                       .
        inx                                     ; 8409 E8                       .
        bcc     L83F7                           ; 840A 90 EB                    ..
        jmp     KL_RESTOR                       ; 840C 4C 96 C6                 L..
; ----------------------------------------------------------------------------
L840F:  jsr     L8067                           ; 840F 20 67 80                  g.
        beq     L841C                           ; 8412 F0 08                    ..
        bit     #$C0                            ; 8414 89 C0                    ..
        bne     L841C                           ; 8416 D0 04                    ..
        ldy     #$01                            ; 8418 A0 01                    ..
        clc                                     ; 841A 18                       .
        rts                                     ; 841B 60                       `
; ----------------------------------------------------------------------------
L841C:  sec                                     ; 841C 38                       8
        bit     #$00                            ; 841D 89 00                    ..
        rts                                     ; 841F 60                       `
; ----------------------------------------------------------------------------
L8420:  jsr     L8277                           ; 8420 20 77 82                  w.
        jmp     LFA67                           ; 8423 4C 67 FA                 Lg.
; ----------------------------------------------------------------------------
MON_CMD_EXIT:
L8426:  stz     $0202                           ; 8426 9C 02 02                 ...
        ldx     $0203                           ; 8429 AE 03 02                 ...
        stx     $0200                           ; 842C 8E 00 02                 ...
        stz     $0203                           ; 842F 9C 03 02                 ...
L8433           := * + 1
        jsr     L840F                           ; 8432 20 0F 84                  ..
        bcc     L843A                           ; 8435 90 03                    ..
        jmp     L843F                           ; 8437 4C 3F 84                 L?.
; ----------------------------------------------------------------------------
L843A:  ldx     #$0A                            ; 843A A2 0A                    ..
        jsr     L8420                           ; 843C 20 20 84                   .
L843F:  jsr     L8685                           ; 843F 20 85 86                  ..
        lda     #$20                            ; 8442 A9 20                    .
        ldy     #$01                            ; 8444 A0 01                    ..
        jsr     L806B                           ; 8446 20 6B 80                  k.
        clc                                     ; 8449 18                       .
        jsr     L8459                           ; 844A 20 59 84                  Y.
        ldy     #$01                            ; 844D A0 01                    ..
        lda     #$10                            ; 844F A9 10                    ..
        jsr     L806B                           ; 8451 20 6B 80                  k.
        clc                                     ; 8454 18                       .
        jsr     L8459                           ; 8455 20 59 84                  Y.
        brk                                     ; 8458 00                       .
L8459:  ldy     $0202                           ; 8459 AC 02 02                 ...
        bne     L843F                           ; 845C D0 E1                    ..
        bcc     L8472                           ; 845E 90 12                    ..
        jsr     L840F                           ; 8460 20 0F 84                  ..
        beq     L84C3                           ; 8463 F0 5E                    .^
        bit     #$12                            ; 8465 89 12                    ..
        beq     L84C3                           ; 8467 F0 5A                    .Z
        ldy     $0200                           ; 8469 AC 00 02                 ...
        sty     $0203                           ; 846C 8C 03 02                 ...
        stz     $0200                           ; 846F 9C 00 02                 ...
L8472:  jsr     L840F                           ; 8472 20 0F 84                  ..
        beq     L84C3                           ; 8475 F0 4C                    .L
        bit     #$01                            ; 8477 89 01                    ..
        bne     L849B                           ; 8479 D0 20                    .
        bit     #$12                            ; 847B 89 12                    ..
        bne     L8482                           ; 847D D0 03                    ..
        stz     $0203                           ; 847F 9C 03 02                 ...
L8482:  sta     $0201                           ; 8482 8D 01 02                 ...
        stx     $0200                           ; 8485 8E 00 02                 ...
        sei                                     ; 8488 78                       x
        jsr     KL_RESTOR                       ; 8489 20 96 C6                  ..
        ldx     #$04                            ; 848C A2 04                    ..
        lda     $0203                           ; 848E AD 03 02                 ...
        beq     L8495                           ; 8491 F0 02                    ..
        ldx     #$06                            ; 8493 A2 06                    ..
L8495:  jsr     L8420                           ; 8495 20 20 84                   .
        jmp     L8426                           ; 8498 4C 26 84                 L&.
; ----------------------------------------------------------------------------
L849B:  stx     $0202
        php
        sei
        jsr     LC6CB
        jsr     KL_RESTOR
        ldx     #$08
        jsr     L8420
        sei
        jsr     LC6CB
L84B0 := *+1
        stz     $0202
        ldx     $0200
        jsr     L840F
        beq     L84C0
        jsr     L8277
        plp
        sec
        rts
; ----------------------------------------------------------------------------
L84C0:  jmp     L8426
; ----------------------------------------------------------------------------
L84C3:  clc
        rts
; ----------------------------------------------------------------------------
L84C5:  php
        sei
        ldx     $0202
        beq     L84DA
        jsr     LC6CB
L84D0 := * +1
        jsr     L84ED
        jsr     LC6CB
        ldx     $0202
        bra     L84E0
L84DA:  jsr     L84ED
        ldx     $0200
L84E0:  jsr     L840F
        beq     L84EA
        jsr     L8277
        plp
        rts
; ----------------------------------------------------------------------------
L84EA:  jmp     L843F
; ----------------------------------------------------------------------------
L84ED:  ldx     $0200
        jsr     L840F
        beq     L84FA_MAYBE_SHUTDOWN
        ldx     #$0E
        jmp     L8420
; ----------------------------------------------------------------------------
; This seems to be the "shutdown" function or part of it: "state" should be
; saved (which is checked on next reset to see it was a clean shutdown) and
; then it used /POWEROFF line to actually switch the power off (the RAM is
; still powered at least on CLCD!)
L84FA_MAYBE_SHUTDOWN:
        sec
L84FB:  php
        sei
        php
        ldx     #$00
L8500:  phx
        jsr     LFCF1_APPL_CLOSE
        plx
        dex
        bpl     L8500
        plp
        bcs     L8510
        tsx
        cpx     #$20
        bcs     L8516
L8510:  ldx     #$FF
        tsx
        jsr     L8685
L8516:  jsr     L889A
        jsr     L83ED
        jsr     L8644_CHECK_BUTTON
        jsr     L86E9_MAYBE_V1541_SHUTDOWN
        sei
        tsx
        stx     $0207
        jsr     L83A2
; Release /POWERON signal, machine will switch off. Run the endless BRA if it
; needs some cycle to happen or some kind of odd problem makes it impossible
; to power off actually.
        lda     #$04
        tsb     VIA1_PORTB
        trb     VIA1_DDRB
L8532:  bra     L8532

KL_RESET:
; *************************************
; Start of the real RESET routine after
; MMU set up.
; *************************************
        sei
; As soon as possible set /POWERON signal to low (low-active signal)
; configure DDR bit as well.
        lda     #$04
        tsb     VIA1_DDRB
        trb     VIA1_PORTB
        ldx     $0207
        txs
        cpx     #$20
        bcc     L8582_COULD_NOT_RESTORE_STATE
        jsr     L83A2
        bne     L8582_COULD_NOT_RESTORE_STATE
        sec
        jsr     LCDsetupGetOrSet
        jsr     L870F_CHECK_V1541_DISK_INTACT
        bcs     L8582_COULD_NOT_RESTORE_STATE ;Branch if not intact
        jsr     ScanROMs
        bne     L8582_COULD_NOT_RESTORE_STATE
        ldx     $0200
        jsr     L840F
        beq     L8582_COULD_NOT_RESTORE_STATE
        jsr     InitIOhw
        jsr     KBD_TRIGGER_AND_READ_NORMAL_KEYS
        jsr     KBD_READ_MODIFIER_KEYS_DO_SWITCH_AND_CAPS
        lsr     a ;Bit 0 = MOD_STOP
        bcs     L8582_COULD_NOT_RESTORE_STATE ;Branch if STOP is pressed
        jsr     L83F0
        jsr     L8644_CHECK_BUTTON
        jsr     L887F
        ldx     $0200
        jsr     L840F
        beq     L8582_COULD_NOT_RESTORE_STATE
        jsr     L8277
        plp
        rts
; ----------------------------------------------------------------------------
L8582_COULD_NOT_RESTORE_STATE:
        ldx     #$FF
        txs
        jsr     L8685
        cli
        jsr     PRIMM
        .byte   " COULD NOT RESTORE PREVIOUS STATE",$0d,$07,0
        ldx     #$02
        jsr     WaitXticks_
        lda     MODKEY
        and     #MOD_CBM + MOD_SHIFT + MOD_CTRL + MOD_CAPS + MOD_STOP
        eor     #MOD_CBM + MOD_SHIFT + MOD_STOP
        bne     L85C0
        jmp     L87C5
; ----------------------------------------------------------------------------
L85C0:  jsr     L870F_CHECK_V1541_DISK_INTACT
        bcc     L85E2 ;branch if intact
        jsr     PRIMM
        .byte   "YOUR DISK IS NOT INTACT",$0d,$07,0
; ----------------------------------------------------------------------------
L85E2:  jsr     L82BE_CHECK_ROM_ENV
        beq     L8607
        jsr     PRIMM
        .byte   "ROM ENVIROMENT HAS CHANGED",$0d,$07,0
; ----------------------------------------------------------------------------
L8607:  jsr     L889A
        jsr     L83F0
        jsr     L8644_CHECK_BUTTON
        stz     $0384
        lda     #$0E
        sta     CursorY
        jsr     PRIMM
        .byte   "PRESS ANY KEY TO CONTINUE",0
        cli
        jsr     LB2D6_SHOW_CURSOR
        jsr     LB6DF_GET_KEY_BLOCKING
        jsr     LB2E4_HIDE_CURSOR
        jsr     PrintNewLine
        jmp     L843F
; ----------------------------------------------------------------------------
L8644_CHECK_BUTTON:
        cli
        ldy     #$00
L8647:  ldx     #$02
        jsr     WaitXticks_
        lda     MODKEY
        bit     #MOD_BIT_5
        bne     L8653
        rts
L8653:  iny
        bne     L8647
        jsr     PRIMM80
        .byte   "HEY, LEAVE OFF THE BUTTON, WILL YA ??",$0D,0
        jsr     BELL
        bra     L8644_CHECK_BUTTON
; ----------------------------------------------------------------------------
L8685:  stz     $0200
        stz     $0203
        stz     $0202
        jsr     KL_IOINIT
        jsr     L87BA_INIT_KEYB_AND_EDITOR
        jsr     KL_RESTOR
        jsr     LFDDF_JSR_LFFE7_CLALL
        jsr     L8C6F_V1541_I_INITIALIZE
        stz     $0384
; Set MEMBOT vector to $0FFF
        ldy     #>$0FFF
        ldx     #<$0FFF
        clc
        jmp     MEMBOT__
; ----------------------------------------------------------------------------
KL_RAMTAS:
        php
; D9/DA shows here the tested amount of RAM to be found OK, starts from zero
        sei
        stz     $D9
        stz     $DA
; This seems to test the zero page memory.
        ldx     #$00
L86B0_LOOP:
        lda     $00,x
        ldy     #$01
L86B4:  eor     $FF
        sta     $00,x
        cmp     $00,x
        bne     L86E3_NOT_EQUAL
        dey
        bpl     L86B4
        dex
        bne     L86B0_LOOP

; Test rest of the RAM, using the kernal window to page in the testable area.
L86C2:  lda     $D9
        ldx     $DA
        inc     a
        bne     L86CA
        inx
L86CA:  jsr     L8A87
        ldy     #$00
L86CF:  lda     ($E4),y
        ldx     #$01
L86D3:  eor     #$FF
        sta     ($E4),y
        cmp     ($E4),y
        bne     L86E3_NOT_EQUAL
        dex
        bpl     L86D3
        iny
L86DF:  bne     L86CF
        bra     L86C2

L86E3_NOT_EQUAL:
        lda     $D9
        ldx     $DA
        plp
        rts
; ----------------------------------------------------------------------------
;Called only from L84FA_MAYBE_SHUTDOWN
L86E9_MAYBE_V1541_SHUTDOWN:
        jsr     L8C6F_V1541_I_INITIALIZE
        jsr     L86F6_V1541_UNKNOWN
        sta     $02D9
        sty     $02DA
        rts

;Called only from routine directly above (L86E9_MAYBE_V1541_SHUTDOWN)
L86F6_V1541_UNKNOWN:
        cld
        lda     #$00
        tay
        ldx     #$D1
L86FC:  clc
        adc     $0208,x
        bcc     L8703
        iny
L8703:  dex
        bpl     L86FC
        cmp     $02D9
        bne     L870E
        cpy     $02DA
L870E:  rts
; ----------------------------------------------------------------------------
;carry clear = intact, set = not intact
L870F_CHECK_V1541_DISK_INTACT:
        jsr     L8E46
        bcc     L8745
        lda     $020A
        ldx     $020B
        bne     L8720
        cmp     #$10
        bcc     L8745
L8720:  jsr     KL_RAMTAS
        cmp     $0208
        bne     L8745
        cpx     $0209
        bne     L8745
        cpx     $020B
        bcc     L8745
        bne     L8739
        cmp     $020A
        bcc     L8745
L8739:  cpx     #$02
        bcc     L8743
        bne     L8745
        cmp     #$00
        bne     L8745
L8743:  clc
        rts
; ----------------------------------------------------------------------------
L8745:  sec
        rts
; ----------------------------------------------------------------------------
KL_IOINIT:
        jsr     InitIOhw
        jsr     KEYB_INIT

        ;Clear alarm seconds, minutes, hours
        ldx     #$02
L874F:  stz     ALARM_SECS,x
        dex
        bpl     L874F

        stz     DFLTN ;Default input = 0 Keyboard

        lda     #$03
        sta     DFLTO ;Default output = 3 Screen

        lda     #$FF
        sta     MSGFLG
        rts
; ----------------------------------------------------------------------------
InitIOhw:
; Inits VIAs, ACIA and possible other stuffs with JSRing routines.
        php
        sei
        lda     #$FF
        sta     VIA1_DDRA

        lda     #%00111111  ;PB7 = Input    IEC DAT In
                            ;PB6 = Input    IEC CLK In
                            ;PB5 = Output   IEC DAT Out
                            ;PB4 = Output   IEC CLK Out
                            ;PB3 = Output   IEC ATN Out
                            ;PB2 = Output   ?
                            ;PB1 = Output   ?
                            ;PB0 = Output   ?
        sta     VIA1_DDRB

        lda     #$00
        sta     VIA1_PORTB

        lda     #%01001000  ;ACR7=0 Timer 1 PB7 Output = Disabled
                            ;ACR6=1 Timer 1 = Continuous (Jiffy clock)
                            ;ACR5=0 Timer 2 = One-shot (IEC)
                            ;ACR4=0 \
                            ;ACR3=1  Shift in under control of Phi2
                            ;ACR2=0 /
                            ;ACR1=0 Port B Latch = Disabled
                            ;ACR0=0 Port A Latch = Disabled
        sta     VIA1_ACR

        lda     #%10100000  ;PCR7=1 \
                            ;PCR6=0  CB2 Control = Pulse Output (Beeper)
                            ;PCR5=1 /
                            ;PCR4=0 CB1 Interrupt Control = Negative Active Edge
                            ;PCR3=0 \
                            ;PCR2=0  CA2 Control = Input-negative active edge
                            ;PCR1=0 /
                            ;PCR0=0 CA1 Interrupt Control = Negative Active Edge
        sta     VIA1_PCR

                            ;Timer 1 Count (Jiffy clock)
        lda     #<16666     ;TOD clock code in IRQ handler expects to be called at 60 Hz.
        sta     VIA1_T1LL   ;60 Hz has a period of 16666 microseconds.
        lda     #>16666     ;Timer 1 fires every 16666 microseconds by counting phi2.
        sta     VIA1_T1CH   ;Phi2 must be 1 MHz, since 1 MHz has a period of 1 microsecond.

        lda     #%11000000  ;IER7=1 Set/Clear=Set interrupts
                            ;IER6=1 Timer 1 interrupt enabled (Jiffy clock)
                            ;All other interrupts disabled
        sta     VIA1_IER

        stz     VIA2_PORTA
        lda     #$FF
        sta     VIA2_DDRA
        lda     #$AF
        sta     VIA2_DDRB
        lda     #$82
        sta     VIA2_PORTB
        lda     #$00
        sta     VIA2_ACR
        lda     #$0C
        sta     VIA2_PCR
        lda     #$80
        sta     VIA2_IFR
        stz     ACIA_ST
        jsr     LBFBE ;UNKNOWN_SECS/MINS
        sec
        jsr     LCDsetupGetOrSet
        plp
        rts
; ----------------------------------------------------------------------------
L87BA_INIT_KEYB_AND_EDITOR:
        jsr     KEYB_INIT
        ldx     #$00
        jsr     LD230_JMP_LD233_PLUS_X ;-> LD247_X_00
        jmp     SCINIT_
; ----------------------------------------------------------------------------
L87C5:  sei
        ldx     #$FF
        txs
        inx
L87CA:  stz     $00,x
        stz     stack,x
        stz     $0200,x
        stz     L0300,x
        stz     $0400,x
        inx
        bne     L87CA
        jsr     L8685
        cli
L87F0 := *+17
L87F3 := *+20
        jsr     PRIMM
        .byte   "ESTABLISHING SYSTEM PARAMETERS ",$07,$0D,0
; ----------------------------------------------------------------------------
L8805           := * + 1
        jsr     L82BE_CHECK_ROM_ENV
        lda     #$0F
L880B           := * + 2
        sta     $020C
L880E           := * + 2
        jsr     KL_RAMTAS
L8811           := * + 2
        sta     $0208
        stx     $0209
        sta     $020A
        stx     $020B
        stx     $00
        lsr     $00
        ror     a
        lsr     $00
        ror     a
        jsr     L8850
        jsr     L8E5C
L882A := *+1
L882D := *+4
L8841 := *+24
L8844 := *+27
        jsr PRIMM
        .byte   " KBYTE SYSTEM ESTABLISHED",$0d,0
        jsr     LD411
        jsr     L8644_CHECK_BUTTON
        jmp     L843F
; ----------------------------------------------------------------------------
L8850:  jsr     L886A
        pha
        phx
        tya
        bne     L885D
        pla
        bne     L8861
        beq     L8864
L885D:  jsr     L8865
        pla
L8861:  jsr     L8865
L8864:  pla
L8865:  ora     #$30
        jmp     KR_ShowChar_
; ----------------------------------------------------------------------------
L886A:  ldy     #$FF
        cld
        sec
L886E:  iny
        sbc     #$64
        bcs     L886E
        adc     #$64
        ldx     #$FF
L8877:  inx
        sbc     #$0A
        bcs     L8877
        adc     #$0A
        rts
; ----------------------------------------------------------------------------
L887F:  clc
        jsr     L88C2
        bit     $0384
        bvc     L8896
        ldy     #$02
L888A:  lda     ($E4),y
        sta     SETUP_LCD_A,y
        dey
        bpl     L888A
        sec
        jsr     LCDsetupGetOrSet
L8896:  stz     $0384
        rts
; ----------------------------------------------------------------------------
L889A:  jsr     LBE69
        sec
        jsr     L88C2
        bit     $0384
        bvc     L88BF
        lda     #$93 ;CHR$(147) Clear Screen
        jsr     KR_ShowChar_
        ldy     #$02
L88AD:  lda     SETUP_LCD_A,y
        sta     ($E4),y
        dey
        bpl     L88AD
        and     #$01
        ldy     VidMemHi
        ldx     #$00
        clc
        jsr     LCDsetupGetOrSet
L88BF:  jmp     KL_RESTOR
; ----------------------------------------------------------------------------
L88C2:  ldx     #$C0
        ldy     #$04
        jsr     KL_VECTOR
        lda     $020C
        ldx     $020D
        inc     a
        bne     L88D3
        inx
L88D3:  cpx     $020B
        bcc     L88E5
        bne     L88DF
        cmp     $020A
        bcc     L88E5
L88DF:  lda     #$80
        sta     $0384
        rts
; ----------------------------------------------------------------------------
L88E5:  jsr     L8A87
        lda     #$FF
        sta     $0384
        lda     #$05
        sta     $03E7
        ldy     #$FF
L88F4:  phy
        clc
        cld
        lda     $03E7
        adc     #$04
        tax
        ldy     #$13
        sec
        jsr     LB6F9_MAYBE_PUT_CHAR_IN_FKEY_BAR_SLOT
        ply
        ldx     #$29
L8906:  phy
        lda     ($E4),y
        pha
        phy
        txa
        tay
        lda     ($BD),y
        ply
        sta     ($E4),y
        txa
        tay
        pla
        sta     ($BD),y
        ply
        dey
        dex
        bpl     L8906
        dec     $03E7
        bpl     L88F4
        rts
; ----------------------------------------------------------------------------
L8922:  lda     #$05
        sta     $03E7
        ldx     #$A4
L8929:  jsr     L893C
        ldx     #$0D
        dec     $03E7
        bne     L8929
        ldx     #$A3
        jsr     L893C
        lda     #$0D
        bra     L8948
; ----------------------------------------------------------------------------
L893C:  phx
        jsr     L8964
        plx
L8941:  txa
        jsr     L897C
        bcc     L8941
        rts
; ----------------------------------------------------------------------------
L8948:  cmp     #$07 ;CHR$(7) Bell
        bne     L894F
        jmp     BELL
; ----------------------------------------------------------------------------
L894F:  cmp     #$93 ;CHR$(147) Clear Screen
        beq     L8922
        cmp     #$0D ;CHR$(13) Carriage Return
        bne     L897C
L8959 := *+2
        jsr     L897C
        lda     $03e7
        cmp     #$04
        bcs     L8980
        inc     $03E7
L8964:  clc
        cld
        lda     $03E7
        adc     #$04
        tax
        ldy     #$13
        lda     #$29
        pha
        sec
        jsr     LB6F9_MAYBE_PUT_CHAR_IN_FKEY_BAR_SLOT
        lda     #$65
        ply
        sta     ($BD),y
        lda     #$A7
L897C:  clc
        jmp     LB6F9_MAYBE_PUT_CHAR_IN_FKEY_BAR_SLOT
; ----------------------------------------------------------------------------
L8980:  stz     $03E7
L8983:  inc     $03E7
        jsr     L8964
        lda     $03E7
        cmp     #$04
        beq     L89A1
        ldy     #$AA
L8992:  lda     ($BD),y
        jsr     L89A8
        sta     ($BD),y
        jsr     L89A8
        dey
        bmi     L8992
        bra     L8983
L89A1:  lda     #$0D
        jsr     L897C
        bra     L8964
L89A8:  tax
        tya
        eor     #$80
        tay
        txa
        rts
; ----------------------------------------------------------------------------
L89AF:  jsr     L8A39_V1541_DOESNT_WRITE_BUT_CONDITIONALLY_RETURNS_WRITE_ERROR
        bcs     L89B5 ;branch if no error
        rts
; ----------------------------------------------------------------------------
L89B5:  lda     $020A
L89B8:  bne     L89BD
        dec     $020B
L89BD:  dec     $020A
        jsr     LD3F6
        jmp     L8A81
; ----------------------------------------------------------------------------
L89C6:  jsr     L89AF
        bcc     L89E1
        lda     V1541_ACTIV_E8
        sta     $020E
        sta     ($E4)
        lda     V1541_ACTIV_E9
        sta     $020F
        ldy     #$01
        sta     ($E4),y
        iny
        lda     #$02
        sta     ($E4),y
        sec
L89E1:  rts
; ----------------------------------------------------------------------------
L89E2:  jsr     L8A81
L89E5:  lda     $020E
        cmp     V1541_DATA_BUF+1
        bne     L89F2
        jsr     L89FF
        bra     L89E2
L89F2:  jsr     L8A61
        bcs     L89E5
        sec
        rts
; ----------------------------------------------------------------------------
L89F9:  jsr     L8AD5_MAYBE_READS_BLOCK_HEADER
        bcs     L89FF ;branch if no error
        rts
; ----------------------------------------------------------------------------
L89FF:  lda     $0216
        pha
        lda     $E5
        pha
        jsr     L8A81
        stz     $D9
        pla
        sta     $DA
        ldy     #$00
L8A10:  lda     ($E4),y
        tax
        pla
L8A14:  pha
        sta     MMU_KERN_WINDOW
        lda     ($D9),y
L8A1A:  pha
        txa
        sta     ($D9),y
L8A20 := *+2
        lda     $0216
L8A23 := *+2
        sta     MMU_KERN_WINDOW
        pla
        sta     ($e4),y
        iny
        bne     L8A10
        pla
        inc     $020A
        bne     L8A33
        inc     $020B
L8A33:  jsr     LD3F6
        jmp     L8A81
; ----------------------------------------------------------------------------
L8A39_V1541_DOESNT_WRITE_BUT_CONDITIONALLY_RETURNS_WRITE_ERROR:
        ldx     $020B
        lda     $020A
        bne     L8A42
        dex
L8A42:  dec     a
        cpx     $020D
        bne     L8A4E_25_WRITE_ERROR
        cmp     $020C
        bne     L8A4E_25_WRITE_ERROR
        clc
L8A4E_25_WRITE_ERROR:
        lda     #doserr_25_write_err ;25 write error (write-verify error)
        rts
; ----------------------------------------------------------------------------
        cld                                     ; 8A51 D8                       .
        sec                                     ; 8A52 38                       8
        lda     $0208                           ; 8A53 AD 08 02                 ...
        sbc     $020A                           ; 8A56 ED 0A 02                 ...
        tax                                     ; 8A59 AA                       .
        lda     $0209                           ; 8A5A AD 09 02                 ...
        sbc     $020B                           ; 8A5D ED 0B 02                 ...
        rts                                     ; 8A60 60                       `
; ----------------------------------------------------------------------------
L8A61:  ldx     $DA                             ; 8A61 A6 DA                    ..
        lda     $D9                             ; 8A63 A5 D9                    ..
        inc     a                               ; 8A65 1A                       .
        bne     L8A69                           ; 8A66 D0 01                    ..
        inx                                     ; 8A68 E8                       .
L8A69:  cpx     $0209                           ; 8A69 EC 09 02                 ...
        bcc     L8A77                           ; 8A6C 90 09                    ..
        bne     L8A75                           ; 8A6E D0 05                    ..
        cmp     $0208                           ; 8A70 CD 08 02                 ...
        bcc     L8A77                           ; 8A73 90 02                    ..
L8A75:  clc                                     ; 8A75 18                       .
        rts                                     ; 8A76 60                       `
; ----------------------------------------------------------------------------
L8A77:  stx     $DA                             ; 8A77 86 DA                    ..
        sta     $D9                             ; 8A79 85 D9                    ..
        inc     $E5                             ; 8A7B E6 E5                    ..
        bmi     L8A87                           ; 8A7D 30 08                    0.
        bra     L8AA9                           ; 8A7F 80 28                    .(

L8A81:  ldx     $020B                           ; 8A81 AE 0B 02                 ...

L8A84:  lda     $020A                           ; 8A84 AD 0A 02                 ...

L8A87:  sta     $D9                             ; 8A87 85 D9                    ..
        stx     $DA                             ; 8A89 86 DA                    ..
        sec                                     ; 8A8B 38                       8
        cld                                     ; 8A8C D8                       .
        sbc     #$40                            ; 8A8D E9 40                    .@
        bcs     L8A92                           ; 8A8F B0 01                    ..
        dex                                     ; 8A91 CA                       .
L8A92:  sta     $E5                             ; 8A92 85 E5                    ..
        txa                                     ; 8A94 8A                       .
        asl     $E5                             ; 8A95 06 E5                    ..
        rol     a                               ; 8A97 2A                       *
        asl     $E5                             ; 8A98 06 E5                    ..
        rol     a                               ; 8A9A 2A                       *
        asl     a                               ; 8A9B 0A                       .
        asl     a                               ; 8A9C 0A                       .
        asl     a                               ; 8A9D 0A                       .
        asl     a                               ; 8A9E 0A                       .
        sta     $0216                           ; 8A9F 8D 16 02                 ...
        sec                                     ; 8AA2 38                       8
        ror     $E5                             ; 8AA3 66 E5                    f.
        lsr     $E5                             ; 8AA5 46 E5                    F.
        stz     $E4                             ; 8AA7 64 E4                    d.
L8AA9:  lda     $0216                           ; 8AA9 AD 16 02                 ...
        sta     MMU_KERN_WINDOW                 ; 8AAC 8D 00 FF                 ...
L8AAF:  ldy     #$01                            ; 8AAF A0 01                    ..
        lda     ($E4)                           ; 8AB1 B2 E4                    ..
        tax                                     ; 8AB3 AA                       .
        sta     $020E                           ; 8AB4 8D 0E 02                 ...
        lda     ($E4),y                         ; 8AB7 B1 E4                    ..
        tay                                     ; 8AB9 A8                       .
        lda     $020A                           ; 8ABA AD 0A 02                 ...
        eor     $0208                           ; 8ABD 4D 08 02                 M..
        bne     L8ACD                           ; 8AC0 D0 0B                    ..
        lda     $020B                           ; 8AC2 AD 0B 02                 ...
        eor     $0209                           ; 8AC5 4D 09 02                 M..
        bne     L8ACD                           ; 8AC8 D0 03                    ..
        ldy     #$FF                            ; 8ACA A0 FF                    ..
        tax                                     ; 8ACC AA                       .
L8ACD:  stx     $020E                           ; 8ACD 8E 0E 02                 ...
        sty     $020F                           ; 8AD0 8C 0F 02                 ...
        sec                                     ; 8AD3 38                       8
        rts                                     ; 8AD4 60                       `
; ----------------------------------------------------------------------------
;maybe returns a cbm dos error code
L8AD5_MAYBE_READS_BLOCK_HEADER:
        jsr     L8AA9
        jsr     L8AEE
        beq     L8AFA
        jsr     L8A81
L8AE0:  jsr     L8AEE
        beq     L8AFA
        jsr     L8A61
        bcs     L8AE0
        clc
        lda     #doserr_20_read_err ;20 read error (block header not found)
        rts
; ----------------------------------------------------------------------------
L8AEE:  lda     V1541_ACTIV_E8
        cmp     $020E
        bne     L8AFA
        lda     V1541_ACTIV_E9
        cmp     $020F
L8AFA:  rts
; ----------------------------------------------------------------------------
        cpx     $DA                             ; 8AFB E4 DA                    ..
        bne     L8B08                           ; 8AFD D0 09                    ..
        cmp     $D9                             ; 8AFF C5 D9                    ..
        bne     L8B08                           ; 8B01 D0 05                    ..
        jsr     L8AA9                           ; 8B03 20 A9 8A                  ..
        bra     L8B0B                           ; 8B06 80 03                    ..
L8B08:  jsr     L8A87                           ; 8B08 20 87 8A                  ..
L8B0B:  stz     $020E                           ; 8B0B 9C 0E 02                 ...
        stz     $020F                           ; 8B0E 9C 0F 02                 ...
        sec                                     ; 8B11 38                       8
        rts                                     ; 8B12 60                       `
; ----------------------------------------------------------------------------
;maybe returns cbm dos error code in a
L8B13_MAYBE_ALLOCATES_SPACE_OR_CHECKS_DISK_FULL:
        lda     $0207
        bne     L8B1D_LOOP
        inc     $0207
        bra     L8B13_MAYBE_ALLOCATES_SPACE_OR_CHECKS_DISK_FULL

L8B1D_LOOP:
        pha
        jsr     L8DBE_UNKNOWN_CALLS_DOES_62_FILE_NOT_FOUND_ON_ERROR
        pla
        bcs     L8B27 ;branch if no error
        sec
        bra     L8B31_STORE_0207_0219_THEN_72_DISK_FULL

L8B27:  inc     a
        bne     L8B2B
        inc     a
L8B2B:  cmp     $0207
        bne     L8B1D_LOOP
        clc
L8B31_STORE_0207_0219_THEN_72_DISK_FULL:
        sta     $0207
        sta     V1541_DATA_BUF+1
        lda     #doserr_72_disk_full ;72 disk full
        rts
; ----------------------------------------------------------------------------
;CHRIN to Virtual 1541
L8B3C := *+2
V1541_CHRIN:
        jsr     L8B40_V1541_INTERNAL_CHRIN
L8B3F := *+2
        jmp     V1541_KERNAL_CALL_DONE

L8B40_V1541_INTERNAL_CHRIN:
        jsr     V1541_SELECT_CHANNEL_GIVEN_SA
        bcs     L8B46 ;branch if no error
        rts
; ----------------------------------------------------------------------------
L8B46:  lda     V1541_ACTIV_FLAGS
        bit     #$10
        bne     L8B50
        lda     #doserr_61_file_not_open
        clc
        rts
; ----------------------------------------------------------------------------
L8B50:  lda     V1541_DEFAULT_CHAN
        cmp     #doschan_15_command ;command channel?
        bne     L8B59
        jmp     L9AA5_V1541_CHRIN_CMD_CHAN
; ----------------------------------------------------------------------------
L8B59:  lda     V1541_ACTIV_FLAGS
        bit     #$80 ;eof?
        bne     L8BA0_CHRIN_EOF  ;branch if eof
        ;not eof
        lda     V1541_ACTIV_E8
        bne     L8B66_CHRIN_V1541_ACTIV_E8_NONZERO
        jmp     L939A
; ----------------------------------------------------------------------------
L8B66_CHRIN_V1541_ACTIV_E8_NONZERO:
        stz     SXREG
        lda     V1541_ACTIV_EA
        bne     L8B7F
        jsr     L8AD5_MAYBE_READS_BLOCK_HEADER
        bcs     L8B7B_CHRIN_NO_ERROR ;branch if no error
        dec     SXREG
        lda     #$0D      ;carriage return if error or eof
        sec
        rts
; ----------------------------------------------------------------------------
L8B79:  inc     V1541_ACTIV_E9
L8B7B_CHRIN_NO_ERROR:
        lda     #$02
        sta     V1541_ACTIV_EA
L8B7F:  jsr     L8AD5_MAYBE_READS_BLOCK_HEADER
        bcc     L8B9F_RTS ;branch if error
        ldy     #$02
        lda     ($E4),y
        beq     L8B8E
        cmp     V1541_ACTIV_EA
        beq     L8B92
L8B8E:  inc     V1541_ACTIV_EA
        beq     L8B79
L8B92:  lda     V1541_ACTIV_EA
        cmp     ($E4),y
        bne     L8B9B
        ror     SXREG
L8B9B:  tay
        lda     ($E4),y
        sec
L8B9F_RTS:  rts
; ----------------------------------------------------------------------------
L8BA0_CHRIN_EOF:
        lda     #$0D    ;CR is returned when reading past EOF
        stz     SXREG
        dec     SXREG
        sec
        rts
; ----------------------------------------------------------------------------
;CHROUT to Virtual 1541
V1541_CHROUT:
        jsr     L8BB0_V1541_INTERNAL_CHROUT
        jmp     V1541_KERNAL_CALL_DONE
; ----------------------------------------------------------------------------
L8BB0_V1541_INTERNAL_CHROUT:
        sta     V1541_BYTE_TO_WRITE
        jsr     V1541_SELECT_CHANNEL_GIVEN_SA
        bcs     L8BB9 ;branch if no error
        rts

L8BB9:  lda     V1541_ACTIV_FLAGS
        bit     #$20
        bne     L8BC3
        lda     #doserr_61_file_not_open
L8BC1_CLC_RTS:
        clc
        rts

L8BC3:  bit     #$80
        beq     L8BCB
L8BC7_73_DOS_MISMATCH:
        lda     #doserr_73_dos_mismatch
        bra     L8BC1_CLC_RTS

L8BCB:  lda     V1541_DEFAULT_CHAN
        cmp     #doschan_15_command ;command channel?
        bne     L8BD7_V1541_CHROUT_NOT_CMD_CHAN
        jmp     L975D_V1541_CHROUT_CMD_CHAN
; ----------------------------------------------------------------------------
L8BD4:  sta     V1541_BYTE_TO_WRITE
        ;Fall through

L8BD7_V1541_CHROUT_NOT_CMD_CHAN:
        lda     V1541_ACTIV_EA
        bne     L8BE1_WRITE_BYTE
        jsr     L8A39_V1541_DOESNT_WRITE_BUT_CONDITIONALLY_RETURNS_WRITE_ERROR
        bcs     L8BF7 ;branch if no error
        rts
; ----------------------------------------------------------------------------
L8BE1_WRITE_BYTE:
        inc     V1541_ACTIV_EA
        bne     L8BFE
        jsr     L8A39_V1541_DOESNT_WRITE_BUT_CONDITIONALLY_RETURNS_WRITE_ERROR
        bcc     L8C0E_RTS ;branch if error
        jsr     L8AD5_MAYBE_READS_BLOCK_HEADER
        bcc     L8C0E_RTS ;branch if error
        ldy     #$02
        lda     #$00
L8BF3:  sta     ($E4),y
        inc     V1541_ACTIV_E9
L8BF7:  ldy     #$03
        sty     V1541_ACTIV_EA
        jsr     L89C6
L8BFE:  jsr     L8AD5_MAYBE_READS_BLOCK_HEADER
        ldy     #$02
        lda     V1541_ACTIV_EA
        sta     ($E4),y
        tay
        lda     V1541_BYTE_TO_WRITE
        sta     ($E4),y
        sec
L8C0E_RTS:
        rts
; ----------------------------------------------------------------------------
L8C0F_DIR_RELATED:
        pha
        lda     V1541_ACTIV_EA
L8C12:  inc     a
        bne     L8C17
        inc     V1541_ACTIV_E9
L8C17:  cmp     #$03
        bcc     L8C12
L8C1B:  sta     V1541_ACTIV_EA
        jsr     L8AD5_MAYBE_READS_BLOCK_HEADER
        pla
        bcc     L8C27_71_DIR_ERROR ;branch if error
        ldy     V1541_ACTIV_EA
        sta     ($E4),y
L8C27_71_DIR_ERROR:
        lda     #doserr_71_dir_error ;71 directory error
        rts

; ----------------------------------------------------------------------------
L8C2B := *+1
L8C2A_JSR_V1541_SELECT_CHAN_17_JMP_L8C8B_CLEAR_ACTIVE_CHANNEL:
        jsr     V1541_SELECT_CHAN_17
        jmp     L8C8B_CLEAR_ACTIVE_CHANNEL

V1541_SELECT_DIR_CHANNEL_AND_CLEAR_IT:
        jsr     V1541_SELECT_DIR_CHANNEL
        jmp     L8C8B_CLEAR_ACTIVE_CHANNEL
; ----------------------------------------------------------------------------

;Get a channel's 4 bytes of data from the all-channels area
;into the active area.  Returns carry clear on failure, set on success.
V1541_SELECT_CHANNEL_GIVEN_SA:
        ;SA high nib is command, low nib is channel
        lda     SA
        and     #$0F
L8C3A:  .byte   $2C ;skip next 2 bytes

V1541_SELECT_CHAN_17:
        lda     #doschan_17_unknown
        .byte   $2C ;skip next 2 bytes

V1541_SELECT_DIR_CHANNEL:
        lda     #doschan_16_directory

V1541_SELECT_CHANNEL_A:
        cmp     V1541_DEFAULT_CHAN
        beq     L8C66_70_NO_CHANNEL

        pha                               ;Save the requested channel number
        lda     V1541_DEFAULT_CHAN                ;Get the current channel number
        jsr     L8C4D_SWAP_ACTIV_AND_BUF  ;Save the active channel in its slot in all-channels buf

L8C4A:  pla                               ;Get the requested channel number back
        sta     V1541_DEFAULT_CHAN                ;Set it as the active channel number
                                          ;Fall through to get data from all-channels buf into active

;Get buffer index from channel number
L8C4D_SWAP_ACTIV_AND_BUF:
        ;X = ((A+1)*4) - 1       Examples:
        inc     a               ;A=0 -> X=3
        asl     a               ;A=1 -> X=7
        asl     a               ;A=2 -> X=11
        dec     a               ;A=3 -> X=15
        tax                     ;A=4 -> X=19
                                ;A=5 -> X=23

        ldy     #$03
L8C54_LOOP:
        lda     V1541_ACTIV_FLAGS,y
        pha
        lda     V1541_CHAN_BUF,x
        sta     V1541_ACTIV_FLAGS,y
        pla
        sta     V1541_CHAN_BUF,x
        dex
        dey
        bpl     L8C54_LOOP

L8C66_70_NO_CHANNEL:
        lda     #doserr_70_no_channel
L8C68:  clc
        ldx     V1541_ACTIV_FLAGS
        beq     L8C6E_RTS
        sec
L8C6E_RTS:
        rts

; ----------------------------------------------------------------------------
L8C6F_V1541_I_INITIALIZE:
        lda     #doschan_14_cmd_app
        jsr     V1541_SELECT_CHANNEL_A
        ldx     #$47
L8C77 := *+1
L8C76:  STZ     V1541_CHAN_BUF,X
        dex
L8C7A:  bpl     L8C76
        stz     V1541_CMD_LEN
        inx
        txa
        tay
        sec
        jmp     L9964_STORE_XAY_CLEAR_0217
; ----------------------------------------------------------------------------
V1541_SELECT_CHANNEL_AND_CLEAR_IT:
        jsr     V1541_SELECT_CHANNEL_GIVEN_SA

L8C8B_CLEAR_ACTIVE_CHANNEL:
        ldx     #$03
L8C8B_LOOP:
        stz     V1541_ACTIV_FLAGS,x
        dex
        bpl     L8C8B_LOOP
        sec
        rts
; ----------------------------------------------------------------------------
L8C92:  lda     #$00
        jsr     L8C9F
        bcc     L8C9E_RTS ;branch on error
        jsr     L8C8B_CLEAR_ACTIVE_CHANNEL
        bra     L8C92

L8C9E_RTS:  rts
; ----------------------------------------------------------------------------
L8C9F:  tay
        ldx     #doschan_15_command
L8CA2:  phy
        phx
        txa
        jsr     V1541_SELECT_CHANNEL_A
        plx
        ply
        lda     V1541_ACTIV_FLAGS
        beq     L8CB6
        bit     #$80
        bne     L8CB6
        cpy     V1541_ACTIV_E8
        beq     L8CBA
L8CB6:  dex
        bpl     L8CA2
        clc
L8CBA:  rts
; ----------------------------------------------------------------------------
L8CBB_CLEAR_ACTIVE_CHANNEL_EXCEPT_FLAGS_THEN_BRA_L8CCE_JSR_L8CE6_THEN_UPDATE_ACTIVE_CHANNEL_AND_03A7_03A6:
        stz     V1541_ACTIV_E9
        stz     V1541_ACTIV_EA
        stz     V1541_ACTIV_E8
        bra     L8CCE_JSR_L8CE6_THEN_UPDATE_ACTIVE_CHANNEL_AND_03A7_03A6
; ----------------------------------------------------------------------------
;returns cbm dos error code in A
L8CC3:  jsr     L8CE6
        bcc     L8CD1 ;branch if error
        clc
        bit     SXREG
        bmi     L8CD1

L8CCE_JSR_L8CE6_THEN_UPDATE_ACTIVE_CHANNEL_AND_03A7_03A6:
        jsr     L8CE6
L8CD1:  ldx     V1541_ACTIV_EA
        ldy     $03A7
        stx     $03A7
        sty     V1541_ACTIV_EA
        ldx     V1541_ACTIV_E9
        ldy     $03A6
        stx     $03A6
        sty     V1541_ACTIV_E9
        rts
; ----------------------------------------------------------------------------
;returns cbm dos error code in A
L8CE6:  ldx     V1541_ACTIV_EA
        ldy     V1541_ACTIV_E9
        stx     $03A7
L8CEE := *+1
        sty     $03a6
        stz     $02D8
        ldx     #$FF
L8CF5_LOOP:
        inx
        cpx     #$19
        beq     L8D13_67_ILLEGAL_SYS_TS
        phx
        jsr     L8B66_CHRIN_V1541_ACTIV_E8_NONZERO
        plx
        bcc     L8D15_CLC_RTS ;branch if error
        sta     V1541_DATA_BUF,x
        cpx     #$05
        bit     SXREG
        bmi     L8D12_RTS
        bcc     L8CF5_LOOP
        cmp     #$00
        bne     L8CF5_LOOP
        sec
L8D12_RTS:
        rts

L8D13_67_ILLEGAL_SYS_TS:
        lda     #doserr_67_illegal_sys_ts ;67 illegal system t or s
L8D15_CLC_RTS:
        clc
        rts
; ----------------------------------------------------------------------------
;maybe returns cbm dos error in a
L8D17:  jsr     L8C92
        jsr     V1541_SELECT_DIR_CHANNEL
        jsr     L8CE6
        bcc     L8D3C ;branch if error
L8D22:  bit     SXREG
        bmi     L8D3C
L8D27:  jsr     L8B66_CHRIN_V1541_ACTIV_E8_NONZERO ;maybe returns cbm dos error in a
        bcc     L8D5A_RTS ;branch if error
        jsr     L8CD1
        jsr     L8C0F_DIR_RELATED ;maybe returns cbm dos error in a
        bcc     L8D5A_RTS
        jsr     L8CD1
        bit     SXREG
        bpl     L8D27
L8D3C:  jsr     L8CD1
        jsr     L8AD5_MAYBE_READS_BLOCK_HEADER
        lda     #doserr_71_dir_error ;71 directory error
        bcc     L8D5A_RTS ;branch if error
        lda     V1541_ACTIV_EA
        beq     L8D50
        ldy     #$02
        sta     ($E4),y
        inc     V1541_ACTIV_E9
L8D50:  jsr     L89F9
        jsr     V1541_SELECT_DIR_CHANNEL_AND_CLEAR_IT
        jsr     L8E39
        sec
L8D5A_RTS:
        rts
; ----------------------------------------------------------------------------
L8D5B_UNKNOWN_DIR_RELATED:
        jsr     L8E10
        lda     #$30
        trb     V1541_DATA_BUF
L8D63:  jsr     L8E91
        bcc     L8D9E_ERROR_OR_DONE ;branch if error
        jsr     L8C92
        jsr     V1541_SELECT_DIR_CHANNEL_AND_CLEAR_IT
        lda     #$10 ;file is open for reading?
        sta     V1541_ACTIV_FLAGS
L8D72:  jsr     L8B66_CHRIN_V1541_ACTIV_E8_NONZERO
        bcs     L8D7A_NO_ERROR ;branch if no error
        lda     #doserr_71_dir_error ;maybe: 71 directory error
        rts

L8D7A_NO_ERROR:
        lda     SXREG
        bpl     L8D72
        lda     #$20 ;file open for writing?
        tsb     V1541_ACTIV_FLAGS
        ldx     #$FF
L8D85_LOOP:
        inx
        phx
        lda     V1541_DATA_BUF,x
        jsr     L8BD4
        plx
        cpx     #$05
        bcc     L8D85_LOOP
        lda     V1541_DATA_BUF,x
        bne     L8D85_LOOP
        jsr     V1541_SELECT_DIR_CHANNEL_AND_CLEAR_IT
        jsr     L8E39
        sec
L8D9E_ERROR_OR_DONE:
        rts
; ----------------------------------------------------------------------------
;returns cbm dos error code in a
;carry clear = file exists, carry set = not found
L8D9F_SELECT_DIR_CHANNEL_AND_CLEAR_IT_THEN_UNKNOWN_THEN_FILENAME_COMPARE:
        jsr     V1541_SELECT_DIR_CHANNEL_AND_CLEAR_IT
        jsr     L8CBB_CLEAR_ACTIVE_CHANNEL_EXCEPT_FLAGS_THEN_BRA_L8CCE_JSR_L8CE6_THEN_UPDATE_ACTIVE_CHANNEL_AND_03A7_03A6
        bra     L8DAA

L8DA7:  jsr     L8CC3

L8DAA:  bcc     L8DBA_62_FILE_NOT_FOUND ;branch if error from L8CBB_CLEAR_ACTIVE_CHANNEL_EXCEPT_FLAGS_THEN_BRA_L8CCE_JSR_L8CE6_THEN_UPDATE_ACTIVE_CHANNEL_AND_03A7_03A6 or L8CC3
        jsr     L8FC3_COMPARE_FILENAME_INCL_WILDCARDS
        bcc     L8DB5_NO_MATCH ;filename does not match
        lda     V1541_DATA_BUF
        rts

L8DB5_NO_MATCH:
        bit     SXREG
        bpl     L8DA7
L8DBA_62_FILE_NOT_FOUND:
        clc
        lda     #doserr_62_file_not_found
        rts
; ----------------------------------------------------------------------------
;returns cbm dos error code in a
L8DBE_UNKNOWN_CALLS_DOES_62_FILE_NOT_FOUND_ON_ERROR:
        pha
        jsr     V1541_SELECT_DIR_CHANNEL_AND_CLEAR_IT
        jsr     L8CBB_CLEAR_ACTIVE_CHANNEL_EXCEPT_FLAGS_THEN_BRA_L8CCE_JSR_L8CE6_THEN_UPDATE_ACTIVE_CHANNEL_AND_03A7_03A6
        bra     L8DCA_SKIP_LD8C7

L8DC7:  jsr     L8CC3

L8DCA_SKIP_LD8C7:
        bcc     L8DDC_62_FILE_NOT_FOUND ;branch if error
        lda     V1541_DATA_BUF
        bit     #$80
        bne     L8DC7
        tsx
        lda     V1541_DATA_BUF+1
        cmp     stack+1,x
        bne     L8DC7

L8DDC_62_FILE_NOT_FOUND:
        pla
        lda     #doserr_62_file_not_found
        rts
; ----------------------------------------------------------------------------
;Returns number of blocks used in A
L8DE0_SOMEHOW_GETS_FILE_BLOCKS_USED_1:
        lda     V1541_DATA_BUF+1
        .byte   $2C
L8DE4_SOMEHOW_GETS_FILE_BLOCKS_USED_2:
        lda     #$00
        ldx     #$00
        phx
        phx
        pha
        jsr     L8A81
        beq     L8E0A
L8DF0:  tsx
        lda     $020E
        cmp     stack+1,x
        bne     L8E05
        inc     stack+2,x
        ldy     #$02
        lda     ($E4),y
        beq     L8E05
        sta     stack+3,x
L8E05:  jsr     L8A61
        bcs     L8DF0
L8E0A:  pla
        pla
        ply
        cmp     #$00
        rts
; ----------------------------------------------------------------------------
L8E10:  lda     V1541_DATA_BUF+1
        jsr     L8E5E
        sta     V1541_DATA_BUF+2
        stx     V1541_DATA_BUF+3
        sty     V1541_DATA_BUF+4
        rts
; ----------------------------------------------------------------------------
L8E20_MAYBE_CHECKS_HEADER:
        lda     V1541_DATA_BUF+1
L8E25 := *+2
        jsr     L8E5E
        cmp     V1541_DATA_BUF+2
        bne     L8E35_27_CHECKSUM_ERROR_IN_HEADER
        cpx     V1541_DATA_BUF+3
        bne     L8E35_27_CHECKSUM_ERROR_IN_HEADER
        cpy     V1541_DATA_BUF+4
        beq     L8E36
L8E35_27_CHECKSUM_ERROR_IN_HEADER:
        clc
L8E36:  lda     #doserr_27_read_error ;27 read error (checksum error in header)
        rts
; ----------------------------------------------------------------------------
L8E39:  jsr     L8E5C
        sta     $0213
        stx     $0214
        sty     $0215
        rts
; ----------------------------------------------------------------------------
L8E46:  jsr     L8E5C
        cmp     $0213
        bne     L8E58
        cpx     $0214
        bne     L8E58
        cpy     $0215
        beq     L8E59
L8E58:  clc
L8E59:  lda     #$1B
        rts
; ----------------------------------------------------------------------------
L8E5C:  lda     #$00                            ; 8E5C A9 00                    ..
L8E5E:  ldx     #$00                            ; 8E5E A2 00                    ..
        phx                                     ; 8E60 DA                       .
        phx                                     ; 8E61 DA                       .
        pha                                     ; 8E62 48                       H
        jsr     L8A81                           ; 8E63 20 81 8A                  ..
        beq     L8E8D                           ; 8E66 F0 25                    .%
        lda     #$00                            ; 8E68 A9 00                    ..
L8E6A:  tsx                                     ; 8E6A BA                       .
        ldy     stack+1,x                       ; 8E6B BC 01 01                 ...
        cpy     $020E                           ; 8E6E CC 0E 02                 ...
        bne     L8E86                           ; 8E71 D0 13                    ..
        ldy     #$00                            ; 8E73 A0 00                    ..
        clc                                     ; 8E75 18                       .
L8E76:  adc     ($E4),y                         ; 8E76 71 E4                    q.
        bcc     L8E83                           ; 8E78 90 09                    ..
        clc                                     ; 8E7A 18                       .
        inc     stack+2,x                       ; 8E7B FE 02 01                 ...
        bne     L8E83                           ; 8E7E D0 03                    ..
        inc     stack+3,x                       ; 8E80 FE 03 01                 ...
L8E83:  iny                                     ; 8E83 C8                       .
        bne     L8E76                           ; 8E84 D0 F0                    ..
L8E86:  pha                                     ; 8E86 48                       H
        jsr     L8A61                           ; 8E87 20 61 8A                  a.
        pla                                     ; 8E8A 68                       h
        bcs     L8E6A                           ; 8E8B B0 DD                    ..
L8E8D:  plx                                     ; 8E8D FA                       .
        plx                                     ; 8E8E FA                       .
        ply                                     ; 8E8F 7A                       z
        rts                                     ; 8E90 60                       `
; ----------------------------------------------------------------------------
L8E91:  jsr     L8DE4_SOMEHOW_GETS_FILE_BLOCKS_USED_2
        beq     L8EA7_BLOCKS_USED_0 ;branch if blocks used = 0
        tya
        ldx     #$FF
L8E99_LOOP:
        inc     a
        beq     L8EA7_BLOCKS_USED_0 ;branch if just-incremented blocks used = 0
        inx
        cpx     #$05
        bcc     L8E99_LOOP
        lda     V1541_DATA_BUF+5,x
        bne     L8E99_LOOP
        rts

L8EA7_BLOCKS_USED_0:
        jsr     L8A39_V1541_DOESNT_WRITE_BUT_CONDITIONALLY_RETURNS_WRITE_ERROR
        bcc     L8EAE_RTS ;branch if error
        lda     #$01
L8EAE_RTS:
        rts
; ----------------------------------------------------------------------------
L8EAF_COPY_FNADR_FNLEN_THEN_SETUP_FOR_FILE_ACCESS:
        lda     FNADR
        ldx     FNADR+1
        ldy     FNLEN
L8EB6:  sta     V1541_FNADR
        stx     V1541_FNADR+1
        sty     V1541_FNLEN
        ;Fall through
; ----------------------------------------------------------------------------
L8EBD_SETUP_FOR_FILE_ACCESS_AND_DO_DIR_SEARCH_STUFF:
        stz     $03A5
        stz     V1541_FILE_MODE
        stz     V1541_FILE_TYPE
        stz     $03A0
        lda     #V1541_FNADR ;ZP-address
        sta     SINNER ;Y-index for (ZP),Y
        lda     V1541_FNLEN
        bne     L8ED7

L8ED3_33_SYNTAX_ERROR:
        lda     #doserr_33_syntax_err ;33 invalid filename
        clc
        rts

L8ED7:  ldy     #$00
        jsr     L8FAD_GET_AND_CHECK_NEXT_CHAR_OF_FILENAME
        dey
        bcc     L8ED3_33_SYNTAX_ERROR
        cmp     #'$'
        beq     L8EE7_GOT_DOLLAR
        cmp     #'@'
        bne     L8EEB_GOT_AT
L8EE7_GOT_DOLLAR:
        iny
        sta     $03A0
L8EEB_GOT_AT:
        sty     MON_MMU_MODE

L8EEE_NEXT_CHAR:
        sty     $03A2
        cpy     V1541_FNLEN
        bne     L8EF9
        jmp     L8F86

;Looks like filename parsing for directory listing LOAD"$0:*=P"
L8EF9:  jsr     L8FAD_GET_AND_CHECK_NEXT_CHAR_OF_FILENAME
        bcc     L8ED3_33_SYNTAX_ERROR
        tax
        cpx     #' '
        beq     L8EEE_NEXT_CHAR
        cpx     #'0'
        beq     L8EEE_NEXT_CHAR
        cpx     #'9'+1
        bne     L8F14
        lda     #$03
        tsb     $03A5
        bne     L8ED3_33_SYNTAX_ERROR
        bra     L8EEB_GOT_AT
L8F14:  lda     #$02
        tsb     $03A5
        cpx     #'='
        beq     L8F81_GOT_EQUALS
        cpx     #'?'
        beq     L8F25_GOT_QUESTION_OR_STAR
        cpx     #'*'
        bne     L8F2A
L8F25_GOT_QUESTION_OR_STAR:
        lda     #$40
        tsb     $03A5
L8F2A:  cpx     #','
        bne     L8EEE_NEXT_CHAR
        dey
L8F2F_NEXT_CHAR:
        cpy     V1541_FNLEN
        beq     L8F86
        jsr     L8FAD_GET_AND_CHECK_NEXT_CHAR_OF_FILENAME
        bcc     L8F5F_33_SYNTAX_ERROR
        cmp     #'='
        beq     L8F81_GOT_EQUALS
        cmp     #' '
        beq     L8F2F_NEXT_CHAR
        cmp     #','
        bne     L8F5F_33_SYNTAX_ERROR

L8F45_LOOP:
        cpy     V1541_FNLEN
        bcs     L8F5F_33_SYNTAX_ERROR
        jsr     L8FAD_GET_AND_CHECK_NEXT_CHAR_OF_FILENAME
        bcc     L8F5F_33_SYNTAX_ERROR
        cmp     #' '
        beq     L8F45_LOOP
        and     #$DF

        ldx     #$05
L8F57_SPRWAM_SEARCH_LOOP:
        cmp     L8F7B_SPRWAM,x
        beq     L8F63_FOUND_IN_SPRWAM
        dex
        bpl     L8F57_SPRWAM_SEARCH_LOOP

L8F5F_33_SYNTAX_ERROR:
        lda     #doserr_33_syntax_err ;Invalid filename
        clc
        rts
; ----------------------------------------------------------------------------
L8F63_FOUND_IN_SPRWAM:
        cpx     #$02
        bcs     L8F71_RWAM
        ;PR
        ldx     V1541_FILE_TYPE
        bne     L8F5F_33_SYNTAX_ERROR
        sta     V1541_FILE_TYPE
        bra     L8F2F_NEXT_CHAR
L8F71_RWAM:
        ;RWAM
        ldx     V1541_FILE_MODE
        bne     L8F5F_33_SYNTAX_ERROR
        sta     V1541_FILE_MODE
        bra     L8F2F_NEXT_CHAR

L8F7B_SPRWAM:
        .byte ftype_s_seq, ftype_p_prg
        .byte fmode_r_read, fmode_w_write, fmode_a_append, fmode_m_modify

L8F81_GOT_EQUALS:
        lda     #$20
        tsb     $03A5
L8F86:  lda     MON_MMU_MODE
        cmp     $03A2
        bcc     L8F96
        stz     $03A2
        stz     MON_MMU_MODE
        bcs     L8F9B
L8F96:  lda     #$80
        tsb     $03A5
L8F9B:  cld
        clc
        lda     #$10
        adc     MON_MMU_MODE
        cmp     $03A2
        lda     #doserr_33_syntax_err ;33 syntax error
        bcc     L8FAC_RTS
L8FAA := *+1
        lda     $03a5
L8FAC_RTS:  rts
; ----------------------------------------------------------------------------
;Get the next character from the filename and check
;if it contains a disallowed character.
;
;Returns A=char, carry=clear on error
L8FAD_GET_AND_CHECK_NEXT_CHAR_OF_FILENAME:
        jsr     GO_RAM_LOAD_GO_KERN  ;get the char
        iny
L8FB1:  ldx     #$03
L8FB4 := *+1
L8FB3_LOOP:
        cmp L8FBF_DIASLLOWED_FNAME_CHARS,X
        bne L8FBA_NOT_EQU
        clc ;Found a bad character
        rts
L8FBA_NOT_EQU:
        dex
        bpl     L8FB3_LOOP
        sec
        rts

L8FBF_DIASLLOWED_FNAME_CHARS:
       .byte $00 ;null
       .byte $0d ;return
       .byte $22 ;quote
       .byte $8d ;shift-return
; ----------------------------------------------------------------------------
;Compare filename at V1541_DATA_BUF+5 with indirect filename
;carry set = filename matches
L8FC3_COMPARE_FILENAME_INCL_WILDCARDS:
        ldx     #$00
        ldy     MON_MMU_MODE
        lda     #V1541_FNADR ;ZP-address
        sta     SINNER
L8FCD_LOOP:
        jsr     GO_RAM_LOAD_GO_KERN ;get char from filename
L8FD0:  cmp     #'*'
        beq     L8FE9_SUCCESS_FILENAME_MATCHES
        cmp     #'?'
        beq     L8FDD_ANY_ONE_CHAR
        cmp     V1541_DATA_BUF+5,x
        bne     L8FF1_FAIL_FILENAME_DOES_NOT_MATCH
L8FDD_ANY_ONE_CHAR:
        iny
        cpy     $03A2
        bne     L8FEB
        inx
        lda     V1541_DATA_BUF+5,x
        bne     L8FF1_FAIL_FILENAME_DOES_NOT_MATCH
L8FE9_SUCCESS_FILENAME_MATCHES:
        sec
        rts
L8FED := *+2
L8FEB:  inx
        lda     V1541_DATA_BUF+5,X
        bne     L8FCD_LOOP
L8FF1_FAIL_FILENAME_DOES_NOT_MATCH:
        clc
        rts
; ----------------------------------------------------------------------------
L8FF3:  stz     $02D8
        lda     #V1541_FNADR ;ZP-address
        sta     SINNER
        ldx     #$00
        ldy     MON_MMU_MODE
L9000_LOOP:
        jsr     GO_RAM_LOAD_GO_KERN
        sta     V1541_DATA_BUF+5,x
        inx
        iny
        cpy     $03A2
        bne     L9000_LOOP
        stz     V1541_DATA_BUF+5,x
        rts
; ----------------------------------------------------------------------------
;maybe returns cbm dos error code in A
L9011_TEST_0218_AND_STORE_FILE_TYPE:
        ldx     #ftype_s_seq
        lda     V1541_DATA_BUF
        bit     #$40
        beq     L901C_GOT_SEQ
        ldx     #ftype_p_prg
L901C_GOT_SEQ:
        lda     #'@'
        cpx     V1541_FILE_TYPE
        beq     L9029_STORE_TYPE_AND_RTS
        ldy     V1541_FILE_TYPE
L9026:
        beq     L9029_STORE_TYPE_AND_RTS
        clc
L9029_STORE_TYPE_AND_RTS:
        stx     V1541_FILE_TYPE
        rts
; ----------------------------------------------------------------------------
L902D:  ldx     #$04
        lda     V1541_DATA_BUF
        bit     #$80
        bne     L9038
        ldx     #$01
L9038:  lda     V1541_DATA_BUF,x
        sta     V1541_ACTIV_FLAGS,x
        dex
        bpl     L9038
        rts
; ----------------------------------------------------------------------------
L9041:  jsr     L8C92
        stz     V1541_02D6
        lda     #'*'
        sta     $0238
        stz     $0239
        stz     $024C
        lda     $03A5
L9055:  bit     #$80
        beq     L907D_SEC_RTS
        ldx     #$00
        ldy     MON_MMU_MODE
L905E:  lda     #V1541_FNADR ;ZP-address
        sta     SINNER
        jsr     GO_RAM_LOAD_GO_KERN
        sta     $0238,x
        iny
        inx
        cpy     $03A2
        bne     L905E
        cpx     #$14
        bcs     L9077
        stz     $0238,x
L9079 := *+2
L9077:  LDA     V1541_FILE_TYPE
        sta     $024C
L907D_SEC_RTS:
        sec
        rts
; ----------------------------------------------------------------------------
        ldx     EAL
        ldy     EAH
        sec
        rts
; ----------------------------------------------------------------------------
L9085_V1541_SAVE:
        jsr     L908B_V1541_INTERNAL_SAVE
        jmp     V1541_KERNAL_CALL_DONE
; ----------------------------------------------------------------------------
L908B_V1541_INTERNAL_SAVE:
        ldx     STAH
        lda     STAL
        sta     SAL
        stx     SAH
        cpx     #>$08F8
        bcc     L90DD_25_WRITE_ERROR
        cpx     #<$08F8
        bcs     L90DD_25_WRITE_ERROR
        lda     EAH
        cmp     #>$F800
        bcc     L90A7
        bne     L90DD_25_WRITE_ERROR
        lda     EAL
        bne     L90DD_25_WRITE_ERROR
L90A7:  jsr     L8EAF_COPY_FNADR_FNLEN_THEN_SETUP_FOR_FILE_ACCESS
        bcc     L90DA_33_SYNTAX_ERROR
        bit     #$80
        beq     L90DA_33_SYNTAX_ERROR
        bit     #$60
        bne     L90DA_33_SYNTAX_ERROR
        lda     V1541_FILE_MODE
        bne     L90DA_33_SYNTAX_ERROR
        lda     $03A0
        beq     L90C2
        cmp     #$40 ;'@'
        bne     L90DA_33_SYNTAX_ERROR

L90C3 := *+1
L90C2:  jsr     L8D9F_SELECT_DIR_CHANNEL_AND_CLEAR_IT_THEN_UNKNOWN_THEN_FILENAME_COMPARE
        bcc     L90EC_ERROR ;branch if error (file not found)

        lda     $03A0
L90CB := *+1
        bne     L90D0_03A0_NOT_ZERO
        lda     #doserr_63_file_exists ;63 file exists
        bra     L90DF_ERROR

L90D2 := *+2
L90D0_03A0_NOT_ZERO:
        lda     V1541_DATA_BUF
        and     #$80
        beq     L90E1
        lda     #doserr_26_write_prot_on ;#26 write protect on
        .byte   $2C
L90DA_33_SYNTAX_ERROR:
        lda     #doserr_33_syntax_err  ;33 syntax error (invalid filename)
        .byte   $2C
L90DD_25_WRITE_ERROR:
        lda     #doserr_25_write_err ;25 write error (write-verify error)
L90DF_ERROR:
        clc
        rts

L90E1:  jsr     L9011_TEST_0218_AND_STORE_FILE_TYPE ;maybe returns cbm dos error code in A
        bcc     L90DF_ERROR ;branch if error
        jsr     L8DE0_SOMEHOW_GETS_FILE_BLOCKS_USED_1
        inc     a ;increment number of blocks used
        bra     L910D

L90EC_ERROR:
        stz     $03A0
        jsr     L8B13_MAYBE_ALLOCATES_SPACE_OR_CHECKS_DISK_FULL ;maybe returns cbm dos error code in A                               ; 90EF 20 13 8B                  ..
L90F2:  bcc     L90DF_ERROR ;branch if error
        jsr     L8FF3
        stz     V1541_DATA_BUF
        lda     V1541_FILE_TYPE
        cmp     #ftype_s_seq
        beq     L9106
        lda     #$40
        sta     V1541_DATA_BUF
L9108:=*+2
L9106:  jsr     L8E91
        bcc     L90DF_ERROR
        eor     #$01
L910D:  pha                         ;push number of blocks used
L9110:=*+2
        jsr     L91A4
        sty     V1541_DATA_BUF+2
        pla                         ;pull number of blocks used
        clc
        adc     $020A
        ldx     $020B
        bcc     L911F
        inx
L911F:  clc
        sbc     V1541_DATA_BUF+2
        bcs     L9126
        dex
L9126:  tay
        bne     L912A
        dex
L912A:  dec     a
        cpx     $020D
        bcc     L9137
        bne     L913A
        cmp     $020C
        bcs     L913A
L9137:  jmp     L90DD_25_WRITE_ERROR
; ----------------------------------------------------------------------------
L913A:  cpx     #$00
        bne     L9145
        cmp     STAH
        bcs     L9145
        jsr     L91D5
L9145:  lda     $03A0
        beq     L9150
        jsr     L89E2
        jsr     L8D17 ;maybe returns cbm dos error in a
L9150:  jsr     L91A4
        cpy     #$00
        beq     L91A1
        dey
L915A := *+2
        sty     V1541_DATA_BUF+2
        sta     V1541_DATA_BUF+3
        lda     #$E0 ;ZP-address
        sta     SINNER
L9163:  jsr     L89AF
        ldy     #$FF
L9168:  jsr     GO_RAM_LOAD_GO_KERN
        sta     ($E4),y
        dey
        bne     L9168
        ldy     #$02
L9172:  lda     V1541_DATA_BUF+1,y
        sta     ($E4),y
        dey
        bpl     L9172
        sec
        lda     $E0
        sbc     #$FD
        bcs     L9183
        dec     $E1
L9183:  sta     $E0
        stz     V1541_DATA_BUF+3
        ldy     V1541_DATA_BUF+2
        dec     V1541_DATA_BUF+2
        tya
        bne     L9163
        bit     V1541_DATA_BUF
        bvc     L91A1
        ldy     #$04
        lda     SAH
        sta     ($E4),y
        dey
        lda     SAL
        sta     ($E4),y
L91A1:  jmp     L8D5B_UNKNOWN_DIR_RELATED
; ----------------------------------------------------------------------------
L91A4:  ldx     STAH
        lda     STAL
        bit     V1541_DATA_BUF
        bvc     L91B3
        sec
        sbc     #$02
        bcs     L91B3
        dex
L91B3:  ldy     #$00
L91B5:  cpx     EAH
        bcc     L91BD
        cmp     EAL
        bcs     L91C9
L91BD:  adc     #$FD
        bcc     L91C2
        inx
L91C2:  iny
        bne     L91B5
        lda     #$34
        clc
        rts
; ----------------------------------------------------------------------------
L91C9:  dex
        sta     $E0
L91CC:  stx     $E1
        clc
        lda     EAL
        sbc     $E0
        sec
        rts
; ----------------------------------------------------------------------------
L91D5:  pha
        sta     $E1
        stz     $E0
        lda     #STAH
        sta     SINNER
        lda     #$E0
        sta     $0360
L91E4:  lda     STAH
        cmp     EAH
        bne     L91F0
        lda     $B6
        cmp     EAL
        beq     L9206
L91F0:  ldy     #$00
        jsr     GO_RAM_LOAD_GO_KERN
        jsr     GO_RAM_STORE_GO_KERN
        inc     $E0
        bne     L91FE
L91FC:  inc     $E1
L91FE:  inc     $B6
        bne     L9204
        inc     STAH
L9204:  bra     L91E4
L9206:  lda     $E0
        sta     EAL
        lda     $E1
        sta     EAH
        pla
        sta     STAH
        stz     STAL
        rts
; ----------------------------------------------------------------------------
V1541_CLOSE:
        jsr     L921A_V1541_INTERNAL_CLOSE
        jmp     V1541_KERNAL_CALL_DONE
; ----------------------------------------------------------------------------
L921A_V1541_INTERNAL_CLOSE:
        jsr     V1541_SELECT_CHANNEL_GIVEN_SA
        bcs     L9221 ;branch if no error
        sec
        rts
L9221:  lda     V1541_DEFAULT_CHAN
        cmp     #doschan_15_command ;command channel?
        beq     L9240_RTS
        lda     V1541_ACTIV_FLAGS
        bit     #$20 ;is file open for writing?
        beq     L9240_RTS
        bit     #$80
        bne     L9240_RTS
        lda     V1541_ACTIV_E8
        beq     L9240_RTS
L9236 := *+1
        jsr     L8DBE_UNKNOWN_CALLS_DOES_62_FILE_NOT_FOUND_ON_ERROR
        bcc     L9240_RTS ;branch if error
        jsr     L8D17
        jsr     L8D5B_UNKNOWN_DIR_RELATED
L9240_RTS:
        jmp     V1541_SELECT_CHANNEL_AND_CLEAR_IT
; ----------------------------------------------------------------------------
L9244 := *+1
L9243_OPEN_V1541:
        jsr     L9249_V1541_INTERNAL_OPEN
        jmp     V1541_KERNAL_CALL_DONE
; ----------------------------------------------------------------------------
L924A := *+1
L9249_V1541_INTERNAL_OPEN:
        jsr     V1541_SELECT_CHANNEL_GIVEN_SA
        lda     V1541_DEFAULT_CHAN
        cmp     #doschan_15_command ;command channel
L9250:  bne     L9255_V1541_INTERNAL_OPEN_NOT_CMD_CHAN
        jmp     L9737_V1541_INTERNAL_OPEN_CMD_CHAN

        ;not the command channel

L9256 := *+1
L9255_V1541_INTERNAL_OPEN_NOT_CMD_CHAN:
        jsr     L8C8B_CLEAR_ACTIVE_CHANNEL
        jsr     L8EAF_COPY_FNADR_FNLEN_THEN_SETUP_FOR_FILE_ACCESS
L925C := *+1
        BCC     L9287_ERROR
        bit     #$20
        bne     L9282
L9262 := *+1
        LDX     $03a0
        beq     L928C
        cpx     #'$'
L9268:  bne     L927B_NOT_DOLLAR
        ldx     V1541_FILE_MODE
L926E := *+1
        BNE     L9287_ERROR
        jsr     V1541_SELECT_CHANNEL_GIVEN_SA
L2973 := *+1
L9274 := *+2
        jsr     L9041
        lda     #$50
        sta     V1541_ACTIV_FLAGS
        sec
L927A:  rts
; ----------------------------------------------------------------------------
L927B_NOT_DOLLAR:
        ldy     V1541_FILE_MODE
L927E:  cpy     #fmode_w_write
        beq     L9289
L9282:  lda     #$21 ;33 syntax error (invalid filename)
        .byte   $2C ;skip next two bytes
L9286 := *+1
L9285:  lda #$21 ;33 syntax error (invalid filename)
L9287_ERROR:  clc
        rts
; ----------------------------------------------------------------------------
L9289:  stx     V1541_FILE_MODE
L928C:  bit     #$80
        beq     L9282
        ldy     #fmode_r_read
        ldx     V1541_FILE_MODE
        bne     L929A
        sty     V1541_FILE_MODE
L929A:  bit     #$40
        beq     L92A3
        cpx     V1541_FILE_MODE
        bne     L9285

L92A3:  jsr     L8D9F_SELECT_DIR_CHANNEL_AND_CLEAR_IT_THEN_UNKNOWN_THEN_FILENAME_COMPARE
        bcc     L9317_DO_STUFF_WITH_FILE_TYPE_AND_MODE ;branch if error (file not found)

        jsr     L9011_TEST_0218_AND_STORE_FILE_TYPE
        bcc     L92C7_ERROR

        ldy     V1541_FILE_MODE
        lda     #doserr_63_file_exists ;63 file exists
        cpy     #fmode_w_write
        beq     L92C7_ERROR
        lda     V1541_DATA_BUF
        bit     #$80
        beq     L92C9
        lda     #doserr_26_write_prot_on ;26 write protect on
        cpy     #$40
        beq     L92C7_ERROR
        cpy     #$41
        bne     L9315
L92C7_ERROR:
        clc
        rts
; ----------------------------------------------------------------------------
L92C9:  lda     V1541_DATA_BUF+1
        jsr     L8C9F
        bcc     L92E6
        lda     V1541_ACTIV_FLAGS
        and     #$20
        beq     L92DB
        lda     #doserr_60_write_file_open ;60 write file open
        bra     L92C7_ERROR
L92DD := *+2
L92DB:  ldy     V1541_FILE_MODE
        cpy     #fmode_r_read
        beq     L92F8
L92E2:  lda     #doserr_60_write_file_open ;60 write file open
        bra     L92C7_ERROR
L92E6:  lda     V1541_DATA_BUF
        bit     #$20
        beq     L92F8
        ldy     V1541_FILE_MODE
        cpy     #fmode_m_modify
        beq     L92F8
        cpy     #$40
        bne     L92E2
L92F8:  ldy     V1541_FILE_MODE
        cpy     #'@' ;TODO weird for a mode maybe somehow A?
        bne     L930C
        jsr     L8D17 ;maybe returns cbm dos error in a
        jsr     L89E2
        lda     #fmode_w_write
        sta     V1541_FILE_MODE
        bra     L9317_DO_STUFF_WITH_FILE_TYPE_AND_MODE
L930C:  cpy     #fmode_m_modify
        beq     L9315
        jsr     L8E20_MAYBE_CHECKS_HEADER
        bcc     L92C7_ERROR ;branch if error
L9315:  bra     L9335

L9317_DO_STUFF_WITH_FILE_TYPE_AND_MODE:
        ldy     V1541_FILE_MODE
        cpy     #fmode_r_read
        beq     L9322_ERROR
        cpy     #fmode_m_modify
        bne     L9326
L9322_ERROR:
        lda     #doserr_62_file_not_found ;62 file not found
        clc
        rts

L9326:  lda     #fmode_w_write
        sta     V1541_FILE_MODE
        lda     V1541_FILE_TYPE
        bne     L9335
        lda     #ftype_s_seq
        sta     V1541_FILE_TYPE
L9335:  ldy     V1541_FILE_MODE
        cpy     #fmode_w_write
        bne     L935A
        jsr     L8B13_MAYBE_ALLOCATES_SPACE_OR_CHECKS_DISK_FULL
        bcc     L9358_ERROR ;branch on error
        jsr     L8FF3
        stz     V1541_DATA_BUF
        lda     V1541_FILE_TYPE
        cmp     #ftype_p_prg
        bne     L9353
        lda     #$40
        sta     V1541_DATA_BUF
L9353:  jsr     L8E91
        bcs     L935A
L9358_ERROR:
        clc
        rts

L935A:  jsr     V1541_SELECT_CHANNEL_GIVEN_SA
        jsr     L902D
L9361 := *+1
        lda     #$10
        tsb     V1541_ACTIV_FLAGS
        ldy     V1541_FILE_MODE
L9367:  cpy     #fmode_m_modify
        beq     L9378
        cpy     #fmode_r_read
        bne     L937A
        lda     V1541_DEFAULT_CHAN
        cmp     #$0E
        bne     L9378
        dec     LDTND
L9378:  sec
        rts

L937A:  cpy     #$41
        bne     L938D
        jsr     L8D17  ;maybe returns cbm dos error in a
L9381:  jsr     L8B40_V1541_INTERNAL_CHRIN
        lda     #$47
        bcc     L9358_ERROR
        bit     SXREG
        bpl     L9381
L938D:  jsr     V1541_SELECT_CHANNEL_GIVEN_SA
        lda     #$20
        tsb     V1541_ACTIV_FLAGS
        tsb     V1541_DATA_BUF
        jmp     L8D63

; ----------------------------------------------------------------------------

L939A:  lda     V1541_02D6
L939D:  bne     L93A2
        sta     V1541_02D7
L93A2:  ldx     V1541_02D7
        beq     L93C0
        lda     $02D8
        beq     L941F_GET_DIRPART_ONLY
        lda     $0217,x
        inx
        tay
        bne     L93B8
        cpx     #$0A
        bcc     L93B8
        tax
L93B8:  stx     V1541_02D7
        stz     SXREG
        sec
        rts

L93C0:  ldx     V1541_02D6
        jmp     (L93C6,x)
L93C6:  .addr   L9414_INC_02D6_TWICE_STA_1_02D7_GET_DIRPART
        .addr   L93E4
        .addr   L93E9_LOOP
        .addr   L93D0
        .addr   L93D6

L93D0:  ldx     #$08
        lda     #$00
        bra     L93DA

L93D6:  ldx     #$00
        lda     #$FF
L93DA:  stx     V1541_02D6
        sta     SXREG
        lda     #$00
        sec
        rts

L93E4:  jsr     L8CBB_CLEAR_ACTIVE_CHANNEL_EXCEPT_FLAGS_THEN_BRA_L8CCE_JSR_L8CE6_THEN_UPDATE_ACTIVE_CHANNEL_AND_03A7_03A6
        bra     L93EC

L93E9_LOOP:
        jsr     L8CC3
L93EC:  ldx     #$04
        stx     V1541_02D6
        bcc     L9414_INC_02D6_TWICE_STA_1_02D7_GET_DIRPART ;branch if error from L8CC3

        lda     #<$0238
        sta     V1541_FNADR
        lda     #>$0238
        stz     MON_MMU_MODE
L93FC:  sta     V1541_FNADR+1
        ldx     #$00
L9400:  lda     $0238,x
L9403:  beq     L940A
        inx
        cpx     #$14
        bne     L9400
L940A:  stx     $03A2
        jsr     L8FC3_COMPARE_FILENAME_INCL_WILDCARDS
        bcc     L93E9_LOOP ;filename does not match
        bra     L941A_STA_1_02D7_GET_DIRPART

L9414_INC_02D6_TWICE_STA_1_02D7_GET_DIRPART:
        inc     V1541_02D6
        inc     V1541_02D6

L941A_STA_1_02D7_GET_DIRPART:
        lda     #$01
        sta     V1541_02D7

L941F_GET_DIRPART_ONLY:
        jsr     L8CCE_JSR_L8CE6_THEN_UPDATE_ACTIVE_CHANNEL_AND_03A7_03A6
        jsr     L942B_GET_V1541_DIR_PART
        dec     $02D8
        jmp     L939A

L942B_GET_V1541_DIR_PART:
        ldx     V1541_02D6
L942F           := * + 1
        jmp     (L942F,x)
        .addr   L9457_GET_V1541_HEADER
        .addr   L94A8_GET_V1541_FILE
        .addr   L9488_GET_V1541_BLOCKS_USED

L9437_V1541_HEADER:
        .word $1001   ;load address
        .word $1001   ;pointer to next basic line
        .word 0       ;basic line number
L944C := * + 15
        .byte $12,$22,"VIRTUAL 1541    ",$22," ID 00" ;basic line text
        .byte 0       ;end of basic line

;Put the start of the BASIC program and the first BASIC line
;with the disk header in the buffer
L9457_GET_V1541_HEADER:
        ldx     #$1F
L9459_LOOP:
        lda     L9437_V1541_HEADER,x
        sta     V1541_DATA_BUF,x
        dex
        bpl     L9459_LOOP
        jsr     L8DE4_SOMEHOW_GETS_FILE_BLOCKS_USED_2  ;sets A = blocks used
        sta     V1541_DATA_BUF+4  ;basic line number low byte
        rts

L9469_BLOCKS_USED:
        .word $1001   ;pointer to next basic line
        .word 0       ;basic line number
        .byte "BLOCKS USED.            "  ;basic line text
        .byte 0       ;end of basic line
        .byte 0,0     ;end of basic program

;Put a BASIC line with the "BLOCKS USED" in the buffer
L9488_GET_V1541_BLOCKS_USED:
        ldx     #$1E
L948A_LOOP:
        lda     L9469_BLOCKS_USED,x
        sta     V1541_DATA_BUF,x
        dex
        bpl     L948A_LOOP
        cld
        sec
        lda     $0208
        sbc     $020A
        sta     V1541_DATA_BUF+2  ;basic line number low byte
        lda     $0209
        sbc     $020B
L94A6           := * + 2
        sta     V1541_DATA_BUF+3  ;basic line number high byte
        rts

;Put a BASIC line with a file in the buffer
L94A8_GET_V1541_FILE:
        ldx     #$04
L94AA_LOOP:
        inx
        lda     V1541_DATA_BUF,x
        beq     L94B4
        cpx     #$15
        bne     L94AA_LOOP
L94B4:  lda     #'"'
L94B6:  sta     V1541_DATA_BUF,x
        lda     #' '
        inx
        cpx     #' '
        bne     L94B6

        lda     V1541_DATA_BUF
        bit     #$30
        beq     L94CC
        ldx     #'*' ;splat file like "*PRG"
        stx     V1541_DATA_BUF+22

L94CC:  bit     #$80
        bne     L94D5

        jsr     L8DE0_SOMEHOW_GETS_FILE_BLOCKS_USED_1
        bra     L94D8

L94D5:  lda     V1541_DATA_BUF+3

L94D8:  sta     V1541_DATA_BUF+2  ;Set number of blocks used by file
                                  ;as the line number low byte
        lda     V1541_DATA_BUF
        and     #$40
        beq     L94EA
        lda     #'P' ;ftype_p_prg
        ldx     #'R'
        ldy     #'G'
        bra     L94F0
L94EA:  lda     #'S' ;ftype_s_seq
        ldx     #'E'
        ldy     #'Q'
L94F0:  sta     V1541_DATA_BUF+23   ;P    S
        stx     V1541_DATA_BUF+24   ;R or E
        sty     V1541_DATA_BUF+25   ;G    Q

        lda     #$01
        sta     V1541_DATA_BUF      ;pointer to next basic line (low byte)
        lda     #$10
        sta     V1541_DATA_BUF+1    ;pointer to next basic line (high byte)
        stz     V1541_DATA_BUF+3

        lda     #'"'
        sta     V1541_DATA_BUF+4    ;first byte of basic line (quote before filename)

        lda     V1541_DATA_BUF+2    ;A = size of file in blocks
        cmp     #100
        bcs     L9515 ;branch if >= 100
        jsr     L9522_SHIFT_BASIC_TEXT_RIGHT
L9515:  lda     V1541_DATA_BUF+2    ;A = size of file in blocks again
        cmp     #10
        bcc     L951F ;branch if < 10
        jsr     L9522_SHIFT_BASIC_TEXT_RIGHT
L951F:  jsr     L9522_SHIFT_BASIC_TEXT_RIGHT
        ;Fall through

;Prepend one space to the beginning of the BASIC text.  The number of blocks
;is shown as the BASIC line number.  It can vary (1-3 decimal digits) so these
;spaces are added to the BASIC text to keep the filenames aligned.
L9522_SHIFT_BASIC_TEXT_RIGHT:
        lda     #' '
        ldx     #$04
L9526_LOOP:
        ldy     V1541_DATA_BUF,x
        sta     V1541_DATA_BUF,x
        tya
        inx
        cpx     #$1F
        bne     L9526_LOOP

        lda     #0
        sta     V1541_DATA_BUF+31   ;end of basic line
        rts
; ----------------------------------------------------------------------------
LOAD__: sta     VERCHK
        stz     SATUS
        lda     FA
        bne     L9544
        ;Device 0
L9541_BAD_DEVICE:
        jmp     ERROR9 ;BAD DEVICE #
; ----------------------------------------------------------------------------
L9544:  cmp     #$01
        beq     L9550_LOAD_V1541_OR_IEC
        cmp     #$04
        bcc     L9541_BAD_DEVICE
        cmp     #$1E
        bcs     L9541_BAD_DEVICE
L9550_LOAD_V1541_OR_IEC: ;Device=1 (Virtual 1541), Device=4-29 (IEC)
        ldy     FNLEN
        bne     L9558_LOAD_FNLEN_OK
        jmp     ERROR8 ;MISSING FILE NAME
; ----------------------------------------------------------------------------
L9558_LOAD_FNLEN_OK:
        jsr     LUKING  ;Print "SEARCHING FOR " then do OUTFN
        ldx     SA
        stx     WRBASE  ;Save SA before changes
        stz     SA
        lda     FA
        dec     a
        beq     L957A
        lda     #$60
        sta     SA
        jsr     OPENI
        lda     FA
        jsr     TALK__
        lda     SA
        jsr     TKSA
        bra     L9592
; ----------------------------------------------------------------------------
L957A:  phx
        jsr     V1541_OPEN
        plx
        lda     SATUS
        bit     #$0C
        beq     L9592
L9585:  jmp     ERROR4 ;FILE NOT FOUND
; ----------------------------------------------------------------------------
L9588_CLSEI_OR_ERROR16_OOM:
        lda     SA
        beq     L958F_JMP_ERROR16
        jsr     CLSEI
L958F_JMP_ERROR16:
        jmp     ERROR16 ;OUT OF MEMORY
; ----------------------------------------------------------------------------
L9592:  jsr     L9661
        sta     EAL
        lda     #$02
        bit     SATUS
        bne     L9585
        jsr     L9661
        sta     EAH
        lda     WRBASE  ;Recall SA before changes
        bne     L95AF
        lda     $B4
        sta     EAL
        lda     $B5
        sta     EAH
L95AF:  lda     VERCHK
        bne     L95E4_VERIFY
        jsr     PRIMM80
        .byte   "LOADING",$0d,0
        lda     EAH
        cmp     #>$05F8
        bcc     L9588_CLSEI_OR_ERROR16_OOM
        cmp     #<$05F8
        bcs     L9588_CLSEI_OR_ERROR16_OOM
        cmp     $020A
        bcc     L95D4
        lda     $020B
        beq     L9588_CLSEI_OR_ERROR16_OOM
L95D4:  lda     SA
        bne     L95F0
L95DA := *+2
        LDA     $03a0
        cmp     #$40 ;'@'
        bne     L95F0
        jsr     L96D6_USED_BY_LOAD
        bra     L9651_LOAD_OR_VERIFY_DONE
; ----------------------------------------------------------------------------
L95E4_VERIFY:
        jsr     PRIMM80
L95ED := *+6
        .byte   $0d,"VERIFY ",0
L95F0:  lda     #$02
        trb     SATUS
        jsr     LFDB9_STOP
        beq     L9657_STOP_PRESSED
L95F9:  jsr     L9661
        tax
        lda     SATUS
        lsr     a
        lsr     a
        bcs     L95F9
        txa
        ldy     VERCHK
        beq     L9622
        ldy     #$00
        sta     WRBASE                ;save .A
        lda     #EAL
        sta     SINNER
        jsr     GO_RAM_LOAD_GO_KERN
        cmp     WRBASE                ;compare with old .A
        beq     L963D
        lda     #$10
        jsr     UDST
        bra     L963D
L9622:  ldx     #$B2
        stx     $0360
        ldx     EAH
        cpx     #$F8
        bcs     L9637
        cpx     $020A
        bcc     L963A
        ldx     $020B
        bne     L963A
L9637:  jmp     L9588_CLSEI_OR_ERROR16_OOM
; ----------------------------------------------------------------------------
L963A:  jsr     GO_RAM_STORE_GO_KERN
L963D:  inc     EAL
        bne     L9643
        inc     EAH
L9643:  bit     SATUS
        bvc     L95F9
        lda     SA
        beq     L9651_LOAD_OR_VERIFY_DONE
        jsr     UNTLK
        jsr     CLSEI
L9651_LOAD_OR_VERIFY_DONE:
        ldx     EAL
        ldy     EAH
        clc
        rts
; ----------------------------------------------------------------------------
L9657_STOP_PRESSED:
        lda     SA
        bne     L965E
        jsr     CLSEI
L965E:  jmp     ERROR0  ;OK
; ----------------------------------------------------------------------------
L9661:  lda     SA
        beq     L9668
        jmp     ACPTR
L9668:  jmp     L971F
; ----------------------------------------------------------------------------
V1541_OPEN:
        jsr     L9671_V1541_INTERNAL_OPEN
        jmp     V1541_KERNAL_CALL_DONE
; ----------------------------------------------------------------------------
L9671_V1541_INTERNAL_OPEN:
        jsr     L8EAF_COPY_FNADR_FNLEN_THEN_SETUP_FOR_FILE_ACCESS
L9675 := *+1
        BCC     L969A_ERROR ;branch if error
        BIT     #$20
        BNE     L969A_ERROR

        ldx     $03A0
        cpx     #'$'
        bne     L969C_03A0_NOT_DOLLAR

        ;Opening the directory

        ldx     V1541_FILE_MODE
        bne     L9698_ERROR_34_SYNTAX_ERROR

        jsr     L9041
        jsr     L8C2A_JSR_V1541_SELECT_CHAN_17_JMP_L8C8B_CLEAR_ACTIVE_CHANNEL
        lda     #$40
        tsb     V1541_ACTIV_FLAGS
        bra     L96C0

L9692_ERROR_64_FILE_TYPE_MISMATCH:
        lda     #doserr_64_file_type_mism
        .byte   $2C
L9695_ERROR_60_WRITE_FILE_OPEN:
        lda     #doserr_60_write_file_open
        .byte   $2C
L9698_ERROR_34_SYNTAX_ERROR:
        lda     #doserr_34_syntax_err
L969A_ERROR:
        clc
        rts

L969C_03A0_NOT_DOLLAR:
        jsr     L8D9F_SELECT_DIR_CHANNEL_AND_CLEAR_IT_THEN_UNKNOWN_THEN_FILENAME_COMPARE
        bcc     L969A_ERROR ;branch if error (file not found)

        lda     V1541_DATA_BUF
L96A5 := *+1
        bit     #$20
        bne     L9695_ERROR_60_WRITE_FILE_OPEN
        bit     #$80
        bne     L96B1
        jsr     L8E20_MAYBE_CHECKS_HEADER
        bcc     L969A_ERROR ;branch if error
L96B1:  jsr     L9011_TEST_0218_AND_STORE_FILE_TYPE
        bcc     L969A_ERROR
        cpx     #ftype_s_seq
        beq     L9692_ERROR_64_FILE_TYPE_MISMATCH
        jsr     L8C2A_JSR_V1541_SELECT_CHAN_17_JMP_L8C8B_CLEAR_ACTIVE_CHANNEL
        jsr     L902D

L96C0:  lda     #$10
        tsb     V1541_ACTIV_FLAGS
        lda     $03A0
        cmp     #$40 ;'@'
        bne     L96D1
        lda     V1541_ACTIV_FLAGS
        and     #$80
        beq     L96D4
L96D1:  stz     $03A0
L96D4:  sec
        rts
; ----------------------------------------------------------------------------
;Called only from load
L96D6_USED_BY_LOAD:
        stz     V1541_ACTIV_E9
        dec     V1541_ACTIV_E9
L96DA_LOOP:
        inc     V1541_ACTIV_E9
        jsr     L89F9
        bcc     L9719
L96E1:  ldx     $020B
        lda     $020A
        bne     L96EA
        dex
L96EA:  dec     a
        jsr     L8A87
        ldy     #$02
        lda     ($E4),y
        bne     L96F5
        dec     a
L96F5:  sta     $E0
        lda     V1541_ACTIV_E9
        bne     L9703
L96FB:  lda     V1541_ACTIV_FLAGS
        and     #$40
        beq     L9703
        iny
        iny
L9703:  iny
        lda     ($E4),y
        phy
        ldy     #$00
        jsr     GO_RAM_STORE_GO_KERN
        inc     EAL
        bne     L9712
        inc     EAH
L9712:  ply
        cpy     $E0
        bne     L9703
L9718 := *+1
        bra     L96DA_LOOP
; ----------------------------------------------------------------------------
L971A := *+1
L9719:  jsr     L89E2
        jmp     L8D17

L971F:  jsr     L9725 ;maybe returns a cbm dos error code
L9724 := *+2
        jmp     V1541_KERNAL_CALL_DONE
; ----------------------------------------------------------------------------
L9725:  jsr     V1541_SELECT_CHAN_17 ;maybe returns a cbm dos error code
        bcc     L972D_RTS ;branch if error
        jsr     L8B46 ;maybe returns a cbm dos error code
L972D_RTS:  rts
; ----------------------------------------------------------------------------
;Called with Y=cmd len
;If Y>=$3C then return carry=0 and A=32 syntax error (long line)
;          else return carry=1 and A=32 (don't care)
L972E_V1541_CHECK_MAX_CMD_LEN:
        lda     #doserr_32_syntax_err
L9730:  cpy     #$3C ;if Y<3C then OK, else error 32
L9732:  rol     a
        eor     #$01
        ror     a
        rts
; ----------------------------------------------------------------------------
L9737_V1541_INTERNAL_OPEN_CMD_CHAN:
        jsr     V1541_SELECT_CHANNEL_GIVEN_SA
        lda     #$10
        tsb     V1541_ACTIV_FLAGS
        ldy     FNLEN
        sty     V1541_CMD_LEN
        jsr     L972E_V1541_CHECK_MAX_CMD_LEN
        bcs     L974A ;branch if no error
L9749_RTS:
        rts
; ----------------------------------------------------------------------------
L974A:  lda     #FNADR
        sta     SINNER
        dey
        bmi     L9749_RTS
L9752:  jsr     GO_RAM_LOAD_GO_KERN
        sta     V1541_CMD_BUF,y
        dey
        bpl     L9752
        bra     L9772_V1541_INTERPRET_CMD

L975D_V1541_CHROUT_CMD_CHAN:
        ldy     V1541_CMD_LEN
        jsr     L972E_V1541_CHECK_MAX_CMD_LEN
        bcs     L9766_STORE_CHR_IF_0D_INTERP_CMD ;branch if no error
        rts
; ----------------------------------------------------------------------------
L9767 :=  *+1
L9766_STORE_CHR_IF_0D_INTERP_CMD:
        sta     V1541_CMD_BUF,Y
        inc     V1541_CMD_LEN
        cmp     #$0D ;CR?
        beq     L9772_V1541_INTERPRET_CMD
        sec
        rts

L9772_V1541_INTERPRET_CMD:
        lda     V1541_CMD_BUF
L9775:  ldx     #(4*2)-1 ;4 cmds in table, two chars each
L9777:  cmp     L978E_V1541_CMDS,x
        beq     L9783_FOUND_CMD_IN_TABLE
        dex
L977E := *+1
        bpl     L9777
        lda     #doserr_31_invalid_cmd
        clc
        rts

L9783_FOUND_CMD_IN_TABLE:
        txa
        and     #$FE
        pha
        jsr     L979E
        plx
        jmp     (L9796_V1541_CMD_HANDLERS,x)
L9792 := *+4

L978E_V1541_CMDS:
        .byte "Ii", "Rr", "Ss", "Vv"
L9796_V1541_CMD_HANDLERS:
        .addr L8C6F_V1541_I_INITIALIZE
        .addr L980E_V1541_R_RENAME
L979A:  .addr L97D6_V1541_S_SCRATCH
        .addr L9842_V1541_V_VALIDATE

L979E:  ldy     V1541_CMD_LEN
        dey
        lda     #$96 ;TODO probably an address, see L8EB6
        ldx     #$02
L97A7 := *+1
        jmp     L8EB6

;Called twice from rename, not used anywhere else
L97A9_USED_BY_RENAME:
        jsr     L979E
L97AC:  lda     (V1541_FNADR)
        inc     V1541_FNADR
        bne     L97B4
        inc     V1541_FNADR+1
L97B4:  dec     V1541_FNLEN
        beq     L97D2_33_SYNTAX_ERROR
        cmp     #'='
        bne     L97AC
        jsr     L8EBD_SETUP_FOR_FILE_ACCESS_AND_DO_DIR_SEARCH_STUFF
        bcc     L97D4_CLC_RTS
        and     #$40
        ora     V1541_FILE_TYPE
        ora     V1541_FILE_MODE
        ora     $03A0
        bne     L97D2_33_SYNTAX_ERROR
        jmp     L8D9F_SELECT_DIR_CHANNEL_AND_CLEAR_IT_THEN_UNKNOWN_THEN_FILENAME_COMPARE
; ----------------------------------------------------------------------------

L97D2_33_SYNTAX_ERROR:
        lda     #doserr_33_syntax_err ;Invalid filename
L97D4_CLC_RTS:
        clc
        rts
; ----------------------------------------------------------------------------
L97D6_V1541_S_SCRATCH:
        bcs     L97DC
L97D8_SCRATCH_NO_FILENAME:
        lda     #doserr_34_syntax_err ;34 No file given
        clc
        rts

L97DC:  bit     #$80
        beq     L97D8_SCRATCH_NO_FILENAME
        and     #$20
        ora     V1541_FILE_TYPE
        ora     V1541_FILE_MODE
        bne     L97D8_SCRATCH_NO_FILENAME
        lda     #$00
        pha
L97ED:
L97EE           := * + 1
        jsr     L8D9F_SELECT_DIR_CHANNEL_AND_CLEAR_IT_THEN_UNKNOWN_THEN_FILENAME_COMPARE
        bcc     L9805_ERROR
L97F2:  tsx
L97F5           := * + 2
        inc     stack+1,x
        jsr     L8D17  ;maybe returns cbm dos error in a
        lda     V1541_DATA_BUF
        and     #$80
        bne     L97ED
        jsr     L89E2
L9803:  bra     L97ED

L9805_ERROR:  pla
        ldx     #$01
        ldy     #$00
        sec
        jmp     L9964_STORE_XAY_CLEAR_0217

; ----------------------------------------------------------------------------
L980F := *+1
L980E_V1541_R_RENAME:
        bcc     L9840_RENAME_ERROR
        bit     #$80
        beq     L983E_RENAME_INVALID_FILENAME
        and     #$40
        ora     $03A0
        ora     V1541_FILE_MODE
L981D := *+1
        ORA     V1541_FILE_TYPE
        bne     L983E_RENAME_INVALID_FILENAME

        jsr     L8D9F_SELECT_DIR_CHANNEL_AND_CLEAR_IT_THEN_UNKNOWN_THEN_FILENAME_COMPARE
        lda     #doserr_63_file_exists
        bcs     L9840_RENAME_ERROR ;branch if no error (file exists, which is an error here)

        jsr     L97A9_USED_BY_RENAME
        bcc     L9840_RENAME_ERROR

        jsr     L979E
        jsr     L8FF3

L9833:  jsr     L8D5B_UNKNOWN_DIR_RELATED
        bcc     L9840_RENAME_ERROR

        jsr     L97A9_USED_BY_RENAME
        jmp     L8D17 ;maybe returns cbm dos error in a

L983E_RENAME_INVALID_FILENAME:
        lda     #doserr_33_syntax_err ;33 Invalid filename
L9840_RENAME_ERROR:
        clc
        rts

; ----------------------------------------------------------------------------
L9842_V1541_V_VALIDATE:
        jsr     L8C6F_V1541_I_INITIALIZE
        jsr     KL_RAMTAS
        cpx     $0209
        beq     L985B

L984D:  stx     $0209
        sta     $0208
        stx     $020B
        sta     $020A
        sec
        rts

L985B:  cmp     $0208
        bne     L984D
        cpx     $020A
        bcc     L984D
        bne     L986C
        cmp     $020A
        bcc     L984D
L986C:  jsr     L8CBB_CLEAR_ACTIVE_CHANNEL_EXCEPT_FLAGS_THEN_BRA_L8CCE_JSR_L8CE6_THEN_UPDATE_ACTIVE_CHANNEL_AND_03A7_03A6
        bne     L9890
L9871:  jsr     L8CC3
        bcc     L988B ;branch if error
        jsr     L8CD1
        jsr     L8AD5_MAYBE_READS_BLOCK_HEADER
        ldy     #$02
        lda     V1541_ACTIV_EA
        sta     ($E4),y
L9882:  inc     V1541_ACTIV_E9
        beq     L9890
        jsr     L89F9
        bra     L9882
L988B:  bit     SXREG
        bpl     L9871
L9890:  jsr     L8CBB_CLEAR_ACTIVE_CHANNEL_EXCEPT_FLAGS_THEN_BRA_L8CCE_JSR_L8CE6_THEN_UPDATE_ACTIVE_CHANNEL_AND_03A7_03A6
L9894 := *+1
        bcc     L98D0
        bra     L98AB
L9897:  jsr     L8CC3
L989B :=*+1
        BCC     L98D0 ;branch if error
L989E := *+2
        jsr     L8C2A_JSR_V1541_SELECT_CHAN_17_JMP_L8C8B_CLEAR_ACTIVE_CHANNEL
        LDA     V1541_DATA_BUF
        bit     #$80
        bne     L98B4
        lda     V1541_DATA_BUF+1
        sta     V1541_ACTIV_E8
L98AB:  jsr     L8AD5_MAYBE_READS_BLOCK_HEADER
        bcs     L98B9 ;branch if no error
        ;error
        lda     V1541_ACTIV_E9
        beq     L9897
L98B4:  jsr     L8D17 ;maybe returns cbm dos error in a
        bra     L9890

L98B9:  inc     V1541_ACTIV_E9
        ldy     #$02
        lda     ($E4),y
        beq     L98AB
        lda     V1541_ACTIV_E9
        pha
        jsr     L8DE0_SOMEHOW_GETS_FILE_BLOCKS_USED_1
        sta     V1541_ACTIV_E9 ;store number of blocks used
        pla
        cmp     V1541_ACTIV_E9
L98CD := *+1
        BNE     L98B4
        BRA     L9897
L98D0:  ldx     #$3F
L98D2:  stz     V1541_CMD_BUF,x
        dex
        bpl     L98D2
        inc     V1541_CMD_BUF
        jsr     L8CBB_CLEAR_ACTIVE_CHANNEL_EXCEPT_FLAGS_THEN_BRA_L8CCE_JSR_L8CE6_THEN_UPDATE_ACTIVE_CHANNEL_AND_03A7_03A6
L98DE:  bcc     L9917
        bra     L98E5
L98E2:  jsr     L8D17 ;maybe returns cbm dos error in a
L98E5:  jsr     L8CBB_CLEAR_ACTIVE_CHANNEL_EXCEPT_FLAGS_THEN_BRA_L8CCE_JSR_L8CE6_THEN_UPDATE_ACTIVE_CHANNEL_AND_03A7_03A6
L98E8:  bra     L98ED
L98EA:  jsr     L8CC3
L98ED:  bcc     L9917 ;branch if error
        jsr     L9932
        and     V1541_CMD_BUF,y
        bne     L98E2
        lda     PowersOfTwo,x
        ora     V1541_CMD_BUF,y
        sta     V1541_CMD_BUF,y
        lda     #$30
        trb     V1541_DATA_BUF
        bne     L990F
        lda     V1541_DATA_BUF+1
        jsr     L8E20_MAYBE_CHECKS_HEADER ;maybe returns cbm dos error code in A
        bcs     L98EA ;branch if no error
        ;error occurred
L990F:  jsr     L8D17 ;maybe returns cbm dos error in a
        jsr     L8D5B_UNKNOWN_DIR_RELATED
        bra     L98D0
L9917:  jsr     L8A81
L991A:  beq     L9930
L991C:  lda     ($E4)
        jsr     L9932
        and     V1541_CMD_BUF,y
        bne     L992B
        jsr     L89FF
        bra     L9917
L992B:  jsr     L8A61
        bcs     L991C
L9930:  sec
        rts
; ----------------------------------------------------------------------------
L9932:  pha
        lsr     a
        lsr     a
        lsr     a
        tay
        pla
        and     #$07
        tax
        lda     PowersOfTwo,x
L993E:  rts
; ----------------------------------------------------------------------------
V1541_KERNAL_CALL_DONE:
        tax ;Save error code in X
        lda     #$00
        bcs     L9955 ;branch if no error

        ;error occurred
        lda     V1541_ACTIV_E8
        ldy     V1541_ACTIV_E9
        jsr     L9964_STORE_XAY_CLEAR_0217
        lda     #$04
        cpx     #doserr_25_write_err ;25 write-verify error
        bne     L9953
        ora     #$08
L9953:  ldx     #$0D
L9955:  bit     SXREG
        bpl     L995C
        ora     #$40 ;EOF
L995C:  sta     SATUS
        stz     SXREG
        txa
L9962:  clc
        rts
; ----------------------------------------------------------------------------
L9964_STORE_XAY_CLEAR_0217:
        stx     $0210
        sta     $0211
L96A9 := *-1
        sty     $0212

        stz     $0217
        rts
; ----------------------------------------------------------------------------
L9971:  .byte   "CHANNEL",0
        .byte   "COMMAND",0
        .byte   "DIRECTORY",0
        .byte   "DISK",0
        .byte   "DOS",0
        .byte   "ERROR",0
L999A:  .byte   "EXISTS",0
L99A2 := *+1
        .byte   "FILE",0
L99A6:  .byte   "FILES",0
        .byte   "FOUND",0
        .byte   "FULL",0
        .byte   "ILLEGAL",0
        .byte   "INVALID",0
        .byte   "LARGE",0
        .byte   "LINE",0
        .byte   "LONG",0
        .byte   "MISMATCH",0
        .byte   "NO",0
        .byte   "NOT",0
        .byte   "OK",0
        .byte   "OPEN",0
        .byte   "PROTECT",0
        .byte   "READ",0
        .byte   "SCRATCHED",0
        .byte   "SYNTAX",0
        .byte   "SYSTEM",0
        .byte   "T&S",0
        .byte   "TOO",0
        .byte   "TYPE",0
        .byte   "VERIFY",0
L9A2A := *+2
L9A2B := *+3
        .byte   "WRITE",0
        .byte   0
; ----------------------------------------------------------------------------
        .byte   $77,$00,$00,$01,$36,$8C,$00,$14 ; 9A2F 77 00 00 01 36 8C 00 14  w...6...
        .byte   $47,$A4,$00,$19,$B8,$B1,$24,$1A ; 9A37 47 A4 00 19 B8 B1 24 1A  G.....$.
        .byte   $B8,$7F,$24,$1B,$87,$24,$00,$1F ; 9A3F B8 7F 24 1B 87 24 00 1F  ..$..$..
        .byte   $4F,$09,$00,$20,$62,$5D,$00,$21 ; 9A47 4F 09 00 20 62 5D 00 21  O.. b].!
        .byte   $96,$24,$00,$21,$96,$24,$00,$22 ; 9A4F 96 24 00 21 96 24 00 22  .$.!.$."
        .byte   $96,$24,$00,$27,$96,$24,$00,$34 ; 9A57 96 24 00 27 96 24 00 34  .$.'.$.4
        .byte   $31,$A8,$57,$3C,$B8,$31,$7A,$3D ; 9A5F 31 A8 57 3C B8 31 7A 3D  1.W<.1z=
        .byte   $31,$73,$7A                     ; 9A67 31 73 7A                 1sz
L9A6A:  .byte   $3E,$31,$73,$3C,$3F,$31,$2A,$00 ; 9A6A 3E 31 73 3C 3F 31 2A 00  >1s<?1*.
        .byte   $40,$31,$AC,$67,$43,$47,$9D,$A4 ; 9A72 40 31 AC 67 43 47 9D A4  @1.gCG..
        .byte   $46,$70,$01,$00,$47,$11,$24,$00 ; 9A7A 46 70 01 00 47 11 24 00  Fp..G.$.
        .byte   $47,$11,$24,$00,$48
L9A87:  .byte   $1B,$42,$00,$49,$20,$67,$24
L9A8E:  .byte   $00,$01,$02,$80,$81,$82,$83,$84 ; 9A8E 00 01 02 80 81 82 83 84  ........
        .byte   $85,$86,$87,$88                 ; 9A96 85 86 87 88              ....
L9A9A:  .byte   $41,$81,$10,$22,$42,$82,$10,$23 ; 9A9A 41 81 10 22 42 82 10 23  A.."B..#
        .byte   $43,$83,$00                     ; 9AA2 43 83 00                 C..
; ----------------------------------------------------------------------------
L9AA5_V1541_CHRIN_CMD_CHAN:
        lda     $0217
        inc     $0217
        ldy     #$0B
L9AAD_SEARCH_L9A8E_LOOP:
        cmp     L9A8E,y
        beq     L9AB8_FOUND_IN_L9A8E
        dey
        bpl     L9AAD_SEARCH_L9A8E_LOOP
        jmp     L9AE8_NOT_FOUND_IN_L9A8E
; ----------------------------------------------------------------------------
L9AB8_FOUND_IN_L9A8E:
        lda     L9A9A,y
        bne     L9ACD
        tax
        tay
L9AC1 := *+2
        JSR     L9964_STORE_XAY_CLEAR_0217
        SEC
        ROR     $039d
        LDA     #$0d ;cr
        .byte $2c
L9AC9:  lda     #$2C ;,
        sec
        rts
; ----------------------------------------------------------------------------
L9ACD:  bit     #$10
        bne     L9AC9
        sta     $E0
        and     #$03
L9AD5:  tax
L9AD6:  lda     $020F,x
        jsr     L886A
        bit     $E0
        bmi     L9AE4
        txa
        bvs     L9AE4
        tya
L9AE5 := *+1
L9AE4:  ora #$30
        sec
        rts
; ----------------------------------------------------------------------------
L9AE8_NOT_FOUND_IN_L9A8E:
        dec     a
        sta     $E0
        ldx     #$00
        lda     $0210
L9AF0_LOOP:
        inx
        inx
        inx
        inx
        beq     L9B12
        cmp     L9A2A,x
        bne     L9AF0_LOOP
L9AFB_OUTER_LOOP:
        lda     #$20
        ldy     L9A2B,x
L9B01 := *+1
        beq     L9B12
L9B02_INNER_LOOP:
        dec     $E0
        beq     L9B19
        iny
        lda     L9971-2,y
        bne     L9B02_INNER_LOOP
        inx
        txa
        and     #$03
        bne     L9AFB_OUTER_LOOP
L9B12:  lda     #$80
        sta     $0217
        lda     #$2C
L9B19:  sec
        rts
; ----------------------------------------------------------------------------
L9B1B:  jmp     (L9B1E,x)
L9B1F := *+1
L9B1E:  .addr L9BF6
        .addr L9BDA
L9B23 := *+1
        .addr LA473
        .addr L9C6B
        .addr L9BE0
        .addr LA2D1
        .addr L9CA4
        .addr L9CA7
        .addr L9CBB
        .addr L9CBE
        .addr L9F60
        .addr L9F63
        .addr LA0F6
        .addr LA0F9
        .addr L9EF0
        .addr LA369
        .addr LA661
        .addr LA6A7
        .addr LA65A
        .addr LA66B
        .addr LA72B
        .addr LA848
        .addr LA84F
        .addr LA898
        .addr LA92D
        .addr LA28A
        .addr LA2D9
        .addr LA29A
        .addr LA2DC_UNKNOWN_INDIRECT_STUFF_LOAD
        .addr LA7DB
        .addr LA02B
        .addr L9FF1_INDIRECT_STUFF
        .addr LA1DB
        .addr LA1DD_INDIRECT_STUFF_LOAD
        .addr LA21A
        .addr LA26B
        .addr LA27B
        .addr LA2AB
        .addr LA2CD
        .addr LA2D5
        .addr LA338
        .addr LA421
        .addr $A396
        .addr LA226
        .addr LA475
        .addr LA2A8
        .addr LA7D8
        .addr L9F4E
        .addr L9F42
        .addr L9F33
        .addr L9F5A
        .addr LA65F
        .addr LA06D
        .addr LA1B7
        .addr L9BCE
        .addr L9B9F
        .addr L9BA2
        .addr L9B98
        .addr L9B9B
        .addr LA9C6
        .addr LA9C9

L9B98:  jsr     LA02B                           ; 9B98 20 2B A0                  +.
L9B9B:  ldy     #$FF                            ; 9B9B A0 FF                    ..
        bra     L9BA4                           ; 9B9D 80 05                    ..
L9B9F:  jsr     LA02B                           ; 9B9F 20 2B A0                  +.
L9BA2:  ldy     #$00                            ; 9BA2 A0 00                    ..
L9BA4:  sty     $49                             ; 9BA4 84 49                    .I
        jsr     L9BF6                           ; 9BA6 20 F6 9B                  ..
        lda     $2B                             ; 9BA9 A5 2B                    .+
        eor     $49                             ; 9BAB 45 49                    EI
        sta     $00                             ; 9BAD 85 00                    ..
        lda     $2C                             ; 9BAF A5 2C                    .,
        eor     $49                             ; 9BB1 45 49                    EI
        sta     $01                             ; 9BB3 85 01                    ..
        jsr     LA26B                           ; 9BB5 20 6B A2                  k.
        jsr     L9BF6                           ; 9BB8 20 F6 9B                  ..
        lda     $2C                             ; 9BBB A5 2C                    .,
        eor     $49                             ; 9BBD 45 49                    EI
        and     $01                             ; 9BBF 25 01                    %.
        eor     $49                             ; 9BC1 45 49                    EI
        tay                                     ; 9BC3 A8                       .
        lda     $2B                             ; 9BC4 A5 2B                    .+
        eor     $49                             ; 9BC6 45 49                    EI
        and     $00                             ; 9BC8 25 00                    %.
        eor     $49                             ; 9BCA 45 49                    EI
        bra     L9BDA                           ; 9BCC 80 0C                    ..
L9BCE:  jsr     L9BF6                           ; 9BCE 20 F6 9B                  ..
        lda     $2C                             ; 9BD1 A5 2C                    .,
        eor     #$FF                            ; 9BD3 49 FF                    I.
        tay                                     ; 9BD5 A8                       .
        lda     $2B                             ; 9BD6 A5 2B                    .+
        eor     #$FF                            ; 9BD8 49 FF                    I.
; ----------------------------------------------------------------------------
L9BDA:  jsr     L9C60                           ; 9BDA 20 60 9C                  `.
L9BDD:  jmp     LA2B3                           ; 9BDD 4C B3 A2                 L..
; ----------------------------------------------------------------------------
L9BE0:  lda     $2D                             ; 9BE0 A5 2D                    .-
        bmi     L9C05                           ; 9BE2 30 21                    0!
        lda     $25                             ; 9BE4 A5 25                    .%
        cmp     #$91                            ; 9BE6 C9 91                    ..
        bcs     L9C05                           ; 9BE8 B0 1B                    ..
        jsr     LA338                           ; 9BEA 20 38 A3                  8.
L9BEE := *+1
         LDA    $2b
         LDY    $2c
         STY    $06
         STA    $07
L9BF4:   rts
; ----------------------------------------------------------------------------
L9BF6:  lda     $25                             ; 9BF6 A5 25                    .%
        cmp     #$90                            ; 9BF8 C9 90                    ..
        bcc     L9C0A                           ; 9BFA 90 0E                    ..
        lda     #<L9C58                         ; 9BFC A9 58                    .X
        ldy     #>L9C58                         ; 9BFE A0 9C                    ..
        jsr     LA2DC_UNKNOWN_INDIRECT_STUFF_LOAD ; 9C00 20 DC A2                  ..
        beq     L9C0A                           ; 9C03 F0 05                    ..
L9C05:  ldx     #$0E                            ; 9C05 A2 0E                    ..
        jmp     LFB4B                           ; 9C07 4C 4B FB                 LK.
; ----------------------------------------------------------------------------
L9C0C := *+2
L9C0A:  jmp     LA338
L9C0D:  inc     $3F                             ; 9C0D E6 3F                    .?
        bne     L9C13                           ; 9C0F D0 02                    ..
        inc     $40                             ; 9C11 E6 40                    .@
L9C13:  sei                                     ; 9C13 78                       x
        ldy     #$00                            ; 9C14 A0 00                    ..
        lda     #$3F ;ZP-address                ; 9C16 A9 3F                    .?
        sta     SINNER                          ; 9C18 8D 4E 03                 .N.
        jsr     GO_RAM_LOAD_GO_KERN             ; 9C1B 20 4A 03                  J.
        cli                                     ; 9C1E 58                       X
        cmp     #$3A                            ; 9C1F C9 3A                    .:
        bcs     L9C2D                           ; 9C21 B0 0A                    ..
        cmp     #$20                            ; 9C23 C9 20                    .
        beq     L9C0D                           ; 9C25 F0 E6                    ..
        sec                                     ; 9C27 38                       8
        sbc     #$30                            ; 9C28 E9 30                    .0
        sec                                     ; 9C2A 38                       8
        sbc     #$D0                            ; 9C2B E9 D0                    ..
L9C2D:  rts                                     ; 9C2D 60                       `
; ----------------------------------------------------------------------------
L9C2E:  lda     #$3F ;ZP-address                ; 9C2E A9 3F                    .?
        sta     SINNER                          ; 9C30 8D 4E 03                 .N.
        jmp     GO_RAM_LOAD_GO_KERN             ; 9C33 4C 4A 03                 LJ.
; ----------------------------------------------------------------------------
L9C36:  lda     #$08 ;ZP-address                ; 9C36 A9 08                    ..
        sta     SINNER                          ; 9C38 8D 4E 03                 .N.
L9C3C := *+1
        jmp     GO_RAM_LOAD_GO_KERN
L9C3E:  lda     #$08                            ; 9C3E A9 08                    ..
        sta     $0357                           ; 9C40 8D 57 03                 .W.
        jmp     GO_APPL_LOAD_GO_KERN            ; 9C43 4C 53 03                 LS.
; ----------------------------------------------------------------------------
L9C46:  lda     #$0A ;ZP-address                ; 9C46 A9 0A                    ..
        sta     SINNER                          ; 9C48 8D 4E 03                 .N.
        jmp     GO_RAM_LOAD_GO_KERN             ; 9C4B 4C 4A 03                 LJ.
; ----------------------------------------------------------------------------
L9C4E:  pha                                     ; 9C4E 48                       H
        lda     #$0A                            ; 9C4F A9 0A                    ..
        sta     $0360                           ; 9C51 8D 60 03                 .`.
        pla                                     ; 9C54 68                       h
        jmp     GO_RAM_STORE_GO_KERN            ; 9C55 4C 5C 03                 L\.
; ----------------------------------------------------------------------------
L9C58:  bcc     L9BDA                           ; 9C58 90 80                    ..
        brk                                     ; 9C5A 00                       .
        brk                                     ; 9C5B 00                       .
        brk                                     ; 9C5C 00                       .
        brk                                     ; 9C5D 00                       .
        brk                                     ; 9C5E 00                       .
        brk                                     ; 9C5F 00                       .
L9C60:  ldx     #$00                            ; 9C60 A2 00                    ..
;TODO probably code
        .byte   $86                             ; 9C62 86                       .
L9C63:  .byte   $02                             ; 9C63 02                       .
        sta     $26                             ; 9C64 85 26                    .&
        sty     $27                             ; 9C66 84 27                    .'
        ldx     #$90                            ; 9C68 A2 90                    ..
        rts                                     ; 9C6A 60                       `
; ----------------------------------------------------------------------------
L9C6B:  ldx     $3F                             ; 9C6B A6 3F                    .?
        ldy     $40                             ; 9C6D A4 40                    .@
        stx     $3B                             ; 9C6F 86 3B                    .;
        sty     $3C                             ; 9C71 84 3C                    .<
        ldx     $08                             ; 9C73 A6 08                    ..
        stx     $3F                             ; 9C75 86 3F                    .?
        clc                                     ; 9C77 18                       .
        adc     $08                             ; 9C78 65 08                    e.
        sta     $0A                             ; 9C7A 85 0A                    ..
        ldx     $09                             ; 9C7C A6 09                    ..
        stx     $40                             ; 9C7E 86 40                    .@
        bcc     L9C83                           ; 9C80 90 01                    ..
        inx                                     ; 9C82 E8                       .
L9C83:  stx     $0B                             ; 9C83 86 0B                    ..
        ldy     #$00                            ; 9C85 A0 00                    ..
        jsr     L9C46                           ; 9C87 20 46 9C                  F.
        pha                                     ; 9C8A 48                       H
        tya                                     ; 9C8B 98                       .
        jsr     L9C4E                           ; 9C8C 20 4E 9C                  N.
        jsr     L9C13                           ; 9C8F 20 13 9C                  ..
        jsr     LA396                           ; 9C92 20 96 A3                  ..
        pla                                     ; 9C95 68                       h
        ldy     #$00                            ; 9C96 A0 00                    ..
        jsr     L9C4E                           ; 9C98 20 4E 9C                  N.
        ldx     $3B                             ; 9C9B A6 3B                    .;
        ldy     $3C                             ; 9C9D A4 3C                    .<
        stx     $3F                             ; 9C9F 86 3F                    .?
        sty     $40                             ; 9CA1 84 40                    .@
L9CA3:  rts                                     ; 9CA3 60                       `
; ----------------------------------------------------------------------------
L9CA4:  jsr     LA02B                           ; 9CA4 20 2B A0                  +.
L9CA7:  lda     $2D                             ; 9CA7 A5 2D                    .-
        eor     #$FF                            ; 9CA9 49 FF                    I.
        sta     $2D                             ; 9CAB 85 2D                    .-
        eor     $38                             ; 9CAD 45 38                    E8
        sta     $39                             ; 9CAF 85 39                    .9
        lda     $25                             ; 9CB1 A5 25                    .%
        jmp     L9CBE                           ; 9CB3 4C BE 9C                 L..
; ----------------------------------------------------------------------------
L9CB6:  jsr     L9E56                           ; 9CB6 20 56 9E                  V.
        bcc     L9CF7                           ; 9CB9 90 3C                    .<
L9CBD := *+2 ;todo this is code; entry in table
L9CBB:  jsr     LA02B
L9CBE:  bne     L9CC3                           ; 9CBE D0 03                    ..
        jmp     LA26B                           ; 9CC0 4C 6B A2                 Lk.
; ----------------------------------------------------------------------------
L9CC3:  ldx     $3A                             ; 9CC3 A6 3A                    .:
        stx     $14                             ; 9CC5 86 14                    ..
        ldx     #$30                            ; 9CC7 A2 30                    .0
        lda     $30                             ; 9CC9 A5 30                    .0
L9CCB:  tay                                     ; 9CCB A8                       .
        beq     L9CA3                           ; 9CCC F0 D5                    ..
        sec                                     ; 9CCE 38                       8
        sbc     $25                             ; 9CCF E5 25                    .%
        beq     L9CF7                           ; 9CD1 F0 24                    .$
        bcc     L9CE7                           ; 9CD3 90 12                    ..
        .byte   $84                             ; 9CD5 84                       .
L9CD6:  and     WIN_BTM_RGHT_X                  ; 9CD6 25 A4                    %.
        sec                                     ; 9CD8 38                       8
        sty     $2D                             ; 9CD9 84 2D                    .-
L9CDB:  eor     #$FF                            ; 9CDB 49 FF                    I.
        adc     #$00                            ; 9CDD 69 00                    i.
        ldy     #$00                            ; 9CDF A0 00                    ..
        sty     $14                             ; 9CE1 84 14                    ..
        ldx     #$25                            ; 9CE3 A2 25                    .%
        bne     L9CEB                           ; 9CE5 D0 04                    ..
L9CE7:  ldy     #$00                            ; 9CE7 A0 00                    ..
        sty     $3A                             ; 9CE9 84 3A                    .:
L9CEB:  cmp     #$F9                            ; 9CEB C9 F9                    ..
        bmi     L9CB6                           ; 9CED 30 C7                    0.
        tay                                     ; 9CEF A8                       .
        lda     $3A                             ; 9CF0 A5 3A                    .:
        lsr     $01,x                           ; 9CF2 56 01                    V.
        jsr     L9E6D                           ; 9CF4 20 6D 9E                  m.
L9CF7:  bit     $39                             ; 9CF7 24 39                    $9
        bpl     L9D73                           ; 9CF9 10 78                    .x
        ldy     #$25                            ; 9CFB A0 25                    .%
        cpx     #$30                            ; 9CFD E0 30                    .0
        beq     L9D03                           ; 9CFF F0 02                    ..
        ldy     #$30                            ; 9D01 A0 30                    .0
L9D03:  sec                                     ; 9D03 38                       8
        eor     #$FF                            ; 9D04 49 FF                    I.
        adc     $14                             ; 9D06 65 14                    e.
        sta     $3A                             ; 9D08 85 3A                    .:
        lda     $07,y                           ; 9D0A B9 07 00                 ...
        sbc     $07,x                           ; 9D0D F5 07                    ..
L9D0F:  sta     $2C                             ; 9D0F 85 2C                    .,
        lda     $06,y                           ; 9D11 B9 06 00                 ...
        sbc     $06,x                           ; 9D14 F5 06                    ..
        .byte   $85                             ; 9D16 85                       .
L9D17:  .byte   $2B                             ; 9D17 2B                       +
        lda     $05,y                           ; 9D18 B9 05 00                 ...
        sbc     $05,x                           ; 9D1B F5 05                    ..
        sta     $2A                             ; 9D1D 85 2A                    .*
        lda     $04,y                           ; 9D1F B9 04 00                 ...
        sbc     $04,x                           ; 9D22 F5 04                    ..
        sta     $29                             ; 9D24 85 29                    .)
L9D26:  lda     $03,y                           ; 9D26 B9 03 00                 ...
        sbc     $03,x                           ; 9D29 F5 03                    ..
        sta     $28                             ; 9D2B 85 28                    .(
        lda     $02,y                           ; 9D2D B9 02 00                 ...
        sbc     $02,x                           ; 9D30 F5 02                    ..
        sta     $27                             ; 9D32 85 27                    .'
        lda     $01,y                           ; 9D34 B9 01 00                 ...
        sbc     $01,x                           ; 9D37 F5 01                    ..
        sta     $26                             ; 9D39 85 26                    .&
L9D3B:  bcs     L9D40                           ; 9D3B B0 03                    ..
L9D3D:  jsr     L9DDA                           ; 9D3D 20 DA 9D                  ..
L9D40:  ldy     #$00                            ; 9D40 A0 00                    ..
        tya                                     ; 9D42 98                       .
        clc                                     ; 9D43 18                       .
L9D44:  ldx     $26                             ; 9D44 A6 26                    .&
        bne     L9DB6                           ; 9D46 D0 6E                    .n
        ldx     $27                             ; 9D48 A6 27                    .'
        stx     $26                             ; 9D4A 86 26                    .&
        .byte   $A6                             ; 9D4C A6                       .
L9D4D:  plp                                     ; 9D4D 28                       (
        stx     $27                             ; 9D4E 86 27                    .'
        ldx     $29                             ; 9D50 A6 29                    .)
        stx     $28                             ; 9D52 86 28                    .(
        ldx     $2A                             ; 9D54 A6 2A                    .*
        stx     $29                             ; 9D56 86 29                    .)
        ldx     $2B                             ; 9D58 A6 2B                    .+
        stx     $2A                             ; 9D5A 86 2A                    .*
        ldx     $2C                             ; 9D5C A6 2C                    .,
L9D5E:  stx     $2B                             ; 9D5E 86 2B                    .+
L9D60:  ldx     $3A                             ; 9D60 A6 3A                    .:
        stx     $2C                             ; 9D62 86 2C                    .,
        sty     $3A                             ; 9D64 84 3A                    .:
        adc     #$08                            ; 9D66 69 08                    i.
        cmp     #$38                            ; 9D68 C9 38                    .8
        bne     L9D44                           ; 9D6A D0 D8                    ..
L9D6C:  lda     #$00                            ; 9D6C A9 00                    ..
L9D6E:  .byte   $85                             ; 9D6E 85                       .
L9D6F:  .byte   $25                             ; 9D6F 25                       %
L9D70:  sta     $2D                             ; 9D70 85 2D                    .-
        rts                                     ; 9D72 60                       `
; ----------------------------------------------------------------------------
L9D73:  adc     $14                             ; 9D73 65 14                    e.
        sta     $3A                             ; 9D75 85 3A                    .:
        lda     $2C                             ; 9D77 A5 2C                    .,
        adc     $37                             ; 9D79 65 37                    e7
        sta     $2C                             ; 9D7B 85 2C                    .,
        lda     $2B                             ; 9D7D A5 2B                    .+
        adc     $36                             ; 9D7F 65 36                    e6
        .byte   $85                             ; 9D81 85                       .
L9D82:  .byte   $2B                             ; 9D82 2B                       +
        lda     $2A                             ; 9D83 A5 2A                    .*
        adc     $35                             ; 9D85 65 35                    e5
        sta     $2A                             ; 9D87 85 2A                    .*
        lda     $29                             ; 9D89 A5 29                    .)
        .byte   $65                             ; 9D8B 65                       e
L9D8C:  bit     $85,x                           ; 9D8C 34 85                    4.
        .byte   $29                             ; 9D8E 29                       )
L9D8F:  lda     $28                             ; 9D8F A5 28                    .(
L9D91:  adc     $33                             ; 9D91 65 33                    e3
        sta     $28                             ; 9D93 85 28                    .(
        lda     $27                             ; 9D95 A5 27                    .'
        adc     $32                             ; 9D97 65 32                    e2
        sta     $27                             ; 9D99 85 27                    .'
        lda     $26                             ; 9D9B A5 26                    .&
        adc     $31                             ; 9D9D 65 31                    e1
        sta     $26                             ; 9D9F 85 26                    .&
L9DA1:  jmp     L9DC3                           ; 9DA1 4C C3 9D                 L..
; ----------------------------------------------------------------------------
L9DA4:  adc     #$01                            ; 9DA4 69 01                    i.
        asl     $3A                             ; 9DA6 06 3A                    .:
        rol     $2C                             ; 9DA8 26 2C                    &,
        rol     $2B                             ; 9DAA 26 2B                    &+
        rol     $2A                             ; 9DAC 26 2A                    &*
        rol     $29                             ; 9DAE 26 29                    &)
        rol     $28                             ; 9DB0 26 28                    &(
        rol     $27                             ; 9DB2 26 27                    &'
        rol     $26                             ; 9DB4 26 26                    &&
L9DB6:  bpl     L9DA4                           ; 9DB6 10 EC                    ..
        sec                                     ; 9DB8 38                       8
        sbc     $25                             ; 9DB9 E5 25                    .%
        bcs     L9D6C                           ; 9DBB B0 AF                    ..
        eor     #$FF                            ; 9DBD 49 FF                    I.
        adc     #$01                            ; 9DBF 69 01                    i.
        sta     $25                             ; 9DC1 85 25                    .%
L9DC3:  bcc     L9DD9                           ; 9DC3 90 14                    ..
L9DC5:  inc     $25                             ; 9DC5 E6 25                    .%
        beq     L9E2F                           ; 9DC7 F0 66                    .f
        ror     $26                             ; 9DC9 66 26                    f&
        ror     $27                             ; 9DCB 66 27                    f'
        ror     $28                             ; 9DCD 66 28                    f(
        ror     $29                             ; 9DCF 66 29                    f)
        ror     $2A                             ; 9DD1 66 2A                    f*
        ror     $2B                             ; 9DD3 66 2B                    f+
        ror     $2C                             ; 9DD5 66 2C                    f,
        ror     $3A                             ; 9DD7 66 3A                    f:
L9DD9:  rts                                     ; 9DD9 60                       `
; ----------------------------------------------------------------------------
L9DDA:  lda     $2D                             ; 9DDA A5 2D                    .-
        eor     #$FF                            ; 9DDC 49 FF                    I.
        sta     $2D                             ; 9DDE 85 2D                    .-
L9DE0:  lda     $26                             ; 9DE0 A5 26                    .&
        eor     #$FF                            ; 9DE2 49 FF                    I.
        sta     $26                             ; 9DE4 85 26                    .&
        lda     $27                             ; 9DE6 A5 27                    .'
        eor     #$FF                            ; 9DE8 49 FF                    I.
        sta     $27                             ; 9DEA 85 27                    .'
L9DEC:  lda     $28                             ; 9DEC A5 28                    .(
        eor     #$FF                            ; 9DEE 49 FF                    I.
        sta     $28                             ; 9DF0 85 28                    .(
        lda     $29                             ; 9DF2 A5 29                    .)
        eor     #$FF                            ; 9DF4 49 FF                    I.
        sta     $29                             ; 9DF6 85 29                    .)
        lda     $2A                             ; 9DF8 A5 2A                    .*
        eor     #$FF                            ; 9DFA 49 FF                    I.
        sta     $2A                             ; 9DFC 85 2A                    .*
        lda     $2B                             ; 9DFE A5 2B                    .+
        eor     #$FF                            ; 9E00 49 FF                    I.
        sta     $2B                             ; 9E02 85 2B                    .+
        lda     $2C                             ; 9E04 A5 2C                    .,
        eor     #$FF                            ; 9E06 49 FF                    I.
        sta     $2C                             ; 9E08 85 2C                    .,
        lda     $3A                             ; 9E0A A5 3A                    .:
        eor     #$FF                            ; 9E0C 49 FF                    I.
        sta     $3A                             ; 9E0E 85 3A                    .:
        .byte   $E6                             ; 9E10 E6                       .
L9E11:  dec     a                               ; 9E11 3A                       :
        bne     L9E2E                           ; 9E12 D0 1A                    ..
L9E14:  inc     $2C                             ; 9E14 E6 2C                    .,
        bne     L9E2E                           ; 9E16 D0 16                    ..
        inc     $2B                             ; 9E18 E6 2B                    .+
        bne     L9E2E                           ; 9E1A D0 12                    ..
        inc     $2A                             ; 9E1C E6 2A                    .*
        bne     L9E2E                           ; 9E1E D0 0E                    ..
        inc     $29                             ; 9E20 E6 29                    .)
        bne     L9E2E                           ; 9E22 D0 0A                    ..
        inc     $28                             ; 9E24 E6 28                    .(
        bne     L9E2E                           ; 9E26 D0 06                    ..
        inc     $27                             ; 9E28 E6 27                    .'
        bne     L9E2E                           ; 9E2A D0 02                    ..
        inc     $26                             ; 9E2C E6 26                    .&
L9E2E:  rts                                     ; 9E2E 60                       `
; ----------------------------------------------------------------------------
L9E2F:  ldx     #$0F                            ; 9E2F A2 0F                    ..
        jmp     LFB4B                           ; 9E31 4C 4B FB                 LK.
; ----------------------------------------------------------------------------
L9E34:  ldx     #$0B                            ; 9E34 A2 0B                    ..
L9E36:  ldy     $07,x                           ; 9E36 B4 07                    ..
        sty     $3A                             ; 9E38 84 3A                    .:
        ldy     $06,x                           ; 9E3A B4 06                    ..
        sty     $07,x                           ; 9E3C 94 07                    ..
        ldy     $05,x                           ; 9E3E B4 05                    ..
        .byte   $94                             ; 9E40 94                       .
L9E41:  asl     $B4                             ; 9E41 06 B4                    ..
        tsb     $94                             ; 9E43 04 94                    ..
        ora     $B4                             ; 9E45 05 B4                    ..
        .byte   $03                             ; 9E47 03                       .
        sty     $04,x                           ; 9E48 94 04                    ..
        .byte   $B4                             ; 9E4A B4                       .
L9E4B:  .byte   $02                             ; 9E4B 02                       .
        sty     $03,x                           ; 9E4C 94 03                    ..
        ldy     $01,x                           ; 9E4E B4 01                    ..
        sty     $02,x                           ; 9E50 94 02                    ..
        ldy     $2F                             ; 9E52 A4 2F                    ./
        sty     $01,x                           ; 9E54 94 01                    ..
L9E56:  adc     #$08                            ; 9E56 69 08                    i.
        bmi     L9E36                           ; 9E58 30 DC                    0.
        beq     L9E36                           ; 9E5A F0 DA                    ..
        sbc     #$08                            ; 9E5C E9 08                    ..
        tay                                     ; 9E5E A8                       .
        lda     $3A                             ; 9E5F A5 3A                    .:
        .byte   $B0                             ; 9E61 B0                       .
L9E62:  inc     a                               ; 9E62 1A                       .
L9E63:  asl     $01,x                           ; 9E63 16 01                    ..
        bcc     L9E69                           ; 9E65 90 02                    ..
        inc     $01,x                           ; 9E67 F6 01                    ..
L9E69:  ror     $01,x                           ; 9E69 76 01                    v.
        ror     $01,x                           ; 9E6B 76 01                    v.
L9E6D:  ror     $02,x                           ; 9E6D 76 02                    v.
        ror     $03,x                           ; 9E6F 76 03                    v.
        ror     $04,x                           ; 9E71 76 04                    v.
        ror     $05,x                           ; 9E73 76 05                    v.
        ror     $06,x                           ; 9E75 76 06                    v.
        ror     $07,x                           ; 9E77 76 07                    v.
        ror     a                               ; 9E79 6A                       j
        iny                                     ; 9E7A C8                       .
        bne     L9E63                           ; 9E7B D0 E6                    ..
L9E7D:  clc                                     ; 9E7D 18                       .
        rts                                     ; 9E7E 60                       `
; ----------------------------------------------------------------------------
L9E7F:  sta     ($00,x)                         ; 9E7F 81 00                    ..
        brk                                     ; 9E81 00                       .
        brk                                     ; 9E82 00                       .
        brk                                     ; 9E83 00                       .
        brk                                     ; 9E84 00                       .
        brk                                     ; 9E85 00                       .
        brk                                     ; 9E86 00                       .
L9E87:  php                                     ; 9E87 08                       .
        ror     LCD2D,x                         ; 9E88 7E 2D CD                 ~-.
        stz     $DB                             ; 9E8B 64 DB                    d.
        lda     ($F8,x)                         ; 9E8D A1 F8                    ..
        pla                                     ; 9E8F 68                       h
        ror     LF944,x                         ; 9E90 7E 44 F9                 ~D.
        cld                                     ; 9E93 D8                       .
        ldy     WIN_BTM_RGHT_Y,x                ; 9E94 B4 A6                    ..
        bbr7    $F4,L9F17                       ; 9E96 7F F4 7E                 ..~
        .byte   $63                             ; 9E99 63                       c
        rmb4    $AB                             ; 9E9A 47 AB                    G.
        lsr     $98                             ; 9E9C 46 98                    F.
        .byte   $BB                             ; 9E9E BB                       .
        tsb     $7F                             ; 9E9F 04 7F                    ..
L9EA1:  asl     $4D                             ; 9EA1 06 4D                    .M
        .byte   $42                             ; 9EA3 42                       B
        jmp     L11A0                           ; 9EA4 4C A0 11                 L..
; ----------------------------------------------------------------------------
        ror     $7F                             ; 9EA7 66 7F                    f.
        bit     $25                             ; 9EA9 24 25                    $%
        bit     #$EB                            ; 9EAB 89 EB                    ..
        cpx     #$15                            ; 9EAD E0 15                    ..
        lsr     $7F                             ; 9EAF 46 7F                    F.
        .byte   $53                             ; 9EB1 53                       S
        .byte   $0B                             ; 9EB2 0B                       .
        lda     ($53),y                         ; 9EB3 B1 53                    .S
        dec     $F6,x                           ; 9EB5 D6 F6                    ..
        cpy     $1380                           ; 9EB7 CC 80 13                 ...
        .byte   $BB                             ; 9EBA BB                       .
        .byte   $62                             ; 9EBB 62                       b
        smb0    $7C                             ; 9EBC 87 7C                    .|
        bbs5    $EE,L9E41                       ; 9EBE DF EE 80                 ...
        ror     $38,x                           ; 9EC1 76 38                    v8
        lsr     $D0E1                           ; 9EC3 4E E1 D0                 N..
        bbr1    $E8,L9E4B                       ; 9EC6 1F E8 82                 ...
        sec                                     ; 9EC9 38                       8
        tax                                     ; 9ECA AA                       .
        .byte   $3B                             ; 9ECB 3B                       ;
        and     #$5C                            ; 9ECC 29 5C                    )\
        rmb1    $EE                             ; 9ECE 17 EE                    ..
; ----------------------------------------------------------------------------
L9ED0:  bra     L9F07                           ; 9ED0 80 35                    .5
        tsb     $F3                             ; 9ED2 04 F3                    ..
        .byte   $33                             ; 9ED4 33                       3
        sbc     $68DE,y                         ; 9ED5 F9 DE 68                 ..h
; ----------------------------------------------------------------------------
L9ED8:  sta     ($35,x)                         ; 9ED8 81 35                    .5
        tsb     $F3                             ; 9EDA 04 F3                    ..
        .byte   $33                             ; 9EDC 33                       3
        sbc     $68DE,y                         ; 9EDD F9 DE 68                 ..h
; ----------------------------------------------------------------------------
L9EE0:  bra     L9E62                           ; 9EE0 80 80                    ..
        brk                                     ; 9EE2 00                       .
        brk                                     ; 9EE3 00                       .
        brk                                     ; 9EE4 00                       .
        brk                                     ; 9EE5 00                       .
        brk                                     ; 9EE6 00                       .
        brk                                     ; 9EE7 00                       .
; ----------------------------------------------------------------------------
L9EE8:  bra     L9F1B                           ; 9EE8 80 31                    .1
        adc     ($17)                           ; 9EEA 72 17                    r.
        smb7    $D1                             ; 9EEC F7 D1                    ..
        .byte   $CF                             ; 9EEE CF                       .
        .byte   $7C                             ; 9EEF 7C                       |
; ----------------------------------------------------------------------------
L9EF0:  jsr     LA29A                           ; 9EF0 20 9A A2                  ..
        beq     L9EF7                           ; 9EF3 F0 02                    ..
        bpl     L9EFA                           ; 9EF5 10 03                    ..
L9EF7:  jmp     L9C05                           ; 9EF7 4C 05 9C                 L..
; ----------------------------------------------------------------------------
L9EFB := *+1
L9EFA:  lda     $25
        sbc     #$7f
        pha
        lda     #$80
        sta     $25
        lda     #<L9ED0
        ldy     #>L9ED0
L9F07:  jsr     L9F3C_JSR_INDIRECT_STUFF_AND_JMP_L9CBE
        lda     #<L9ED8
        ldy     #>L9ED8
        jsr     L9F54_JSR_INDIRECT_STUFF_AND_JMP_LA0F9
L9F11:  lda     #<L9E7F
        ldy     #>L9E7F
L9F17 := *+2
        jsr     L9F48_JSR_INDIRECT_STUFF_AND_JMP_L9CA7
L9F18:  lda     #<L9E87
L9F1B := *+1
        ldy     #>L9E87
L9F1D := *+1
L9F1C:  jsr     LA77E_UNKNOWN_OTHER_INDIRECT_STUFF
        lda     #<L9EE0
        ldy     #>L9EE0
        jsr     L9F3C_JSR_INDIRECT_STUFF_AND_JMP_L9CBE
        pla
        jsr     LA421
        lda     #<L9EE8
        ldy     #>L9EE8
L9F2E_PROBABLY_JSR_TO_INDIRECT_STUFF:
L9F30 := *+2
        jsr     L9FF1_INDIRECT_STUFF
L9F31:  bra     L9F63                           ; 9F31 80 30                    .0
L9F33:  jsr     LA06D                           ; 9F33 20 6D A0                  m.
        bra     L9F63                           ; 9F36 80 2B                    .+
L9F38:  lda     #<LA5BF                         ; 9F38 A9 BF                    ..
        ldy     #>LA5BF                         ; 9F3A A0 A5                    ..
L9F3C_JSR_INDIRECT_STUFF_AND_JMP_L9CBE:
        jsr     L9FF1_INDIRECT_STUFF            ; 9F3C 20 F1 9F                  ..
        jmp     L9CBE                           ; 9F3F 4C BE 9C                 L..
; ----------------------------------------------------------------------------
L9F42:  jsr     LA06D                           ; 9F42 20 6D A0                  m.
        jmp     L9CBE                           ; 9F45 4C BE 9C                 L..
; ----------------------------------------------------------------------------
L9F48_JSR_INDIRECT_STUFF_AND_JMP_L9CA7:
        jsr     L9FF1_INDIRECT_STUFF            ; 9F48 20 F1 9F                  ..
        jmp     L9CA7                           ; 9F4B 4C A7 9C                 L..
; ----------------------------------------------------------------------------
L9F4E:  jsr     LA06D                           ; 9F4E 20 6D A0                  m.
        jmp     L9CA7                           ; 9F51 4C A7 9C                 L..
; ----------------------------------------------------------------------------
L9F54_JSR_INDIRECT_STUFF_AND_JMP_LA0F9:
        jsr     L9FF1_INDIRECT_STUFF                           ; 9F54 20 F1 9F                  ..
        jmp     LA0F9                           ; 9F57 4C F9 A0                 L..
; ----------------------------------------------------------------------------
L9F5A:  jsr     LA06D                           ; 9F5A 20 6D A0                  m.
        jmp     LA0F9                           ; 9F5D 4C F9 A0                 L..
; ----------------------------------------------------------------------------
L9F60:  jsr     LA02B                           ; 9F60 20 2B A0                  +.
L9F63:  bne     L9F68                           ; 9F63 D0 03                    ..
        jmp     L9FF0                           ; 9F65 4C F0 9F                 L..
; ----------------------------------------------------------------------------
L9F68:  jsr     LA096                           ; 9F68 20 96 A0                  ..
        lda     #$00                            ; 9F6B A9 00                    ..
        sta     $0C                             ; 9F6D 85 0C                    ..
        sta     $0D                             ; 9F6F 85 0D                    ..
        sta     $0E                             ; 9F71 85 0E                    ..
        sta     $0F                             ; 9F73 85 0F                    ..
        sta     $10                             ; 9F75 85 10                    ..
        sta     $11                             ; 9F77 85 11                    ..
        sta     $12                             ; 9F79 85 12                    ..
        lda     $3A                             ; 9F7B A5 3A                    .:
        jsr     L9FA6                           ; 9F7D 20 A6 9F                  ..
        lda     $2C                             ; 9F80 A5 2C                    .,
        jsr     L9FA6                           ; 9F82 20 A6 9F                  ..
L9F85:  lda     $2B                             ; 9F85 A5 2B                    .+
        jsr     L9FA6                           ; 9F87 20 A6 9F                  ..
        lda     $2A                             ; 9F8A A5 2A                    .*
        jsr     L9FA6                           ; 9F8C 20 A6 9F                  ..
        lda     $29                             ; 9F8F A5 29                    .)
        jsr     L9FA6                           ; 9F91 20 A6 9F                  ..
        lda     $28                             ; 9F94 A5 28                    .(
        jsr     L9FA6                           ; 9F96 20 A6 9F                  ..
        lda     $27                             ; 9F99 A5 27                    .'
        jsr     L9FA6                           ; 9F9B 20 A6 9F                  ..
        lda     $26                             ; 9F9E A5 26                    .&
        jsr     L9FAB                           ; 9FA0 20 AB 9F                  ..
        jmp     LA198                           ; 9FA3 4C 98 A1                 L..
; ----------------------------------------------------------------------------
L9FA6:  bne     L9FAB                           ; 9FA6 D0 03                    ..
        jmp     L9E34                           ; 9FA8 4C 34 9E                 L4.
; ----------------------------------------------------------------------------
L9FAB:  lsr     a                               ; 9FAB 4A                       J
        ora     #$80                            ; 9FAC 09 80                    ..
L9FAE:  tay                                     ; 9FAE A8                       .
        bcc     L9FDC                           ; 9FAF 90 2B                    .+
        clc                                     ; 9FB1 18                       .
        lda     $12                             ; 9FB2 A5 12                    ..
        adc     $37                             ; 9FB4 65 37                    e7
        sta     $12                             ; 9FB6 85 12                    ..
        lda     $11                             ; 9FB8 A5 11                    ..
L9FBA:  adc     $36                             ; 9FBA 65 36                    e6
        sta     $11                             ; 9FBC 85 11                    ..
        lda     $10                             ; 9FBE A5 10                    ..
        adc     $35                             ; 9FC0 65 35                    e5
        sta     $10                             ; 9FC2 85 10                    ..
        lda     $0F                             ; 9FC4 A5 0F                    ..
        adc     $34                             ; 9FC6 65 34                    e4
        sta     $0F                             ; 9FC8 85 0F                    ..
        lda     $0E                             ; 9FCA A5 0E                    ..
        adc     $33                             ; 9FCC 65 33                    e3
        sta     $0E                             ; 9FCE 85 0E                    ..
        lda     $0D                             ; 9FD0 A5 0D                    ..
        adc     $32                             ; 9FD2 65 32                    e2
        sta     $0D                             ; 9FD4 85 0D                    ..
        lda     $0C                             ; 9FD6 A5 0C                    ..
        adc     $31                             ; 9FD8 65 31                    e1
        sta     $0C                             ; 9FDA 85 0C                    ..
L9FDC:  ror     $0C                             ; 9FDC 66 0C                    f.
        ror     $0D                             ; 9FDE 66 0D                    f.
        ror     $0E                             ; 9FE0 66 0E                    f.
        ror     $0F                             ; 9FE2 66 0F                    f.
        ror     $10                             ; 9FE4 66 10                    f.
        ror     $11                             ; 9FE6 66 11                    f.
        ror     $12                             ; 9FE8 66 12                    f.
        ror     $3A                             ; 9FEA 66 3A                    f:
        tya                                     ; 9FEC 98                       .
        lsr     a                               ; 9FED 4A                       J
        bne     L9FAE                           ; 9FEE D0 BE                    ..
L9FF0:  rts                                     ; 9FF0 60                       `
; ----------------------------------------------------------------------------
;Address in A (low byte) Y (high byte)
L9FF1_INDIRECT_STUFF:
        sta     $08                             ; 9FF1 85 08                    ..
        sty     $09                             ; 9FF3 84 09                    ..
        ldy     #$07                            ; 9FF5 A0 07                    ..
        lda     ($08),y                         ; 9FF7 B1 08                    ..
        sta     $37                             ; 9FF9 85 37                    .7
        dey                                     ; 9FFB 88                       .
        lda     ($08),y                         ; 9FFC B1 08                    ..
        sta     $36                             ; 9FFE 85 36                    .6
        dey                                     ; A000 88                       .
        lda     ($08),y                         ; A001 B1 08                    ..
        sta     $35                             ; A003 85 35                    .5
        dey                                     ; A005 88                       .
        lda     ($08),y                         ; A006 B1 08                    ..
        sta     $34                             ; A008 85 34                    .4
        dey                                     ; A00A 88                       .
        lda     ($08),y                         ; A00B B1 08                    ..
        sta     $33                             ; A00D 85 33                    .3
        dey                                     ; A00F 88                       .
        lda     ($08),y                         ; A010 B1 08                    ..
        sta     $32                             ; A012 85 32                    .2
        dey                                     ; A014 88                       .
        lda     ($08),y                         ; A015 B1 08                    ..
        sta     $38                             ; A017 85 38                    .8
        eor     $2D                             ; A019 45 2D                    E-
        sta     $39                             ; A01B 85 39                    .9
        lda     $38                             ; A01D A5 38                    .8
        ora     #$80                            ; A01F 09 80                    ..
        sta     $31                             ; A021 85 31                    .1
        dey                                     ; A023 88                       .
        lda     ($08),y                         ; A024 B1 08                    ..
        sta     $30                             ; A026 85 30                    .0
        lda     $25                             ; A028 A5 25                    .%
        rts                                     ; A02A 60                       `
; ----------------------------------------------------------------------------
LA02B:  sta     $08                             ; A02B 85 08                    ..
        sty     $09                             ; A02D 84 09                    ..
        ldy     #$07                            ; A02F A0 07                    ..
        jsr     L9C36                           ; A031 20 36 9C                  6.
        sta     $37                             ; A034 85 37                    .7
        dey                                     ; A036 88                       .
        jsr     L9C36                           ; A037 20 36 9C                  6.
        sta     $36                             ; A03A 85 36                    .6
        dey                                     ; A03C 88                       .
        jsr     L9C36                           ; A03D 20 36 9C                  6.
        sta     $35                             ; A040 85 35                    .5
        dey                                     ; A042 88                       .
        jsr     L9C36                           ; A043 20 36 9C                  6.
        sta     $34                             ; A046 85 34                    .4
        dey                                     ; A048 88                       .
        jsr     L9C36                           ; A049 20 36 9C                  6.
        sta     $33                             ; A04C 85 33                    .3
        dey                                     ; A04E 88                       .
        jsr     L9C36                           ; A04F 20 36 9C                  6.
        sta     $32                             ; A052 85 32                    .2
        dey                                     ; A054 88                       .
LA055:  jsr     L9C36                           ; A055 20 36 9C                  6.
        sta     $38                             ; A058 85 38                    .8
        eor     $2D                             ; A05A 45 2D                    E-
        sta     $39                             ; A05C 85 39                    .9
        lda     $38                             ; A05E A5 38                    .8
        ora     #$80                            ; A060 09 80                    ..
        sta     $31                             ; A062 85 31                    .1
        dey                                     ; A064 88                       .
LA067 := *+2
        jsr     L9C36
LA068:  sta     $30                             ; A068 85 30                    .0
        lda     $25                             ; A06A A5 25                    .%
        rts                                     ; A06C 60                       `
; ----------------------------------------------------------------------------
LA06D:  sta     $08                             ; A06D 85 08                    ..
        sty     $09                             ; A06F 84 09                    ..
LA072 := *+1
        ldy     #$07
LA073:  jsr     L9C3E                           ; A073 20 3E 9C                  >.
        sta     $30,y                           ; A076 99 30 00                 .0.
        dey                                     ; A079 88                       .
        cpy     #$02                            ; A07A C0 02                    ..
        bcs     LA073                           ; A07C B0 F5                    ..
        jsr     L9C3E                           ; A07E 20 3E 9C                  >.
        sta     $38                             ; A081 85 38                    .8
        eor     $2D                             ; A083 45 2D                    E-
        sta     $39                             ; A085 85 39                    .9
        lda     $38                             ; A087 A5 38                    .8
        ora     #$80                            ; A089 09 80                    ..
        sta     $31                             ; A08B 85 31                    .1
        dey                                     ; A08D 88                       .
        jsr     L9C3E                           ; A08E 20 3E 9C                  >.
        sta     $30                             ; A091 85 30                    .0
        lda     $25                             ; A093 A5 25                    .%
        rts                                     ; A095 60                       `
; ----------------------------------------------------------------------------
LA096:  lda     $30                             ; A096 A5 30                    .0
LA098:  beq     LA0B9                           ; A098 F0 1F                    ..
        clc                                     ; A09A 18                       .
        adc     $25                             ; A09B 65 25                    e%
        bcc     LA0A3                           ; A09D 90 04                    ..
        bmi     LA0BE                           ; A09F 30 1D                    0.
        clc                                     ; A0A1 18                       .
        .byte   $2C                             ; A0A2 2C                       ,
LA0A3:  bpl     LA0B9                           ; A0A3 10 14                    ..
        adc     #$80                            ; A0A5 69 80                    i.
        sta     $25                             ; A0A7 85 25                    .%
        bne     LA0AE                           ; A0A9 D0 03                    ..
        jmp     L9D70                           ; A0AB 4C 70 9D                 Lp.
; ----------------------------------------------------------------------------
LA0AE:  lda     $39                             ; A0AE A5 39                    .9
        sta     $2D                             ; A0B0 85 2D                    .-
        rts                                     ; A0B2 60                       `
; ----------------------------------------------------------------------------
LA0B3:  lda     $2D                             ; A0B3 A5 2D                    .-
        eor     #$FF                            ; A0B5 49 FF                    I.
        bmi     LA0BE                           ; A0B7 30 05                    0.
LA0B9:  pla                                     ; A0B9 68                       h
        pla                                     ; A0BA 68                       h
        jmp     L9D6C                           ; A0BB 4C 6C 9D                 Ll.
; ----------------------------------------------------------------------------
LA0BE:  jmp     L9E2F                           ; A0BE 4C 2F 9E                 L/.
; ----------------------------------------------------------------------------
LA0C1:  jsr     LA27B                           ; A0C1 20 7B A2                  {.
        tax                                     ; A0C4 AA                       .
        beq     LA0D7                           ; A0C5 F0 10                    ..
        clc                                     ; A0C7 18                       .
        adc     #$02                            ; A0C8 69 02                    i.
        bcs     LA0BE                           ; A0CA B0 F2                    ..
        ldx     #$00                            ; A0CC A2 00                    ..
        stx     $39                             ; A0CE 86 39                    .9
        jsr     L9CCB                           ; A0D0 20 CB 9C                  ..
        inc     $25                             ; A0D3 E6 25                    .%
        beq     LA0BE                           ; A0D5 F0 E7                    ..
LA0D7:  rts                                     ; A0D7 60                       `
; ----------------------------------------------------------------------------
LA0D8:  sty     $20                             ; A0D8 84 20                    .
        brk                                     ; A0DA 00                       .
        brk                                     ; A0DB 00                       .
        brk                                     ; A0DC 00                       .
        brk                                     ; A0DD 00                       .
        brk                                     ; A0DE 00                       .
        brk                                     ; A0DF 00                       .
LA0E0:  ldx     #$14                            ; A0E0 A2 14                    ..
        jmp     LFB4B                           ; A0E2 4C 4B FB                 LK.
; ----------------------------------------------------------------------------
LA0E6 := *+1
LA0E5:  jsr     LA27B
        lda     #<LA0D8
        ldy     #>LA0D8                         ; A0EA A0 A0                    ..
        ldx     #$00                            ; A0EC A2 00                    ..
LA0EE:  stx     $39                             ; A0EE 86 39                    .9
        jsr     LA1DD_INDIRECT_STUFF_LOAD       ; A0F0 20 DD A1                  ..
        jmp     LA0F9                           ; A0F3 4C F9 A0                 L..
; ----------------------------------------------------------------------------
LA0F6:  jsr     LA02B                           ; A0F6 20 2B A0                  +.
LA0F9:  beq     LA0E0                           ; A0F9 F0 E5                    ..
        jsr     LA28A                           ; A0FB 20 8A A2                  ..
        lda     #$00                            ; A0FE A9 00                    ..
        sec                                     ; A100 38                       8
        sbc     $25                             ; A101 E5 25                    .%
        sta     $25                             ; A103 85 25                    .%
        jsr     LA096
LA107 := *-1
        inc     $25
        BEQ     LA0BE
        LDX     #$f9
        LDA     #$01
LA110:  ldy     $31                             ; A110 A4 31                    .1
        cpy     $26                             ; A112 C4 26                    .&
        bne     LA138                           ; A114 D0 22                    ."
        ldy     $32                             ; A116 A4 32                    .2
        cpy     $27                             ; A118 C4 27                    .'
        bne     LA138                           ; A11A D0 1C                    ..
        ldy     $33                             ; A11C A4 33                    .3
        cpy     $28                             ; A11E C4 28                    .(
        bne     LA138                           ; A120 D0 16                    ..
        ldy     $34                             ; A122 A4 34                    .4
        cpy     $29                             ; A124 C4 29                    .)
        bne     LA138                           ; A126 D0 10                    ..
        ldy     $35                             ; A128 A4 35                    .5
        cpy     $2A                             ; A12A C4 2A                    .*
        bne     LA138                           ; A12C D0 0A                    ..
        ldy     $36                             ; A12E A4 36                    .6
        cpy     $2B                             ; A130 C4 2B                    .+
        bne     LA138                           ; A132 D0 04                    ..
        ldy     $37                             ; A134 A4 37                    .7
        cpy     $2C                             ; A136 C4 2C                    .,
LA138:  php                                     ; A138 08                       .
        rol     a                               ; A139 2A                       *
        bcc     LA145                           ; A13A 90 09                    ..
        inx                                     ; A13C E8                       .
        sta     $12,x                           ; A13D 95 12                    ..
        beq     LA18B                           ; A13F F0 4A                    .J
        bpl     LA18F                           ; A141 10 4C                    .L
        lda     #$01                            ; A143 A9 01                    ..
LA145:  plp                                     ; A145 28                       (
        bcs     LA15C                           ; A146 B0 14                    ..
LA148:  asl     $37                             ; A148 06 37                    .7
LA14A:  rol     $36                             ; A14A 26 36                    &6
        rol     $35                             ; A14C 26 35                    &5
        rol     $34                             ; A14E 26 34                    &4
        rol     $33                             ; A150 26 33                    &3
        rol     $32                             ; A152 26 32                    &2
        rol     $31                             ; A154 26 31                    &1
        bcs     LA138                           ; A156 B0 E0                    ..
        bmi     LA110                           ; A158 30 B6                    0.
        bpl     LA138                           ; A15A 10 DC                    ..
LA15C:  tay                                     ; A15C A8                       .
        lda     $37                             ; A15D A5 37                    .7
        sbc     $2C                             ; A15F E5 2C                    .,
        sta     $37                             ; A161 85 37                    .7
        lda     $36                             ; A163 A5 36                    .6
        sbc     $2B                             ; A165 E5 2B                    .+
        sta     $36                             ; A167 85 36                    .6
        lda     $35                             ; A169 A5 35                    .5
        sbc     $2A                             ; A16B E5 2A                    .*
        sta     $35                             ; A16D 85 35                    .5
        lda     $34                             ; A16F A5 34                    .4
        sbc     $29                             ; A171 E5 29                    .)
        sta     $34                             ; A173 85 34                    .4
LA176 := *+1
        lda     $33
        sbc     $28                             ; A177 E5 28                    .(
        sta     $33                             ; A179 85 33                    .3
        lda     $32                             ; A17B A5 32                    .2
        sbc     $27                             ; A17D E5 27                    .'
        sta     $32                             ; A17F 85 32                    .2
        lda     $31                             ; A181 A5 31                    .1
        sbc     $26                             ; A183 E5 26                    .&
        sta     $31                             ; A185 85 31                    .1
        tya                                     ; A187 98                       .
        jmp     LA148                           ; A188 4C 48 A1                 LH.
; ----------------------------------------------------------------------------
LA18B:  lda     #$40                            ; A18B A9 40                    .@
        bne     LA145                           ; A18D D0 B6                    ..
LA18F:  asl     a                               ; A18F 0A                       .
        asl     a                               ; A190 0A                       .
        asl     a                               ; A191 0A                       .
        asl     a                               ; A192 0A                       .
        asl     a                               ; A193 0A                       .
        asl     a                               ; A194 0A                       .
        sta     $3A                             ; A195 85 3A                    .:
        plp                                     ; A197 28                       (
LA198:  lda     $0C                             ; A198 A5 0C                    ..
        sta     $26                             ; A19A 85 26                    .&
        lda     $0D                             ; A19C A5 0D                    ..
        sta     $27                             ; A19E 85 27                    .'
        lda     $0E                             ; A1A0 A5 0E                    ..
        sta     $28                             ; A1A2 85 28                    .(
        lda     $0F                             ; A1A4 A5 0F                    ..
        sta     $29                             ; A1A6 85 29                    .)
        lda     $10                             ; A1A8 A5 10                    ..
        sta     $2A                             ; A1AA 85 2A                    .*
        lda     $11                             ; A1AC A5 11                    ..
        sta     $2B                             ; A1AE 85 2B                    .+
        lda     $12                             ; A1B0 A5 12                    ..
        sta     $2C                             ; A1B2 85 2C                    .,
        jmp     L9D40                           ; A1B4 4C 40 9D                 L@.
; ----------------------------------------------------------------------------
LA1B7:  sec                                     ; A1B7 38                       8
        sta     $08                             ; A1B8 85 08                    ..
        sty     $09                             ; A1BA 84 09                    ..
        ldy     #$07                            ; A1BC A0 07                    ..
LA1BE:  jsr     L9C3E                           ; A1BE 20 3E 9C                  >.
        sta     $25,y                           ; A1C1 99 25 00                 .%.
        dey                                     ; A1C4 88                       .
        cpy     #$02                            ; A1C5 C0 02                    ..
        bcs     LA1BE                           ; A1C7 B0 F5                    ..
        jsr     L9C3E                           ; A1C9 20 3E 9C                  >.
        sta     $2D                             ; A1CC 85 2D                    .-
        ora     #$80                            ; A1CE 09 80                    ..
        sta     $26                             ; A1D0 85 26                    .&
        dey                                     ; A1D2 88                       .
        jsr     L9C3E                           ; A1D3 20 3E 9C                  >.
        sta     $25                             ; A1D6 85 25                    .%
        sty     $3A                             ; A1D8 84 3A                    .:
        rts                                     ; A1DA 60                       `
; ----------------------------------------------------------------------------
LA1DB:  clc                                     ; A1DB 18                       .
        .byte   $24 ;skip next byte (sec)       ; A1DC 24                       $
LA1DD_INDIRECT_STUFF_LOAD:
        sec                                     ; A1DD 38                       8
        sta     $08                             ; A1DE 85 08                    ..
        sty     $09                             ; A1E0 84 09                    ..
        ldy     #$07                            ; A1E2 A0 07                    ..
        jsr     LA331_LOAD_INDIRECT_FROM_08_JMP_L9C36                           ; A1E4 20 31 A3                  1.
        sta     $2C                             ; A1E7 85 2C                    .,
        dey                                     ; A1E9 88                       .
        jsr     LA331_LOAD_INDIRECT_FROM_08_JMP_L9C36                           ; A1EA 20 31 A3                  1.
        sta     $2B                             ; A1ED 85 2B                    .+
        dey                                     ; A1EF 88                       .
        jsr     LA331_LOAD_INDIRECT_FROM_08_JMP_L9C36                           ; A1F0 20 31 A3                  1.
        sta     $2A                             ; A1F3 85 2A                    .*
        dey                                     ; A1F5 88                       .
        jsr     LA331_LOAD_INDIRECT_FROM_08_JMP_L9C36                           ; A1F6 20 31 A3                  1.
        sta     $29                             ; A1F9 85 29                    .)
        dey                                     ; A1FB 88                       .
        jsr     LA331_LOAD_INDIRECT_FROM_08_JMP_L9C36                           ; A1FC 20 31 A3                  1.
        sta     $28                             ; A1FF 85 28                    .(
        dey                                     ; A201 88                       .
        jsr     LA331_LOAD_INDIRECT_FROM_08_JMP_L9C36                           ; A202 20 31 A3                  1.
        sta     $27                             ; A205 85 27                    .'
        dey                                     ; A207 88                       .
        jsr     LA331_LOAD_INDIRECT_FROM_08_JMP_L9C36                           ; A208 20 31 A3                  1.
        sta     $2D                             ; A20B 85 2D                    .-
        ora     #$80                            ; A20D 09 80                    ..
        sta     $26                             ; A20F 85 26                    .&
        dey                                     ; A211 88                       .
        jsr     LA331_LOAD_INDIRECT_FROM_08_JMP_L9C36                           ; A212 20 31 A3                  1.
        sta     $25                             ; A215 85 25                    .%
        sty     $3A                             ; A217 84 3A                    .:
        rts                                     ; A219 60                       `
; ----------------------------------------------------------------------------
LA21A:  tax                                     ; A21A AA                       .
        bra     LA227                           ; A21B 80 0A                    ..
LA21D:  ldx     #$1D                            ; A21D A2 1D                    ..
        .byte   $2C                             ; A21F 2C                       ,
LA220:  ldx     #$15                            ; A220 A2 15                    ..
        .byte   $A0                             ; A222 A0                       .
LA223:  brk                                     ; A223 00                       .
        beq     LA227                           ; A224 F0 01                    ..
LA226:  tax                                     ; A226 AA                       .
LA227:  jsr     LA28A                           ; A227 20 8A A2                  ..
        stx     $08                             ; A22A 86 08                    ..
        sty     $09                             ; A22C 84 09                    ..
        ldy     #$07                            ; A22E A0 07                    ..
        lda     #$08                            ; A230 A9 08                    ..
        sta     $0360                           ; A232 8D 60 03                 .`.
        lda     $2C                             ; A235 A5 2C                    .,
        jsr     GO_RAM_STORE_GO_KERN            ; A237 20 5C 03                  \.
        dey                                     ; A23A 88                       .
        lda     $2B                             ; A23B A5 2B                    .+
        jsr     GO_RAM_STORE_GO_KERN            ; A23D 20 5C 03                  \.
        dey                                     ; A240 88                       .
        lda     $2A                             ; A241 A5 2A                    .*
        jsr     GO_RAM_STORE_GO_KERN            ; A243 20 5C 03                  \.
        dey                                     ; A246 88                       .
        lda     $29                             ; A247 A5 29                    .)
        jsr     GO_RAM_STORE_GO_KERN            ; A249 20 5C 03                  \.
        dey                                     ; A24C 88                       .
        lda     $28                             ; A24D A5 28                    .(
        jsr     GO_RAM_STORE_GO_KERN            ; A24F 20 5C 03                  \.
        dey                                     ; A252 88                       .
        lda     $27                             ; A253 A5 27                    .'
        jsr     GO_RAM_STORE_GO_KERN            ; A255 20 5C 03                  \.
        dey                                     ; A258 88                       .
        lda     $2D                             ; A259 A5 2D                    .-
        ora     #$7F                            ; A25B 09 7F                    ..
        and     $26                             ; A25D 25 26                    %&
        jsr     GO_RAM_STORE_GO_KERN            ; A25F 20 5C 03                  \.
        dey                                     ; A262 88                       .
        lda     $25                             ; A263 A5 25                    .%
        jsr     GO_RAM_STORE_GO_KERN            ; A265 20 5C 03                  \.
        sty     $3A                             ; A268 84 3A                    .:
        rts                                     ; A26A 60                       `
; ----------------------------------------------------------------------------
LA26B:  lda     $38                             ; A26B A5 38                    .8
LA26D:  sta     $2D                             ; A26D 85 2D                    .-
        ldx     #$08                            ; A26F A2 08                    ..
LA271:  lda     $2F,x                           ; A271 B5 2F                    ./
        sta     $24,x                           ; A273 95 24                    .$
        dex                                     ; A275 CA                       .
        bne     LA271                           ; A276 D0 F9                    ..
        stx     $3A                             ; A278 86 3A                    .:
        rts                                     ; A27A 60                       `
; ----------------------------------------------------------------------------
LA27B:  jsr     LA28A                           ; A27B 20 8A A2                  ..
LA27E:  ldx     #$09                            ; A27E A2 09                    ..
LA280:  lda     $24,x                           ; A280 B5 24                    .$
        sta     $2F,x                           ; A282 95 2F                    ./
        dex                                     ; A284 CA                       .
        bne     LA280                           ; A285 D0 F9                    ..
        stx     $3A                             ; A287 86 3A                    .:
LA289:  rts                                     ; A289 60                       `
; ----------------------------------------------------------------------------
LA28A:  lda     $25                             ; A28A A5 25                    .%
        beq     LA289                           ; A28C F0 FB                    ..
        asl     $3A                             ; A28E 06 3A                    .:
        bcc     LA289                           ; A290 90 F7                    ..
LA292:  jsr     L9E14                           ; A292 20 14 9E                  ..
        bne     LA289                           ; A295 D0 F2                    ..
        jmp     L9DC5                           ; A297 4C C5 9D                 L..
; ----------------------------------------------------------------------------
LA29A:  lda     $25                             ; A29A A5 25                    .%
        beq     LA2A7                           ; A29C F0 09                    ..
LA29E:  lda     $2D                             ; A29E A5 2D                    .-
LA2A0:  rol     a                               ; A2A0 2A                       *
        lda     #$FF                            ; A2A1 A9 FF                    ..
        bcs     LA2A7                           ; A2A3 B0 02                    ..
        lda     #$01                            ; A2A5 A9 01                    ..
LA2A7:  rts                                     ; A2A7 60                       `
; ----------------------------------------------------------------------------
LA2A8:  jsr     LA29A                           ; A2A8 20 9A A2                  ..
LA2AB:  sta     $26                             ; A2AB 85 26                    .&
        lda     #$00                            ; A2AD A9 00                    ..
        sta     $27                             ; A2AF 85 27                    .'
        ldx     #$88                            ; A2B1 A2 88                    ..
LA2B3:  lda     $26                             ; A2B3 A5 26                    .&
        eor     #$FF                            ; A2B5 49 FF                    I.
        rol     a                               ; A2B7 2A                       *
LA2B8:  lda     #$00                            ; A2B8 A9 00                    ..
        sta     $2C                             ; A2BA 85 2C                    .,
        sta     $2B                             ; A2BC 85 2B                    .+
        sta     $2A                             ; A2BE 85 2A                    .*
        sta     $29                             ; A2C0 85 29                    .)
        sta     $28                             ; A2C2 85 28                    .(
LA2C4:  stx     $25                             ; A2C4 86 25                    .%
        sta     $3A                             ; A2C6 85 3A                    .:
        sta     $2D                             ; A2C8 85 2D                    .-
        .byte   $4C                             ; A2CA 4C                       L
LA2CB:  .byte   $3B                             ; A2CB 3B                       ;
LA2CD = *+1 ;todo this is code; entry in table
        sta     $FA5A,x                         ; A2CC 9D 5A FA                 .Z.
        bra     LA2C4                           ; A2CF 80 F3                    ..
LA2D1:  phy                                     ; A2D1 5A                       Z
        plx                                     ; A2D2 FA                       .
        bra     LA2B8                           ; A2D3 80 E3                    ..
LA2D5:  phy                                     ; A2D5 5A                       Z
        plx                                     ; A2D6 FA                       .
        bra     LA2B3                           ; A2D7 80 DA                    ..
LA2D9:  lsr     $2D                             ; A2D9 46 2D                    F-
        rts                                     ; A2DB 60                       `
; ----------------------------------------------------------------------------
LA2DC_UNKNOWN_INDIRECT_STUFF_LOAD:
        sta     $0A                             ; A2DC 85 0A                    ..
        sty     $0B                             ; A2DE 84 0B                    ..
        ldy     #$00                            ; A2E0 A0 00                    ..
        lda     ($0A),y                         ; A2E2 B1 0A                    ..
        iny                                     ; A2E4 C8                       .
        tax                                     ; A2E5 AA                       .
        beq     LA29A                           ; A2E6 F0 B2                    ..
        lda     ($0A),y                         ; A2E8 B1 0A                    ..
        eor     $2D                             ; A2EA 45 2D                    E-
        bmi     LA29E                           ; A2EC 30 B0                    0.
        cpx     $25                             ; A2EE E4 25                    .%
        bne     LA328                           ; A2F0 D0 36                    .6
        lda     ($0A),y                         ; A2F2 B1 0A                    ..
        ora     #$80                            ; A2F4 09 80                    ..
        cmp     $26                             ; A2F6 C5 26                    .&
        bne     LA328                           ; A2F8 D0 2E                    ..
        iny                                     ; A2FA C8                       .
        lda     ($0A),y                         ; A2FB B1 0A                    ..
        cmp     $27                             ; A2FD C5 27                    .'
        bne     LA328                           ; A2FF D0 27                    .'
        iny                                     ; A301 C8                       .
        lda     ($0A),y                         ; A302 B1 0A                    ..
        cmp     $28                             ; A304 C5 28                    .(
        bne     LA328                           ; A306 D0 20                    .
        iny                                     ; A308 C8                       .
        lda     ($0A),y                         ; A309 B1 0A                    ..
        cmp     $29                             ; A30B C5 29                    .)
        bne     LA328                           ; A30D D0 19                    ..
        iny                                     ; A30F C8                       .
        lda     ($0A),y                         ; A310 B1 0A                    ..
        cmp     $2A                             ; A312 C5 2A                    .*
        bne     LA328                           ; A314 D0 12                    ..
        iny                                     ; A316 C8                       .
        lda     ($0A),y                         ; A317 B1 0A                    ..
        cmp     $2B                             ; A319 C5 2B                    .+
        bne     LA328                           ; A31B D0 0B                    ..
        iny                                     ; A31D C8                       .
        lda     #$7F                            ; A31E A9 7F                    ..
        cmp     $3A                             ; A320 C5 3A                    .:
        lda     ($0A),y                         ; A322 B1 0A                    ..
        sbc     $2C                             ; A324 E5 2C                    .,
        beq     LA357                           ; A326 F0 2F                    ./
LA328:  lda     $2D                             ; A328 A5 2D                    .-
        bcc     LA32E                           ; A32A 90 02                    ..
        eor     #$FF                            ; A32C 49 FF                    I.
LA32E:  jmp     LA2A0                           ; A32E 4C A0 A2                 L..
; ----------------------------------------------------------------------------
LA331_LOAD_INDIRECT_FROM_08_JMP_L9C36:
        lda     ($08),y                         ; A331 B1 08                    ..
        bcs     LA357                           ; A333 B0 22                    ."
        jmp     L9C36                           ; A335 4C 36 9C                 L6.
; ----------------------------------------------------------------------------
LA338:  lda     $25                             ; A338 A5 25                    .%
        beq     LA386                           ; A33A F0 4A                    .J
        sec                                     ; A33C 38                       8
        sbc     #$B8                            ; A33D E9 B8                    ..
        bit     $2D                             ; A33F 24 2D                    $-
        bpl     LA34C                           ; A341 10 09                    ..
        tax                                     ; A343 AA                       .
        lda     #$FF                            ; A344 A9 FF                    ..
        sta     $2F                             ; A346 85 2F                    ./
        jsr     L9DE0                           ; A348 20 E0 9D                  ..
        txa                                     ; A34B 8A                       .
LA34C:  ldx     #$25                            ; A34C A2 25                    .%
        cmp     #$F9                            ; A34E C9 F9                    ..
        bpl     LA358                           ; A350 10 06                    ..
        jsr     L9E56                           ; A352 20 56 9E                  V.
        sty     $2F                             ; A355 84 2F                    ./
LA357:  rts                                     ; A357 60                       `
; ----------------------------------------------------------------------------
LA358:  tay                                     ; A358 A8                       .
        lda     $2D                             ; A359 A5 2D                    .-
        and     #$80                            ; A35B 29 80                    ).
        lsr     $26                             ; A35D 46 26                    F&
        ora     $26                             ; A35F 05 26                    .&
        sta     $26                             ; A361 85 26                    .&
        jsr     L9E6D                           ; A363 20 6D 9E                  m.
        sty     $2F                             ; A366 84 2F                    ./
        rts                                     ; A368 60                       `
; ----------------------------------------------------------------------------
LA369:  lda     $25                             ; A369 A5 25                    .%
        cmp     #$B8                            ; A36B C9 B8                    ..
        bcs     LA395                           ; A36D B0 26                    .&
        jsr     LA338                           ; A36F 20 38 A3                  8.
        .byte   $84                             ; A372 84                       .
LA373:  dec     a                               ; A373 3A                       :
        lda     $2D                             ; A374 A5 2D                    .-
        sty     $2D                             ; A376 84 2D                    .-
        eor     #$80                            ; A378 49 80                    I.
        rol     a                               ; A37A 2A                       *
        lda     #$B8                            ; A37B A9 B8                    ..
        sta     $25                             ; A37D 85 25                    .%
        lda     $2C                             ; A37F A5 2C                    .,
        sta     $00                             ; A381 85 00                    ..
        jmp     L9D3B                           ; A383 4C 3B 9D                 L;.
; ----------------------------------------------------------------------------
LA386:  sta     $26                             ; A386 85 26                    .&
        sta     $27                             ; A388 85 27                    .'
        sta     $28                             ; A38A 85 28                    .(
        sta     $29                             ; A38C 85 29                    .)
        .byte   $85                             ; A38E 85                       .
LA38F:  rol     a                               ; A38F 2A                       *
        sta     $2B                             ; A390 85 2B                    .+
        sta     $2C                             ; A392 85 2C                    .,
        tay                                     ; A394 A8                       .
LA395:  rts                                     ; A395 60                       `
; ----------------------------------------------------------------------------
LA396:  ldy     #$00                            ; A396 A0 00                    ..
LA398:  ldx     #$0D                            ; A398 A2 0D                    ..
LA39A:  sty     $21,x                           ; A39A 94 21                    .!
        dex                                     ; A39C CA                       .
        bpl     LA39A                           ; A39D 10 FB                    ..
        bcc     LA3B0                           ; A39F 90 0F                    ..
        cmp     #$2D                            ; A3A1 C9 2D                    .-
        bne     LA3A9                           ; A3A3 D0 04                    ..
        stx     $2E                             ; A3A5 86 2E                    ..
        beq     LA3AD                           ; A3A7 F0 04                    ..
LA3A9:  cmp     #$2B                            ; A3A9 C9 2B                    .+
        bne     LA3B2                           ; A3AB D0 05                    ..
LA3AD:  jsr     L9C0D                           ; A3AD 20 0D 9C                  ..
LA3B0:  bcc     LA40D                           ; A3B0 90 5B                    .[
LA3B2:  cmp     #$2E                            ; A3B2 C9 2E                    ..
        beq     LA3E4                           ; A3B4 F0 2E                    ..
        cmp     #$45                            ; A3B6 C9 45                    .E
        bne     LA3EA                           ; A3B8 D0 30                    .0
        jsr     L9C0D                           ; A3BA 20 0D 9C                  ..
        bcc     LA3D6                           ; A3BD 90 17                    ..
        cmp     #$AB                            ; A3BF C9 AB                    ..
LA3C1:  beq     LA3D1                           ; A3C1 F0 0E                    ..
        cmp     #$2D                            ; A3C3 C9 2D                    .-
        beq     LA3D1                           ; A3C5 F0 0A                    ..
        cmp     #$AA                            ; A3C7 C9 AA                    ..
        beq     LA3D3                           ; A3C9 F0 08                    ..
        cmp     #$2B                            ; A3CB C9 2B                    .+
        beq     LA3D3                           ; A3CD F0 04                    ..
LA3CF:  bne     LA3D8                           ; A3CF D0 07                    ..
LA3D1:  ror     $24                             ; A3D1 66 24                    f$
LA3D3:  jsr     L9C0D                           ; A3D3 20 0D 9C                  ..
LA3D6:  bcc     LA434                           ; A3D6 90 5C                    .\
LA3D8:  bit     $24                             ; A3D8 24 24                    $$
        bpl     LA3EA                           ; A3DA 10 0E                    ..
        lda     #$00                            ; A3DC A9 00                    ..
        sec                                     ; A3DE 38                       8
        sbc     $22                             ; A3DF E5 22                    ."
        jmp     LA3EC                           ; A3E1 4C EC A3                 L..
; ----------------------------------------------------------------------------
LA3E4:  ror     $23                             ; A3E4 66 23                    f#
        bit     $23                             ; A3E6 24 23                    $#
        bvc     LA3AD                           ; A3E8 50 C3                    P.
LA3EA:  lda     $22                             ; A3EA A5 22                    ."
LA3EC:  sec                                     ; A3EC 38                       8
        sbc     $21                             ; A3ED E5 21                    .!
        sta     $22                             ; A3EF 85 22                    ."
        beq     LA405                           ; A3F1 F0 12                    ..
        bpl     LA3FE                           ; A3F3 10 09                    ..
LA3F5:  jsr     LA0E5                           ; A3F5 20 E5 A0                  ..
        inc     $22                             ; A3F8 E6 22                    ."
        bne     LA3F5                           ; A3FA D0 F9                    ..
        beq     LA405                           ; A3FC F0 07                    ..
LA3FE:  jsr     LA0C1                           ; A3FE 20 C1 A0                  ..
        dec     $22                             ; A401 C6 22                    ."
        bne     LA3FE                           ; A403 D0 F9                    ..
LA405:  lda     $2E                             ; A405 A5 2E                    ..
        bmi     LA40A                           ; A407 30 01                    0.
        rts                                     ; A409 60                       `
; ----------------------------------------------------------------------------
LA40A:  jmp     LA6A7                           ; A40A 4C A7 A6                 L..
; ----------------------------------------------------------------------------
LA40D:  pha                                     ; A40D 48                       H
LA40E:  bit     $23                             ; A40E 24 23                    $#
        bpl     LA414                           ; A410 10 02                    ..
        inc     $21                             ; A412 E6 21                    .!
LA414:  jsr     LA0C1                           ; A414 20 C1 A0                  ..
        pla                                     ; A417 68                       h
        sec                                     ; A418 38                       8
        sbc     #$30                            ; A419 E9 30                    .0
        jsr     LA421                           ; A41B 20 21 A4                  !.
        jmp     LA3AD                           ; A41E 4C AD A3                 L..
; ----------------------------------------------------------------------------
LA421:  pha                                     ; A421 48                       H
        jsr     LA27B                           ; A422 20 7B A2                  {.
        pla                                     ; A425 68                       h
        jsr     LA2AB                           ; A426 20 AB A2                  ..
        lda     $38                             ; A429 A5 38                    .8
        eor     $2D                             ; A42B 45 2D                    E-
        sta     $39                             ; A42D 85 39                    .9
        ldx     $25                             ; A42F A6 25                    .%
        jmp     L9CBE                           ; A431 4C BE 9C                 L..
; ----------------------------------------------------------------------------
LA434:  lda     $22                             ; A434 A5 22                    ."
        cmp     #$0A                            ; A436 C9 0A                    ..
        bcc     LA443                           ; A438 90 09                    ..
        lda     #$64                            ; A43A A9 64                    .d
        bit     $24                             ; A43C 24 24                    $$
        bmi     LA456                           ; A43E 30 16                    0.
        jmp     L9E2F                           ; A440 4C 2F 9E                 L/.
; ----------------------------------------------------------------------------
LA443:  asl     a                               ; A443 0A                       .
        asl     a                               ; A444 0A                       .
        clc                                     ; A445 18                       .
        adc     $22                             ; A446 65 22                    e"
        asl     a                               ; A448 0A                       .
        clc                                     ; A449 18                       .
        ldy     #$00                            ; A44A A0 00                    ..
        sta     $22                             ; A44C 85 22                    ."
        jsr     L9C2E                           ; A44E 20 2E 9C                  ..
        .byte   $65                             ; A451 65                       e
LA452:  .byte   $22                             ; A452 22                       "
        sec                                     ; A453 38                       8
        sbc     #$30                            ; A454 E9 30                    .0
LA456:  sta     $22                             ; A456 85 22                    ."
        jmp     LA3D3                           ; A458 4C D3 A3                 L..
; ----------------------------------------------------------------------------
LA45B:  .byte   $AF,$35,$E6,$20,$F4,$7F,$FF,$CC ; A45B AF 35 E6 20 F4 7F FF CC  .5. ....
LA463:  .byte   $B2,$63,$5F,$A9,$31,$9F,$FF,$E8 ; A463 B2 63 5F A9 31 9F FF E8  .c_.1...
LA46B:  .byte   $B2,$63,$5F,$A9,$31,$9F,$FF,$FC ; A46B B2 63 5F A9 31 9F FF FC  .c_.1...
; ----------------------------------------------------------------------------
LA473:  ldy     #$01
LA475:  lda     #$20
        bit     $2d
        bpl     $a47d
        lda     #$2d
        sta     $00ff,Y
        sta     $2d
        sty     $3b
        iny
        lda     #$30
        ldx     $25
        bne     LA48E
; ----------------------------------------------------------------------------
LA48B:  jmp     LA5B2                           ; A48B 4C B2 A5                 L..
; ----------------------------------------------------------------------------
LA48E:  lda     #$00                            ; A48E A9 00                    ..
        cpx     #$80                            ; A490 E0 80                    ..
        beq     LA496                           ; A492 F0 02                    ..
        bcs     LA49F                           ; A494 B0 09                    ..
LA496:  lda     #<LA46B                         ; A496 A9 6B                    .k
        ldy     #>LA46B                         ; A498 A0 A4                    ..
        jsr     L9F2E_PROBABLY_JSR_TO_INDIRECT_STUFF ; A49A 20 2E 9F                  ..
        lda     #$F1                            ; A49D A9 F1                    ..
LA49F:  sta     $21                             ; A49F 85 21                    .!
LA4A1:  lda     #<LA463                         ; A4A1 A9 63                    .c
        ldy     #>LA463                         ; A4A3 A0 A4                    ..
        jsr     LA2DC_UNKNOWN_INDIRECT_STUFF_LOAD ; A4A5 20 DC A2                  ..
        beq     LA4C8                           ; A4A8 F0 1E                    ..
        bpl     LA4BE                           ; A4AA 10 12                    ..
LA4AC:  lda     #<LA45B                         ; A4AC A9 5B                    .[
        ldy     #>LA45B                         ; A4AE A0 A4                    ..
        jsr     LA2DC_UNKNOWN_INDIRECT_STUFF_LOAD ; A4B0 20 DC A2                  ..
LA4B3:  beq     LA4B7                           ; A4B3 F0 02                    ..
        bpl     LA4C5                           ; A4B5 10 0E                    ..
LA4B7:  jsr     LA0C1                           ; A4B7 20 C1 A0                  ..
        dec     $21                             ; A4BA C6 21                    .!
        bne     LA4AC                           ; A4BC D0 EE                    ..
LA4BE:  jsr     LA0E5                           ; A4BE 20 E5 A0                  ..
        inc     $21                             ; A4C1 E6 21                    .!
        bne     LA4A1                           ; A4C3 D0 DC                    ..
LA4C5:  jsr     L9F38                           ; A4C5 20 38 9F                  8.
LA4C8:  jsr     LA338                           ; A4C8 20 38 A3                  8.
        ldx     #$01                            ; A4CB A2 01                    ..
        .byte   $A5                             ; A4CD A5                       .
LA4CE:  and     ($18,x)                         ; A4CE 21 18                    !.
        adc     #$10                            ; A4D0 69 10                    i.
LA4D2:  bmi     LA4DD                           ; A4D2 30 09                    0.
        cmp     #$11                            ; A4D4 C9 11                    ..
        bcs     LA4DE                           ; A4D6 B0 06                    ..
        adc     #$FF                            ; A4D8 69 FF                    i.
        tax                                     ; A4DA AA                       .
        lda     #$02                            ; A4DB A9 02                    ..
LA4DD:  sec                                     ; A4DD 38                       8
LA4DE:  sbc     #$02                            ; A4DE E9 02                    ..
        sta     $22                             ; A4E0 85 22                    ."
        stx     $21                             ; A4E2 86 21                    .!
        txa                                     ; A4E4 8A                       .
        beq     LA4E9                           ; A4E5 F0 02                    ..
        bpl     LA4FC                           ; A4E7 10 13                    ..
LA4E9:  ldy     $3B                             ; A4E9 A4 3B                    .;
        lda     #$2E                            ; A4EB A9 2E                    ..
        iny                                     ; A4ED C8                       .
        sta     $FF,y                           ; A4EE 99 FF 00                 ...
        txa                                     ; A4F1 8A                       .
        beq     LA4FA                           ; A4F2 F0 06                    ..
        lda     #$30                            ; A4F4 A9 30                    .0
        iny                                     ; A4F6 C8                       .
        sta     $FF,y                           ; A4F7 99 FF 00                 ...
LA4FA:  sty     $3B                             ; A4FA 84 3B                    .;
LA4FC:  ldy     #$00                            ; A4FC A0 00                    ..
        ldx     #$80                            ; A4FE A2 80                    ..
LA500:  lda     $2C                             ; A500 A5 2C                    .,
        clc                                     ; A502 18                       .
        adc     LA5CD,y                         ; A503 79 CD A5                 y..
        sta     $2C                             ; A506 85 2C                    .,
        lda     $2B                             ; A508 A5 2B                    .+
        adc     LA5CC,y                         ; A50A 79 CC A5                 y..
        sta     $2B                             ; A50D 85 2B                    .+
        lda     $2A                             ; A50F A5 2A                    .*
        adc     LA5CB,y                         ; A511 79 CB A5                 y..
        sta     $2A                             ; A514 85 2A                    .*
        lda     $29                             ; A516 A5 29                    .)
        adc     LA5CA,y                         ; A518 79 CA A5                 y..
        sta     $29                             ; A51B 85 29                    .)
        lda     $28                             ; A51D A5 28                    .(
        adc     LA5C9,y                         ; A51F 79 C9 A5                 y..
        sta     $28                             ; A522 85 28                    .(
        lda     $27                             ; A524 A5 27                    .'
        adc     LA5C8,y                         ; A526 79 C8 A5                 y..
        sta     $27                             ; A529 85 27                    .'
        lda     $26                             ; A52B A5 26                    .&
        adc     LA5C7,y                         ; A52D 79 C7 A5                 y..
        sta     $26                             ; A530 85 26                    .&
        inx                                     ; A532 E8                       .
        bcs     LA539                           ; A533 B0 04                    ..
        bpl     LA500                           ; A535 10 C9                    ..
        bmi     LA53B                           ; A537 30 02                    0.
LA539:  bmi     LA500                           ; A539 30 C5                    0.
LA53B:  txa                                     ; A53B 8A                       .
        bcc     LA542                           ; A53C 90 04                    ..
        .byte   $49                             ; A53E 49                       I
LA53F:  bbs7    $69,LA54B+1                     ; A53F FF 69 0A                 .i.
LA542:  adc     #$2F                            ; A542 69 2F                    i/
        iny                                     ; A544 C8                       .
        iny                                     ; A545 C8                       .
        iny                                     ; A546 C8                       .
        iny                                     ; A547 C8                       .
        iny                                     ; A548 C8                       .
        iny                                     ; A549 C8                       .
        iny                                     ; A54A C8                       .
LA54B:  sty     $3D                             ; A54B 84 3D                    .=
        ldy     $3B                             ; A54D A4 3B                    .;
        iny                                     ; A54F C8                       .
        tax                                     ; A550 AA                       .
        and     #$7F                            ; A551 29 7F                    ).
        sta     $FF,y                           ; A553 99 FF 00                 ...
        dec     $21                             ; A556 C6 21                    .!
        .byte   $D0                             ; A558 D0                       .
LA559:  asl     $A9                             ; A559 06 A9                    ..
        rol     $99C8                           ; A55B 2E C8 99                 ...
        .byte   $FF                             ; A55E FF                       .
        brk                                     ; A55F 00                       .
LA560:  sty     $3B                             ; A560 84 3B                    .;
        ldy     $3D                             ; A562 A4 3D                    .=
LA564:  txa                                     ; A564 8A                       .
        eor     #$FF                            ; A565 49 FF                    I.
        and     #$80                            ; A567 29 80                    ).
        tax                                     ; A569 AA                       .
        cpy     #$69                            ; A56A C0 69                    .i
        beq     LA572                           ; A56C F0 04                    ..
        cpy     #$93                            ; A56E C0 93                    ..
        bne     LA500                           ; A570 D0 8E                    ..
LA572:  ldy     $3B                             ; A572 A4 3B                    .;
LA574:  .byte   SAH                             ; A574 B9                       .
LA575:  bbs7    $00,LA500                       ; A575 FF 00 88                 ...
        cmp     #$30                            ; A578 C9 30                    .0
        beq     LA574                           ; A57A F0 F8                    ..
        cmp     #$2E                            ; A57C C9 2E                    ..
        beq     LA581                           ; A57E F0 01                    ..
        iny                                     ; A580 C8                       .
LA581:  lda     #$2B                            ; A581 A9 2B                    .+
        ldx     $22                             ; A583 A6 22                    ."
        beq     LA5B5                           ; A585 F0 2E                    ..
        bpl     LA591                           ; A587 10 08                    ..
        lda     #$00                            ; A589 A9 00                    ..
        sec                                     ; A58B 38                       8
        sbc     $22                             ; A58C E5 22                    ."
        tax                                     ; A58E AA                       .
        .byte   $A9                             ; A58F A9                       .
LA590:  .byte   $2D                             ; A590 2D                       -
LA591:  sta     stack+1,y                       ; A591 99 01 01                 ...
        lda     #$45                            ; A594 A9 45                    .E
        sta     stack,y                         ; A596 99 00 01                 ...
        txa                                     ; A599 8A                       .
        ldx     #$2F                            ; A59A A2 2F                    ./
        sec                                     ; A59C 38                       8
LA59D:  inx                                     ; A59D E8                       .
        sbc     #$0A                            ; A59E E9 0A                    ..
        bcs     LA59D                           ; A5A0 B0 FB                    ..
        adc     #$3A                            ; A5A2 69 3A                    i:
        sta     stack+3,y                       ; A5A4 99 03 01                 ...
        txa                                     ; A5A7 8A                       .
        sta     stack+2,y                       ; A5A8 99 02 01                 ...
        lda     #$00                            ; A5AB A9 00                    ..
        sta     stack+4,y                       ; A5AD 99 04 01                 ...
        beq     LA5BA                           ; A5B0 F0 08                    ..
LA5B2:  sta     $FF,y                           ; A5B2 99 FF 00                 ...
LA5B5:  lda     #$00                            ; A5B5 A9 00                    ..
        sta     stack,y                         ; A5B7 99 00 01                 ...
LA5BA:  lda     #$00                            ; A5BA A9 00                    ..
        ldy     #$01                            ; A5BC A0 01                    ..
        rts                                     ; A5BE 60                       `
; ----------------------------------------------------------------------------
LA5BF:  bra     LA5C1                           ; A5BF 80 00                    ..

LA5C1:  brk                                     ; A5C1 00                       .
LA5C2:  brk                                     ; A5C2 00                       .
        brk                                     ; A5C3 00                       .
        brk                                     ; A5C4 00                       .
        brk                                     ; A5C5 00                       .
        brk                                     ; A5C6 00                       .
LA5C7:  .byte   $FF                             ; A5C7 FF                       .
LA5C8:  .byte   $A5                             ; A5C8 A5                       .
LA5C9:  .byte   $0C                             ; A5C9 0C                       .
LA5CA:  .byte   $EF                             ; A5CA EF                       .
LA5CB:  .byte   $85                             ; A5CB 85                       .
LA5CC:  .byte   $C0                             ; A5CC C0                       .
LA5CD:  brk                                     ; A5CD 00                       .
        brk                                     ; A5CE 00                       .
        ora     #$18                            ; A5CF 09 18                    ..
        lsr     LA072                           ; A5D1 4E 72 A0                 Nr.
        brk                                     ; A5D4 00                       .
        bbs7    $FF,LA5EF                       ; A5D5 FF FF 17                 ...
        .byte   $2B                             ; A5D8 2B                       +
        phy                                     ; A5D9 5A                       Z
LA5DA:  beq     LA5DC                           ; A5DA F0 00                    ..
LA5DC:  brk                                     ; A5DC 00                       .
        brk                                     ; A5DD 00                       .
        rmb1    $48                             ; A5DE 17 48                    .H
        ror     $E8,x                           ; A5E0 76 E8                    v.
        brk                                     ; A5E2 00                       .
LA5E3:  bbs7    $FF,LA5E3                       ; A5E3 FF FF FD                 ...
        .byte   $AB                             ; A5E6 AB                       .
        .byte   $F4                             ; A5E7 F4                       .
        trb     a:$00                           ; A5E8 1C 00 00                 ...
LA5EB:  brk                                     ; A5EB 00                       .
        brk                                     ; A5EC 00                       .
        .byte   $3B                             ; A5ED 3B                       ;
        txs                                     ; A5EE 9A                       .
LA5EF:  dex                                     ; A5EF CA                       .
        brk                                     ; A5F0 00                       .
        .byte   $FF                             ; A5F1 FF                       .
LA5F2:  .byte   $FF                             ; A5F2 FF                       .
LA5F3:  bbs7    $FA,LA5FF+1                     ; A5F3 FF FA 0A                 ...
        .byte   $1F                             ; A5F6 1F                       .
LA5F7:  brk                                     ; A5F7 00                       .
        brk                                     ; A5F8 00                       .
LA5F9:  brk                                     ; A5F9 00                       .
        brk                                     ; A5FA 00                       .
LA5FB:  brk                                     ; A5FB 00                       .
LA5FC:  tya                                     ; A5FC 98                       .
        stx     $80,y                           ; A5FD 96 80                    ..
LA5FF:  .byte   $FF                             ; A5FF FF                       .
        .byte   $FF                             ; A600 FF                       .
LA601:  bbs7    $FF,LA5F3+1                     ; A601 FF FF F0                 ...
LA604:  lda     a:$C0,x                         ; A604 BD C0 00                 ...
        brk                                     ; A607 00                       .
        brk                                     ; A608 00                       .
        brk                                     ; A609 00                       .
        ora     ($86,x)                         ; A60A 01 86                    ..
        ldy     #$FF                            ; A60C A0 FF                    ..
        .byte   $FF                             ; A60E FF                       .
        .byte   $FF                             ; A60F FF                       .
LA610:  bbs7    $FF,LA5EB                       ; A610 FF FF D8                 ...
        .byte   $F0                             ; A613 F0                       .
LA614:  brk                                     ; A614 00                       .
        brk                                     ; A615 00                       .
        brk                                     ; A616 00                       .
        brk                                     ; A617 00                       .
        brk                                     ; A618 00                       .
        .byte   $03                             ; A619 03                       .
        inx                                     ; A61A E8                       .
        .byte   $FF                             ; A61B FF                       .
        .byte   $FF                             ; A61C FF                       .
LA61D:  .byte $FF
        .byte $FF
        .byte $FF
LA620:  bbs7    $9C,LA623                       ; A620 FF 9C 00                 ...
LA623:  brk                                     ; A623 00                       .
        brk                                     ; A624 00                       .
        brk                                     ; A625 00                       .
        brk                                     ; A626 00                       .
        brk                                     ; A627 00                       .
        asl     a                               ; A628 0A                       .
        .byte   $FF                             ; A629 FF                       .
        .byte   $FF                             ; A62A FF                       .
LA62B:  .byte $FF, $FF, $FF                     ; A62B FF FF FF                 ...
LA62E:  .byte $FF, $FF, $FF                     ; A62E FF FF FF                 ...
LA631:  .byte $FF, $FF, $FF                     ; A631 FF FF FF                 ...
        .byte $DF, $0A, $80                     ; A634 DF 0A 80                 ...
        brk                                     ; A637 00                       .
LA638:  brk                                     ; A638 00                       .
        brk                                     ; A639 00                       .
        brk                                     ; A63A 00                       .
        .byte   $03                             ; A63B 03                       .
LA63C:  .byte   $4B                             ; A63C 4B                       K
        cpy     #$FF                            ; A63D C0 FF                    ..
        .byte   $FF                             ; A63F FF                       .
        .byte   $FF                             ; A640 FF                       .
LA641:  .byte $FF, $FF, $73
        rts                                     ; A644 60                       `
; ----------------------------------------------------------------------------
        brk                                     ; A645 00                       .
LA646:  brk                                     ; A646 00                       .
        brk                                     ; A647 00                       .
        brk                                     ; A648 00                       .
        brk                                     ; A649 00                       .
        asl     LFF10                           ; A64A 0E 10 FF                 ...
        .byte   $FF                             ; A64D FF                       .
        .byte   $FF                             ; A64E FF                       .
LA64F:  bbs7    $FF,LA64F                       ; A64F FF FF FD                 ...
        tay                                     ; A652 A8                       .
        brk                                     ; A653 00                       .
        brk                                     ; A654 00                       .
        brk                                     ; A655 00                       .
        brk                                     ; A656 00                       .
        brk                                     ; A657 00                       .
        brk                                     ; A658 00                       .
        .byte $3c
; ----------------------------------------------------------------------------
LA65A:  jsr LA1DB
        bra LA66B
; ----------------------------------------------------------------------------
LA65F:  bra LA66B
; ----------------------------------------------------------------------------
LA661:  jsr     LA27B                           ; A661 20 7B A2                  {.
        lda     #<LA5BF                         ; A664 A9 BF                    ..
        ldy     #>LA5BF                         ; A666 A0 A5                    ..
        jsr     LA1DD_INDIRECT_STUFF_LOAD                           ; A668 20 DD A1                  ..
LA66B:  bne     LA670                           ; A66B D0 03                    ..
        jmp     LA72B                           ; A66D 4C 2B A7                 L+.
; ----------------------------------------------------------------------------
LA670:  lda     $30                             ; A670 A5 30                    .0
        bne     LA677                           ; A672 D0 03                    ..
        jmp     L9D6E                           ; A674 4C 6E 9D                 Ln.
; ----------------------------------------------------------------------------
LA677:  ldx     #$41                            ; A677 A2 41                    .A
        ldy     #$00                            ; A679 A0 00                    ..
        jsr     LA227                           ; A67B 20 27 A2                  '.
        lda     $38                             ; A67E A5 38                    .8
        bpl     LA691                           ; A680 10 0F                    ..
        jsr     LA369                           ; A682 20 69 A3                  i.
        lda     #<L0041                         ; A685 A9 41                    .A
        ldy     #>L0041                         ; A687 A0 00                    ..
        jsr     LA2DC_UNKNOWN_INDIRECT_STUFF_LOAD ; A689 20 DC A2                  ..
        bne     LA691                           ; A68C D0 03                    ..
        tya                                     ; A68E 98                       .
        ldy     $00                             ; A68F A4 00                    ..
LA691:  jsr     LA26D                           ; A691 20 6D A2                  m.
        tya                                     ; A694 98                       .
        pha                                     ; A695 48                       H
        jsr     L9EF0                           ; A696 20 F0 9E                  ..
        lda     #$41                            ; A699 A9 41                    .A
        ldy     #$00                            ; A69B A0 00                    ..
        jsr     L9F60                           ; A69D 20 60 9F                  `.
        jsr     LA72B                           ; A6A0 20 2B A7                  +.
        pla                                     ; A6A3 68                       h
        lsr     a                               ; A6A4 4A                       J
LA6A5:  bcc     LA6B1                           ; A6A5 90 0A                    ..
LA6A7:  lda     $25                             ; A6A7 A5 25                    .%
        beq     LA6B1                           ; A6A9 F0 06                    ..
        lda     $2D                             ; A6AB A5 2D                    .-
        eor     #$FF                            ; A6AD 49 FF                    I.
        sta     $2D                             ; A6AF 85 2D                    .-
LA6B1:  rts                                     ; A6B1 60                       `
; ----------------------------------------------------------------------------
;TODO probably data
        sta     ($38,x)                         ; A6B2 81 38                    .8
        tax                                     ; A6B4 AA                       .
        .byte   $3B                             ; A6B5 3B                       ;
        and     #$5C                            ; A6B6 29 5C                    )\
        rmb1    $EE                             ; A6B8 17 EE                    ..
LA6BA:
        ora     $4A59                           ; A6BA 0D 59 4A                 .YJ
        brk                                     ; A6BD 00                       .
        brk                                     ; A6BE 00                       .
        brk                                     ; A6BF 00                       .
        brk                                     ; A6C0 00                       .
        brk                                     ; A6C1 00                       .
        brk                                     ; A6C2 00                       .
        eor     LDE61,x                         ; A6C3 5D 61 DE                 ]a.
        lda     ($87)                           ; A6C6 B2 87                    ..
LA6C8:  sbc     ($4C,x)                         ; A6C8 E1 4C                    .L
        trb     $7461                           ; A6CA 1C 61 74                 .at
        adc     $63                             ; A6CD 65 63                    ec
        txs                                     ; A6CF 9A                       .
        sta     $14D9                           ; A6D0 8D D9 14                 ...
        adc     $72                             ; A6D3 65 72                    er
        rmb6    INSRT                           ; A6D5 67 A8                    g.
        ldy     $765C                           ; A6D7 AC 5C 76                 .\v
        .byte   $44                             ; A6DA 44                       D
        adc     #$5A                            ; A6DB 69 5A                    iZ
        sta     ($9E)                           ; A6DD 92 9E                    ..
        stz     $3EAF                           ; A6DF 9C AF 3E                 ..>
        tsb     $316D                           ; A6E2 0C 6D 31                 .m1
        rts                                     ; A6E5 60                       `
; ----------------------------------------------------------------------------
;TODO probably data
        ora     ($1D),y                         ; A6E6 11 1D                    ..
        rol     $0E41                           ; A6E8 2E 41 0E                 .A.
        bvs     $A76C                           ; A6EB 70 7F                    p.
        sbc     $FE                             ; A6ED E5 FE                    ..
        bit     $8645                           ; A6EF 2C 45 86                 ,E.
        bit     $74                             ; A6F2 24 74                    $t
LA6F4:  and     ($84,x)                         ; A6F4 21 84                    !.
        bit     #$7C                            ; A6F6 89 7C                    .|
        rol     $3C,x                           ; A6F8 36 3C                    6<
        bmi     $A773                           ; A6FA 30 77                    0w
        rol     LFFC3_CLOSE                     ; A6FC 2E C3 FF                 ...
        bit     $3953,x                         ; A6FF 3C 53 39                 <S9
        .byte   $82                             ; A702 82                       .
        ply                                     ; A703 7A                       z
        ora     $5B95,x                         ; A704 1D 95 5B                 ..[
        adc     $73D2,x                         ; A707 7D D2 73                 }.s
        sty     $7C                             ; A70A 84 7C                    .|
        .byte   $63                             ; A70C 63                       c
        cli                                     ; A70D 58                       X
        lsr     SAL                             ; A70E 46 B8                    F.
        and     $05                             ; A710 25 05                    %.
        sed                                     ; A712 F8                       .
        ror     LFD75,x                         ; A713 7E 75 FD                 ~u.
        bbs6    $FC,LA72F                       ; A716 EF FC 16                 ...
        bit     L8074                           ; A719 2C 74 80                 ,t.
        and     ($72),y                         ; A71C 31 72                    1r
LA71E:  rmb1    $F7                             ; A71E 17 F7                    ..
        cmp     ($CF),y                         ; A720 D1 CF                    ..
        jmp     (L0081,x)                       ; A722 7C 81 00                 |..
LA725:  brk                                     ; A725 00                       .
        brk                                     ; A726 00                       .
        brk                                     ; A727 00                       .
        brk                                     ; A728 00                       .
        brk                                     ; A729 00                       .
        brk                                     ; A72A 00                       .
LA72B:  lda     #$B2                            ; A72B A9 B2                    ..
        ldy     #$A6                            ; A72D A0 A6                    ..
LA72F:  .byte   $20                             ; A72F 20
LA730:  rol     $A59F                           ; A730 2E 9F A5                 ...
        dec     a                               ; A733 3A                       :
        .byte   $69                             ; A734 69                       i
LA735:  bvc     LA6C8-1                         ; A735 50 90                    P.
        .byte   $03                             ; A737 03                       .
        jsr     LA292                           ; A738 20 92 A2                  ..
LA73B:  sta     $14                             ; A73B 85 14                    ..
        jsr     LA27E                           ; A73D 20 7E A2                  ~.
        lda     $25                             ; A740 A5 25                    .%
        cmp     #$88                            ; A742 C9 88                    ..
LA744:  bcc     LA749                           ; A744 90 03                    ..
LA746:  jsr     LA0B3                           ; A746 20 B3 A0                  ..
LA749:  jsr     LA369                           ; A749 20 69 A3                  i.
        .byte   $A5                             ; A74C A5                       .
LA74D:  brk                                     ; A74D 00                       .
        clc                                     ; A74E 18                       .
        adc     #$81                            ; A74F 69 81                    i.
        beq     LA746                           ; A751 F0 F3                    ..
        sec                                     ; A753 38                       8
        sbc     #$01                            ; A754 E9 01                    ..
        pha                                     ; A756 48                       H
        ldx     #$08                            ; A757 A2 08                    ..
LA759:  lda     $30,x                           ; A759 B5 30                    .0
        ldy     $25,x                           ; A75B B4 25                    .%
        sta     $25,x                           ; A75D 95 25                    .%
        sty     $30,x                           ; A75F 94 30                    .0
        dex                                     ; A761 CA                       .
        bpl     LA759                           ; A762 10 F5                    ..
        lda     $14                             ; A764 A5 14                    ..
        sta     $3A                             ; A766 85 3A                    .:
        jsr     L9CA7                           ; A768 20 A7 9C                  ..
        jsr     LA6A7
        lda     #<LA6BA                            ; A76E A9 BA                    ..
        ldy     #>LA6BA                            ; A770 A0 A6                    ..
        jsr     LA794
        lda     #$00                            ; A775 A9 00                    ..
        sta     $39                             ; A777 85 39                    .9
        pla                                     ; A779 68                       h
        jsr     LA098                           ; A77A 20 98 A0                  ..
        rts                                     ; A77D 60                       `
; ----------------------------------------------------------------------------
LA77E_UNKNOWN_OTHER_INDIRECT_STUFF:
        sta     $3B                             ; A77E 85 3B                    .;
        sty     $3C                             ; A780 84 3C                    .<
        jsr     LA220                           ; A782 20 20 A2                   .
        lda     #$15                            ; A785 A9 15                    ..
        jsr     L9F60                           ; A787 20 60 9F                  `.
        jsr     LA798                           ; A78A 20 98 A7                  ..
        lda     #$15                            ; A78D A9 15                    ..
        ldy     #$00                            ; A78F A0 00                    ..
        jmp     L9F60                           ; A791 4C 60 9F                 L`.
; ----------------------------------------------------------------------------
LA794:  sta     $3B                             ; A794 85 3B                    .;
        sty     $3C                             ; A796 84 3C                    .<
LA798:  jsr     LA21D                           ; A798 20 1D A2                  ..
        lda     ($3B),y                         ; A79B B1 3B                    .;
LA79D:  sta     $2E                             ; A79D 85 2E                    ..
        ldy     $3B                             ; A79F A4 3B                    .;
        iny                                     ; A7A1 C8                       .
        tya                                     ; A7A2 98                       .
        bne     LA7A7                           ; A7A3 D0 02                    ..
        inc     $3C                             ; A7A5 E6 3C                    .<
LA7A7:  sta     $3B                             ; A7A7 85 3B                    .;
        ldy     $3C                             ; A7A9 A4 3C                    .<
LA7AB:  jsr     L9F2E_PROBABLY_JSR_TO_INDIRECT_STUFF                           ; A7AB 20 2E 9F                  ..
        lda     $3B                             ; A7AE A5 3B                    .;
        ldy     $3C                             ; A7B0 A4 3C                    .<
        clc                                     ; A7B2 18                       .
        adc     #$08                            ; A7B3 69 08                    i.
        .byte   $90                             ; A7B5 90                       .
LA7B6:  ora     ($C8,x)                         ; A7B6 01 C8                    ..
LA7B8:  sta     $3B                             ; A7B8 85 3B                    .;
        sty     $3C                             ; A7BA 84 3C                    .<
        jsr     L9F3C_JSR_INDIRECT_STUFF_AND_JMP_L9CBE                           ; A7BC 20 3C 9F                  <.
        lda     #$1D                            ; A7BF A9 1D                    ..
        ldy     #$00                            ; A7C1 A0 00                    ..
        dec     $2E                             ; A7C3 C6 2E                    ..
        bne     LA7AB                           ; A7C5 D0 E4                    ..
        rts                                     ; A7C7 60                       `
; ----------------------------------------------------------------------------
LA7C8:  tya                                     ; A7C8 98                       .
        and     $44,x                           ; A7C9 35 44                    5D
        ply                                     ; A7CB 7A                       z
        brk                                     ; A7CC 00                       .
        brk                                     ; A7CD 00                       .
        brk                                     ; A7CE 00                       .
        brk                                     ; A7CF 00                       .
LA7D0:  pla                                     ; A7D0 68                       h
        plp                                     ; A7D1 28                       (
        lda     ($46),y                         ; A7D2 B1 46                    .F
        brk                                     ; A7D4 00                       .
        brk                                     ; A7D5 00                       .
        brk                                     ; A7D6 00                       .
        brk                                     ; A7D7 00                       .
LA7D8:  jsr     LA29A                           ; A7D8 20 9A A2                  ..
LA7DB:  bmi     LA81A                           ; A7DB 30 3D                    0=
        bne     LA805                           ; A7DD D0 26                    .&
        lda     VIA1_T1CL                       ; A7DF AD 04 F8                 ...
LA7E2:  sta     $26                             ; A7E2 85 26                    .&
        lda     VIA1_T1CH                       ; A7E4 AD 05 F8                 ...
        sta     $2B                             ; A7E7 85 2B                    .+
        lda     VIA1_T2CL                       ; A7E9 AD 08 F8                 ...
        sta     $2A                             ; A7EC 85 2A                    .*
        lda     VIA2_T2CL                       ; A7EE AD 88 F8                 ...
        sta     $29                             ; A7F1 85 29                    .)
        lda     VIA2_T1CL                       ; A7F3 AD 84 F8                 ...
        sta     $28                             ; A7F6 85 28                    .(
        lda     VIA1_T2CL                       ; A7F8 AD 08 F8                 ...
        sta     $27                             ; A7FB 85 27                    .'
        lda     VIA1_T2CH                       ; A7FD AD 09 F8                 ...
        sta     $2C                             ; A800 85 2C                    .,
        jmp     LA832                           ; A802 4C 32 A8                 L2.
; ----------------------------------------------------------------------------
LA805:  lda     #<L03AC                         ; A805 A9 AC                    ..
        ldy     #>L03AC                         ; A807 A0 03                    ..
        jsr     LA1DD_INDIRECT_STUFF_LOAD       ; A809 20 DD A1                  ..
        lda     #<LA7C8                         ; A80C A9 C8                    ..
        ldy     #>LA7C8                         ; A80E A0 A7                    ..
        jsr     L9F2E_PROBABLY_JSR_TO_INDIRECT_STUFF    ; A810 20 2E 9F                  ..
        lda     #<LA7D0                         ; A813 A9 D0                    ..
        ldy     #>LA7D0                         ; A815 A0 A7                    ..
        jsr     L9F3C_JSR_INDIRECT_STUFF_AND_JMP_L9CBE  ; A817 20 3C 9F                  <.
LA81A:  ldx     $2C                             ; A81A A6 2C                    .,
        lda     $26                             ; A81C A5 26                    .&
        sta     $2C                             ; A81E 85 2C                    .,
        stx     $26                             ; A820 86 26                    .&
        ldx     $2A                             ; A822 A6 2A                    .*
        lda     $29                             ; A824 A5 29                    .)
        sta     $2A                             ; A826 85 2A                    .*
        stx     $29                             ; A828 86 29                    .)
        ldx     $27                             ; A82A A6 27                    .'
        lda     $2B                             ; A82C A5 2B                    .+
        sta     $27                             ; A82E 85 27                    .'
        stx     $2B                             ; A830 86 2B                    .+
LA832:  lda     #$00                            ; A832 A9 00                    ..
        sta     $2D                             ; A834 85 2D                    .-
        lda     $25                             ; A836 A5 25                    .%
        sta     $3A                             ; A838 85 3A                    .:
        lda     #$80                            ; A83A A9 80                    ..
        sta     $25                             ; A83C 85 25                    .%
        jsr     L9D40                           ; A83E 20 40 9D                  @.
        ldx     #>LAC03                         ; A841 A2 AC                    ..
        ldy     #<LAC03                         ; A843 A0 03                    ..
LA845:  jmp     LA227                           ; A845 4C 27 A2                 L'.
; ----------------------------------------------------------------------------
LA848:  lda     #<LA8C4                         ; A848 A9 C4                    ..
        ldy     #>LA8C4                          ; A84A A0 A8                    ..
        jsr     L9F3C_JSR_INDIRECT_STUFF_AND_JMP_L9CBE  ; A84C 20 3C 9F                  <.
LA84F:  jsr     LA27B                           ; A84F 20 7B A2                  {.
        lda     #$CC                            ; A852 A9 CC                    ..
        ldy     #$A8                            ; A854 A0 A8                    ..
        ldx     $38                             ; A856 A6 38                    .8
        jsr     LA0EE                           ; A858 20 EE A0                  ..
        jsr     LA27B                           ; A85B 20 7B A2                  {.
        jsr     LA369                           ; A85E 20 69 A3                  i.
        lda     #$00                            ; A861 A9 00                    ..
        sta     $39                             ; A863 85 39                    .9
        jsr     L9CA7                           ; A865 20 A7 9C                  ..
        lda     #<LA8D4                         ; A868 A9 D4                    ..
LA86B := *+1
        ldy     #>LA8D4
        jsr     L9F48_JSR_INDIRECT_STUFF_AND_JMP_L9CA7                           ; A86C 20 48 9F                  H.
        lda     $2D                             ; A86F A5 2D                    .-
        pha                                     ; A871 48                       H
        bpl     LA881                           ; A872 10 0D                    ..
        jsr     L9F38                           ; A874 20 38 9F                  8.
        lda     $2D                             ; A877 A5 2D                    .-
        bmi     LA884                           ; A879 30 09                    0.
        lda     $04                             ; A87B A5 04                    ..
        eor     #$FF                            ; A87D 49 FF                    I.
        sta     $04                             ; A87F 85 04                    ..
LA881:  jsr     LA6A7                           ; A881 20 A7 A6                  ..
LA884:  lda     #<LA8D4                         ; A884 A9 D4                    ..
        ldy     #>LA8D4                         ; A886 A0 A8                    ..
        jsr     L9F3C_JSR_INDIRECT_STUFF_AND_JMP_L9CBE                           ; A888 20 3C 9F                  <.
        pla                                     ; A88B 68                       h
        bpl     LA891                           ; A88C 10 03                    ..
        jsr     LA6A7                           ; A88E 20 A7 A6                  ..
LA891:  lda     #<LA8DC                         ; A891 A9 DC                    ..
        ldy     #>LA8DC                         ; A893 A0 A8                    ..
        jmp     LA77E_UNKNOWN_OTHER_INDIRECT_STUFF                           ; A895 4C 7E A7                 L~.
; ----------------------------------------------------------------------------
LA898:  jsr     LA220                           ; A898 20 20 A2                   .
        lda     #$00                            ; A89B A9 00                    ..
        sta     $04                             ; A89D 85 04                    ..
        jsr     LA84F                           ; A89F 20 4F A8                  O.
        ldx     #$41                            ; A8A2 A2 41                    .A
        ldy     #$00                            ; A8A4 A0 00                    ..
        jsr     LA845                           ; A8A6 20 45 A8                  E.
        lda     #<L0015                         ; A8A9 A9 15                    ..
        ldy     #>L0015                         ; A8AB A0 00                    ..
        jsr     LA1DD_INDIRECT_STUFF_LOAD       ; A8AD 20 DD A1                  ..
        lda     #$00                            ; A8B0 A9 00                    ..
        sta     $2D                             ; A8B2 85 2D                    .-
        lda     $04                             ; A8B4 A5 04                    ..
        jsr     LA8C0                           ; A8B6 20 C0 A8                  ..
        lda     #$41                            ; A8B9 A9 41                    .A
        ldy     #$00                            ; A8BB A0 00                    ..
        jmp     LA0F6                           ; A8BD 4C F6 A0                 L..
; ----------------------------------------------------------------------------
LA8C0:  pha                                     ; A8C0 48                       H
        jmp     LA881                           ; A8C1 4C 81 A8                 L..
; ----------------------------------------------------------------------------
LA8C4:  sta     ($49,x)                         ; A8C4 81 49                    .I
        bbr0    $DA,LA86B                       ; A8C6 0F DA A2                 ...
        and     ($68,x)                         ; A8C9 21 68                    !h
        iny                                     ; A8CB C8                       .
        .byte   $83                             ; A8CC 83                       .
        eor     #$0F                            ; A8CD 49 0F                    I.
        phx                                     ; A8CF DA                       .
        ldx     #$21                            ; A8D0 A2 21                    .!
        pla                                     ; A8D2 68                       h
        iny                                     ; A8D3 C8                       .
LA8D4:  bbr7    $00,LA8D7                       ; A8D4 7F 00 00                 ...
LA8D7:  brk                                     ; A8D7 00                       .
        brk                                     ; A8D8 00                       .
        brk                                     ; A8D9 00                       .
        brk                                     ; A8DA 00                       .
        brk                                     ; A8DB 00                       .
LA8DC:  ora     #$7A                            ; A8DC 09 7A                    .z
        cmp     $20                             ; A8DE C5 20                    .
        and     ($08,x)                         ; A8E0 21 08                    !.
        .byte   $FC                             ; A8E2 FC                       .
        tax                                     ; A8E3 AA                       .
        trb     $7D                             ; A8E4 14 7D                    .}
        eor     $76,x                           ; A8E6 55 76                    Uv
        ora     $C957,y                         ; A8E8 19 57 C9                 .W.
        txs                                     ; A8EB 9A                       .
        ldy     LB780                           ; A8EC AC 80 B7                 ...
        dec     $DC,x                           ; A8EF D6 DC                    ..
        sed                                     ; A8F1 F8                       .
        tax                                     ; A8F2 AA                       .
        lda     L82FE,y                         ; A8F3 B9 FE 82                 ...
        stz     $7A,x                           ; A8F6 74 7A                    tz
        inc     a                               ; A8F8 1A                       .
        pla                                     ; A8F9 68                       h
        .byte   $0C                             ; A8FA 0C                       .
LA8FB:  ror     a                               ; A8FB 6A                       j
        .byte   $F4                             ; A8FC F4                       .
        sty     $F1                             ; A8FD 84 F1                    ..
        .byte   $83                             ; A8FF 83                       .
        smb2    $EF                             ; A900 A7 EF                    ..
        .byte   $44                             ; A902 44                       D
        sec                                     ; A903 38                       8
        .byte   $DC                             ; A904 DC                       .
        stx     $28                             ; A905 86 28                    .(
        bit     $431A,x                         ; A907 3C 1A 43                 <.C
        smb7    $3B                             ; A90A F7 3B                    .;
        sed                                     ; A90C F8                       .
        smb0    $99                             ; A90D 87 99                    ..
        adc     #$66                            ; A90F 69 66                    if
        .byte   $73                             ; A911 73                       s
        ora     $EC,x                           ; A912 15 EC                    ..
        .byte   $23                             ; A914 23                       #
        smb0    $23                             ; A915 87 23                    .#
        and     $E3,x                           ; A917 35 E3                    5.
        .byte   $3B                             ; A919 3B                       ;
        lda     a:$57                           ; A91A AD 57 00                 .W.
        stx     $A5                             ; A91D 86 A5                    ..
        eor     $31E7,x                         ; A91F 5D E7 31                 ].1
        and     L90F2                           ; A922 2D F2 90                 -..
        .byte   $83                             ; A925 83                       .
        eor     #$0F                            ; A926 49 0F                    I.
        phx                                     ; A928 DA                       .
        ldx     #$21                            ; A929 A2 21                    .!
        pla                                     ; A92B 68                       h
        iny                                     ; A92C C8                       .
LA92D:  lda     $2D                             ; A92D A5 2D                    .-
        pha                                     ; A92F 48                       H
        bpl     LA935                           ; A930 10 03                    ..
        jsr     LA6A7                           ; A932 20 A7 A6                  ..
LA935:  lda     $25                             ; A935 A5 25                    .%
        pha                                     ; A937 48                       H
        cmp     #$81                            ; A938 C9 81                    ..
        bcc     LA943                           ; A93A 90 07                    ..
        lda     #<L9E7F                         ; A93C A9 7F                    ..
        ldy     #>L9E7F                         ; A93E A0 9E                    ..
        jsr     L9F54_JSR_INDIRECT_STUFF_AND_JMP_LA0F9  ; A940 20 54 9F                  T.
LA943:  lda     #<LA95D                         ; A943 A9 5D                    .]
        ldy     #>LA95D                         ; A945 A0 A9                    ..
        jsr     LA77E_UNKNOWN_OTHER_INDIRECT_STUFF  ; A947 20 7E A7                  ~.
        pla                                     ; A94A 68                       h
        cmp     #$81                            ; A94B C9 81                    ..
        bcc     LA956                           ; A94D 90 07                    ..
        lda     #<LA8C4                         ; A94F A9 C4                    ..
        ldy     #>LA8C4                         ; A951 A0 A8                    ..
        jsr     L9F48_JSR_INDIRECT_STUFF_AND_JMP_L9CA7  ; A953 20 48 9F                  H.
LA956:  pla                                     ; A956 68                       h
        bpl     LA95C                           ; A957 10 03                    ..
        jmp     LA6A7                           ; A959 4C A7 A6                 L..
; ----------------------------------------------------------------------------
LA95C:  rts                                     ; A95C 60                       `
; ----------------------------------------------------------------------------
;TODO probably data
LA95D:  tsb     $6275                           ; A95D 0C 75 62                 .ub
        inc     $07BA,x                         ; A960 FE BA 07                 ...
        trb     $3A                             ; A963 14 3A                    .:
        tay                                     ; A965 A8                       .
        sei                                     ; A966 78                       x
        dec     $D8,x                           ; A967 D6 D8                    ..
        dec     $5116                           ; A969 CE 16 51                 ..Q
        eor     $7A14                           ; A96C 4D 14 7A                 M.z
        rol     $7DD1,x                         ; A96F 3E D1 7D                 >.}
        .byte   $BD                             ; A972 BD                       .
        .byte   $4C                             ; A973 4C                       L
LA974:  rol     $88,x                           ; A974 36 88                    6.
        .byte   $7B                             ; A976 7B                       {
        .byte   $D7                             ; A977 D7                       .
LA978:  cpy     $23                             ; A978 C4 23                    .#
        .byte   $CB                             ; A97A CB                       .
        ora     ($6B,x)                         ; A97B 01 6B                    .k
        .byte   $9C                             ; A97D 9C                       .
LA97E:  jmp     ($1734,x)                       ; A97E 7C 34 17                 |4.
        asl     a                               ; A981 0A                       .
        dec     a                               ; A982 3A                       :
        .byte   $DC                             ; A983 DC                       .
        eor     ($78,x)                         ; A984 41 78                    Ax
        jmp     (L81F7,x)                       ; A986 7C F7 81                 |..
        .byte   $A3                             ; A989 A3                       .
        cmp     ($36,x)                         ; A98A C1 36                    .6
        rmb2    $00                             ; A98C 27 00                    '.
        adc     LAE19,x                         ; A98E 7D 19 AE                 }..
        adc     ($16,x)                         ; A991 61 16                    a.
        nop                                     ; A993 EA                       .
        tsx                                     ; A994 BA                       .
        eor     LB97D                           ; A995 4D 7D B9                 M}.
        rts                                     ; A998 60                       `
; ----------------------------------------------------------------------------
;TODO probably data
        bbs0    $78,LA9F9                       ; A999 8F 78 5D                 .x]
        .byte   $0B                             ; A99C 0B                       .
        tsx                                     ; A99D BA                       .
        adc     $7263,x                         ; A99E 7D 63 72                 }cr
        ora     ($44)                           ; A9A1 12 44                    .D
        .byte   $A1                             ; A9A3 A1                       .
LA9A4:  sta     $B4                             ; A9A4 85 B4                    ..
        ror     $4792,x                         ; A9A6 7E 92 47                 ~.G
        .byte   $FB                             ; A9A9 FB                       .
        .byte   $62                             ; A9AA 62                       b
        asl     $0D,x                           ; A9AB 16 0D                    ..
        .byte   $43                             ; A9AD 43                       C
        ror     LCC4C,x                         ; A9AE 7E 4C CC                 ~L.
        bbs3    $F0,LA974                       ; A9B1 BF F0 C0                 ...
        ply                                     ; A9B4 7A                       z
        stz     $7F                             ; A9B5 64 7F                    d.
        tax                                     ; A9B7 AA                       .
        tax                                     ; A9B8 AA                       .
        tax                                     ; A9B9 AA                       .
LA9BA:  stx     LB07D                           ; A9BA 8E 7D B0                 .}.
        cpy     #$80                            ; A9BD C0 80                    ..
        .byte   $7F                             ; A9BF 7F                       .
        .byte   $FF                             ; A9C0 FF                       .
        .byte   $ff, $ff, $f5, $b9, $2c
; ----------------------------------------------------------------------------
LA9C6:  jsr     LA02B
; ----------------------------------------------------------------------------
LA9C9:  jsr     L9BF6
        lda     $2C                             ; A9CC A5 2C                    .,
        sta     $00                             ; A9CE 85 00                    ..
        lda     $2B                             ; A9D0 A5 2B                    .+
        sta     $01                             ; A9D2 85 01                    ..
        jsr     LA26B                           ; A9D4 20 6B A2                  k.
        jsr     L9BF6                           ; A9D7 20 F6 9B                  ..
        lda     $2C                             ; A9DA A5 2C                    .,
        eor     $00                             ; A9DC 45 00                    E.
        tay                                     ; A9DE A8                       .
        lda     $2B                             ; A9DF A5 2B                    .+
LA9E1:  eor     $01                             ; A9E1 45 01                    E.
        jmp     L9BDA                           ; A9E3 4C DA 9B                 L..
; ----------------------------------------------------------------------------
LA9E6:  php                                     ; A9E6 08                       .
        sty     $03A0                           ; A9E7 8C A0 03                 ...
        cpx     #$50                            ; A9EA E0 50                    .P
        bcs     LAA17                           ; A9EC B0 29                    .)
        stx     V1541_FNLEN                     ; A9EE 8E 9F 03                 ...
LA9F1:  tax                                     ; A9F1 AA                       .
        and     #$0F                            ; A9F2 29 0F                    ).
        sta     SXREG                           ; A9F4 8D 9D 03                 ...
        txa                                     ; A9F7 8A                       .
        lsr     a                               ; A9F8 4A                       J
LA9F9:  lsr     a                               ; A9F9 4A                       J
        lsr     a                               ; A9FA 4A                       J
        lsr     a                               ; A9FB 4A                       J
        inc     a                               ; A9FC 1A                       .
        sta     V1541_BYTE_TO_WRITE                           ; A9FD 8D 9E 03                 ...
        cld                                     ; AA00 D8                       .
        lda     #$FF                            ; AA01 A9 FF                    ..
        sta     $ED                             ; AA03 85 ED                    ..
        lda     VidMemHi                        ; AA05 A5 A0                    ..
        clc                                     ; AA07 18                       .
        adc     #$07                            ; AA08 69 07                    i.
        sta     $EE                             ; AA0A 85 EE                    ..
LAA0C:  lda     SXREG                           ; AA0C AD 9D 03                 ...
        inc     SXREG                           ; AA0F EE 9D 03                 ...
        cmp     V1541_BYTE_TO_WRITE                           ; AA12 CD 9E 03                 ...
        bcc     LAA19                           ; AA15 90 02                    ..
LAA17:  plp                                     ; AA17 28                       (
        rts                                     ; AA18 60                       `
; ----------------------------------------------------------------------------
LAA19:  stz     $EB                             ; AA19 64 EB                    d.
        lsr     a                               ; AA1B 4A                       J
        ror     $EB                             ; AA1C 66 EB                    f.
        adc     VidMemHi                        ; AA1E 65 A0                    e.
        sta     $EC                             ; AA20 85 EC                    ..
        ldy     V1541_FNLEN                           ; AA22 AC 9F 03                 ...
LAA25:  plp                                     ; AA25 28                       (
        php                                     ; AA26 08                       .
        lda     ($ED)                           ; AA27 B2 ED                    ..
        bcs     LAA31                           ; AA29 B0 06                    ..
        lda     ($EB),y                         ; AA2B B1 EB                    ..
        sta     ($ED)                           ; AA2D 92 ED                    ..
        lda     #$20                            ; AA2F A9 20                    .
LAA31:  sta     ($EB),y                         ; AA31 91 EB                    ..
        lda     $ED                             ; AA33 A5 ED                    ..
        asl     a                               ; AA35 0A                       .
        eor     #$A2                            ; AA36 49 A2                    I.
        bne     LAA47                           ; AA38 D0 0D                    ..
        ror     a                               ; AA3A 6A                       j
        sta     $ED                             ; AA3B 85 ED                    ..
        bmi     LAA47                           ; AA3D 30 08                    0.
        dec     $EE                             ; AA3F C6 EE                    ..
        lda     $EE                             ; AA41 A5 EE                    ..
        cmp     VidMemHi                        ; AA43 C5 A0                    ..
        bcc     LAA17                           ; AA45 90 D0                    ..
LAA47:  dec     $ED                             ; AA47 C6 ED                    ..
        dey                                     ; AA49 88                       .
        bmi     LAA0C                           ; AA4A 30 C0                    0.
        cpy     $03A0                           ; AA4C CC A0 03                 ...
        bcs     LAA25                           ; AA4F B0 D4                    ..
        bra     LAA0C                           ; AA51 80 B9                    ..
LAA53:  stx     V1541_FILE_MODE                 ; AA53 8E A3 03                 ...
        sty     $03A7                           ; AA56 8C A7 03                 ...
        sty     $0357                           ; AA59 8C 57 03                 .W.
        pha                                     ; AA5C 48                       H
        and     #$07                            ; AA5D 29 07                    ).
        sta     $03A2                           ; AA5F 8D A2 03                 ...
        pla                                     ; AA62 68                       h
        eor     #$F8                            ; AA63 49 F8                    I.
        bit     #$F8                            ; AA65 89 F8                    ..
        beq     LAA7F                           ; AA67 F0 16                    ..
        .byte   $09                             ; AA69 09                       .
;TODO this looks like data, see above
LAA6A:  rmb0    $8D                             ; AA6A 07 8D                    ..
        lda     ($03,x)                         ; AA6C A1 03                    ..
        ldy     #$00                            ; AA6E A0 00                    ..
        ldx     #$00                            ; AA70 A2 00                    ..
LAA72:  jsr     GO_APPL_LOAD_GO_KERN            ; AA72 20 53 03                  S.
        beq     LAA81                           ; AA75 F0 0A                    ..
        cmp     #$0D                            ; AA77 C9 0D                    ..
        bne     LAA7C                           ; AA79 D0 01                    ..
        inx                                     ; AA7B E8                       .
LAA7C:  iny                                     ; AA7C C8                       .
        bne     LAA72                           ; AA7D D0 F3                    ..
LAA7F:  sec                                     ; AA7F 38                       8
        rts                                     ; AA80 60                       `
; ----------------------------------------------------------------------------
LAA81:  cpx     #$0F                            ; AA81 E0 0F                    ..
        bcs     LAA7F                           ; AA83 B0 FA                    ..
        stx     V1541_FILE_TYPE                           ; AA85 8E A4 03                 ...
        clc                                     ; AA88 18                       .
        jsr     LAB90                           ; AA89 20 90 AB                  ..
LAA8C:  ldx     V1541_FILE_TYPE                           ; AA8C AE A4 03                 ...
        lda     V1541_FILE_MODE                           ; AA8F AD A3 03                 ...
        bmi     LAA9C                           ; AA92 30 08                    0.
        cpx     V1541_FILE_MODE                           ; AA94 EC A3 03                 ...
        bcs     LAA9D                           ; AA97 B0 04                    ..
        lda     #$00                            ; AA99 A9 00                    ..
;TODO code
        .byte   $24                             ; AA9B 24                       $
LAA9C:  txa                                     ; AA9C 8A                       .
LAA9D:  sta     V1541_FILE_MODE                           ; AA9D 8D A3 03                 ...
        jsr     LAAF7                           ; AAA0 20 F7 AA                  ..
        jsr     LB6DF_GET_KEY_BLOCKING          ; AAA3 20 DF B6                  ..
        cmp     #$91 ;UP                        ; AAA6 C9 91                    ..
        bne     LAAAD                           ; AAA8 D0 03                    ..
        inc     V1541_FILE_MODE                           ; AAAA EE A3 03                 ...
LAAAD:  cmp     #$11 ;DOWN                      ; AAAD C9 11                    ..
        bne     LAAB4                           ; AAAF D0 03                    ..
        dec     V1541_FILE_MODE                           ; AAB1 CE A3 03                 ...
LAAB4:  tax                                     ; AAB4 AA                       .
        lda     #$80                            ; AAB5 A9 80                    ..
        cpx     #$9D ;LEFT                      ; AAB7 E0 9D                    ..
        beq     LAAD9                           ; AAB9 F0 1E                    ..
        lsr     a                               ; AABB 4A                       J
        cpx     #$1D ;RIGHT                     ; AABC E0 1D                    ..
        beq     LAAD9                           ; AABE F0 19                    ..
        lsr     a                               ; AAC0 4A                       J
        cpx     #$0D ;RETURN                    ; AAC1 E0 0D                    ..
        beq     LAAD9                           ; AAC3 F0 14                    ..
        cpx     #$85 ;F1                        ; AAC5 E0 85                    ..
        bcc     LAA8C                           ; AAC7 90 C3                    ..
        cpx     #$8D ;F8 + 1                    ; AAC9 E0 8D                    ..
        bcs     LAA8C                           ; AACB B0 BF                    ..
        lda     LAA6A,x                         ; AACD BD 6A AA                 .j.
        cmp     $03A2                           ; AAD0 CD A2 03                 ...
        beq     LAAD7                           ; AAD3 F0 02                    ..
        ora     #$18                            ; AAD5 09 18                    ..
LAAD7:  eor     #$08                            ; AAD7 49 08                    I.
LAAD9:  and     MON_MMU_MODE                    ; AAD9 2D A1 03                 -..
        bit     #$F8                            ; AADC 89 F8                    ..
        beq     LAA8C                           ; AADE F0 AC                    ..
        sta     MON_MMU_MODE                    ; AAE0 8D A1 03                 ...
        sec                                     ; AAE3 38                       8
        jsr     LAB90                           ; AAE4 20 90 AB                  ..
        lda     MON_MMU_MODE                    ; AAE7 AD A1 03                 ...
        ldx     V1541_FILE_MODE                 ; AAEA AE A3 03                 ...
        clc                                     ; AAED 18                       .
        rts                                     ; AAEE 60                       `
; ----------------------------------------------------------------------------
        brk                                     ; AAEF 00                       .
        .byte   $02                             ; AAF0 02                       .
        tsb     $06                             ; AAF1 04 06                    ..
        ora     ($03,x)                         ; AAF3 01 03                    ..
        ora     $07                             ; AAF5 05 07                    ..
LAAF7:  stz     $03A5                           ; AAF7 9C A5 03                 ...
        lda     #$FF                            ; AAFA A9 FF                    ..
        sta     $03A6                           ; AAFC 8D A6 03                 ...
        ldy     $03A7                           ; AAFF AC A7 03                 ...
        sty     $0357                           ; AB02 8C 57 03                 .W.
LAB05:  jsr     LAB57                           ; AB05 20 57 AB                  W.
        lda     #$A5                            ; AB08 A9 A5                    ..
        jsr     LAB50                           ; AB0A 20 50 AB                  P.
        bne     LAB11                           ; AB0D D0 02                    ..
        lda     #$20                            ; AB0F A9 20                    .
LAB11:  clc                                     ; AB11 18                       .
        jsr     LB6F9_MAYBE_PUT_CHAR_IN_FKEY_BAR_SLOT                           ; AB12 20 F9 B6                  ..
        inc     $03A6                           ; AB15 EE A6 03                 ...
        ldy     $03A6                           ; AB18 AC A6 03                 ...
        jsr     GO_APPL_LOAD_GO_KERN            ; AB1B 20 53 03                  S.
        beq     LAB24                           ; AB1E F0 04                    ..
        cmp     #$0D                            ; AB20 C9 0D                    ..
        bne     LAB11                           ; AB22 D0 ED                    ..
LAB24:  lda     #$0D                            ; AB24 A9 0D                    ..
        clc                                     ; AB26 18                       .
        jsr     LB6F9_MAYBE_PUT_CHAR_IN_FKEY_BAR_SLOT                           ; AB27 20 F9 B6                  ..
        lda     #$67                            ; AB2A A9 67                    .g
        jsr     LAB50                           ; AB2C 20 50 AB                  P.
        bne     LAB33                           ; AB2F D0 02                    ..
        lda     #$A0                            ; AB31 A9 A0                    ..
LAB33:  sta     ($BD)                           ; AB33 92 BD                    ..
        lda     $03A5                           ; AB35 AD A5 03                 ...
        inc     $03A5                           ; AB38 EE A5 03                 ...
        cmp     V1541_FILE_TYPE                 ; AB3B CD A4 03                 ...
        bcc     LAB05                           ; AB3E 90 C5                    ..
        cmp     #$0E                            ; AB40 C9 0E                    ..
        bcs     LAB50                           ; AB42 B0 0C                    ..
        jsr     LAB57                           ; AB44 20 57 AB                  W.
        ldy     #$08                            ; AB47 A0 08                    ..
        lda     #$64                            ; AB49 A9 64                    .d
LAB4B:  sta     ($BD),y                         ; AB4B 91 BD                    ..
        dey                                     ; AB4D 88                       .
        bpl     LAB4B                           ; AB4E 10 FB                    ..
LAB50:  ldx     $03A5                           ; AB50 AE A5 03                 ...
        cpx     V1541_FILE_MODE                 ; AB53 EC A3 03                 ...
        rts                                     ; AB56 60                       `
; ----------------------------------------------------------------------------
LAB57:  ldx     $03A2                           ; AB57 AE A2 03                 ...
        ldy     LAB80,x                         ; AB5A BC 80 AB                 ...
        lda     #$08                            ; AB5D A9 08                    ..
        jsr     LAB50                           ; AB5F 20 50 AB                  P.
        bne     LAB66                           ; AB62 D0 02                    ..
        eor     #$80                            ; AB64 49 80                    I.
LAB66:  pha                                     ; AB66 48                       H
        lda     LAB70,x                         ; AB67 BD 70 AB                 .p.
        tax                                     ; AB6A AA                       .
        pla                                     ; AB6B 68                       h
        sec                                     ; AB6C 38                       8
        jmp     LB6F9_MAYBE_PUT_CHAR_IN_FKEY_BAR_SLOT                           ; AB6D 4C F9 B6                 L..
; ----------------------------------------------------------------------------
LAB70:  .byte   $0E                             ; AB70 0E                       .
LAB71:  .byte   $0D,$0C,$0B,$0A,$09,$08,$07,$06 ; AB71 0D 0C 0B 0A 09 08 07 06  ........
        .byte   $05,$04,$03,$02,$01,$00,$00     ; AB79 05 04 03 02 01 00 00     .......
LAB80:  .byte   $00,$0A,$14,$1E,$28,$32,$3C,$46 ; AB80 00 0A 14 1E 28 32 3C 46  ....(2<F
LAB88:  .byte   $09,$13,$1D,$27,$31,$3B,$45,$4F ; AB88 09 13 1D 27 31 3B 45 4F  ...'1;EO
; ----------------------------------------------------------------------------
LAB90:  php
        ldx     #$04
        bcc     LAB97
        ldx     #$06
LAB97:  clc
        jsr     LD230_JMP_LD233_PLUS_X  ;-> LD297_X_06
        ldx     V1541_FILE_TYPE
        lda     LAB71,x
        eor     #$E0
        pha
        ldx     $03A2
        ldy     LAB80,x
        lda     LAB88,x
        tax
        pla
        plp
        jmp     LA9E6
; ----------------------------------------------------------------------------
KR_ShowChar_:
        phx
        phy
        bit     $0384
        bpl     LABC1
        bvc     LABC4
        jsr     L8948
        bra     LABC4
LABC1:  jsr     LABC8
LABC4:  ply
        plx
        clc
        rts
; ----------------------------------------------------------------------------
LABC8:  bit     $0382
        bpl     LABD6
        stz     $0382
        jsr     ESC_O_CANCEL_MODES
        jsr     LAEA6
LABD6:  pha
LABD7:  php
        pla
        bit     #$04
        bne     LABED
        lda     $AA
        and     $036D
        and     #$02
        beq     LABED
        ldx     #$02
        jsr     WaitXticks_
        bra     LABD7
LABED:  pla
        ldx     $036E
        sta     $036E
        cmp     #$0D ;Return
        beq     LAC2F
        cmp     #$8D ;Shift-Return
        beq     LAC2F
        cpx     #$1B ;Escape
        bne     LAC03
        jmp     LB10E
; ----------------------------------------------------------------------------
LAC03:  cmp     #$1B ;Escape
        bne     LAC08
        rts
; ----------------------------------------------------------------------------
LAC08:  bit     $AA
        bpl     LAC24
        ldy     INSRT
        beq     LAC19
        cmp     #$94 ;Insert
        beq     LAC2F
        dec     INSRT
        jmp     LAC3A
; ----------------------------------------------------------------------------
LAC19:  jsr     LB08E
        ldy     QTSW
        beq     LAC24
        cmp     #$14 ;Delete
        bne     LAC3A
LAC24:  cmp     #$13 ;Home
        bne     LAC2F
        cpx     #$13
        bne     LAC2F
        jmp     LAE5B
; ----------------------------------------------------------------------------
LAC2F:  bit     #$20
        bne     LAC3A
        bit     #$40
        bne     LAC3A
        jmp     DO_CTRL_CODE
; ----------------------------------------------------------------------------
LAC3A:  jsr     LB09B
        ldx     REVERSE
        beq     LAC44
        ora     #$80
LAC44:  ldx     INSFLG
        beq     LAC4D
        pha
        jsr     CODE_94_INSERT
        pla
LAC4D:  jsr     PutCharAtCursorXY
LAC50:  ldx     CursorX
        cpx     WIN_BTM_RGHT_X
        beq     LAC59
        inc     CursorX
LAC58:  rts
; ----------------------------------------------------------------------------
LAC59:  lda     $AA
        bit     #$04
        beq     JMP_CTRL_1D_CRSR_RIGHT
        bit     #$20
        beq     LAC58
        ldy     CursorY
        jsr     LB059
        bcs     JMP_CTRL_1D_CRSR_RIGHT
        ldx     WIN_TOP_LEFT_X
        stx     CursorX
        ldy     CursorY
        sec
        jsr     LB06F
        ldy     CursorY
        cpy     WIN_BTM_RGHT_Y
        bne     LAC8E
        ldy     LSXP
        bmi     LAC88
        cpy     WIN_TOP_LEFT_Y
        beq     LAC88
        dec     LSXP
        bra     LAC8B
LAC88:  jsr     LB393
LAC8B:  jmp     LAF4B
; ----------------------------------------------------------------------------
LAC8E:  inc     CursorY
        jmp     LAF89
; ----------------------------------------------------------------------------
JMP_CTRL_1D_CRSR_RIGHT:
        jmp     CTRL_1D_CRSR_RIGHT
; ----------------------------------------------------------------------------
CTRL_CODES:
        .byte   $07 ;CHR$(7) Bell
        .addr   CODE_07_BELL

        .byte   $09 ;CHR$(9) Tab
        .addr   CODE_09_TAB

        .byte   $0A ;CHR$(10) Linefeed
        .addr   CODE_0A_LINEFEED

        .byte   $0D ;CHR$(13) Carriage Return
        .addr   CODE_0D_RETURN

        .byte   $0E ;CHR$(14) Lowercase Mode
        .addr   CODE_14_LOWERCASE

        .byte   $11 ;CHR$(17) Cursor Down
        .addr   CODE_11_CRSR_DOWN

        .byte   $12 ;CHR$(18) Reverse On
        .addr   CODE_12_RVS_ON

        .byte   $13 ;CHR$(19) Home
        .addr   CODE_13_HOME

        .byte   $14 ;CHR$(20) Delete
        .addr   CODE_14_DELETE

        .byte   $18 ;CHR$(24) Set or Clear Tab
        .addr   CODE_18_CTRL_X

        .byte   $19 ;CHR$(25) CTRL-Y Lock (Disables Shift-Commodore)
        .addr   CODE_19_CTRL_Y_LOCK

        .byte   $1A ;CHR$(26) CTRL-Z Unlock (Enables Shift-Commodore)
        .addr   CODE_1A_CTRL_Z_UNLOCK

        .byte   $1D ;CHR$(29) Cursor Right
        .addr   CTRL_1D_CRSR_RIGHT

        .byte   $8D ;CHR$(141) Shift-Return
        .addr   CODE_8D_SHIFT_RETURN

        .byte   $8E ;CHR$(142) Uppercase Mode
        .addr   CODE_8E_UPPERCASE

        .byte   $91 ;CHR$(145) Cursor Up
        .addr   CODE_91_CRSR_UP

        .byte   $92 ;CHR$(146) Reverse Off
        .addr   CODE_92_RVS_OFF

        .byte   $93 ;CHR$(147) Clear Screen
        .addr   CODE_93_CLR_SCR

        .byte   $94 ;CHR$(148) Insert
        .addr   CODE_94_INSERT

        .byte   $9D ;CHR$(157) Cursor Left
        .addr   CODE_9D_CRSR_LEFT
; ----------------------------------------------------------------------------
DO_CTRL_CODE:
        ldx     #$39
LACD4:  cmp     CTRL_CODES,x
        beq     JMP_TO_CTRL_CODE
        dex
        dex
        dex
        bpl     LACD4
        rts
; ----------------------------------------------------------------------------
JMP_TO_CTRL_CODE:
        jmp     (CTRL_CODES+1,x)
; ----------------------------------------------------------------------------
;CHR$(25) CTRL-Y Lock
;Disables switching uppercase/lowercase mode when Shift-Commodore is pressed
CODE_19_CTRL_Y_LOCK:
        lda     #$40
        tsb     $036D
        rts
; ----------------------------------------------------------------------------
;CHR$(26) CTRL-Z Unlock
CODE_1A_CTRL_Z_UNLOCK:
;Enables switching uppercase/lowercase mode when Shift-Commodore is pressed
        lda     #$40
        trb     $036D
        rts
; ----------------------------------------------------------------------------
;Switch between uppercase and lowercase character sets
;Called from KBD_READ_MODIFIER_KEYS_DO_SWITCH_AND_CAPS
;when Shift + Commodore is pressed
SWITCH_CHARSET:
        bit     $036D
        bvs     CODE_19_CTRL_Y_LOCK ;If locked, branch to re-lock (does nothing) and return

        lda     #$01
        tsb     SETUP_LCD_A  ;Uppercase mode
        beq     JmpToSetUpLcdController
        ;Fall through to set lowercase mode

;CHR$(14) Lowercase Mode
CODE_14_LOWERCASE:
        lda     #$01
        trb     SETUP_LCD_A
        bne     JmpToSetUpLcdController
        rts
; ----------------------------------------------------------------------------
;CHR$(142) Uppercase Mode
CODE_8E_UPPERCASE:
        lda     #$01
        tsb     SETUP_LCD_A
        beq     JmpToSetUpLcdController
        rts
; ----------------------------------------------------------------------------
JmpToSetUpLcdController:
        sec
        jmp     LCDsetupGetOrSet
; ----------------------------------------------------------------------------
;CHR$(9) Tab
CODE_09_TAB:
        ldx     CursorX
        cpx     WIN_BTM_RGHT_X
        beq     LAD27
        lda     #$1D
        ldx     INSFLG
        beq     LAD1C
        lda     #$20
LAD1C:  jsr     LABD6
        jsr     CursorXtoTabMapIndex
        and     TABMAP,y
        beq     CODE_09_TAB
LAD27:  rts
; ----------------------------------------------------------------------------
CursorXtoTabMapIndex:
        lda     CursorX
        lsr     a
        lsr     a
        lsr     a
        tay
        lda     CursorX
        and     #$07
        tax
        lda     PowersOfTwo,x
        rts
; ----------------------------------------------------------------------------
;CHR$(24) CTRL-X
;Set or clear tab at current position
CODE_18_CTRL_X:
        jsr     CursorXtoTabMapIndex
        eor     TABMAP,y
        sta     TABMAP,y
        rts
; ----------------------------------------------------------------------------
;ESC-Y Set default tab stops (8 spaces)
ESC_Y_SET_DEFAULT_TABS:
        lda     #$80
        .byte   $2C

;ESC-Z Clear all tab stops
ESC_Z_CLEAR_ALL_TABS:
        lda     #$00
        ldx     #$09
LAD48:  sta     TABMAP,x
        dex
        bpl     LAD48
        rts
; ----------------------------------------------------------------------------
;CHR$(13) Carriage Return
;CHR$(141) Shift-Return
CODE_0D_RETURN:
CODE_8D_SHIFT_RETURN:
        lda     $AA
        lsr     a
        bcc     LAD65

        ;Check if the CTRL key is being pressed.  If so, and no interrupt
        ;is pending, pause before doing the linefeed.  This allows the user
        ;to slow down screen scrolling during LIST or DIRECTORY in BASIC.
        lda     #MOD_CTRL
        bit     MODKEY
        beq     LAD65 ;Branch to skip pause if CTRL is not down

        ;CTRL key being pressed
        php           ;Push processor status to test it
        pla           ;A = NV-BDIZC
        bit     #$04  ;Test Interrupt flag
        bne     LAD65 ;Branch to skip pause if interrupt flag is set

        ;Pause before doing the linefeed
        ldx     #$2D
        jsr     WaitXticks_

LAD65:  jsr     ESC_K_MOVE_TO_END_OF_LINE
        ldx     WIN_TOP_LEFT_X
        stx     CursorX
        jsr     CODE_0A_LINEFEED
        jmp     ESC_O_CANCEL_MODES
; ----------------------------------------------------------------------------
;CHR$(18) Reverse On
CODE_12_RVS_ON:
        lda     #$80
        sta     REVERSE
        rts
; ----------------------------------------------------------------------------
;CHR$(145) Cursor Up
CODE_91_CRSR_UP:
        ldy     CursorY
        cpy     WIN_TOP_LEFT_Y
        beq     LAD8A
        dec     CursorY
        dey
        jsr     LB059
        bcs     LAD89
        jsr     LB393
LAD89:  rts
; ----------------------------------------------------------------------------
LAD8A:  lda     #$10
        bit     $AA
        bne     LAD91
        rts
; ----------------------------------------------------------------------------
LAD91:  jsr     LB393
        bit     $AA
        bvc     LADA0
        jsr     LAF89
        ldy     WIN_TOP_LEFT_Y
        sty     CursorY
        rts
; ----------------------------------------------------------------------------
LADA0:  ldy     WIN_BTM_RGHT_Y
        sty     CursorY
        rts
; ----------------------------------------------------------------------------
;CHR$(10) Linefeed
;CHR$(17) Cursor Down
CODE_0A_LINEFEED:
CODE_11_CRSR_DOWN:
        ldy     CursorY
        cpy     WIN_BTM_RGHT_Y
        beq     LADB6
        jsr     LB059
        bcs     LADB3
        jsr     LB393
LADB3:  inc     CursorY
        rts
; ----------------------------------------------------------------------------
LADB6:  lda     #$08
        bit     $AA
        bne     LADBD
        rts
; ----------------------------------------------------------------------------
LADBD:  jsr     LB393
        bit     $AA
        bvc     LADCC
        jsr     LAF4B
        ldy     WIN_BTM_RGHT_Y
        sty     CursorY
        rts
; ----------------------------------------------------------------------------
LADCC:  ldy     WIN_TOP_LEFT_Y
        sty     CursorY
        rts
; ----------------------------------------------------------------------------
;CHR$(29) Cursor Right
CTRL_1D_CRSR_RIGHT:
        ldx     WIN_BTM_RGHT_X
        cpx     CursorX
        beq     LADDA
        inc     CursorX
        rts
; ----------------------------------------------------------------------------
LADDA:  ldy     CursorY
        cpy     WIN_BTM_RGHT_Y
        beq     LADEF
        jsr     LB059
        bcs     LADE8
        jsr     LB393
LADE8:  inc     CursorY
        ldx     WIN_TOP_LEFT_X
        stx     CursorX
        rts
; ----------------------------------------------------------------------------
LADEF:  lda     $AA
        bit     #$08
        bne     LADF6
        rts
; ----------------------------------------------------------------------------
LADF6:  ldx     WIN_TOP_LEFT_X
        stx     CursorX
        jsr     LB393
        bit     #$40
        bne     LAE04
        jmp     CODE_13_HOME
; ----------------------------------------------------------------------------
LAE04:  ldy     CursorY
        jmp     LAF4B
; ----------------------------------------------------------------------------
;CHR$(157) Cursor Left
CODE_9D_CRSR_LEFT:
        ldx     CursorX
        cpx     WIN_TOP_LEFT_X
        beq     LAE12
        dec     CursorX
        rts
; ----------------------------------------------------------------------------
LAE12:  ldy     CursorY
        cpy     WIN_TOP_LEFT_Y
        beq     LAE28
        .byte   $C6
LAE19:  ldx     #$A6
        ldy     $86
        lda     ($88,x)
        jsr     LB059
        bcs     LAE27
        jsr     LB393
LAE27:  rts
; ----------------------------------------------------------------------------
LAE28:  lda     $AA
        bit     #$10
        bne     LAE2F
        rts
; ----------------------------------------------------------------------------
LAE2F:  jsr     LB393
        ldx     WIN_BTM_RGHT_X
        stx     CursorX
        bit     $AA
        bvc     LAE42
        jsr     LAF89
        ldy     WIN_TOP_LEFT_Y
        sty     CursorY
        rts
; ----------------------------------------------------------------------------
LAE42:  ldy     WIN_BTM_RGHT_Y
        sty     CursorY
        rts
; ----------------------------------------------------------------------------
;CHR$(147) Clear Screen
CODE_93_CLR_SCR:
        jsr     CODE_13_HOME
        ldy     WIN_BTM_RGHT_Y
LAE4C:  sty     CursorY
        jsr     ESC_D_DELETE_LINE
        ldy     CursorY
        dey
        cpy     WIN_TOP_LEFT_Y
        bpl     LAE4C
        jmp     LB087
; ----------------------------------------------------------------------------
LAE5B:  ldx     L0380
        stx     WIN_TOP_LEFT_X
        ldx     CurMaxX
        stx     WIN_BTM_RGHT_X
        ldy     $037F
LAE68:  sty     WIN_TOP_LEFT_Y
        ldy     CurMaxY
        sty     WIN_BTM_RGHT_Y
;CHR$(19) Home
CODE_13_HOME:
        jsr     LB393
        ldx     WIN_TOP_LEFT_X
        stx     CursorX
        ldy     WIN_TOP_LEFT_Y
        sty     CursorY
        rts
; ----------------------------------------------------------------------------
;CHR$(20) Delete
CODE_14_DELETE:
        jsr     CODE_9D_CRSR_LEFT
        jsr     SaveCursorXY
LAE81:  ldx     CursorX
        cpx     WIN_BTM_RGHT_X
        bne     LAE8E
        ldy     CursorY
        jsr     LB059
        bcc     LAEA1
LAE8E:  jsr     CTRL_1D_CRSR_RIGHT
        jsr     GetCharAtCursorXY
        pha
        jsr     CODE_9D_CRSR_LEFT
        pla
        jsr     PutCharAtCursorXY
        jsr     CTRL_1D_CRSR_RIGHT
        bra     LAE81
LAEA1:  lda     #' '
        jsr     PutCharAtCursorXY
LAEA6:  ldx     SavedCursorX
        ldy     SavedCursorY
        stx     CursorX
        sty     CursorY
        rts
; ----------------------------------------------------------------------------
SaveCursorXY:
        ldx     CursorX
        ldy     CursorY
        stx     SavedCursorX
        sty     SavedCursorY
        rts
; ----------------------------------------------------------------------------
CompareCursorXYtoSaved:
        ldx     CursorX
        ldy     CursorY
        cpy     SavedCursorY
        bne     LAEC8
        cpx     SavedCursorX
LAEC8:  rts
; ----------------------------------------------------------------------------
;CHR$(148) Insert
CODE_94_INSERT:
        inc     INSRT
        bne     LAECF
        dec     INSRT
LAECF:  ldx     INSFLG
        beq     LAED5
        stz     INSRT
LAED5:  lda     #' '
        pha
        jsr     SaveCursorXY
        dec     CursorX
LAEDD:  jsr     LAC50
        jsr     GetCharAtCursorXY
        tax
        pla
        sta     (VidPtrLo)
        phx
        lda     CursorX
        cmp     WIN_BTM_RGHT_X
        bne     LAEDD
        lda     $AA
        bit     #$20
        beq     LAF16
        bit     #$04
        beq     LAF16
        cpx     #$20
        beq     LAF0F
        ldy     CursorY
        cpy     WIN_BTM_RGHT_Y
        bne     LAEDD
        ldy     SavedCursorY
        dey
        cpy     WIN_TOP_LEFT_Y
        bmi     LAEDD
        sty     SavedCursorY
        bra     LAEDD
LAF0F:  ldy     CursorY
        jsr     LB059
        bcs     LAEDD
LAF16:  pla
        jmp     LAEA6
; ----------------------------------------------------------------------------
PutSpaceAtCursorXY:
        lda     #' '
PutCharAtCursorXY:
        ldx     CursorX
        ldy     CursorY
        pha
        jsr     XYregsToVidPtrStuff
        pla
        sta     (VidPtrLo)
        rts
; ----------------------------------------------------------------------------
CursorXYtoVidPtrStuff:
        ldy     CursorY
        ldx     CursorX
XYregsToVidPtrStuff:
        cld
        txa
        asl     a
        sta     VidPtrLo
        tya
        lsr     a
        ror     VidPtrLo
        adc     VidMemHi
        sta     VidPtrHi
        rts
; ----------------------------------------------------------------------------
LAF3A:  cld
        sec
        lda     WIN_BTM_RGHT_X
        sbc     WIN_TOP_LEFT_X
        rts
; ----------------------------------------------------------------------------
GetCharAtCursorXY:
        ldx     CursorX
        ldy     CursorY
        jsr     XYregsToVidPtrStuff
        lda     (VidPtrLo)
        rts
; ----------------------------------------------------------------------------
LAF4B:  ldy     WIN_TOP_LEFT_Y
        cpy     CursorY
        beq     LAF7C
        ldx     WIN_TOP_LEFT_X
        jsr     XYregsToVidPtrStuff
        jsr     LAF3A
        sta     $F3
        ldx     WIN_TOP_LEFT_Y
LAF5D:  lda     VidPtrLo
        ldy     VidPtrHi
        sta     $F1
        sty     $F2
        eor     #$80
        sta     VidPtrLo
        bmi     LAF6E
        iny
        sty     VidPtrHi
LAF6E:  ldy     $F3
LAF70:  lda     (VidPtrLo),y
        sta     ($F1),y
        dey
        bpl     LAF70
        inx
        cpx     CursorY
        bne     LAF5D
LAF7C:  jsr     LAFD3
        lda     #$C0
        tsb     $037D
        ldy     CursorY
        jmp     ESC_D_DELETE_LINE
; ----------------------------------------------------------------------------
LAF89:  ldy     CursorY
        cpy     WIN_BTM_RGHT_Y
        beq     ESC_D_DELETE_LINE
        jsr     LAF3A
        sta     $F3
        ldy     WIN_BTM_RGHT_Y
LAF96:  phy
        ldx     WIN_TOP_LEFT_X
        jsr     XYregsToVidPtrStuff
        lda     VidPtrLo
        ldy     VidPtrHi
        eor     #$80
        bpl     LAFA5
        dey
LAFA5:  sta     $F1
        sty     $F2
        ldy     $F3
LAFAB:  lda     ($F1),y
        sta     (VidPtrLo),y
        dey
        bpl     LAFAB
        ply
        dey
        cpy     CursorY
        bne     LAF96
        jsr     LAFF3
        lda     #$80
        tsb     $037D

;ESC-D Delete the current line
ESC_D_DELETE_LINE:
        ldy     CursorY
        ldx     WIN_TOP_LEFT_X
        jsr     XYregsToVidPtrStuff
        jsr     LAF3A
        tay
        lda     #' '
LAFCD:  sta     (VidPtrLo),y
        dey
        bpl     LAFCD
        rts
; ----------------------------------------------------------------------------
LAFD3:  jsr     LB020
        eor     $F1
        and     $036A,x
        sta     $F1
        lda     $036A,x
        and     $F2
        lsr     a
        ora     $F1
        sta     $036A,x
        rol     $036A,x
LAFEB:  ror     $036A,x
        dex
        bpl     LAFEB
        bra     LB013
LAFF3:  jsr     LB020
        eor     $F2
        and     $036A,x
        sta     $F2
        lda     $036A,x
        and     $F1
        asl     a
        ora     $F2
        sta     $036A,x
        .byte   $7E
        ror     a
        .byte   $03
LB00B:  rol     $036A,x
        inx
        cpx     #$02
        bne     LB00B
LB013:  ldy     WIN_TOP_LEFT_Y
        beq     LB01B
        dey
        jsr     LB07B
LB01B:  ldy     WIN_BTM_RGHT_Y
        jmp     LB07B
; ----------------------------------------------------------------------------
LB020:  ldy     $a2
        tya
        and     #$07                            ; B023 29 07                    ).
        tax                                     ; B025 AA                       .
        lda     LB049,x                         ; B026 BD 49 B0                 .I.
        sta     $F2                             ; B029 85 F2                    ..
        lda     LB051,x                         ; B02B BD 51 B0                 .Q.
        sta     $F1                             ; B02E 85 F1                    ..
LB030:  tya                                     ; B030 98                       .
        and     #$07                            ; B031 29 07                    ).
        tax                                     ; B033 AA                       .
        lda     PowersOfTwo,x                   ; B034 BD 41 B0                 .A.
        pha                                     ; B037 48                       H
        tya                                     ; B038 98                       .
        lsr     a                               ; B039 4A                       J
        lsr     a                               ; B03A 4A                       J
        lsr     a                               ; B03B 4A                       J
        and     #$01                            ; B03C 29 01                    ).
        tax                                     ; B03E AA                       .
        pla                                     ; B03F 68                       h
        rts                                     ; B040 60                       `
; ----------------------------------------------------------------------------
PowersOfTwo:
        .byte   $01,$02,$04,$08,$10,$20,$40,$80 ; B041 01 02 04 08 10 20 40 80  ..... @.
LB049:  .byte   $01,$03,$07,$0F,$1F,$3F,$7F,$FF ; B049 01 03 07 0F 1F 3F 7F FF  .....?..
LB051:  .byte   $FF,$FE,$FC,$F8,$F0,$E0,$C0,$80 ; B051 FF FE FC F8 F0 E0 C0 80  ........
; ----------------------------------------------------------------------------
LB059:  lda     #$04
        and     $AA
        beq     LB06D
        cpy     #$10
        bcs     LB06D
        jsr     LB030
        and     $036A,x
        beq     LB06D
        sec
        rts
; ----------------------------------------------------------------------------
LB06D:  clc
        rts
; ----------------------------------------------------------------------------
LB06F:  bcc     LB07B
        jsr     LB030
        ora     $036A,x
        sta     $036A,x
        rts
; ----------------------------------------------------------------------------
LB07B:  .byte   $20                             ; B07B 20
        .byte   $30                             ; B07C 30                       0
LB07D:  bcs     LB0C8                           ; B07D B0 49                    .I
        bbs7    $3D,LB0ED-1                     ; B07F FF 3D 6A                 .=j
        .byte   $03                             ; B082 03                       .
        sta     $036A,x                         ; B083 9D 6A 03                 .j.
        rts                                     ; B086 60                       `
; ----------------------------------------------------------------------------
LB087:  stz     $036A                           ; B087 9C 6A 03                 .j.
        stz     $036B                           ; B08A 9C 6b 03
        rts                                     ; B08D 60                       `
; ----------------------------------------------------------------------------
LB08E:  cmp     #$22
        bne     LB09A
        bit     QTSW
        stz     QTSW
        bvs     LB09A
        dec     QTSW
LB09A:  rts
; ----------------------------------------------------------------------------
LB09B:  cmp     #$FF
        bne     LB0A2
        lda     #$5E
        rts
; ----------------------------------------------------------------------------
LB0A2:  phx
        pha
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        tax
        pla
        eor     LB0B0,x
        plx
        rts
; ----------------------------------------------------------------------------
LB0B0:  .byte   $80,$00                         ; B0B0 80 00                    ..
        .byte   $40,$20,$40,$C0,$80,$80         ; B0B2 40 20 40 C0 80 80        @ @...
; ----------------------------------------------------------------------------
LB0B8:  sta     $F1
        and     #$3F
        asl     $F1
        bit     $F1
        bpl     LB0C4
        ora     #$80
LB0C4:  bcc     LB0CA
        ldx     QTSW
LB0C8:  bne     LB0CE
LB0CA:  bvs     LB0CE
        ora     #$40
LB0CE:  cmp     #$DE
        bne     LB0D4
        lda     #$FF
LB0D4:  rts
; ----------------------------------------------------------------------------
;Screen Editor escape codes
;
;These are very similar to the C128 escape codes;
;see the C128 Programmer's Reference Guide for the list.
;
;C128 codes missing on the LCD:
;  ESC-G (Enable Bell)
;  ESC-H (Disable Bell)
;  ESC-N (Return screen to normal video)
;  ESC-R (Set screen to reverse video)
;  ESC-S (Change to block cursor)
;  ESC-U (Change to underline cursor)
;  ESC-X (Swap 40/80 column output device)
;
LB0D5:  .byte   "A"
        .addr   ESC_A_AUTOINSERT_ON

        .byte   "B"
        .addr   ESC_B_SET_WIN_BTM_RIGHT

        .byte   "C"
        .addr   ESC_C_AUTOINSERT_OFF

        .byte   "D"
        .addr   ESC_D_DELETE_LINE

        .byte   "E"
        .addr   ESC_E_CRSR_BLINK_OFF

        .byte   "F"
        .addr   ESC_F_CRSR_BLINK_ON

        ;ESC-G (Enable Bell) and ESC-H (Disable Bell)
        ;from C128 are missing

LB0E7:  .byte   "I"
        .addr   ESC_I_INSERT_LINE

        .byte   "J"
        .addr   ESC_J_MOVE_TO_START_OF_LINE

LB0ED:  .byte   "K"
        .addr   ESC_K_MOVE_TO_END_OF_LINE

        .byte   "L"
        .addr   ESC_L_SCROLLING_ON

        .byte   "M"
        .addr   ESC_M_SCROLLING_OFF

        ;ESC-N (Normal video) and ESC-R (Reverse Video)
        ;from C128 are missing

        .byte   "O"
        .addr   ESC_O_CANCEL_MODES

        .byte   "P"
        .addr   ESC_P_ERASE_TO_START_OF_LINE

LB0FC:  .byte   "Q"
        .addr   ESC_Q_ERASE_TO_END_OF_LINE

        ;ESC-S (Block cursor) and ESC-U (Underline cursor)
        ;from C128 are missing

        .byte   "T"
        .addr   ESC_T_SET_WIN_TOP_LEFT

        .byte   "V"
        .addr   ESC_V_SCROLL_UP

        .byte   "W"
        .addr   ESC_W_SCROLL_DOWN

        ;ESC-X (Swap 40/80 column output device)
        ;from C128 is missing

        .byte   "Y"
        .addr   ESC_Y_SET_DEFAULT_TABS

        .byte   "Z"
        .addr   ESC_Z_CLEAR_ALL_TABS
; ----------------------------------------------------------------------------
LB10E:  bit     $036E
        bmi     LB126
        bvc     LB126
        lda     $036E
        and     #$DF
        ldx     #$36
LB11C:  cmp     LB0D5,x
        beq     LB127
        dex
        dex
        dex
        bpl     LB11C
LB126:  rts
; ----------------------------------------------------------------------------
LB127:  jmp     (LB0D5+1,x)
; ----------------------------------------------------------------------------
;ESC-A Enable auto-insert mode
ESC_A_AUTOINSERT_ON:
        sta     INSFLG ;Auto-insert = nonzero (on)
        stz     INSRT  ;Insert count = 0
        rts
; ----------------------------------------------------------------------------
;ESC-B Set bottom right of screen window at current position
ESC_B_SET_WIN_BTM_RIGHT:
        ldx     CursorX
        stx     WIN_BTM_RGHT_X
        ldy     CursorY
        sty     WIN_BTM_RGHT_Y
        jmp     LB087
; ----------------------------------------------------------------------------
;ESC-C Disable auto-insert mode
ESC_C_AUTOINSERT_OFF:
        stz     INSFLG
        rts
; ----------------------------------------------------------------------------
;ESC-I Insert line
ESC_I_INSERT_LINE:
        jsr     LAF89
        ldy     CursorY
        dey
        jsr     LB059
        iny
        jmp     LB06F
; ----------------------------------------------------------------------------
;ESC-J Move to start of current line
ESC_J_MOVE_TO_START_OF_LINE:
        ldx     WIN_TOP_LEFT_X
        stx     CursorX
        ldy     CursorY
LB150:  dey
        jsr     LB059
        bcs     LB150
        iny
        sty     CursorY
        rts
; ----------------------------------------------------------------------------
;ESC-K Move to end of current line
ESC_K_MOVE_TO_END_OF_LINE:
        dec     CursorY
LB15C:  inc     CursorY
        ldy     CursorY
        jsr     LB059
        bcs     LB15C
        ldx     WIN_BTM_RGHT_X
        stx     CursorX
        bra     LB16E
LB16B:  jsr     CODE_9D_CRSR_LEFT
LB16E:  jsr     GetCharAtCursorXY
        cmp     #$20
        bne     LB17F
        cpx     WIN_TOP_LEFT_X
        bne     LB16B
        dey
        jsr     LB059
        bcs     LB16B
LB17F:  rts
; ----------------------------------------------------------------------------
;ESC-L Enable scrolling
ESC_L_SCROLLING_ON:
        lda     #$40
        tsb     $AA
        rts
; ----------------------------------------------------------------------------
;ESC-M Disable scrolling
ESC_M_SCROLLING_OFF:
        lda     #$40
        trb     $AA
        rts
; ----------------------------------------------------------------------------
;ESC-Q Erase to end of current line
ESC_Q_ERASE_TO_END_OF_LINE:
        jsr     SaveCursorXY
        jsr     ESC_K_MOVE_TO_END_OF_LINE
        jsr     CompareCursorXYtoSaved
        bcs     LB19E
        jmp     LAEA6
; ----------------------------------------------------------------------------
;ESC-P Erase to start of current line
ESC_P_ERASE_TO_START_OF_LINE:
        jsr     SaveCursorXY
        jsr     ESC_J_MOVE_TO_START_OF_LINE
LB19E:  jsr     PutSpaceAtCursorXY
        jsr     CompareCursorXYtoSaved
        bne     LB1A7
        rts
LB1A7:  bpl     LB1AE
        jsr     CTRL_1D_CRSR_RIGHT
        bra     LB19E
LB1AE:  jsr     CODE_9D_CRSR_LEFT
        bra     LB19E
; ----------------------------------------------------------------------------
;ESC-T Set top left of screen window at cursor position
ESC_T_SET_WIN_TOP_LEFT:
        ldx     CursorX
        ldy     CursorY
        stx     WIN_TOP_LEFT_X
        sty     WIN_TOP_LEFT_Y
        jmp     LB087
; ----------------------------------------------------------------------------
;ESC-V Scroll up
ESC_V_SCROLL_UP:
        jsr     SaveCursorXY
        ldy     WIN_BTM_RGHT_Y
        sty     CursorY
        jsr     LAF4B
        bra     LB1D4
;ESC-W Scroll down
ESC_W_SCROLL_DOWN:
        jsr     SaveCursorXY
        ldy     WIN_TOP_LEFT_Y
        sty     CursorY
        jsr     LAF89
LB1D4:  jsr     LB393
        jmp     LAEA6
; ----------------------------------------------------------------------------
;Start the screen editor
SCINIT_:
        jsr     LB2E4_HIDE_CURSOR
        lda     #>$0828
        sta     VidMemHi
        ldx     #<$0828
        stx     $0368
        ldy     #$10
        sty     $0369
        lda     #16-1
        sta     CurMaxY
        lda     #80-1
        sta     CurMaxX
        stz     $037F
        stz     L0380
        jsr     LAE5B
        lda     #$00
        tax
        ldy     VidMemHi
        clc
        jsr     LCDsetupGetOrSet
        jsr     CODE_93_CLR_SCR
        stz     QTSW
        stz     $0382
        stz     INSFLG
        stz     $036E
        stz     INSFLG
        lda     #$ED
        sta     $AA
        stz     BLNOFF ;Blink = on
        jsr     ESC_Y_SET_DEFAULT_TABS
;ESC-O Cancel insert, quote, reverse modes
ESC_O_CANCEL_MODES:
        stz     QTSW  ;Quote mode = off
        stz     INSRT ;# chars to insert = 0
        ;Fall through to cancel reverse
;CHR$(146) Reverse Off
CODE_92_RVS_OFF:
        stz     REVERSE ;Reverse mode = off
        rts
; ----------------------------------------------------------------------------
LCDsetupGetOrSet:
; This routine is called by RESET routine, with carry set.
; It seems it's the only part where locations $FF80 - $FF83 are written.
; $FF80-$FF83 is the write-only registers of the LCD controller.
; It's called first with carry set from $87B5,
; then called second with carry clear from $B204
        php
        sei
        bcc     LCDsetupSet
        lda     SETUP_LCD_A
        ldx     SETUP_LCD_X
        ldy     SETUP_LCD_Y
LCDsetupSet:
        and     #$03
        sta     SETUP_LCD_A
        stx     SETUP_LCD_X
        sty     SETUP_LCD_Y
        ora     #$08
        sta     LCDCTRL_REG2
        sta     LCDCTRL_REG3
        stx     LCDCTRL_REG0
        tya
        asl     a
        sta     LCDCTRL_REG1
        lda     SETUP_LCD_A
        plp
        rts
; ----------------------------------------------------------------------------
EDITOR_LOCS:
        .word   $00A1,$00A2,$00A3,$00A4
        .word   $00A6,$00A5,$00A7,$037D
        .word   $00A8,$00A9,$00AA,BLNOFF
        .word   REVERSE,$036D,$036A,$036B
        .word   $036E,TABMAP,TABMAP+1,TABMAP+2
        .word   TABMAP+3,TABMAP+4,TABMAP+5,TABMAP+6
        .word   TABMAP+7,TABMAP+8,TABMAP+9,$00A0
        .word   SETUP_LCD_A,SETUP_LCD_X,SETUP_LCD_Y
; ----------------------------------------------------------------------------
LB293:  stx     $F1
        sty     $F2
        jsr     LB2E4_HIDE_CURSOR
        stz     $0382
        lda     #$F1 ;ZP-address
        sta     SINNER
        sta     $0360
        ldy     #$00
        ldx     #$00
LB2A9_LOOP:
        lda     EDITOR_LOCS,x
        sta     VidPtrLo
        lda     EDITOR_LOCS+1,x
        sta     VidPtrHi

        lda     (VidPtrLo)
        pha
        jsr     GO_RAM_LOAD_GO_KERN
        sta     (VidPtrLo)
        pla
        jsr     GO_RAM_STORE_GO_KERN
        iny
        inx
        inx
        cpx     #$3E
        bne     LB2A9_LOOP
LB2C6_SEC_JMP_LCDsetupGetOrSet:
        sec
        jmp     LCDsetupGetOrSet
; ----------------------------------------------------------------------------
;ESC-E Set cursor to nonflashing mode
ESC_E_CRSR_BLINK_OFF:
        lda     #$80
        tsb     BLNOFF ;Blink=0x80 (Off)
        rts
; ----------------------------------------------------------------------------
;ESCF-F Set cursor to flashing mode
ESC_F_CRSR_BLINK_ON:
        lda     #$80
        trb     BLNOFF ;Blink=0 (On)
        rts
; ----------------------------------------------------------------------------
LB2D6_SHOW_CURSOR:
        jsr     LB2E4_HIDE_CURSOR
        jsr     CursorXYtoVidPtrStuff
        lda     (VidPtrLo)
        sta     $F0
        sec
        ror     $EF
        rts
; ----------------------------------------------------------------------------
LB2E4_HIDE_CURSOR:
        lda     #$FF
        trb     $EF
        beq     LB2EE
        lda     $F0
        sta     (VidPtrLo)
LB2EE:  rts
; ----------------------------------------------------------------------------
;Blink the cursor
;Called at 60 Hz by the default IRQ handler (see LFA44_VIA1_T1_IRQ).
BLINK:  lda     $0384
        bne     BLINK_RTS

        bit     BLNCT
        bpl     BLINK_RTS

        dec     BLNCT
        bmi     BLINK_RTS

        bit     BLNOFF
        bmi     LB305 ;Branch if blink is off

        lda     #$A0
        sta     BLNCT

LB305:  lda     $F0
        cmp     (VidPtrLo)
        bne     BLINK_STORE_AS_IS
        bit     CAPS_FLAGS
        bpl     BLINK_RVS_AND_STORE ;Branch if caps lock is off
        ;Caps lock is off
        and     #$80
        ora     #$1E ;probably makes "^" cursor when in caps mode
BLINK_RVS_AND_STORE:
        eor     #$80
BLINK_STORE_AS_IS:
        sta     (VidPtrLo)
BLINK_RTS:
        rts
; ----------------------------------------------------------------------------
LB319_CHRIN_DEV_3_SCREEN:
        lda     $80
        tsb     $0382
        bne     LB362
        jsr     LB393
        bra     LB349

;CHRIN from keyboard
;Unlike other devices, CHRIN for the keyboard doesn't read one byte.  It
;reads keys until RETURN is pressed.  It returns one character from the
;input on the first call.  Each subsequent call returns the next character,
;until the end is reached, where 0x0D (return) is returned.
LB325_CHRIN_KEYBOARD:
        lda     #$80
        tsb     $0382
        bne     LB362
        jsr     SaveCursorXY
        stx     LSTP
        sty     LSXP
        bra     LB33A     ;blink cursor until return

LB337_LOOP:
        jsr     LABD6
;Input a line until carriage return
LB33A:  jsr     LB2D6_SHOW_CURSOR
        jsr     LB6DF_GET_KEY_BLOCKING
        pha
        jsr     LB2E4_HIDE_CURSOR
        pla
        cmp     #$0D  ;Return
        bne     LB337_LOOP
LB349:  stz     QTSW ;Quote mode = off
        jsr     ESC_K_MOVE_TO_END_OF_LINE
        jsr     SaveCursorXY
        ldy     LSXP
        bmi     LB35F
        sty     CursorY
        ldx     LSTP
        stx     CursorX
        bra     LB362

LB35F:  jsr     ESC_J_MOVE_TO_START_OF_LINE

LB362:  jsr     CompareCursorXYtoSaved
        bcc     LB36E
        lda     #$40
        tsb     $0382
        bne     LB387
LB36E:  jsr     GetCharAtCursorXY
        jsr     LB0B8
        jsr     LB08E
        bit     $0382
        bvs     LB383
        pha
        jsr     CTRL_1D_CRSR_RIGHT
        pla
LB381:  clc
        rts
; ----------------------------------------------------------------------------
LB383:  cmp     #' '
        bne     LB381
LB387:  jsr     ESC_K_MOVE_TO_END_OF_LINE
        stz     QTSW ;Quote mode = off
        stz     $0382
        lda     #$0D
        clc
        rts
; ----------------------------------------------------------------------------
LB393:  stz     LSXP
        dec     LSXP
        rts

; ----------------------------------------------------------------------------
; Keyboard Matrix Tables
; There are 5 tables representing combinations of the MODIFIER keys:
; 1. NO MODIFIER				NOTE:
; 2. SHIFT					    Keys shown assume TEXT mode
; 3. CAPS-LOCK					IE: $41 is "a" (which is opposite to ASCII)
; 4. COMMODORE
; 5. CTRL
;
; KEY: GR=Graphic Symbol			Character Changes:
;      S- Shifted				      126/$7E = PI
;      C- Control				      127/$7F = "|" (pipe)
;      {} Unknown Code				166/$A6 = "{"
;						                  168/$A8 = "}"
;
;NORMAL (no modifier key)                         C0     C1    C2    C3    C4    C5    C6    C7
KBD_MATRIX_NORMAL:                              ; ----- ----- ----- ----- ----- ----- ----- -----
        .byte   $40,$87,$86,$85,$88,$09,$0D,$14 ; @     F5    F3    F1    F7    TAB   RETRN DEL
        .byte   $8A,$45,$53,$5A,$34,$41,$57,$33 ; F4    e     s     z     4     a     w     3
        .byte   $58,$54,$46,$43,$36,$44,$52,$35 ; x     t     f     c     6     d     r     5
        .byte   $56,$55,$48,$42,$38,$47,$59,$37 ; v     u     h     b     8     g     y     7
        .byte   $4E,$4F,$4B,$4D,$30,$4A,$49,$39 ; n     o     k     m     0     j     i     9
        .byte   $2C,$2D,$3A,$2E,$91,$4C,$50,$11 ; ,     -     :     .     UP    l     p     DOWN
        .byte   $2F,$2B,$3D,$1B,$1D,$3B,$2A,$9D ; /     +     =     ESC   RIGHT ;     *     LEFT
        .byte   $8B,$51,$8C,$20,$32,$89,$13,$31 ; F6    q     F8    SPACE 2     F2    HOME  1

;SHIFT                                            C0     C1    C2    C3    C4    C5    C6    C7
KBD_MATRIX_SHIFT:                               ; ----- ----- ----- ----- ----- ----- ----- -----
        .byte   $BA,$87,$86,$85,$88,$09,$8D,$94 ; GR    F5    F3    F1    F7    TAB   S-RTN INS
        .byte   $8A,$65,$73,$7A,$24,$61,$77,$23 ; F4    E     S     Z     $     A     W     #
        .byte   $78,$74,$66,$63,$26,$64,$72,$25 ; X     T     F     C     &     D     R     %
        .byte   $76,$75,$68,$62,$28,$67,$79,$27 ; V     U     H     B     (     G     Y     '
        .byte   $6E,$6F,$6B,$6D,$5E,$6A,$69,$29 ; N     O     K     M     ^     J     I     )
        .byte   $3C,$60,$5B,$3E,$91,$6C,$70,$11 ; <     S-SPC [     >     UP    L     P     DOWN
        .byte   $3F,$7B,$7D,$1B,$1D,$5D,$A9,$9D ; ?     {     }     ESC   RIGHT ]     GR    LEFT
        .byte   $8B,$71,$8C,$A0,$22,$89,$93,$21 ; F6    Q     F8    S-SPC "     F2    CLS   !

;CAPS-LOCK key                                    C0    C1    C2    C3    C4    C5    C6    C7
KBD_MATRIX_CAPS:                            ; ----- ----- ----- ----- ----- ----- ----- -----
        .byte   $40,$87,$86,$85,$88,$09,$0D,$14 ; @     F5    F3    F1    F7    TAB   RETRN DEL
        .byte   $8A,$65,$73,$7A,$34,$61,$77,$33 ; F4    E     S     Z     4     A     W     3
        .byte   $78,$74,$66,$63,$36,$64,$72,$35 ; X     T     F     C     6     D     R     5
        .byte   $76,$75,$68,$62,$38,$67,$79,$37 ; V     U     H     B     8     G     Y     7
        .byte   $6E,$6F,$6B,$6D,$30,$6A,$69,$39 ; N     O     K     M     0     J     I     9
        .byte   $2C,$2D,$3A,$2E,$91,$6C,$70,$11 ; ,     -     :     .     UP    l     P     DOWN
        .byte   $2F,$2B,$3D,$1B,$1D,$3B,$2A,$9D ; /     +     =     ESC   RIGHT ;     *     LEFT
        .byte   $8B,$71,$8C,$20,$32,$89,$13,$31 ; F6    Q     F8    SPACE 2     F2    HOME  1

;Commodore key                                    C0    C1    C2    C3    C4    C5    C6    C7
KBD_MATRIX_CBMKEY:                              ; ----- ----- ----- ----- ----- ----- ----- -----
        .byte   $BA,$87,$86,$85,$88,$09,$8D,$94 ; GR    F5    F3    F1    F7    TAB   S-RTN INS
        .byte   $8A,$B1,$AE,$AD,$24,$B0,$B3,$23 ; F4    GR    GR    GR    $     GR    GR    #
        .byte   $BD,$A3,$BB,$BC,$26,$AC,$B2,$25 ; GR    GR    GR    GR    &     GR    GR    %
        .byte   $BE,$B8,$B4,$BF,$28,$A5,$B7,$27 ; GR    GR    GR    GR    (     GR    GR    '
        .byte   $AA,$B9,$A1,$A7,$5F,$B5,$A2,$29 ; GR    GR    GR    GR    ~?    GR    GR    )		; ? "~" not in original set
        .byte   $2C,$5C,$A6,$2E,$91,$B6,$AF,$11 ; ,     \     {     .     UP    GR    GR    DOWN
        .byte   $A4,$7C,$FF,$1B,$1D,$A8,$7F,$9D ; GR    |     PI    ESC   RIGHT }     GR    LEFT	; $7C=Pipe
        .byte   $8B,$AB,$8A,$A0,$32,$89,$93,$31 ; F6    GR    F4?   GR    2     F2    CLS   1		; ? Is F4 an error?

;CTRL key                                         C0    C1    C2    C3    C4    C5    C6    C7
KBD_MATRIX_CTRL:                                ; ----- ----- ----- ----- ----- ----- ----- -----
        .byte   $80,$87,$86,$85,$88,$09,$0D,$14 ; @     F5    F3    F1    F7    TAB   RETRN DEL
        .byte   $8A,$05,$13,$1A,$34,$01,$17,$33 ; F4    CT-E  HOME  CT-Z  4     CT-A  CT-W  3
        .byte   $18,$14,$06,$03,$36,$04,$12,$35 ; CT-Z  DEL   CT-F  STOP  6     CT-D  RVS   5
        .byte   $16,$15,$08,$02,$38,$07,$19,$37 ; CT-V  CT-U  LOCK  CT-B  8     CT-G  CT-Y  7
        .byte   $0E,$0F,$0B,$0D,$1E,$0A,$09,$39 ; TEXT  CT-O  CT-K  RETRN UARRW CT-J  CT-I  9
        .byte   $12,$1C,$1B,$92,$91,$0C,$10,$11 ; RVS   CT-\  ESC   R-OFF UP    CT-L  CT-P  DOWN
        .byte   $1F,$2B,$3D,$1B,$1D,$1D,$2A,$9D ; {$1F} +     =     ESC   RIGHT RIGHT *     LEFT	; Why CTRL-] = RIGHT?
        .byte   $8B,$11,$8C,$20,$32,$89,$13,$31 ; F6    CT-Q  F8    SPACE 2     F2    HOME  1
; ------------------------------------------------------------------------------------------------

KEYB_INIT:
        lda     #$09
        sta     $03F6
        lda     #$1E
        sta     $0367
        lda     #$01
        sta     $0366
        sta     $0365
        lda     #$FF
        sta     $038E
        lda     #<LFA87
        sta     L0336
        lda     #>LFA87
        sta     L0336+1
        ;Fall through

;looks like clearing the keyboard buffer
LB4FB_RESET_KEYD_BUFFER:
        php
        sei
        stz     $03F7
        stz     $03F8
        stz     $03F9
        plp
        rts
; ----------------------------------------------------------------------------
;Called at 60 Hz by the default IRQ handler (see LFA44_VIA1_T1_IRQ).
;Scan the keyboard
KL_SCNKEY:
        lda     $F4
        beq     LB54C
        dec     $F4
        lda     $AB
        and     #$07
        tax
        lda     PowersOfTwo,x
        eor     #$FF
        sta     VIA1_PORTA
        lda     $AB
        lsr     a
        lsr     a
        lsr     a
        tay
        jsr     KBD_TRIGGER_AND_READ_NORMAL_KEYS
        and     PowersOfTwo,y
        beq     LB52E
        lda     $0365
        sta     $F4
LB52E:  lda     $AB
        eor     #$07
        tax
        lda     KBD_MATRIX_NORMAL,x
        cmp     #$85   ;F1
        bcc     LB53E
        cmp     #$8C+1 ;F8 +1
        bcc     LB549  ;Branch if key is F1-F8
LB53E:  dec     $F5
        bpl     LB549
        lda     $0366
        sta     $F5
        bne     LB585
LB549:  jmp     KBD_READ_MODIFIER_KEYS_DO_SWITCH_AND_CAPS
; ----------------------------------------------------------------------------
LB54C:  lda     #$00
        sta     VIA1_PORTA
        jsr     KBD_TRIGGER_AND_READ_NORMAL_KEYS
        beq     LB549
        ldx     #$07
LB558:  lda     PowersOfTwo,x
        eor     #$FF
        sta     VIA1_PORTA
        jsr     KBD_TRIGGER_AND_READ_NORMAL_KEYS
        bne     LB56A
        dex
        bpl     LB558
        bra     LB549
LB56A:  ldy     #$FF
LB56C:  iny
        lsr     a
        bcc     LB56C
        tya
        asl     a
        asl     a
        asl     a
        dec     a
LB575:  inc     a
        dex
        bpl     LB575
        sta     $AB
        lda     $0365
        sta     $F4
        lda     $0367
        sta     $F5
LB585:  lda     $AB
        eor     #$07
        tax

        jsr     KBD_READ_MODIFIER_KEYS_DO_SWITCH_AND_CAPS
        and     #MOD_CTRL ;CTRL-key pressed?
        beq     LB5AC_NO_CTRL ;Branch if no

        ;TODO what does $AA do?
        lda     #$02
        and     $AA
        beq     LB5AC_NO_CTRL

        ;Check for CTRL-Q
        ldy     KBD_MATRIX_NORMAL,x
        cpy     #'Q'
        bne     LB5A3_CHECK_CTRL_S

        ;CTRL-Q pressed
        trb     $036D
        bra     LB5E1_JMP_LBFBE ;UNKNOWN_SECS/MINS

LB5A3_CHECK_CTRL_S:
        ;Check for CTRL-S
        cpy     #'S'
        bne     LB5AC_NO_CTRL

        ;CTRL-S pressed
        tsb     $036D
        bra     LB5E1_JMP_LBFBE ;UNKNOWN_SECS/MINS

;No CTRL-key combination pressed
LB5AC_NO_CTRL:
        lda     MODKEY
        and     $038E

        ldy     KBD_MATRIX_CTRL,x
        bit     #MOD_CTRL
        bne     LB5D0_GOT_KEYCODE     ;Branch to keep code from this matrix if CTRL pressed

        ldy     KBD_MATRIX_CBMKEY,x
        bit     #MOD_CBM              ;Branch to keep code from this matrix if CBM pressed
        bne     LB5D0_GOT_KEYCODE

        ldy     KBD_MATRIX_SHIFT,x
        bit     #MOD_SHIFT            ;Branch to keep code from this matrix if SHIFT pressed
        bne     LB5D0_GOT_KEYCODE

        ldy     KBD_MATRIX_CAPS,x
        bit     #MOD_CAPS
        bne     LB5D0_GOT_KEYCODE     ;Branch to keep code from this matrix if CAPS pressed

        ldy     KBD_MATRIX_NORMAL,x   ;Otherwise, use code from normal matrix

LB5D0_GOT_KEYCODE:
        tya                           ;A=key from matrix

        ldy     $03FA
LB5D4:  bne     LB5E1_JMP_LBFBE       ;UNKNOWN_SECS/MINS

        ldy     KBD_MATRIX_NORMAL,x
        jsr     LFA84
        sta     $AC
        jsr     PUT_KEY_INTO_KEYD_BUFFER

LB5E1_JMP_LBFBE:
        jmp     LBFBE ;UNKNOWN_SECS/MINS

; ----------------------------------------------------------------------------
KBD_TRIGGER_AND_READ_NORMAL_KEYS:
;Read "normal" (non-modifier) keys
;
;CLCD's keyboard is read through VIA1's SR.  PB0 seems to trigger (0->1)
;the keyboard "controller" to provide bits through serial transfer.
        lda     VIA1_PORTB
        and     #%11111110
        sta     VIA1_PORTB ;PB0=0
        inc     VIA1_PORTB ;PB0=1 Start Key Read
        lda     VIA1_SR

KBD_READ_SR:
        lda     #$04
KBD_READ_SR_WAIT:
        bit     VIA1_IFR
        beq     KBD_READ_SR_WAIT
        lda     VIA1_SR
        rts

; ----------------------------------------------------------------------------
KBD_READ_MODIFIER_KEYS_DO_SWITCH_AND_CAPS:
;Read the modifier keys (SHIFT, CTRL, etc.)
;Swap upper/lowercase
;Toggle CAPS lock
;
        jsr     KBD_READ_SR
        sta     MODKEY
LB602:  and     #MOD_CBM+MOD_SHIFT
        eor     #MOD_CBM+MOD_SHIFT
        ora     SWITCH_COUNT
        bne     LB613
        jsr     SWITCH_CHARSET ;Switch uppercase/lowercase mode
        lda     #$3C ;Initial count for debounce
        sta     SWITCH_COUNT
LB613:  dec     SWITCH_COUNT
        bpl     LB61B
        stz     SWITCH_COUNT
LB61B:  lda     #MOD_CAPS
        trb     MODKEY
        beq     LB62F_CAPS_PRESSED
        lda     CAPS_FLAGS
        bit     #$40
        bne     LB634
        eor     #$C0
        sta     CAPS_FLAGS
        bra     LB634
LB62F_CAPS_PRESSED:
        lda     #$40
        trb     CAPS_FLAGS
LB634:  bit     CAPS_FLAGS
        bpl     LB63D
        lda     #MOD_CAPS
        tsb     MODKEY
LB63D:  lda     MODKEY
        rts

; ----------------------------------------------------------------------------
;TODO probably put key into buffer
PUT_KEY_INTO_KEYD_BUFFER:
        php                                     ; B640 08                       .
        sei                                     ; B641 78                       x
        phx                                     ; B642 DA                       .
        ldx     $03F7                           ; B643 AE F7 03                 ...
        dex                                     ; B646 CA                       .
        bpl     LB64C                           ; B647 10 03                    ..
        ldx     $03F6                           ; B649 AE F6 03                 ...
LB64C:  cpx     $03F8                           ; B64C EC F8 03                 ...
        bne     LB655                           ; B64F D0 04                    ..
        plx                                     ; B651 FA                       .
        plp                                     ; B652 28                       (
        sec                                     ; B653 38                       8
        rts                                     ; B654 60                       `
LB655:  and     #$FF                            ; B655 29 FF                    ).
        beq     LB668                           ; B657 F0 0F                    ..
LB659:  ldx     $03F7                           ; B659 AE F7 03                 ...
        sta     KEYD,x                         ; B65C 9D EC 03                 ...
        dex                                     ; B65F CA                       .
        bpl     LB665                           ; B660 10 03                    ..
        ldx     $03F6                           ; B662 AE F6 03                 ...
LB665:  stx     $03F7                           ; B665 8E F7 03                 ...
LB668:  plx                                     ; B668 FA                       .
        plp                                     ; B669 28                       (
        clc                                     ; B66A 18                       .
        rts                                     ; B66B 60                       `
; ----------------------------------------------------------------------------
;todo probably get key from buffer
GET_KEY_FROM_KEYD_BUFFER:
        ldx     $03F8                           ; B66C AE F8 03                 ...
        lda     #$00                            ; B66F A9 00                    ..
        cpx     $03F7                           ; B671 EC F7 03                 ...
        beq     LB683                           ; B674 F0 0D                    ..
        lda     KEYD,x                         ; B676 BD EC 03                 ...
        dex                                     ; B679 CA                       .
        bpl     LB67F                           ; B67A 10 03                    ..
        ldx     $03F6                           ; B67C AE F6 03                 ...
LB67F:  stx     $03F8                           ; B67F 8E F8 03                 ...
        clc                                     ; B682 18                       .
LB683:  rts                                     ; B683 60                       `
; ----------------------------------------------------------------------------
LB684_STA_03F9:
        sta     $03F9                           ; B684 8D F9 03                 ...
        rts                                     ; B687 60                       `
; ----------------------------------------------------------------------------
LB688_GET_KEY_NONBLOCKING:
        phx
        phy

        lda     $03F9
        stz     $03F9
        bne     LB6D1_NONZERO

        ldx     #$0C
        jsr     LD230_JMP_LD233_PLUS_X    ;-> LD2B2_X_0C
        tax
        bne     LB6D1_NONZERO

        jsr     GET_KEY_FROM_KEYD_BUFFER
        bcc     LD294_LD233_0A_THEN_0C

        lda     #doschan_14_cmd_app
LB6A1:  jsr     V1541_SELECT_CHANNEL_A
        bcc     LB6C0_V1541_SELECT_ERROR ;branch on error

        rol     $03FA

        lda     MODKEY
        lsr     a ;Bit 0 = MOD_STOP
        bcs     LB6BD_STOP_OR_V1541_L8B46_ERROR ;Branch if STOP pressed

        jsr     L8B46 ;maybe returns a cbm dos error code
        bcc     LB6BD_STOP_OR_V1541_L8B46_ERROR

        bit     SXREG
        bpl     LB6BB_BRA_LD294_LD233_0A_THEN_0C

        jsr     L8C8B_CLEAR_ACTIVE_CHANNEL

LB6BB_BRA_LD294_LD233_0A_THEN_0C:
        bra     LD294_LD233_0A_THEN_0C

LB6BD_STOP_OR_V1541_L8B46_ERROR:
        jsr     L8C8B_CLEAR_ACTIVE_CHANNEL

LB6C0_V1541_SELECT_ERROR:
        stz     $03FA
        lda     #$00
        bra     LB6D9_DONE

LD294_LD233_0A_THEN_0C:
        ldx     #$0A
        jsr     LD230_JMP_LD233_PLUS_X    ;-> LD263_X_0A
        ldx     #$0C
        jsr     LD230_JMP_LD233_PLUS_X    ;-> LD2B2_X_0C

LB6D1_NONZERO:
        tax
        beq     LB6D9_DONE
        pha
        jsr     LBFBE ;UNKNOWN_SECS/MINS
        pla

LB6D9_DONE:
        ply
        plx
        cmp     #$00
        clc
        rts
; ----------------------------------------------------------------------------

LB6DF_GET_KEY_BLOCKING:
        jsr     LBFF2
        jsr     LB688_GET_KEY_NONBLOCKING
        beq     LB6DF_GET_KEY_BLOCKING
        rts
; ----------------------------------------------------------------------------
LB6E8_STOP:
        lda     MODKEY
        eor     #MOD_STOP
        and     #MOD_STOP
        bne     LB6F8_RTS
        php
        jsr     CLRCH
        jsr     LB4FB_RESET_KEYD_BUFFER
        plp
LB6F8_RTS:
        rts
; ----------------------------------------------------------------------------
;There seems to be two different behaviors
;depending on the carry flag when entering this routine
LB6F9_MAYBE_PUT_CHAR_IN_FKEY_BAR_SLOT:
        bcc     LB710_CARRY_CLEAR_ENTRY
        ;carry set entry
        sta     $03FD
        txa
        lsr     a
        clc
        cld
        adc     VidMemHi
        sta     $BE
        txa
LB707:  lsr     a
        tya
        bcc     LB70D
        ora     #$80
LB70D:  sta     $BD
        rts

LB710_CARRY_CLEAR_ENTRY:
        phx
        phy
        LDX     $03fd
        beq     LB754_DONE_SEC
        cpx     #$80
        beq     LB754_DONE_SEC
        cmp     #$0d
        bne     LB729
LB71F:  lda     #$20
        clc
        jsr     LB6F9_MAYBE_PUT_CHAR_IN_FKEY_BAR_SLOT
        bcc     LB71F
        bra     LB754_DONE_SEC
LB729:  cmp     #$12
        bne     LB734_NE_12
        lda     #$80
        tsb     $03FD
        bra     LB750_DONE_CLC
LB734_NE_12:
        cmp     #$92
        bne     LB73F_NE_92
        lda     #$80
        trb     $03FD
        bra     LB750_DONE_CLC
LB73F_NE_92:
        dec     $03FD
        jsr     LB09B
        bit     $03FD
        bpl     LB74C_NC
        eor     #$80
LB74C_NC:
        sta     ($BD)
        inc     $BD
LB750_DONE_CLC:
        clc
        ply
        plx
        rts
LB754_DONE_SEC:
        sec
        ply
        plx
        rts
; ----------------------------------------------------------------------------
LB758:  cpx     #$00
        beq     LB760
        sta     $B0
        stx     $B1
LB760:  ldy     #0
        lda     ($B0),y
        tax
        iny
        lda     ($B0),y
        asl     a
        sta     $F6
        txa
        lsr     a
        tax
        ror     $F6
        adc     VidMemHi
        sta     $F7
        iny
        lda     ($B0),y
        sta     $03FE
        iny
        lda     ($B0),y
        sta     $03FF
LB780:  iny
        lda     ($B0),y
        sta     $0400
        ldx     #$00
LB788:  lda     L0470,x
        beq     LB799
        cpx     $03FE
        beq     LB795
        inx
        bne     LB788
LB795:  sec
        lda     #$00
        rts
; ----------------------------------------------------------------------------
LB799:  stx     $0403
        stx     $0402
        jsr     LB8B3
        lda     $0400
LB7A5:  and     #$02
LB7A7:  beq     LB7AB
        clc
        rts
; ----------------------------------------------------------------------------
LB7AB:
        jsr     SET_CURSOR_XY_FROM_PTR_B0_AND_0404_THEN_TURN_ON_CURSOR
LB7AE_LOOP_UNTIL_KEY:
        jsr     LBFF2
        jsr     LB688_GET_KEY_NONBLOCKING
        bne     LB7BE_GOT_KEY
        lda     MODKEY
        and     #MOD_STOP
        beq     LB7AE_LOOP_UNTIL_KEY
        lda     #$03
LB7BE_GOT_KEY:
        sta     $0401
        ldy     #$05
LB7C3:  lda     ($B0),y
        beq     LB7DE
        cmp     $0401
        beq     LB7CF
        iny
LB7CE := *+1
        BNE     LB7C3
LB7CF:  pha
        jsr     LB8B3
        ldx     $0402
        lda     #$00
        sta     L0470,x
        pla
        clc
        rts

LB7DE:  tax
        lda     $0401
LB7E2_SEARCH_LOOP:
        cmp     LB7F4_KEYCODES,x
        beq     LB7EE_FOUND
        inx
        cpx     #$06
        bne     LB7E2_SEARCH_LOOP
        beq     LB80C_KEYCODE_NOT_FOUND
LB7EE_FOUND:
        jsr     LB806_DISPATCH
        jmp     LB7AB

LB7F4_KEYCODES:
        .byte $94 ;insert
        .byte $14 ;delete
        .byte $1d ;cursor right
        .byte $9d ;cursor left
        .byte $93 ;clear screen
        .byte $8d ;shift-return

LB7FB_KEYCODE_HANDLERS:
        .addr LB845_94_INSERT
        .addr LB86C_14_DELETE
        .addr LB889_1D_CURSOR_RIGHT
        .addr LB897_9D_CURSOR_LEFT
        .addr LB8A2_93_CLEAR
        .addr LB8AD_8D_SHIFT_RETURN

LB806_DISPATCH:
        txa
        asl     a
        tax
        jmp     (LB7FB_KEYCODE_HANDLERS,x)

LB80C_KEYCODE_NOT_FOUND:
        tax
        and     #$7F
        cmp     #$20
        bcc     LB7AE_LOOP_UNTIL_KEY
        txa
        ldx     $0403
        sta     L0470,x
        cpx     $0402
        bne     LB82A
        ldx     $0402
        cpx     $03FE
        beq     LB82E
        inc     $0402
LB82A:  inx
        stx     $0403
LB82E:  lda     $0400
        and     #$01
        beq     LB83F
        cpx     $03FE
        bne     LB83F
        lda     #$00
        jmp     LB7CF

LB83F:  jsr     LB8B3
        jmp     LB7AB
; ----------------------------------------------------------------------------
LB845_94_INSERT:
        ldx     $0402
        cpx     $03FE
        beq     LB869
        cpx     $0403
        beq     LB869
LB852:  lda     L0470,x
        sta     L0470+1,x
        cpx     $0403
        beq     LB861
        dex
        jmp     LB852

LB861:  lda     #$20
        sta     L0470,x
        inc     $0402
LB869:  jmp     LB8B3
; ----------------------------------------------------------------------------
LB86C_14_DELETE:
        ldx     $0403
        beq     LB886
        dec     $0403
        dex
LB875:  lda     $0471,x
        sta     L0470,x
        cpx     $0402
        beq     LB883
        inx
        bne     LB875
LB883:  dec     $0402
LB886:  jmp     LB8B3
; ----------------------------------------------------------------------------
LB889_1D_CURSOR_RIGHT:
        lda     $0403
        cmp     $0402
        beq     LB894
        inc     $0403
LB894:  jmp     LB8B3
; ----------------------------------------------------------------------------
LB897_9D_CURSOR_LEFT:
        lda     $0403
        beq     LB89F
        dec     $0403
LB89F:  jmp     LB8B3
; ----------------------------------------------------------------------------
LB8A2_93_CLEAR:
        lda     #$00
LB8A4:  sta     $0402
        sta     $0403
        jmp     LB8B3
; ----------------------------------------------------------------------------
LB8AD_8D_SHIFT_RETURN:
        lda     $0403
        jmp     LB8A4
; ----------------------------------------------------------------------------
LB8B3:  jsr     LB2E4_HIDE_CURSOR
        ldy     #$00
        ldx     #$00
        lda     $0403
        sec
        sbc     $03FF
        bcc     LB8CB
        tax
        lda     $03FF
        sbc     #$01
        bne     LB8CE
LB8CB:  lda     $0403
LB8CE:  sta     $0404
LB8D1_LOOP:
        cpx     $0402
        beq     LB8F3
        lda     L0470,X
        phx
        jsr     LB09B
        plx
        sta     $0401
        lda     $0400
        and     #$80
        ora     $0401
LB8E9:  sta     ($F6),y
        inx
        iny
        cpy     $03FF
        bne     LB8D1_LOOP
        rts

LB8F3:  lda     $0400
        and     #$80
        ora     #$20
LB8FA_LOOP:
        sta     ($F6),y
        iny
        cpy     $03FF
        bne     LB8FA_LOOP
        rts
; ----------------------------------------------------------------------------
SET_CURSOR_XY_FROM_PTR_B0_AND_0404_THEN_TURN_ON_CURSOR:
        ldy     #$00
        lda     ($B0),y     ;X position
        tax

        iny
        lda     ($B0),y     ;Y position
        clc
        adc     $0404       ;Y = Y + value at $0404
        tay

        clc
        jsr     PLOT_
        jsr     LB2D6_SHOW_CURSOR
        rts
; ----------------------------------------------------------------------------
LB918_CHRIN___OR_LB688_GET_KEY_NONBLOCKING:
        lda     DFLTN
        and     #$1F
        bne     CHRIN__
LB91F:  jmp     LB688_GET_KEY_NONBLOCKING
; ----------------------------------------------------------------------------
LB922_PLY_PLX_RTS:
        ply
        plx
LB924_RTS:
        rts
; ----------------------------------------------------------------------------
CHRIN__:phx
        phy
        lda     #>(LB922_PLY_PLX_RTS-1)
        pha
        lda     #<(LB922_PLY_PLX_RTS-1)
        pha

        lda     DFLTN
        and     #$1F
        bne     LB937_NOT_KEYBOARD
        ;Device 0 keyboard or >31
        jmp     LB325_CHRIN_KEYBOARD

LB937_NOT_KEYBOARD:
        cmp     #$02 ;RS-232
        bne     LB948_NOT_RS232
LB93C = * + 1

        ;Device 2 RS-232
        jsr     AGETCH          ;Get byte from RS-232
        pha
        lda     SA
        and     #$0F            ;SA & 0x0F sets translation mode
        tax
        pla
        jmp     TRANSL_ACIA_RX  ;Translate char before returning it

LB948_NOT_RS232:
        bcs     LB94D ;Device >= 2
        ;Device 1 Virtual 1541
        jmp     V1541_CHRIN

LB94D:  cmp     #$03 ;Screen
LB950 := * + 1
        bne     LB954_NOT_SCREEN

        ;Device 3 Screen
LB952 := * + 1
        jmp     LB319_CHRIN_DEV_3_SCREEN

LB954_NOT_SCREEN:
        cmp     #$1E ;30=Centronics
        bne     LB95B_NOT_CENTRONICS
        ;Device 30 (Centronics)
        jmp     ERROR6 ;NOT INPUT FILE

LB95B_NOT_CENTRONICS:
        ;Device 4-29 (IEC)
        bcc     ACPTR_IF_ST_OK_ELSE_0D

        ;Device 31 (RTC)
        jmp     RTC_CHRIN

; ----------------------------------------------------------------------------

;If ST=0, read a byte from IEC.
;Otherwise, return a carriage return (0x0D).
ACPTR_IF_ST_OK_ELSE_0D:
        lda     SATUS
        bne     LB968
        sec
        jmp     ACPTR
LB968:  lda     #$0D
        clc
        rts

; ----------------------------------------------------------------------------
;NBSOUT
CHROUT__:
        ;Push X and Y onto stack, will be popped on return by LB922_PLY_PLX_RTS
        phx
        phy

        ;Push return address LB922_PLY_PLX_RTS
        ldx     #>(LB922_PLY_PLX_RTS-1)
        phx
        ldx     #<(LB922_PLY_PLX_RTS-1)
        phx

LB974:  pha ;Push byte to write

        ;Get device number into X
        lda     DFLTO
        and     #$1F
        tax

        pla ;Pull byte to write

LB97D := * + 1
        cpx     #$01  ;1 = Virtual 1541
        bne     LB983
        jmp     V1541_CHROUT ;CHROUT to Virtual 1541

LB983:  bcs     LB988
LB985:  jmp     KR_ShowChar_ ;X=0

LB988:  cpx     #$03
        beq     LB985 ;X=3 (Screen)
        bcs     LB994

        ;Device = 2 (ACIA)
        jsr     USING_SA_TRANSL_ACIA_TX_OR_CENTRONICS
        jmp     ACIA_CHROUT

LB994:  cpx     #$1E  ;30
        bne     LB9A7
        ;Device = 30 (Centronics port)
        ldx     SA
        pha
        lda     SA
        and     #$0F            ;SA & 0x0F sets translation mode
        tax
        pla
        jsr     USING_SA_TRANSL_ACIA_TX_OR_CENTRONICS  ;Translate char before sending it
        jmp     CENTRONICS_CHROUT

LB9A7:  bcc     LB9AC
        jmp     RTC_CHROUT

LB9AC:  sec
        jmp     CIOUT ;IEC

; ----------------------------------------------------------------------------

;Translate character before sending it to ACIA TX or Centronics out
;Translation mode is set by secondary address
;Set X=SA & $0F, A=char to translate
USING_SA_TRANSL_ACIA_TX_OR_CENTRONICS:
        pha
LB9B1:  lda     SA
        and     #$0F
        tax
        pla
        jmp     TRANSL_ACIA_TX_OR_CENTRONICS

; ----------------------------------------------------------------------------

CHKIN__:jsr     LOOKUP
        beq     LB9C2
        jmp     ERROR3 ;FILE NOT OPEN

LB9C2:  jsr     JZ100
        beq     JX320_NEW_DFLTN   ;Device 0 (Keyboard)

        cmp     #$1E
        bcs     JX320_NEW_DFLTN   ;Device >= 30 (30=Centronics, 31=RTC)
        cmp     #$01

        beq     LB9FE             ;Device 1 (Virtual 1541)
        cmp     #$03

        beq     JX320_NEW_DFLTN   ;Device 3 (Screen)
        bcs     LB9E1_CHKIN_IEC   ;Device 4-29 (IEC)

        jsr     LBF4D_CHKIN_ACIA  ;Device 2 (ACIA)
        bcs     LB9E0_RTS_ONLY    ;Branch if failed (never fails)

        lda     FA
JX320_NEW_DFLTN:
        sta     DFLTN
        clc
LB9E0_RTS_ONLY:
        rts

LB9E1_CHKIN_IEC:
        tax
        jsr     TALK__
        bit     SATUS
        bmi     LB9FB_JMP_ERROR5
        lda     SA
        bpl     JX340
        jsr     LBD5B
        jmp     JX350

JX340:  jsr     TKSA
JX350:  txa
        bit     SATUS
        bpl     JX320_NEW_DFLTN
LB9FB_JMP_ERROR5:
        jmp     ERROR5 ;DEVICE NOT PRESENT
LB9FE:  jsr     L9962
        bcc     JX320_NEW_DFLTN
        bra     LB9FB_JMP_ERROR5

; ----------------------------------------------------------------------------

;NCKOUT
CHKOUT__:
        jsr     LOOKUP
        beq     LBA0D
        jmp     ERROR3 ;FILE NOT OPEN

LBA0D:  jsr     JZ100
        bne     LBA15
        jmp     ERROR7 ;NOT OUTPUT FILE

LBA15:  cmp     #$1E
        bcs     LBA32
        cmp     #$02
        beq     LBA2B
        bcs     LBA25
        jsr     L9962
        bcc     LBA32
        rts

LBA25:  cmp     #$03
        beq     LBA32
        bne     LBA37
LBA2B:  jsr     LBF4D_CHKIN_ACIA
        bcs     LBA36
        lda     FA
LBA32:  sta     DFLTO
        clc
LBA36:  rts

LBA37:  tax
        jsr     LISTN
        bit     SATUS
        bmi     LBA50
        lda     SA
        bpl     LBA48
        jsr     SCATN
        bne     LBA4B
LBA48:  jsr     SECND
LBA4B:  txa
        bit     SATUS
        bpl     LBA32
LBA50:  jmp     ERROR5 ;DEVICE NOT PRESENT

; ----------------------------------------------------------------------------

;NCLOSE
;Called with logical file name in A
CLOSE__:ror     WRBASE        ;save serial close flag (used below in JX120_CLOSE_IEC)
        jsr     JLTLK         ;look file up
        beq     JX050         ;file is open, branch to close it
        clc                   ;else return
        rts

JX050:  jsr     JZ100         ;extract table data
        txa                   ;save table index
        pha

        lda     FA
        beq     JX150             ;Device 0 (Keyboard)

        cmp     #$1E
        bcs     JX150             ;Device >= 30 (30=Centronics, 31=RTC)

        cmp     #$03
        beq     JX150             ;Device 3 (Screen)
        bcs     JX120_CLOSE_IEC   ;Device 4-29 (IEC)

        cmp     #$02
        bne     LBA79_CLOSE_V1541 ;Device = 1 (Virtual 1541)

        jsr     ACIA_CLOSE        ;Device = 2 (ACIA)
        bra     JX150

LBA79_CLOSE_V1541:
        jsr     V1541_CLOSE
        bra     JX150

JX120_CLOSE_IEC:
        bit     WRBASE        ;do a real close?
        bpl     ROPEN         ;yep
        lda     FA            ;no if a disk & sa=$f
        cmp     #$08
        bcc     ROPEN         ;>8 ==>not a disk, do real close
        lda     SA
        and     #$0F
        cmp     #15           ;command channel?
        beq     JX150         ;yes, sa=$f, no real close

ROPEN:  jsr     CLSEI

; entry to remove a give logical file
; from table of logical, primary,
; and secondary addresses

JX150:  pla                   ;get table index off stack
        tax
        dec     LDTND
        cpx     LDTND         ;is deleted file at end?
        beq     JX170         ;yes...done

; delete entry in middle by moving
; last entry to that position.

        ldy     LDTND
        lda     LAT,y
        sta     LAT,x
        lda     FAT,y
        sta     FAT,x
        lda     SAT,y
        sta     SAT,x
JX170:  clc                   ;close exit
        rts
; ----------------------------------------------------------------------------
;LOOKUP TABLIZED LOGICAL FILE DATA
;
LOOKUP: stz     SATUS
        txa
JLTLK:  ldx     LDTND
JX600:  dex
        bmi     JZ101
        cmp     LAT,x
        bne     JX600
        rts
; ----------------------------------------------------------------------------
;ROUTINE TO FETCH TABLE ENTRIES
;
JZ100:  lda     LAT,x
        sta     LA
        lda     SAT,x
        sta     SA
        lda     FAT,x
        sta     FA
JZ101:  rts
; ----------------------------------------------------------------------------
;NCLALL
;*************************************
;* clall -- close all logical files  *
;* deletes all table entries and     *
;* restores default i/o channels     *
;* and clears serial port devices.   *
;*************************************
CLALL__:stz     LDTND     ;Forget all files

;NCLRCH
;****************************************
;* clrch -- clear channels              *
;* unlisten or untalk serial devcs, but *
;* leave others alone. default channels *
;* are restored.                        *
;****************************************
;
;XXX This is a bug.  This routine assumes that any device > 3 is an
;IEC device that needs to be UNTLKed or UNLSNed.  That was true on other
;machines but the LCD has two new devices, the Centronics port ($1E / 30)
;and the RTC ($1F / 31), that are not IEC.  When one of these devices is
;open, this routine will needlessly send UNLSN or UNTLK to IEC.  This can
;be seen at the power-on menu.  The menu continuously polls the RTC via
;CHRIN and calls CLALL after each poll, which comes here (CLRCHN), and an
;unnecessary UNTLK is sent.  To fix this, ignore devices $1E and $1F here.
CLRCHN__:
        ldx     #3        ;Device 3 (Screen)

        cpx     DFLTO     ;Compare 3 to default output channel
        bcs     LBAE1     ;Branch if DFLTO <= 3 (not IEC)
        jsr     UNLSN     ;Device is IEC so UNLSN

LBAE1:  cpx     DFLTN     ;Compare 3 to default input channel
        bcs     LBAE9     ;Branch if DFLTN <= 3 (not IEC)
        jsr     UNTLK     ;Device is IEC so UNTLK

LBAE9:  stx     DFLTO     ;Default output device = 3 (Screen)
        stz     DFLTN     ;Default output device = 0 (Keyboard)
        rts

; ----------------------------------------------------------------------------

;NOPEN
Open__: ldx     LA
        jsr     LOOKUP
        bne     OP100
        jmp     ERROR2 ;FILE OPEN

OP100:  ldx     LDTND
        cpx     #$0C
        bcc     OP110
        jmp     ERROR1 ;TOO MANY FILES

OP110:  inc     LDTND
        lda     LA
        sta     LAT,x
        lda     SA
        ora     #$60
        sta     SA
        sta     SAT,x
        lda     FA
        sta     FAT,x
;
;PERFORM DEVICE SPECIFIC OPEN TASKS
;
        beq     LBB2F_CLC_RTS     ;Device 0 (Keyboard), nothing to do.

        cmp     #$1E              ;Device 30 (Centronics port)
        beq     LBB2F_CLC_RTS     ;Nothing to do

        bcc     LBB25_OPEN_LT_30  ;Device <30

        ;Device 31 (RTC)
        jmp     RTC_OPEN

;Device < 30
LBB25_OPEN_LT_30:
        cmp     #$03              ;3 (Screen)
        beq     LBB2F_CLC_RTS     ;Return OK
        bcc     LBB31_OPEN_LT_3   ;Device < 3

        sec
        jsr     OPENI    ;Device 4-29
LBB2F_CLC_RTS:
        clc
        rts

;Device < 3
LBB31_OPEN_LT_3:
        cmp     #$02
        bne     LBB3B_OPEN_NOT_2

        ;Device 2 RS232
        jsr     ACIA_INIT
        jmp     ACIA_OPEN

LBB3B_OPEN_NOT_2:
        ;Device 1 Virtual 1541
        jmp     L9243_OPEN_V1541

OP175_OPEN_CLC_RTS:
        clc
        rts

; ----------------------------------------------------------------------------
;OPEN to IEC bus
;OPEN_IEC
OPENI:
        lda     SA
        bmi     OP175_OPEN_CLC_RTS  ;no sa...done

        ldy     FNLEN
        beq     OP175_OPEN_CLC_RTS  ;no file name...done

        stz     SATUS         ;clear the serial status

        lda     FA
        jsr     LISTN         ;device la to listen
        bit     SATUS         ;anybody home?
        bmi     UNP           ;nope

        lda     SA
        ora     #$F0
        jsr     SECND

        lda     SATUS         ;anybody home?...get a dev -pres?
        bpl     OP35          ;yes...continue

;  this routine is called by other
;  kernal routines which are called
;  directly by os. kill return
;  address to return to os.
UNP:    pla
        pla
        jmp     ERROR5 ;DEVICE NOT PRESENT

OP35:   lda     FNLEN
        beq     OP45          ;no name...done sequence

;
;  send file name over serial
;
        ldy     #$00
OP40:   lda     #FNADR
        sta     SINNER
        jsr     GO_RAM_LOAD_GO_KERN   ;Get byte from filename
        jsr     CIOUT                 ;Send it to IEC
        iny
        cpy     FNLEN
        bne     OP40
OP45:   jmp     CUNLSN

; ----------------------------------------------------------------------------

SAVEING:jsr     PRIMM80
        .byte   "SAVEING ",0  ;Not "SAVING" like all other CBM computers
        bra     OUTFN

; ----------------------------------------------------------------------------

LUKING: jsr     PRIMM80
        .byte   "SEARCHING FOR ",0
        ;Fall through

; ----------------------------------------------------------------------------

OUTFN:  bit     MSGFLG
        bpl     LBBBF
        ldy     FNLEN
        beq     LBBBC
        ldy     #$00
LBBAB:  lda     #FNADR
        sta     SINNER
        jsr     GO_RAM_LOAD_GO_KERN
        jsr     KR_ShowChar_
        iny
        cpy     FNLEN
        bne     LBBAB
LBBBC:  jmp     PrintNewLine
; ----------------------------------------------------------------------------
LBBBF:  rts
; ----------------------------------------------------------------------------
SAVE__:
        lda     FA
        bne     LBBC7
LBBC4_BAD_DEVICE:
        jmp     ERROR9 ;BAD DEVICE #
; ----------------------------------------------------------------------------
LBBC7:  cmp     #$03
        beq     LBBC4_BAD_DEVICE
        cmp     #$02
        beq     LBBC4_BAD_DEVICE
        ldy     FNLEN
        bne     LBBD7
        jmp     ERROR8 ;MISSING FILE NAME
; ----------------------------------------------------------------------------
LBBD7:  cmp     #$01   ;Virtual 1541?
        bne     LBBE1_SAVE_IEC
        ;Virtual 1541
        jsr     SAVEING ;Print SAVEING then OUTFN
        jmp     L9085_V1541_SAVE
; ----------------------------------------------------------------------------
;SAVE to IEC
LBBE1_SAVE_IEC:
        lda     #$61
        sta     SA
        jsr     OPENI
        jsr     SAVEING ;Print SAVEING then OUTFN

        lda     FA
        jsr     LISTN
        lda     SA
        jsr     SECND
        ldy     #$00

        ;RD300 from C64 KERNAL inlined
        lda     STAH
        sta     SAH
        lda     $B6
        sta     SAL

        lda     SAL
        jsr     CIOUT
        lda     SAH
        jsr     CIOUT

LBC09:  ;CMPSTE from C64 KERNAL inlined
        sec
        lda     SAL
        sbc     EAL
        lda     SAH
        sbc     EAH

        bcs     LBC33
        lda     #SAL
        sta     SINNER
        jsr     GO_RAM_LOAD_GO_KERN
        jsr     CIOUT
        jsr     LFDB9_STOP
        bne     LBC2B
        jsr     CLSEI
        lda     #$00
        sec
        rts
; ----------------------------------------------------------------------------
LBC2B:  inc     SAL
        bne     LBC09
        inc     SAH
        bne     LBC09
LBC33:  jsr     UNLSN
; ----------------------------------------------------------------------------
CLSEI:  bit     SA
        bmi     CLSEI2
        lda     FA
        jsr     LISTN
        lda     SA
        and     #$EF
        ora     #$E0
        jsr     SECND
CUNLSN: jsr     UNLSN
CLSEI2: clc
        rts
; ----------------------------------------------------------------------------
ERROR0: lda     #$00  ;OK
        .byte   $2C
ERROR1: lda     #$01  ;TOO MANY OPEN FILES
        .byte   $2C
ERROR2: lda     #$02  ;FILE OPEN
        .byte   $2C
ERROR3: lda     #$03  ;FILE NOT OPEN
        .byte   $2C
ERROR4: lda     #$04  ;FILE NOT FOUND
        .byte   $2C
ERROR5: lda     #$05  ;DEVICE NOT PRESENT
        .byte   $2C
ERROR6: lda     #$06  ;NOT INPUT FILE
        .byte   $2C
ERROR7: lda     #$07  ;NOT OUTPUT FILE
        .byte   $2C
ERROR8: lda     #$08  ;MISSING FILE NAME
        .byte   $2C
ERROR9: lda     #$09  ;BAD DEVICE #
        .byte   $2C
ERROR16:lda     #$0A  ;OUT OF MEMORY
        pha
        jsr     CLRCH
        bit     MSGFLG
        bvc     EREXIT
        jsr     PRIMM
        .byte   $0d,"I/O ERROR #",0
        pla
        pha
        jsr     L8850
        jsr     PrintNewLine
EREXIT: pla
        sec
        rts

; ----------------------------------------------------------------------------

;Send TALK to IEC
TALK__:
        ora     #$40          ;A = 0x40 (TALK)
        .byte   $2C           ;Skip next 2 bytes

;Send LISTEN to IEC
LISTN:
        ora     #$20          ;A = 0x20 (LISTEN)

;Send a command byte to IEC
;Start of LIST1 from C64 KERNAL
LIST1:  pha
        bit     C3P0          ;Character left in buf?
        bpl     LIST2         ;No...

        ;Send buffered character
        sec                   ;Set EOI flag
        ror     R2D2
        jsr     ISOUR         ;Send last character
        lsr     C3P0          ;Buffer clear flag
        lsr     R2D2          ;Clear EOI flag

LIST2:  pla                   ;TALK/LISTEN address
        sta     BSOUR         ;Byte buffer for output (FF means no character)
        sei
        jsr     DATAHI        ;Set data line high
        cmp     #$3F          ;CLKHI only on UNLISTEN
        bne     LIST5
        jsr     CLKHI         ;Set clock line high

LIST5:  lda     VIA1_PORTB
        ora     #$08
        sta     VIA1_PORTB    ;Assert ATN (turns VIA PA3 on)

ISOURA: sei
        jsr     CLKLO         ;Set clock line low
        jsr     DATAHI
        jsr     W1MS

;Send last byte to IEC
ISOUR:  sei
        jsr     DATAHI        ;Make sure data is released / Set data line high
        jsr     DEBPIA        ;Data should be low / Debounce VIA PA then ASL A
        bcs     NODEV         ;Branch to device not present error
        jsr     CLKHI         ;Set clock line high

        bit     VIA1_PORTB    ;XXX different from c64
        bvs     NODEV         ;XXX

        bit     R2D2          ;EOI flag test
        bpl     NOEOI

;Do the EOI
ISR02:  jsr     DEBPIA        ;Wait for DATA to go high / Debounce VIA PA then ASL A
        bcc     ISR02

ISR03:  jsr     DEBPIA        ;Wait for DATA to go low / Debounce VIA PA then ASL A
        bcs     ISR03

NOEOI:  jsr     DEBPIA        ;Wait for DATA high / Debounce VIA PA then ASL A
        bcc     NOEOI
        jsr     CLKLO         ;Set clock line low

        ;Set to send data
        lda     #$08          ;Count 8 bits
        sta     IECCNT

ISR01:  lda     VIA1_PORTB    ;Debounce the bus
        cmp     VIA1_PORTB
        bne     ISR01
        eor     #$C0          ;XXX different from c64 (same change in debpia)
        asl     a             ;Set the flags
        bcc     FRMERR        ;Data must be high
        ror     BSOUR         ;Next bit into carry
        bcs     ISRHI
        jsr     DATALO        ;Set data line low
        bne     ISRCLK

ISRHI:  jsr     DATAHI        ;Set data line high

ISRCLK: jsr     CLKHI         ;Set clock line high
        nop
        nop
        nop
        nop
        lda     VIA1_PORTB
        and     #$DF          ;Data high
        ora     #$10          ;Clock low
        sta     VIA1_PORTB
        dec     IECCNT
        bne     ISR01
        ;XXX VC-1541-DOS first stores in 0 VIA1_T2CL here
        lda     #$04          ;XXX different from C64 (VIA vs CIA)
        sta     VIA1_T2CH
        ;XXX VC-1541-DOS does "lda via_ifr" here before the next line

ISR04:  lda     VIA1_IFR      ;XXX different from C64 (VIA vs CIA)
        and     #$20          ;XXX but same as VC-1541-DOS
        bne     FRMERR        ;XXX
        jsr     DEBPIA        ;Debounce VIA PA then ASL A
        bcs     ISR04
        cli
        rts
; ----------------------------------------------------------------------------
NODEV:  lda     #$80          ;A = SATUS bit for device not present error
        .byte   $2C           ;Skip next 2 bytes

FRMERR: lda     #$03          ;A = SATUS bits timeout during write
                              ;(C64 KERNAL calls this "framing")

;Commodore Serial Bus Error Entry
CSBERR: jsr     UDST          ;KERNAL SATUS = SATUS | A
        cli                   ;IRQ's were off...turn on
        clc                   ;Make sure no KERNAL error returned
        bcc     DLABYE        ;Branch always to turn ATN off, release all lines

;Send secondary address for LISTEN to IEC
SECND:
        sta     BSOUR         ;Buffer character
        jsr     ISOURA        ;Send it

;Release ATN after LISTEN
SCATN:
        lda     VIA1_PORTB
        and     #$F7
        sta     VIA1_PORTB    ;Release ATN
        rts

; ----------------------------------------------------------------------------

;Send secondary address for TALK to IEC
TKSA:
        sta     BSOUR         ;Buffer character
        jsr     ISOURA        ;Send secondary address
LBD5B:  sei                   ;No IRQ's here
        jsr     DATALO        ;Set data line low
        jsr     SCATN         ;Release ATN
        jsr     CLKHI         ;Set clock line high

TKATN1: jsr     DEBPIA        ;Wait for clock to go low / Debounce VIA PA then ASL A
        bmi     TKATN1
        cli                   ;IRQ's okay now
        rts

; ----------------------------------------------------------------------------

;Send a byte to IEC
;Buffered output to IEC
CIOUT:
        bit     C3P0          ;Buffered char?
        bmi     CI2           ;Yes...send last

        sec                   ;No...
        ror     C3P0          ;Set buffered char flag
        bne     CI4           ;Branch always

CI2:    pha                   ;Save current char
        jsr     ISOUR         ;Send last char
        pla                   ;Restore current char

CI4:    sta     BSOUR         ;Buffer current char
        clc                   ;Carry-Good exit
        rts

; ----------------------------------------------------------------------------

;Send UNTALK to IEC
UNTLK:  sei
        jsr     CLKLO         ;Set clock line low
        lda     VIA1_PORTB
        ora     #$08
        sta     VIA1_PORTB    ;Assert ATN (turns VIA PB3 on)
        lda     #$5F          ;A = 0x5F (UNTALK)
        .byte   $2C           ;Skip next 2 bytes

;Send UNLISTEN to IEC
UNLSN:  lda     #$3F          ;A = 0x3F (UNLISTEN)
        jsr     LIST1         ;Send it

;Release all lines
DLABYE: jsr     SCATN         ;Always release ATN

;Delay approx 60 us then release clock and data
DLADLH: txa
        ldx     #10

DLAD00: dex
        bne     DLAD00
        tax
        jsr     CLKHI         ;Set clock line high
                              ;XXX this matches the C64 but VC-1541-DOS stores also 0 in C3P0 here
        jmp     DATAHI        ;Set data line high

; ----------------------------------------------------------------------------

;Read a byte from IEC
;Input a byte from serial bus
ACPTR:  sei                   ;No IRQ allowed
        lda     #$00          ;Set EOI/ERROR Flag
        sta     IECCNT
        jsr     CLKHI         ;Make sure clock line is released / Set clock line high

ACP00A: jsr     DEBPIA        ;Wait for clock high / Debounce VIA PA then ASL A
        bpl     ACP00A

EOIACP: lda     #$01          ;XXX different from C64 (VIA vs CIA)
        sta     VIA1_T2CH     ;VC-1541-DOS also stores 0 in VIA1_T2CL first

        jsr     DATAHI        ;Data line high (Makes timing more like VIC-20) / Set data line high
                              ;XXX VC-1541-DOS does "lda via_ifr" here before the next line

ACP00:  lda     VIA1_IFR      ;XXX Check the timer
        and     #$20          ;XXX different from C64 (VIA vs CIA) but same as VC-1541-DOS
        bne     ACP00B        ;Ran out...
        jsr     DEBPIA        ;Check the clock line / Debounce VIA PA then ASL A
        bmi     ACP00         ;No, not yet
        bpl     ACP01         ;Yes...

ACP00B: lda     IECCNT        ;Check for error (twice thru timeouts)
        beq     ACP00C
        lda     #$02          ;A = SATUS bit for timeout error
        jmp     CSBERR        ;ST = 2 read timeout

;Timer ran out, do an EOI thing
ACP00C: jsr     DATALO        ;Set data line low
        jsr     CLKHI         ;Delay and then set DATAHI (fix for 40us C64) / Set clock line high
        lda     #$40          ;A = SATUS bit for End of File (EOF)
        jsr     UDST          ;KERNAL SATUS = SATUS | A
        inc     IECCNT        ;Go around again for error check on EOI
        bne     EOIACP

;Do the byte transfer
ACP01:  lda     #$08          ;Set up counter
        sta     IECCNT

ACP03:  lda     VIA1_PORTB    ;Wait for clock high
        cmp     VIA1_PORTB    ;Debounce
        bne     ACP03
        eor     #$C0          ;XXX different from C64 (lines inverted)
        asl     a             ;Shift data into carry
        bpl     ACP03         ;Clock still low...
        ror     BSOUR1        ;Rotate data in

ACP03A: lda     VIA1_PORTB    ;Wait for clock low
        cmp     VIA1_PORTB    ;Debounce
        bne     ACP03A
        eor     #$C0          ;XXX different from C64 (lines inverted)
        asl     a
        bmi     ACP03A
        dec     IECCNT
        bne     ACP03         ;More bits...
        ;...exit...
        jsr     DATALO        ;Set data line low
        bit     SATUS         ;Check for EOI
        bvc     ACP04         ;None...

        jsr     DLADLH        ;Delay approx 60 then set data high

ACP04:  lda     BSOUR1
        cli                   ;IRQ is OK
        clc                   ;Good exit
        rts
; ----------------------------------------------------------------------------
CLKHI:
;Set clock line high (allows IEC CLK to be pulled to 5V)
;Write 0 to VIA port bit, so 7406 output is Hi-Z
        lda     VIA1_PORTB
        and     #$EF
        sta     VIA1_PORTB
        rts
; ----------------------------------------------------------------------------
CLKLO:
; Set VIA1 port-B bit#4.
        lda     VIA1_PORTB
        ora     #$10
        sta     VIA1_PORTB
        rts
; ----------------------------------------------------------------------------
DATAHI:
;Set data line high (allows IEC DATA to be pulled up to 5V)
;Write 0 to VIA port bit, so 7406 output is Hi-Z
        lda     VIA1_PORTB
        and     #$DF
        sta     VIA1_PORTB
        rts
; ----------------------------------------------------------------------------
DATALO:
;Set data line low (holds IEC DATA to GND)
;Write 1 to VIA port bit, so 7406 output is GND
        lda     VIA1_PORTB
        ora     #$20
        sta     VIA1_PORTB
        rts
; ----------------------------------------------------------------------------
DEBPIA:
;Debounce VIA PA, invert bits 7 (data in) and 6 (clock in), then ASL A
        lda     VIA1_PORTB
        cmp     VIA1_PORTB
        bne     DEBPIA
        eor     #$C0          ;XXX different from C64 (lines inverted)
        asl     a
        rts
; ----------------------------------------------------------------------------
;Delay 1 ms using loop
W1MS:   txa                   ;Save .X
        ldx     #$B8          ;XXX same as C64 but VC-1541-DOS has $C0 here
W1MS1:  dex                   ;5us loop
        bne     W1MS1
        tax                   ;Restore X
        rts
; ----------------------------------------------------------------------------
;Initialize RS-232 variables and reset ACIA
;AINIT
ACIA_INIT:
        stz     $0389
        stz     $0388
        lda     #$40
        sta     $038A
        lda     #$30
        sta     $038B
        lda     #$10
        sta     $038C
        bra     LBE6C
LBE69:  stz     ACIA_ST       ;programmed reset of the acia
LBE6C:  php
        sei
        stz     $040F
        stz     $0410
        stz     $C3
        stz     $038D
        plp
        rts
; ----------------------------------------------------------------------------
;ACIA interrupt occurred
;Called from default interrupt handler (DEFVEC_IRQ)
;RS-232 related
;Similar to AOUT in TED-series KERNAL
ACIA_IRQ:
        lda     ACIA_ST
        bit     #$10          ;Bit 4 = Transmit Data Register Empty (0=not empty, 1=empty)
        beq     TXNMT_AIN     ;tx reg is busy
        ldx     $040E
        lda     #$40
        bit     $C3
        bne     LBE9A
        lda     #$20
        bit     $C3
        bne     TXNMT_AIN
        ldx     $040D
        lda     #$80
        bit     $C3
        beq     TXNMT_AIN
LBE9A:  stx     ACIA_DATA
        trb     $C3
        cpx     #$00
        beq     TXNMT_AIN
        lda     #$10
        cpx     $0388
        bne     TRYCS
        tsb     $C3
        bra     TXNMT_AIN
TRYCS:  cpx     $0389
        bne     TXNMT_AIN
        trb     $C3

;Similar to AIN in TED-series KERNAL
TXNMT_AIN:
        lda     ACIA_ST
        bit     #$08
        beq     RXFULL
        ldx     ACIA_DATA     ;X = byte received from ACIA
        and     #$07          ;Bit 0,1,2 = Error Flags (Parity, Framing, Overrun)
        bne     LBECE         ;Branch if an error occurred
        ;No receive error
        cpx     #0
        beq     LBED9_GOT_NULL
        lda     #' '
        cpx     $0388
        bne     LBED1
LBECE:  tsb     $C3
        rts
LBED1:  cpx     $0389
        bne     LBED9_GOT_NULL
        trb     $C3
        rts

LBED9_GOT_NULL:
        ldy     $038D
        cpy     $038A
        bcs     RXFULL
        inc     $038D
        cpy     $038B
        bcc     LBEFB
        ldy     $0388
        beq     LBEFB
        lda     #$10
        bit     $C3
        bne     LBEFB
        sty     $040E
        lda     #$40
        tsb     $C3
LBEFB:  txa
        ldx     $040F
        bne     LBF04
        ldx     $038A
LBF04:  dex
        sta     $04C0,x
        stx     $040F
RXFULL:  rts
; ----------------------------------------------------------------------------
;CHROUT to RS-232
ACIA_CHROUT:
        tax
LBF0D:  lda     MODKEY
        lsr     a ;Bit 0 = MOD_STOP
        bit     $C3
        bpl     LBF16
        bcc     LBF0D
LBF16:  stx     $040D
        lda     #$80
        tsb     $C3
        rts
; ----------------------------------------------------------------------------
;Get byte from RS-232 input buffer
AGETCH: ldy     $038D
        tya
        beq     LBF4D_CHKIN_ACIA
        dec     $038D
        ldx     $0389
        beq     LBF3E
        cpy     $038C
        bcs     LBF3E
        lda     #$10
        bit     $C3
        beq     LBF3E
        stx     $040E
        lda     #$40
        tsb     $C3
LBF3E:  ldx     $0410
        bne     LBF46
        ldx     $038A
LBF46:  dex
        lda     $04C0,x
        stx     $0410
LBF4D_CHKIN_ACIA:
        clc
        rts
; ----------------------------------------------------------------------------
;Updates time-of-day (TOD) clock.
;Called at 60 Hz by the default IRQ handler (see LFA44_VIA1_T1_IRQ).
UDTIM__:dec     JIFFIES
        bpl     UDTIM_RTS

        ;JIFFIES=0 which means 1 second has elapsed

        ;Reset jiffies for next time
        lda     #59
        sta     JIFFIES

        ;Increment seconds
        lda     #59
        inc     TOD_SECS
        cmp     TOD_SECS
        bcs     UDTIM_UNKNOWN

        ;Seconds rolled over
        ;Seconds=0, Increment minutes
        stz     TOD_SECS
        inc     TOD_MINS
        cmp     TOD_MINS
        bcs     UDTIM_UNKNOWN

        ;Minutes rolled over
        ;Minutes=0, Increment Hours
        stz     TOD_MINS
        inc     TOD_HOURS
        lda     #23
        cmp     TOD_HOURS
        bcs     UDTIM_UNKNOWN

        ;Hours rolled over
        ;Hours=0
        stz     TOD_HOURS

;TODO UNKNOWN_MINS / UNKNOWN_SECS are some kind of countdown, maybe for timeouts
UDTIM_UNKNOWN:
        ;Do nothing if both are zero
        lda     UNKNOWN_SECS
        ora     UNKNOWN_MINS
        beq     UDTIM_ALARM
        ;Decrement secs/mins
        dec     UNKNOWN_SECS
        bpl     UDTIM_ALARM
        ldx     #59
        stx     UNKNOWN_SECS
        dec     UNKNOWN_MINS

;Locations ALARM_HRS, ALARM_MINS, and ALARM_SECS count down the time remaining
;until an alarm sounds.  3 beeps sound in the final seconds of the countdown.
UDTIM_ALARM:
        ;Check if it's time to beep the alarm
        lda     ALARM_SECS
        and     #%11111100
        ora     ALARM_MINS
        ora     ALARM_HOURS
        bne     UDTIM_ALARM_DECR
        ;Beep or pause between beeps
        lda     ALARM_SECS
        beq     UDTIM_RTS
        jsr     BELL
UDTIM_ALARM_DECR:
        ;Decrement alarm secs/mins/hours
        dec     ALARM_SECS
        bpl     UDTIM_RTS
        lda     #59
        sta     ALARM_SECS
        dec     ALARM_MINS
        bpl     UDTIM_RTS
        sta     ALARM_MINS
        dec     ALARM_HOURS
UDTIM_RTS:
        rts
; ----------------------------------------------------------------------------
LBFBE:  php
        sei
        stz     UNKNOWN_SECS
        lda     $0780
        bne     LBFC9
        dec     a
LBFC9:  sta     UNKNOWN_MINS
        plp
        rts
; ----------------------------------------------------------------------------
LBFCE_SETTIM:
        sei
        lda     TOD_HOURS
        ldx     TOD_MINS
        ldy     TOD_SECS
        ;Fall through into LBFD8_RDTIM
; ----------------------------------------------------------------------------
LBFD8_RDTIM:
        sei
        sta     TOD_HOURS
        stx     TOD_MINS
        sty     TOD_SECS
        cli
        rts
; ----------------------------------------------------------------------------
WaitXticks_:
; Waits for multiple of 1/60 seconds. Interrupt must be enabled, since it
; used TOD's 1/60 val.
; Input: X = number of 1/60 seconds.
        pha
LBFE5:  lda     JIFFIES
LBFE8:  cmp     JIFFIES
        beq     LBFE8
        dex
        bpl     LBFE5
        pla
        rts
; ----------------------------------------------------------------------------
LBFF2:  pha
        phx
        phy
        jsr     LC009_CHECK_MODKEY_AND_UNKNOWN_SECS_MINS
        bcc     LBFFD
        jsr     L84C5
LBFFD:  lda     $0335
        beq     LC005
        jsr     LFA78
LC005:  ply
        plx
        pla
        rts
; ----------------------------------------------------------------------------
LC009_CHECK_MODKEY_AND_UNKNOWN_SECS_MINS:
        lda     MODKEY
        and     #MOD_BIT_7 + MOD_BIT_5
        tax
        php
        sei
        lda     UNKNOWN_SECS
        ora     UNKNOWN_MINS
        bne     LC019
        inx
LC019:  plp
        txa
        cmp     #$01
        rts

; ----------------------------------------------------------------------------

DTMF_CHAR_TO_T1CL_VALUE_INDEX:
        ;Ordered by chars: "0123456789#*"
        ;Each entry is an offset to the T1CL_VALUES table
        .byte   $01,$00,$01,$02,$00,$01,$02,$00,$01,$02,$00,$02
DTMF_T1CL_VALUES:
        .byte   $9D,$76,$51

LC033 := *+6
DTMF_DIGIT_TO_LOOP_COUNTS_INDEX:
        ;Ordered by chars: "0123456789#*"
        ;Each entry is an offset to the two loop iteration tables
        .byte   $03,$00,$00,$00,$01,$01,$01,$02,$02,$02,$03,$03
DTMF_OUTER_LOOP_COUNTS:
        .byte   $8B,$9A,$AA,$BC
DTMF_INNER_DELAY_LOOP_COUNTS:
        .byte   $8C,$7E,$72,$67

;Play the DTMF tone for a character
;This is used to dial the telephone for the modem
;Called with one of these characters in A: 0123456789#*
DTMF_PLAY_TONE_FOR_CHAR:
        ldx     #$09
        jsr     WaitXticks_
        php
        sei
        cmp     #'#'
        bne     DTMF_PLAY_NOT_POUND
LC04C:  lda     #$0b
DTMF_PLAY_NOT_POUND:
        and     #$0f
        tax

        lda     #$C0
        tsb     VIA2_ACR

        ldy     DTMF_CHAR_TO_T1CL_VALUE_INDEX,x
        lda     DTMF_T1CL_VALUES,y
        sta     VIA2_T1CL
        lda     #$01
        sta     VIA2_T1CH

        ldy     DTMF_DIGIT_TO_LOOP_COUNTS_INDEX,x
        ldx     DTMF_OUTER_LOOP_COUNTS,y

DTMF_PLAY_OUTER_LOOP:
        lda     VIA2_PORTB
        eor     #$01          ;PB1 turns DTMF generator circuit on/off
        sta     VIA2_PORTB

        lda     DTMF_INNER_DELAY_LOOP_COUNTS,y
DTMF_PLAY_INNER_DELAY_LOOP:
        dec     a
        bne     DTMF_PLAY_INNER_DELAY_LOOP

        dex
        bne     DTMF_PLAY_OUTER_LOOP

        lda     #$C0
        trb     VIA2_ACR
        plp
        rts

; ----------------------------------------------------------------------------

;OPEN the ACIA
ACIA_OPEN:
        lda     #FNADR
        sta     SINNER
        ldx     FNLEN ;FNLEN = 0?
        beq     LC0A6_CLC_RTS
        stz     ACIA_ST
        ldy     #$00
        jsr     GO_RAM_LOAD_GO_KERN
        sta     ACIA_CTRL                 ;First char -> ACIA_CTRL
        cpx     #$01 ;FNLEN = 1?
        beq     LC0A6_CLC_RTS
        iny
        jsr     GO_RAM_LOAD_GO_KERN
        cpx     #$02 ;FNLEN = 2?
        bne     LC0A8_FNLEN_GT_2
        sta     ACIA_CMD                  ;Second char -> ACIA_CMD
LC0A6_CLC_RTS:
        clc
        rts

;FNLEN > 2
LC0A8_FNLEN_GT_2:
        and     #$E0
        sta     ACIA_CMD                  ;Second char & $E0 -> ACIA_CMD

        jsr     LC193_VIA2_PB1_OFF
        jsr     LC1A1_ACIA_DTR_HI_ENABLE_RX_TX
        jsr     LC1AD_VIA2_PB4_ON

        ldy     #$02
        jsr     GO_RAM_LOAD_GO_KERN       ;A = third char

        cmp     #$41 ;'A'
        beq     LC0C3_GOT_A

        cmp     #$41 ;'A' again (weird)
        bne     LC0CE_NOT_A

LC0C3_GOT_A:
        jsr     LC1DF_LOOP_78_WHILE_WAITING_FOR_ACIA_DCD_OR_DSR_OR_STOP_KEY
        bcs     LC0E3_ERROR ;Timeout or STOP pressed
        jsr     LC1BB_ACIA_CMD_BIT_2_ON_WAIT_2_TICKS_CLC ;TODO probably phone on hook or off hook
        jmp     LC1B4_VIA2_PB4_OFF

LC0CE_NOT_A:
        jsr     LC1BB_ACIA_CMD_BIT_2_ON_WAIT_2_TICKS_CLC ;TODO probably phone on hook or off hook
        jsr     LC189_WAIT_76_TICKS_CLC
        lda     #$02
        jsr     DIAL_CHARS_IN_ACIA_FILENAME
        bcs     LC0E3_ERROR
        jsr     DIAL_CHAR_HANDLER_W_WAITS_FOR_ACIA_DCD_OR_DSR_OR_STOP_KEY
        bcs     LC0E3_ERROR
        jmp     LC1B4_VIA2_PB4_OFF

LC0E3_ERROR:
        lda     LA
        jmp     LFCF1_APPL_CLOSE

; ----------------------------------------------------------------------------

;CLOSE the ACIA
ACIA_CLOSE:
        php
        sei
        jsr     ACIA_INIT
        plp
        jmp     LC200_VIA2_PB4_OFF_ACIA_BITS_OFF_VIA2_PB1_ON_JMP_UDST

; ----------------------------------------------------------------------------

;Dial the phone number in the filename passed to OPEN
DIAL_CHARS_IN_ACIA_FILENAME:
        pha
        and     #$7F
        cmp     FNLEN
        bcc     LC0FC
        pla
        clc
        rts
LC0FC:  tay
        jsr     GO_RAM_LOAD_GO_KERN ;A = next byte from filename (number to dial?)
        jsr     LC110_DIAL_CHAR
        jsr     LC1F0_ACIA_CMD_BIT_2_OFF_WAIT_THEN_BACK_ON
        pla
        inc     a
        bcs     LC10F_RTS
        lda     MODKEY
        lsr     a ;Bit 0 = MOD_STOP
        bcc     DIAL_CHARS_IN_ACIA_FILENAME ;Keep going unless STOP pressed
LC10F_RTS:
        rts

;Dial one digit of the phone number in the ACIA filename
LC110_DIAL_CHAR:
        bit     #$40
        beq     LC116_FIND_CHAR
        and     #$DF
LC116_FIND_CHAR:
        ldy     #$0F
LC118_FIND_CHAR_LOOP:
        cmp     DIAL_CHARS,y
        bne     LC123_KEEP_GOING
        ldx     DIAL_CHAR_HANDLER_OFFSETS,y
        jmp     (DIAL_CHAR_HANDLERS,x)
LC123_KEEP_GOING:
        dey
        bpl     LC118_FIND_CHAR_LOOP
        clc
        rts

DIAL_CHARS:
        .byte   "0123456789#*RTW,"

DIAL_CHAR_HANDLER_OFFSETS:
        .byte   $00 ;0 -> DIAL_CHAR_HANDLER_0_TO_9_POUND_STAR
        .byte   $00 ;1
        .byte   $00 ;2
        .byte   $00 ;3
        .byte   $00 ;4
        .byte   $00 ;5
        .byte   $00 ;6
        .byte   $00 ;7
        .byte   $00 ;8
        .byte   $00 ;9
        .byte   $00 ;#
        .byte   $00 ;*
        .byte   $02 ;R -> DIAL_CHAR_HANDLER_R
        .byte   $04 ;T -> DIAL_CHAR_HANDLER_T
        .byte   $06 ;W -> DIAL_CHAR_HANDLER_W_WAITS_FOR_ACIA_DCD_OR_DSR_OR_STOP_KEY
        .byte   $08 ;, -> DIAL_CHAR_HANDLER_COMMA_WAITS_3B_TICKS_CLC

DIAL_CHAR_HANDLERS:
        .addr   DIAL_CHAR_HANDLER_0_TO_9_POUND_STAR
        .addr   DIAL_CHAR_HANDLER_R
        .addr   DIAL_CHAR_HANDLER_T
        .addr   DIAL_CHAR_HANDLER_W_WAITS_FOR_ACIA_DCD_OR_DSR_OR_STOP_KEY
        .addr   DIAL_CHAR_HANDLER_COMMA_WAITS_3B_TICKS_CLC

;Dial a "T" in ACIA device OPEN filename
DIAL_CHAR_HANDLER_T:
        tsx
        lda     stack+3,x
        ora     #$80
        bra     LC160

;Dial a "R" in ACIA device OPEN filename
DIAL_CHAR_HANDLER_R:
        tsx
        lda     stack+3,x
        and     #$7F
LC160:  sta     stack+3,x
        clc
        rts

;Dial a "0"-"9", "#", and "*" in ACIA device OPEN filename
;Dial the character with a DTMF tone or rotary pulses
DIAL_CHAR_HANDLER_0_TO_9_POUND_STAR:
        tsx
        ldy     stack+3,x
        bpl     PULSE_DIAL_CHAR
        jsr     DTMF_PLAY_TONE_FOR_CHAR
        clc
        rts
PULSE_DIAL_CHAR:
        cmp     #'0'
        bcc     LC188_RTS
        and     #$0F
        bne     PULSE_DIAL_LOOP
        lda     #$0A
PULSE_DIAL_LOOP:
        pha
        jsr     LC1C4_ACIA_CMD_BIT_2_OFF_WAIT_4_TICKS_CLC ;TODO probably phone on hook or off hook
        jsr     LC1BB_ACIA_CMD_BIT_2_ON_WAIT_2_TICKS_CLC ;TODO probably phone on hook or off hook
        pla
        dec     a
        bne     PULSE_DIAL_LOOP
        jsr     DIAL_CHAR_HANDLER_COMMA_WAITS_3B_TICKS_CLC
LC188_RTS:
        rts

LC189_WAIT_76_TICKS_CLC:
        jsr     DIAL_CHAR_HANDLER_COMMA_WAITS_3B_TICKS_CLC

;Dial a "," in ACIA device OPEN filename
DIAL_CHAR_HANDLER_COMMA_WAITS_3B_TICKS_CLC:
        ldx     #$3B
WAIT_X_TICKS_CLC:
        jsr     WaitXticks_
        clc
        rts

; ----------------------------------------------------------------------------
LC193_VIA2_PB1_OFF:
        lda     #$02
        trb     VIA2_PORTB
        bra     DIAL_CHAR_HANDLER_COMMA_WAITS_3B_TICKS_CLC
; ----------------------------------------------------------------------------
LC19A_VIA2_PB1_ON:
        lda     #$02
        tsb     VIA2_PORTB
        clc
        rts
; ----------------------------------------------------------------------------
LC1A1_ACIA_DTR_HI_ENABLE_RX_TX:
        lda     #$01
        tsb     ACIA_CMD
        rts
; ----------------------------------------------------------------------------
LC1A7_ACIA_DTR_LO_DISABLE_RX_TX:
        lda     #$01
        trb     ACIA_CMD
        rts
; ----------------------------------------------------------------------------
LC1AD_VIA2_PB4_ON:
        lda     #$08
        tsb     VIA2_PORTB
        clc
        rts
; ----------------------------------------------------------------------------
LC1B4_VIA2_PB4_OFF:
        lda     #$08
        trb     VIA2_PORTB
        clc
        rts
; ----------------------------------------------------------------------------
LC1BB_ACIA_CMD_BIT_2_ON_WAIT_2_TICKS_CLC: ;TODO probably phone on hook or off hook
        lda     #$04
        tsb     ACIA_CMD
        ldx     #$02
        bra     WAIT_X_TICKS_CLC
; ----------------------------------------------------------------------------
LC1C4_ACIA_CMD_BIT_2_OFF_WAIT_4_TICKS_CLC: ;TODO probably phone on hook or off hook
        lda     #$04
        trb     ACIA_CMD
        ldx     #$04
        bra     WAIT_X_TICKS_CLC
; ----------------------------------------------------------------------------
DIAL_CHAR_HANDLER_W_WAITS_FOR_ACIA_DCD_OR_DSR_OR_STOP_KEY:
        lda     ACIA_ST
        bit     #%00100000 ;Bit 5 DCD Carrier Detect (0=carrier, 1=no carrier)
        beq     DIAL_CHAR_HANDLER_COMMA_WAITS_3B_TICKS_CLC
        bit     #%01000000 ;Bit 6 DSR Data Set Ready (0=ready, 1=no ready)
        bne     LC1DD_SEC_RTS
        lda     MODKEY
        lsr     a ;Bit 0 = MOD_STOP
        bcc     DIAL_CHAR_HANDLER_W_WAITS_FOR_ACIA_DCD_OR_DSR_OR_STOP_KEY ;Keep waiting if STOP not pressed
LC1DD_SEC_RTS:
        sec
        rts
; ----------------------------------------------------------------------------
LC1DF_LOOP_78_WHILE_WAITING_FOR_ACIA_DCD_OR_DSR_OR_STOP_KEY:
        ldy     #$78
LC1E1_LOOP:
        ldx     #$01
        jsr     WaitXticks_
        jsr     DIAL_CHAR_HANDLER_W_WAITS_FOR_ACIA_DCD_OR_DSR_OR_STOP_KEY
        bcc     LC1EF_RTS
        dey
        bne     LC1E1_LOOP
        sec
LC1EF_RTS:
        rts
; ----------------------------------------------------------------------------
LC1F0_ACIA_CMD_BIT_2_OFF_WAIT_THEN_BACK_ON:
        lda     #$04
        trb     ACIA_CMD
        lda     #$C8
LC1F7_LOOP:
        dec     a
        bne     LC1F7_LOOP
        lda     #$04
        tsb     ACIA_CMD
        rts
; ----------------------------------------------------------------------------
;Called only from ACIA_CLOSE
LC200_VIA2_PB4_OFF_ACIA_BITS_OFF_VIA2_PB1_ON_JMP_UDST:
        jsr     LC1B4_VIA2_PB4_OFF
        jsr     LC1C4_ACIA_CMD_BIT_2_OFF_WAIT_4_TICKS_CLC ;TODO probably phone on hook or off hook
        jsr     LC1A7_ACIA_DTR_LO_DISABLE_RX_TX
        jsr     LC19A_VIA2_PB1_ON
        lda     #$80 ;maybe BREAK detected?
        jmp     UDST

; ----------------------------------------------------------------------------

LC211_RTC_OFFSETS:
      .byte   $04,$02,$00,$04,$06,$07,$09,$0B
; ----------------------------------------------------------------------------
;OPEN to RTC device 31
;
;OPENing the RTC device makes the RTC hardware available for reading via CHRIN
;or for synchronizing with the software TOD clock via CHROUT.  OPEN will also
;set the RTC hardware time when passed a filename with 8 bytes of time data.
RTC_OPEN:
        stz     RTC_IDX
        lda     FNLEN
        beq     LC22A               ;No filename just opens
        cmp     #$08
        beq     RTC_SET_FROM_OPEN   ;Filename of 8 bytes sets time
        lda     #$01                ;Any other length is an error
        jsr     UDST
LC22A:  clc
        rts

;Set RTC from 8 bytes of time data in filename
RTC_SET_FROM_OPEN:
        lda     #FNADR
        sta     SINNER

        ldy     #$07
LC233_LOOP:
        jsr     GO_RAM_LOAD_GO_KERN ;Get byte from filename
        sta     $0412,y
        dey
        bpl     LC233_LOOP

        lda     $0415
        ror     a
        ror     a
        ror     a
        and     #$C0
        ora     $0412
        sta     $0415
        jsr     RTC_ACCESS_ON
        lda     #$80
        tsb     VIA2_PORTA
        php
        sei
        ldy     #$0E
        lda     #$40
        jsr     RTC_UNKNOWN_VIA_STUFF
        ldx     #$01
LC25D:  lda     $0412,x
        jsr     LC325
        inx
        cpx     #$08
        bne     LC25D
        jsr     RTC_ACCESS_OFF
        plp
        stz     RTC_IDX
        clc
        rts
; ----------------------------------------------------------------------------
;CHROUT to RTC device 31
;
;Sending any character to the RTC device will read the hardware RTC time
;and set the software TOD clock (TI$) to it.  The character sent is ignored.
RTC_CHROUT:
        jsr     LC2CE_READ_RTC_HARDWARE
        php
        sei
        sed
        lda     $0412
        ldx     $0415
        bne     LC287
        cmp     #$12
        bne     LC290
        lda     #$00
        bra     LC290
LC287:  dex
        bne     LC290
        cmp     #$12
        beq     LC290
        adc     #$12
LC290:  jsr     RTC_SHIFT_LOOKUP_SUBTRACT
        sta     TOD_HOURS
        lda     $0413
        jsr     RTC_SHIFT_LOOKUP_SUBTRACT
        sta     TOD_MINS
        lda     $0414
        jsr     RTC_SHIFT_LOOKUP_SUBTRACT
        sta     TOD_SECS
        stz     RTC_IDX
        plp
        rts
; ----------------------------------------------------------------------------
;CHRIN from RTC device 31
;
;Reading a character from the RTC device will read the RTC hardware and return
;8 bytes of time data followed by a carriage return ($0D).  The software TOD
;clock is not affected.  Reading past the CR will read the RTC hardware again
;and return new time data.
RTC_CHRIN:
        ldx     RTC_IDX
        beq     RTC_READ_HW_THEN_FIRST_RAM_VALUE
        cpx     #$08
        bcc     RTC_READ_NEXT_VALUE_FROM_RAM
        lda     #$0D ;Carriage return
        stz     RTC_IDX
        clc
        rts
; ----------------------------------------------------------------------------
RTC_READ_HW_THEN_FIRST_RAM_VALUE:
        jsr     LC2CE_READ_RTC_HARDWARE
        stz     RTC_IDX
        ;Fall through
; ----------------------------------------------------------------------------
RTC_READ_NEXT_VALUE_FROM_RAM:
        ldx     RTC_IDX
        lda     $0412,x
        inc     RTC_IDX
        clc
        rts
; ----------------------------------------------------------------------------
LC2CE_READ_RTC_HARDWARE:
        jsr     RTC_ACCESS_ON
        ldx     #$07
LC2D3:  jsr     LC30E
        sta     $0412,x
        dex
        bpl     LC2D3
        jsr     RTC_ACCESS_OFF
        jsr     RTC_ACCESS_ON
        ldx     #$07
LC2E4:  jsr     LC30E
        cmp     $0412,x
        bne     LC2CE_READ_RTC_HARDWARE
        dex
        bne     LC2E4
        jsr     RTC_ACCESS_OFF
        lda     $0412
        and     #$3F
        sta     $0412
        lda     $0416
        and     #$0F
        sta     $0416
        lda     $0415
        rol     a
        rol     a
        rol     a
        and     #$03
        sta     $0415
        rts
; ----------------------------------------------------------------------------
LC30E:  ldy     LC211_RTC_OFFSETS,x
        phy
        jsr     RTC_READ_NIB
        sta     RTC_IDX
        ply
        iny
        jsr     RTC_READ_NIB
        asl     a
        asl     a
        asl     a
        asl     a
        ora     RTC_IDX
        rts
; ----------------------------------------------------------------------------
LC325:  pha
        and     #$0F
        ldy     LC211_RTC_OFFSETS,x
        jsr     LC337
        pla
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        ldy     LC211_RTC_OFFSETS,x
        iny
        ;Fall through

LC337:  pha
        lda     #$40
        jsr     RTC_UNKNOWN_VIA_STUFF
        ply
        lda     #$20
        ;Fall through

; ----------------------------------------------------------------------------
RTC_UNKNOWN_VIA_STUFF:
        pha
        lda     #$7F
        trb     VIA2_PORTA
        tya
        tsb     VIA2_PORTA

        pla
        tsb     VIA2_PORTA
        trb     VIA2_PORTA
        rts
; ----------------------------------------------------------------------------
; Read a nibble from the RTC chip.
; $40 is for AW (address write) signal for the RTC.
; Input: Y = RTC register number
; Output: A = read value
RTC_READ_NIB:
        lda     #$40
        jsr     RTC_UNKNOWN_VIA_STUFF
        lda     #$1F
        tsb     VIA2_PORTA
        ldy     VIA2_PORTA
        trb     VIA2_PORTA
        tya
        and     #$0F
        rts
; ----------------------------------------------------------------------------
RTC_ACCESS_ON:
        stz     VIA2_PORTA

        lda     #$02
        tsb     VIA1_PORTB
        rts
; ----------------------------------------------------------------------------
RTC_ACCESS_OFF:
        lda     #$02
        trb     VIA1_PORTB
        rts
; ----------------------------------------------------------------------------
;Used for converting RTC values to TOD values
RTC_SHIFT_LOOKUP_SUBTRACT:
        pha
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        tay
        pla
        cld
        sec
        sbc     LC382,y
        rts
LC382:  .byte 0, 6, 12, 18, 24, 30, 36, 42, 48, 54

; ----------------------------------------------------------------------------
;CHROUT to Centronics
;Wait for /BUSY to go high, or STOP key pressed, or timeout
;Returns carry=1 if error (STOP or timeout)
CENTRONICS_CHROUT:
        ldx     SATUS
        bne     LC3AC

        pha ;Save byte to send
        ldy     #$F0 ;loops before timeout
LC393:  lda     VIA2_PORTB
        and     #$40 ;PB6 = /BUSY
        bne     LC3B0 ;Branch if /BUSY=high

        lda     MODKEY
        lsr     a ;Bit 0 = MOD_STOP
        lda     #$00
        bcs     LC3AB ;Return early if pressed

        ldx     #$01
        jsr     WaitXticks_

        dey
        bne     LC393 ;Loop until timeout

        lda     #$01
LC3AB:  plx
LC3AC:  sec
        jmp     UDST

;/BUSY has gone high, so send the byte now
;Always returns carry=0 (OK)
LC3B0:  ldx     #$03
LC3B2:  dex
        bpl     LC3B2 ;delay a bit after /BUSY=1

        ;PORTA = Centronics data lines
        pla     ;A=byte to send
        sta     VIA2_PORTA ;PA = Centronics data

        lda     #$20 ;PB5 = ?
        trb     VIA2_PORTB
        tsb     VIA2_PORTB

        lda     #$02 ;CA2 = ?
        tsb     VIA2_PCR
        trb     VIA2_PCR

        clc
        rts

; ----------------------------------------------------------------------------

;Translate a character received from the ACIA RX
;Called with A = char, X = secondary address & $0F
TRANSL_ACIA_RX:
        pha
        lda     LC44A_ACIA_RX_ONLY,x
        bra     TRANSLATE

;Translate a character before sending it to ACIA TX or Centronics
;Called with A = char, X = secondary address & $0F
TRANSL_ACIA_TX_OR_CENTRONICS:
        pha
        lda     LC444_ACIA_TX_AND_CENTRONICS,x
        ;Fall through

TRANSLATE:
        cpx     #$00
        bne     LC3DC
        clc
LC3DA:  pla
        rts

LC3DC:  cpx     #$07
        bcs     LC3DA
        plx
        phy
        tay
        txa
LC3E4:  phy
        ldx     TRANSL_HANDLER_OFFSETS,y
        jsr     JMP_TO_TRANSL_HANDLER_X
        ply
        iny
        bcs     LC3E4
        ply
        rts

JMP_TO_TRANSL_HANDLER_X:
        jmp     (TRANSL_HANDLERS,x)
TRANSL_HANDLERS:
        .addr   TRANSL_HANDLER_X00
        .addr   TRANSL_HANDLER_X01
        .addr   TRANSL_HANDLER_X02
        .addr   TRANSL_HANDLER_X03
        .addr   TRANSL_HANDLER_X04
        .addr   TRANSL_HANDLER_X05
        .addr   TRANSL_HANDLER_X06
        .addr   TRANSL_HANDLER_X07
        .addr   TRANSL_HANDLER_X08
        .addr   TRANSL_HANDLER_X09
        .addr   TRANSL_HANDLER_X0A
        .addr   TRANSL_HANDLER_X0B
        .addr   TRANSL_HANDLER_X0C
        .addr   TRANSL_HANDLER_X0D
        .addr   TRANSL_HANDLER_X0E
        .addr   TRANSL_HANDLER_X0F
        .addr   TRANSL_HANDLER_X10

TRANSL_HANDLER_OFFSETS:
        .byte   $02,$04,$06,$08,$0A,$0C,$00,$02
        .byte   $06,$08,$0A,$0C,$00,$02,$18,$06
        .byte   $1E,$0A,$1C,$10,$00,$02,$16,$0E
        .byte   $00,$02,$1A,$1C,$10,$00,$04,$06
        .byte   $14,$00,$04,$12,$00,$04,$20,$00
        .byte   $06,$14,$00,$12,$00,$20

LC444_ACIA_TX_AND_CENTRONICS:
        .byte   $00,$00,$07,$0D,$15,$15

LC44A_ACIA_RX_ONLY:
        .byte   $19,$1E,$22,$25,$28,$2B,$2D
; ----------------------------------------------------------------------------
TRANSL_HANDLER_X10:
        cmp     #$5E
        bcc     LC462
        cmp     #$80
        bcs     LC462
        sec
        sbc     #$5E
        tay
        lda     LC464,y
        clc
        rts
LC462:  sec
        rts
LC464:  .byte   $71,$7F,$62,$60,$7B,$AE,$BD,$AD
        .byte   $B0,$B1,$3E,$7F,$7A,$56,$AC,$BB
        .byte   $BE,$BC,$B8,$68,$A9,$B2,$B3,$B1
        .byte   $AB,$76,$6E,$6D,$B7,$AF,$67,$68
        .byte   $78,$7E
; ----------------------------------------------------------------------------
TRANSL_HANDLER_X00:
        clc
        rts
; ----------------------------------------------------------------------------
TRANSL_HANDLER_X02:
        cmp     #$41
        bcc     LC494
        cmp     #$5B
        bcs     LC494
        eor     #$20
        clc
        rts
LC494:  sec
        rts
; ----------------------------------------------------------------------------
TRANSL_HANDLER_X03:
        cmp     #$61
        bcc     LC4A2
        cmp     #$7B
        bcs     LC4A2
        eor     #$20
        clc
        rts
LC4A2:  sec
        rts
; ----------------------------------------------------------------------------
TRANSL_HANDLER_X0A:
        ldx     #$04
LC4A6:  cmp     LC4B5,x
        beq     LC4B0
        dex
        bpl     LC4A6
        sec
        rts
LC4B0:  lda     LC4BD,x
        clc
        rts
LC4B5:  .byte   $7B,$7D,$7E,$60,$5F,$7B,$7D,$60
LC4BD:  .byte   $A6,$A8,$5F,$BA,$A4,$E6,$E8,$FA
; ----------------------------------------------------------------------------
TRANSL_HANDLER_X01:
        cmp     #$80
        bcc     LC4D1
        cmp     #$A0
        bcs     LC4D1
        and     #$7F
        clc
        rts
LC4D1:  sec
        rts
; ----------------------------------------------------------------------------
TRANSL_HANDLER_X0D:
        cmp     #$60
        bcc     LC4E4
        cmp     #$80
        bcs     LC4E4
        sec
        sbc     #$60
LC4DE:  tay
        lda     LC4F3,y
        clc
        rts
LC4E4:  cmp     #$C0
        bcc     LC4F1
        cmp     #$E0
        bcs     LC4F1
        sec
        sbc     #$C0
        bra     LC4DE
LC4F1:  sec
        rts
LC4F3:  .byte   $61,$73,$60,$61,$7A,$7A,$7B,$7C
        .byte   $7D,$63,$65,$64,$4C,$79,$78,$66
        .byte   $63,$5E,$7B,$6B,$7C,$66,$77,$4F
        .byte   $7E,$7D,$6A,$62,$60,$60,$7F,$5F
; ----------------------------------------------------------------------------
TRANSL_HANDLER_X0E:
        cmp     #$A0
        bcc     LC524
        cmp     #$C0
        bcs     LC524
        sec
        sbc     #$A0
LC51E:  tay
        lda     LC533,y
        clc
        rts
LC524:  cmp     #$E0
        bcc     LC531
        cmp     #$FF
        bcs     LC531
        sec
        sbc     #$E0
        bra     LC51E
LC531:  sec
        rts
LC533:  .byte   $20,$7C,$7B,$7A,$7B,$7C,$74,$7D
        .byte   $76,$72,$7D,$76,$6C,$65,$63,$7B
        .byte   $66,$75,$73,$74,$7C,$7C,$7D,$7A
        .byte   $7A,$7B,$64,$6D,$6F,$64,$6E,$25
; ----------------------------------------------------------------------------
TRANSL_HANDLER_X08:
        cmp     #$FF
        bne     LC55B
        lda     #$7F
        clc
        rts
LC55B:  sec
        rts
; ----------------------------------------------------------------------------
TRANSL_HANDLER_X09:
        cmp     #$5F
        bne     LC565
        lda     #$A4
        clc
        rts
LC565:  sec
        rts
; ----------------------------------------------------------------------------
TRANSL_HANDLER_X0C:
        ldx     #$08
LC569:  cmp     LC581,x
        beq     LC573
        dex
        bpl     LC569
        sec
        rts
LC573:  lda     LC578,x
        clc
        rts
LC578:  .byte   $5B,$5C,$5D,$2D,$27,$5F,$5B,$5D,$27
LC581:  .byte   $A6,$7C,$A8,$5F,$BA,$A4,$E6,$E8,$FA
; ----------------------------------------------------------------------------
TRANSL_HANDLER_X0B:
        ldx     #$07
LC58C:  cmp     LC4BD,x
        beq     LC596
        dex
        bpl     LC58C
        sec
        rts
LC596:  lda     LC4B5,x
        clc
        rts
; ----------------------------------------------------------------------------
TRANSL_HANDLER_X0F:
        cmp     #$7B
        bcc     LC5AC
        cmp     #$80
        bcs     LC5AC
        sec
        sbc     #$60
        tay
        lda     LC4F3,y
        clc
        rts
LC5AC:  sec
        rts
; ----------------------------------------------------------------------------
TRANSL_HANDLER_X05:
        cmp     #$C1
        bcc     LC5BA
        cmp     #$DB
        bcs     LC5BA
        eor     #$80
        clc
        rts
LC5BA:  sec
        rts
; ----------------------------------------------------------------------------
TRANSL_HANDLER_X04:
        ldx     #$0A
LC5BE:  cmp     LC5CD,x
        beq     LC5C8
        dex
        bpl     LC5BE
        sec
        rts
LC5C8:  lda     LC5D8,x
        clc
        rts
LC5CD:  .byte   $A6,$A8,$BA,$5F,$A4,$E6,$E8,$FA,$7B,$7E,$7F
LC5D8:  .byte   $7B,$7D,$60,$7E,$5F,$7B,$7D,$60,$20,$20,$20
; ----------------------------------------------------------------------------
TRANSL_HANDLER_X06:
        cmp     #$A0
        bcc     LC5ED
        cmp     #$C0
        bcs     LC5ED
        bra     LC5F1
LC5ED:  cmp     #$E0
        bcc     LC5F5
LC5F1:  lda     #$20
        clc
        rts
LC5F5:  sec
        rts
; ----------------------------------------------------------------------------
TRANSL_HANDLER_X07:
        cmp     #$60
        bcc     LC601
        cmp     #$80
        bcs     LC601
        bra     LC605
LC601:  cmp     #$A0
        bcc     LC609
LC605:  lda     #$20
        clc
        rts
LC609:  sec
        rts

; ----------------------------------------------------------------------------
;Bell-related
JMP_BELL_RELATED_X:
        jmp     (LC60E,x)
LC60E:  .addr   UDBELL
        .addr   LC61E
        .addr   LC626
        .addr   LC63F
        .addr   BELL
; ----------------------------------------------------------------------------
;Called at 60 Hz by the default IRQ handler (see LFA44_VIA1_T1_IRQ).
;Bell-related
UDBELL: jsr     LC63F
        bcs     LC634
        rts
; ----------------------------------------------------------------------------
;Bell-related
LC61E:  sta     VIA2_T2CL
        sty     VIA2_T2CH
        bra     LC63F
; ----------------------------------------------------------------------------
;Bell-related
LC626:  php
        sei
        eor     #$FF
        sta     $041A
        tya
        eor     #$FF
        sta     $041B
        .byte   $2C
LC634:  php
        sei
        inc     $041A
        bne     LC63E
        inc     $041B
LC63E:  .byte   $2C
LC63F:  php
        sei
        lda     $041A
        ora     $041B
        beq     LC654
        lda     #$10
        tsb     VIA2_ACR
        sta     VIA2_SR
        plp
        sec
        rts
; ----------------------------------------------------------------------------
;Bell-related
LC654:  lda     #$10
        trb     VIA2_ACR
        plp
        clc
        rts
; ----------------------------------------------------------------------------
;CTRL$(7) Bell
CODE_07_BELL:
BELL:   lda     #$A0
        tay
        jsr     LC61E
        lda     #$06
        ldy     #$00
        jmp     LC626


MMU_HELPER_ROUTINES:
; ----------------------------------------------------------------------------
; The following routines will be copied from $0338 to the RAM and
; used from there. Guessed purpose: the ROM itself is not always paged in, so
; we need them to be in RAM. Note about the "dummy writes", those (maybe ...)
; used to set/reset flip-flops to switch on/off mapping of various parts of
; the memories, but dunno what exactly :(
; ----------------------------------------------------------------------------
; My best guess so far: dummy writes to ...
; * $FA00: enables lower parts of KERNAL to be "seen"
; * $FA80: disables the above but enable ROM mapped from $4000 to be seen
; * $FB00: disables all mapped, but the "high area"
; "High area" is the end of the KERNAL & some I/O registers from
; at $FA00 (or probably from $F800?) and needs to be always (?)
; seen.
; ----------------------------------------------------------------------------
; This will be $0338 in RAM. It's even used by BASIC for example, the guessed
; purpose: allow to use RAM for BASIC even at an area where there is BASIC
; ROM paged in (from $4000) during its execution. $033C will be the RAM zp
; loc of LDA (zp),Y op.
;GO_RAM_LOAD_GO_APPL:
        sta     MMU_MODE_RAM
        lda     ($00),y ;TODO add symbol for ZP address
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
; This will be $0341 in RAM.
; $0345 will be the RAM zp loc of STA (zp),Y op.
; This routine is also used by BASIC.
; It seems ZP loc of STA is modified in RAM.
;GO_RAM_STORE_GO_APPL:
        sta     MMU_MODE_RAM
        sta     ($00),y ;TODO add symbol for ZP address
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
; This will be $034A in RAM.
; "SINNER" ($034E) will be the RAM zp loc of LDA (zp),Y op.
;GO_RAM_LOAD_GO_KERN:
        sta     MMU_MODE_RAM
;GO_NOWHERE_LOAD_GO_KERN:
        lda     ($00),y         ;ZP address is GRLGK_ADDR
        sta     MMU_MODE_KERN
        rts
; ----------------------------------------------------------------------------
; This will be $0353 in RAM.
; $0357 will be the RAM zp loc of LDA (zp),Y op.
;GO_APPL_LOAD_GO_KERN:
        sta     MMU_MODE_APPL
        lda     ($00),y ;TODO add symbol for ZP address
        sta     MMU_MODE_KERN
        rts
; ----------------------------------------------------------------------------
; This will be $035C in RAM.
; $0360 will be the RAM zp loc of STA (zp),Y op.
;GO_RAM_STORE_GO_KERN:
        sta     MMU_MODE_RAM
;GO_NOWHERE_STORE_GO_KERN:
        sta     ($00),y ;TODO add symbol for ZP address
        sta     MMU_MODE_KERN
        rts
; ----------------------------------------------------------------------------
KL_RESTOR:
        ldx     #$90
        ldy     #$FA
        clc
KL_VECTOR:
        php
        sei
        stx     FNADR
        sty     FNADR+1
; This copies the routines from $C669 into the RAM from $338.
        ldx     #$2C
LC6A3:  lda     MMU_HELPER_ROUTINES,x
        sta     GO_RAM_LOAD_GO_APPL,x
        dex
        bpl     LC6A3
        ldy     #FNADR
        sty     SINNER
        sty     $0360
        ldy     #$23
LC6B6:  lda     RAMVEC_IRQ,y
        bcs     LC6BE
        jsr     GO_RAM_LOAD_GO_KERN
LC6BE:  sta     RAMVEC_IRQ,y
        bcc     LC6C6
        jsr     GO_RAM_STORE_GO_KERN
LC6C6:  dey
        bpl     LC6B6
        plp
        rts
; ----------------------------------------------------------------------------
LC6CB:  sei
        ldx     #$23
LC6CE:  ldy     RAMVEC_IRQ,x
        lda     $03C3,x
        sta     RAMVEC_IRQ,x
        tya
        sta     $03C3,x
        dex
        bpl     LC6CE
        rts
; ----------------------------------------------------------------------------
MON_START:
        stz     L03B7
        stz     MON_MMU_MODE
        ldx     #$FF
        stx     $03BB
        txs
        ldx     #$00
        jsr     LD230_JMP_LD233_PLUS_X  ;-> LD247_X_00
        jsr     PRIMM
        .byte   $0D,"COMMODORE LCD MONITOR",0
        bra     LC748
; ----------------------------------------------------------------------------
MON_BRK:
        cld
        ldx     #$05
LC70F:  pla
        sta     $03B5,x
        dex
        bpl     LC70F
        jsr     LB2E4_HIDE_CURSOR
        jsr     KL_RESTOR
        jsr     CLRCH
        tsx
        stx     $03BB
        cpx     #$0A
        bcs     LC72A
        ldx     #$FF
        txs
LC72A:  php
        jsr     PRIMM
        .byte   $0D,"BREAK",0
        plp
        bcs     LC748
        jsr     PRIMM
        .byte   " STACK RESET",0
LC748:  lda     #$C0
        sta     MSGFLG
        lda     #$00
        sta     $CB
        sta     $CC
        cli
        ;Fall through
; ----------------------------------------------------------------------------
MON_CMD_REGISTERS:
        jsr     MON_PRINT_REGS_WITH_HEADER
        bra     MON_MAIN_INPUT
; ----------------------------------------------------------------------------
MON_BAD_COMMAND:
        jsr     KL_RESTOR
        jsr     CLRCH
        jsr     PRIMM
        .byte   $1D,$1D,":?",0
        ;Fall through
; ----------------------------------------------------------------------------
;Input a monitor command and dispatch it
MON_MAIN_INPUT:
        jsr     PrintNewLine
        stz     $CD
        ldx     #$00
LC76E_GET_NEXT_CHAR:
        jsr     LFD3D_CHRIN ;BASIN
        sta     L0470,x
        stx     $CE
        inx
        cpx     #80  ;80 chars is max line length
        beq     LC77F_GOT_LINE
        cmp     #$0D ;Return
        bne     LC76E_GET_NEXT_CHAR
LC77F_GOT_LINE:
        jsr     GNC
        beq     MON_MAIN_INPUT
        cmp     #' '
        beq     LC77F_GOT_LINE
        ldx     #$10
LC78A:  cmp     MON_COMMANDS,x
        beq     LC794
        dex
        bpl     LC78A
        bmi     MON_BAD_COMMAND
LC794:  cpx     #$0E
        bcs     LC7A6
        txa
        asl     a
        tax
        lda     MON_CMD_ENTRIES+1,x
        pha
        lda     MON_CMD_ENTRIES,x
        pha
        jmp     MON_PARSE_HEX_WORD
LC7A6:  sta     V1541_FNLEN
        jsr     PrintNewLine
        jmp     MON_CMD_LOAD_SAVE_VERIFY
; ----------------------------------------------------------------------------
MON_CMD_MEMORY:
        bcs     LC7B9
        jsr     LCB19
        jsr     MON_PARSE_HEX_WORD
        bcc     LC7BF
LC7B9:  lda     #8-1  ;8 lines of memory to print
        sta     $C7
        bne     LC7D0_LOOP
LC7BF:  jsr     SUB0M2
        lsr     a
        ror     $C7
        lsr     a
        ror     $C7
        lsr     a
        ror     $C7
        lsr     a
        ror     $C7
        sta     $C8
LC7D0_LOOP:
        jsr     LFDB9_STOP
        beq     LC7E2
        jsr     MON_PRINT_LINE_OF_MEMORY
        lda     #$10
        jsr     ADDT2
        jsr     DECT0
        bcs     LC7D0_LOOP
LC7E2:  jmp     MON_MAIN_INPUT
; ----------------------------------------------------------------------------
;Command ";" allows the user to modify the registers by typing over:
;  "   PC  SR AC XR YR SP MODE OPCODE   MNEMONIC"
;  "; 0000 00 00 00 00 FF  02  00       BRK"
MON_CMD_MODIFY_REGISTERS:
        bcs     LC81B_DONE ;Branch if no args

        ;Set new PC
        lda     $C7
        ldy     $C8
        sta     $03B6 ;PC low
        sty     $03B5 ;PC high

        ;Set new SR, AC, XR, YR, SP
        ldy     #$00
LC7F3_LOOP:
        jsr     MON_PARSE_HEX_WORD
        bcs     LC81B_DONE
        lda     $C7
        sta     L03B7,y
        iny
        cpy     #$05 ;0=SR, 1=AC, 2=XR,3=YR,4=SP
        bcc     LC7F3_LOOP

        ;Set new MODE
        ;Valid values are 0, 1, 2.  Any other value leaves mode unchanged.
        jsr     MON_PARSE_HEX_WORD
        bcs     LC81B_DONE
        lda     $C7
        bne     LC810_MODE_NOT_0
        stz     MON_MMU_MODE        ;Keep 0 for MMU_MODE_RAM
        bra     LC81B_DONE
LC810_MODE_NOT_0:
        cmp     #$01
        beq     LC818_STA_MMU_MODE  ;Keep 1 for MMU_MODE_APPL
        cmp     #$02
        bne     LC81B_DONE
LC818_STA_MMU_MODE:
        sta     MON_MMU_MODE        ;Keep 2 for MMU_MODE_KERN

LC81B_DONE:
        jsr     PRIMM
        .byte   $91,$91,$00  ;Cursor Up twice
        jmp     MON_CMD_REGISTERS
; ----------------------------------------------------------------------------
MON_CMD_MODIFY_MEMORY:
        bcs     LC83A_MODFIY_DONE ;Branch if no arg
        jsr     LCB19
        ldy     #$00
LC82B_LOOP:
        jsr     MON_PARSE_HEX_WORD
        bcs     LC83A_MODFIY_DONE ;Branch if no input
        lda     $C7
        jsr     LCC4B
        iny
        cpy     #$10
        bcc     LC82B_LOOP
LC83A_MODFIY_DONE:
        jsr     ESC_O_CANCEL_MODES
        lda     #$91 ;CHR($145) Cursor Up
        jsr     KR_ShowChar_
        jsr     MON_PRINT_LINE_OF_MEMORY
        jmp     MON_MAIN_INPUT
; ----------------------------------------------------------------------------
MON_CMD_GO:
        bcs     LC854
        lda     $C7
        sta     $03B6
        lda     $C8
        sta     $03B5
LC854:  jsr     PrintNewLine
        ldx     $03BB
        txs
        ldx     $03B5
        ldy     $03B6
        bne     LC864
        dex
LC864:  dey
        phx
        phy
        ldx     MON_MMU_MODE
        cpx     #$03
        bcc     LC870
        ldx     #$02
LC870:  lda     LC886,x
        pha
        lda     LC889,x
        pha
        lda     L03B7
        pha
        ldx     $03B9
        ldy     $03BA
        lda     $03B8
        rti
; ----------------------------------------------------------------------------
LC886:  .byte   $FD,$FD,$FD                     ; C886 FD FD FD                 ...
LC889:  .byte   "~zf"                           ; C889 7E 7A 66                 ~zf

MON_COMMANDS:
        .byte   "X" ;Exit
        .byte   "M" ;Memory
        .byte   "R" ;Registers
        .byte   "G" ;Go
        .byte   "T" ;Transfer
        .byte   "C" ;Compare
        .byte   "D" ;Disassemble
        .byte   "A" ;Assemble
        .byte   "." ;Alias for Assemble
        .byte   "H" ;Hunt
        .byte   "F" ;Fill
        .byte   ">" ;Modify Memory
        .byte   ";" ;Modify Registers
        .byte   "W" ;Walk
        .byte   "L" ;Load     \
        .byte   "S" ;Save      | L,S,V are handled separately, not in the table below
        .byte   "V" ;Verify   /

MON_CMD_ENTRIES:
        .word  MON_CMD_EXIT-1
        .word  MON_CMD_MEMORY-1
        .word  MON_CMD_REGISTERS-1
        .word  MON_CMD_GO-1
        .word  MON_CMD_TRANSFER-1
        .word  MON_CMD_COMPARE-1
        .word  MON_CMD_DISASSEMBLE-1
        .word  MON_CMD_ASSEMBLE-1
        .word  MON_CMD_ASSEMBLE-1
        .word  MON_CMD_HUNT-1
        .word  MON_CMD_FILL-1
        .word  MON_CMD_MODIFY_MEMORY-1
        .word  MON_CMD_MODIFY_REGISTERS-1
        .word  MON_CMD_WALK-1
; ----------------------------------------------------------------------------
MON_PRINT_LINE_OF_MEMORY:
        jsr     PRIMM
        .byte   $0D,">",0
        jsr     PrintHexWordAndSpaceFromMem
        ldy     #0
LC8C4:  tya
        and     #$03
        bne     LC8CF
        jsr     PRIMM
        .byte   "  ",0
LC8CF:  jsr     LCC67
        jsr     PrintHexByteAndSpace
        iny
        cpy     #$10
        bcc     LC8C4
        jsr     PRIMM
        .byte   ":",$12,$00
        ldy     #$00
LC8E2:  jsr     LCC67
        and     #$7F
        cmp     #$20
        bcs     LC8ED
        lda     #'.'
LC8ED:  jsr     KR_ShowChar_
        iny
        cpy     #$10
        bcc     LC8E2
        rts
; ----------------------------------------------------------------------------
MON_CMD_COMPARE:
        stz     $D1
        lda     #$00
        sta     $D0
        bra     LC909_TRANSFER_OR_COMPARE
; ----------------------------------------------------------------------------
MON_CMD_TRANSFER:
        lda     #$80
        sta     $D0
        jsr     LCB7E
        bcs     LC952_TRANSFER_BAD_ARG
        bra     LC913

LC909_TRANSFER_OR_COMPARE:
        jsr     LCB67
        bcs     LC952_TRANSFER_BAD_ARG
        jsr     MON_PARSE_HEX_WORD
        bcs     LC952_TRANSFER_BAD_ARG
LC913:  jsr     PrintNewLine
        ldy     #$00
LC918:  jsr     LCC67
        bit     $D0
        bpl     LC922
        jsr     LCC46
LC922:  pha
        jsr     LCC6A
        sta     $D2
        pla
        cmp     $D2
        beq     LC935
        jsr     LFDB9_STOP
        beq     LC94F_TRANSFER_DONE
        jsr     PrintHexWordAndSpaceFromMem
LC935:  lda     $D1
        beq     LC941
        jsr     DECT0
        jsr     LCB52
        bra     LC94A
LC941:  inc     $C7
        bne     LC947
        inc     $C8
LC947:  jsr     INCT2
LC94A:  jsr     LCB44
        bcs     LC918
LC94F_TRANSFER_DONE:
        jmp     MON_MAIN_INPUT
LC952_TRANSFER_BAD_ARG:
        jmp     MON_BAD_COMMAND
; ----------------------------------------------------------------------------
MON_CMD_HUNT:
        jsr     LCB67
        bcs     LC9B6_HUNT_BAD_ARG
        ldy     #$00
        jsr     GNC
        cmp     #$27
        bne     LC975
        jsr     GNC
LC966:  sta     $0450,y
        iny
        jsr     GNC
        beq     LC98A
        cpy     #$20
        bne     LC966
        beq     LC98A
LC975:  sty     $03A0
        jsr     MON_DEC_CD_THEN_PARSE_HEX_WORD
LC97B:  lda     $C7
        sta     $0450,y
        iny
        jsr     MON_PARSE_HEX_WORD
        bcs     LC98A
        cpy     #$20
        bne     LC97B
LC98A:  sty     V1541_FNLEN
        jsr     PrintNewLine
LC990:  ldx     #$00
        ldy     #$00
LC994:  jsr     LCC67
        cmp     $0450,x
        bne     LC9AB
        iny
        inx
        cpx     V1541_FNLEN
        bne     LC994
        jsr     LFDB9_STOP
        beq     LC9B3_HUNT_DONE
        jsr     PrintHexWordAndSpaceFromMem
LC9AB:  jsr     INCT2
        jsr     LCB44
        bcs     LC990
LC9B3_HUNT_DONE:
        jmp     MON_MAIN_INPUT
LC9B6_HUNT_BAD_ARG:
        jmp     MON_BAD_COMMAND
; ----------------------------------------------------------------------------
MON_CMD_LOAD_SAVE_VERIFY:
        ldy     #$01
        sty     FA
        sty     SA
        dey
        sty     FNLEN
        sty     SATUS
        sty     VERCHK
        lda     #>L0450
        sta     FNADR+1
        lda     #<L0450
        sta     FNADR
LC9D0:  jsr     GNC
        beq     LCA33_TRY_LOAD_OR_VERIFY
        cmp     #' '
        beq     LC9D0
        cmp     #'"'
        bne     LC9F5_LSV_BAD_ARG
        ldx     $CD
LC9DF_LOOP:
        cpx     $CE
        bcs     LCA33_TRY_LOAD_OR_VERIFY
        lda     L0470,x
        inx
        cmp     #'"'
        beq     LC9F8_TRY_SAVE
        sta     (FNADR),y
        inc     FNLEN
        iny
        cpy     #$11
        bcc     LC9DF_LOOP
LC9F5_LSV_BAD_ARG:
        jmp     MON_BAD_COMMAND

LC9F8_TRY_SAVE:
        stx     $CD
        jsr     GNC
        jsr     MON_PARSE_HEX_WORD
        bcs     LCA33_TRY_LOAD_OR_VERIFY
        lda     $C7
        beq     LC9F5_LSV_BAD_ARG
        cmp     #$03
        beq     LC9F5_LSV_BAD_ARG
        sta     FA
        jsr     MON_PARSE_HEX_WORD
        bcs     LCA33_TRY_LOAD_OR_VERIFY
        jsr     LCB19
        jsr     MON_PARSE_HEX_WORD
        bcs     LC9F5_LSV_BAD_ARG
        jsr     PrintNewLine
        ldx     $C7
        ldy     $C8
        lda     V1541_FNLEN
        cmp     #'S' ;SAVE
        bne     LC9F5_LSV_BAD_ARG
        lda     #$00
        sta     SA
        lda     #$CB
        jsr     LFD82_SAVE_AND_GO_KERN
LCA30_LSV_DONE:
        jmp     MON_MAIN_INPUT

LCA33_TRY_LOAD_OR_VERIFY:
        lda     V1541_FNLEN
        cmp     #'V' ;VERIFY
        beq     LCA40
        cmp     #'L' ;LOAD
        bne     LC9F5_LSV_BAD_ARG
        lda     #$00
LCA40:  jsr     LFD63_LOAD_THEN_GO_KERN
        lda     SATUS
        and     #$10
        beq     LCA30_LSV_DONE
        jsr     PRIMM
        .byte   "ERROR",0
        bra     LCA30_LSV_DONE
; ----------------------------------------------------------------------------
MON_CMD_FILL:
        jsr     LCB67
        bcs     LCA70_FILL_BAD_ARG
        jsr     MON_PARSE_HEX_WORD
        bcs     LCA70_FILL_BAD_ARG
        ldy     #$00
LCA60_FILL_LOOP:
        lda     $C7
        jsr     LCC4B
        jsr     INCT2
        jsr     LCB44
        bcs     LCA60_FILL_LOOP
        jmp     MON_MAIN_INPUT
LCA70_FILL_BAD_ARG:
        jmp     MON_BAD_COMMAND
; ----------------------------------------------------------------------------
;Decrement $CD then parse 16-bit hex value from user input into $C7/C8
MON_DEC_CD_THEN_PARSE_HEX_WORD:
        dec     $CD

;Parse 16-bit hex value from user input into $C7/C8
MON_PARSE_HEX_WORD:
        lda     #$00
        sta     $C7
        sta     $C8
        sta     V1541_BYTE_TO_WRITE ;not really; location has multiple uses
LCA7E_CONSUME_SPACES:
        jsr     GNC
        beq     LCABD_RTS
        cmp     #' '
        beq     LCA7E_CONSUME_SPACES
LCA87_NEXT_DIGIT:
        cmp     #' '
        beq     LCAB9_LDA_039E_CLC_RTS
        cmp     #','
        beq     LCAB9_LDA_039E_CLC_RTS
        cmp     #'0'
        bcc     LCABE_BAD_DIGIT
        cmp     #'F'+1
        bcs     LCABE_BAD_DIGIT
        cmp     #'9'+1
        bcc     LCAA1
        cmp     #'A'
        bcc     LCABE_BAD_DIGIT
        sbc     #$08
LCAA1:  sbc     #$2F
        asl     a
        asl     a
        asl     a
        asl     a
        ldx     #$04
LCAA9:  asl     a
        rol     $C7
        rol     $C8
        dex
        bne     LCAA9
        inc     V1541_BYTE_TO_WRITE ;not really; location has multiple uses
        jsr     GNC
        bne     LCA87_NEXT_DIGIT
LCAB9_LDA_039E_CLC_RTS:
        lda     V1541_BYTE_TO_WRITE ;not really; location has multiple uses
        clc
LCABD_RTS:
        rts
LCABE_BAD_DIGIT:
        pla
        pla
        jmp     MON_BAD_COMMAND
; ----------------------------------------------------------------------------
PrintHexWordAndSpaceFromMem:
; Prints a hex word given at ZP locs and then a space.
; Input: $CC = high byte, $CB = low byte
        lda     $CB
        ldx     $CC
PrintHexWordAndSpace:
; Prints a hex word and then a space.
; Input: X = high byte, A = low byte
        pha
        txa
        jsr     PrintHexByte
        pla
PrintHexByteAndSpace:
        jsr     PrintHexByte
PrintSpace:
        lda     #$20
        .byte   $2C
PrintNewLine:
        lda     #$0D ;CHR$(13) Carriage Return
        jmp     KR_ShowChar_
; ----------------------------------------------------------------------------
PrintHexByte:
; Byte as hex print function, prints byte in A as hex number.
; X is saved to $39D and loaded back then.
        stx     SXREG
        jsr     Byte2HexChars
        jsr     KR_ShowChar_
        txa
        ldx     SXREG
        jmp     KR_ShowChar_
; ----------------------------------------------------------------------------
Byte2HexChars:
; Byte to hex converter
; Input: A = byte
; Output: A = high nibble hex ASCII digit, X = low nibble hex ASCII digit
        pha
        jsr     Nibble2HexChar
        tax
        pla
        lsr     a
        lsr     a
        lsr     a
        lsr     a
Nibble2HexChar:
; Nibble to hex converter
; Input: A = byte (low nibble is used only)
; Output: A = hex ASCII digit
        and     #$0F
        cmp     #$0A
        bcc     LCAFA
        adc     #$06
LCAFA:  adc     #$30
        rts
; ----------------------------------------------------------------------------
;Get next character
GNC:
        stx     SXREG
        ldx     $CD
        cpx     $CE
        bcs     GNC99
        lda     L0470,x
        cmp     #':'
        beq     GNC99
        inc     $CD
LCB0F:  php
        ldx     SXREG
        plp
        rts
; ----------------------------------------------------------------------------
GNC99:  lda     #$00
        beq     LCB0F
LCB19:  lda     $C7
        sta     $CB
        lda     $C8
        sta     $CC
        rts
; ----------------------------------------------------------------------------
SUB0M2: sec
        lda     $C7
        sbc     $CB
        sta     $C7
        lda     $C8
        sbc     $CC
        sta     $C8
        rts
; ----------------------------------------------------------------------------
DECT0:  lda     #$01
SUBT0:  sta     SXREG
        sec
        lda     $C7
        sbc     SXREG
        sta     $C7
        lda     $C8
        sbc     #$00
        sta     $C8
        rts
; ----------------------------------------------------------------------------
LCB44:  sec
        lda     $C9
        sbc     #$01
        sta     $C9
        lda     $CA
        sbc     #$00
        sta     $CA
        rts
; ----------------------------------------------------------------------------
LCB52:  lda     $CB
        bne     LCB58
        dec     $CC
LCB58:  dec     $CB
        rts
; ----------------------------------------------------------------------------
INCT2:  lda     #$01
ADDT2:  clc
        adc     $CB
        sta     $CB
        bcc     LCB66
        inc     $CC
LCB66:  rts
; ----------------------------------------------------------------------------
LCB67:  bcs     LCB7D
        jsr     LCB19
        jsr     MON_PARSE_HEX_WORD
        bcs     LCB7D
        jsr     SUB0M2
        lda     $C7
        sta     $C9
        lda     $C8
        sta     $CA
        clc
LCB7D:  rts
; ----------------------------------------------------------------------------
LCB7E:  bcs     LCBE0
        jsr     LCB19
        jsr     MON_PARSE_HEX_WORD
        bcs     LCBE0
        lda     $C7
        sta     $D2
        lda     $C8
        sta     $D3
        jsr     MON_PARSE_HEX_WORD
        lda     $C8
        pha
        lda     $C7
        pha
        cmp     $CB
        bcc     LCBAB
        bne     LCBA5
        lda     $C8
        cmp     $CC
        bcc     LCBAB
LCBA5:  lda     #$01
        sta     $D1
        bra     LCBAD
LCBAB:  stz     $D1
LCBAD:  lda     $D2
        sta     $C7
        lda     $D3
        sta     $C8
        jsr     SUB0M2
        lda     $C7
        sta     $C9
        lda     $C8
        sta     $CA
        lda     $D1
        beq     LCBD9
        lda     $D2
        sta     $CB
        lda     $D3
        sta     $CC
        pla
        clc
        adc     $C9
        sta     $C7
        pla
        adc     $CA
        sta     $C8
        clc
        rts
; ----------------------------------------------------------------------------
LCBD9:  pla
        sta     $C7
        pla
        sta     $C8
        clc
LCBE0:  rts
; ----------------------------------------------------------------------------
MON_PRINT_HEADER_FOR_REGS:
        jsr     PRIMM
        .byte   $0d,"   PC  SR AC XR YR SP MODE OPCODE   MNEMONIC",0
        rts

MON_PRINT_REGS_WITH_HEADER:
        jsr     MON_PRINT_HEADER_FOR_REGS

MON_PRINT_REGS_WITHOUT_HEADER:
        jsr     PRIMM
        .byte   $0D,"; ",0

        lda     $03B5 ;PC high
        jsr     PrintHexByte

        ldy     #$00
LCC25_LOOP:
        lda     $03B5+1,y
        jsr     PrintHexByteAndSpace ;0=PC low, 1=SR, 2=AC, 3=XR, 4=YR, 5=SP
        iny
        cpy     #$06
        bcc     LCC25_LOOP

        jsr     PrintSpace
        lda     MON_MMU_MODE
        jsr     PrintHexByteAndSpace

        lda     $03B6 ;PC low
        sta     $CB
        lda     $03B5 ;PC high
        sta     $CC
        jmp     MON_DISASM_OPCODE_MNEMONIC
; ----------------------------------------------------------------------------
LCC46:  pha
        lda     #$C7
        bra     LCC4E
LCC4B:  pha
LCC4C:  lda     #$CB
LCC4E:  sta     $0360
        sta     $0360
        lda     MON_MMU_MODE
        and     #$03
        asl     a
        tax
        pla
        jmp     (LCC5F,x)                 ;MON_MMU_MODE:
LCC5F:  .addr   GO_RAM_STORE_GO_KERN      ;0 stores to MMU_MODE_RAM
        .addr   GO_APPL_STORE_GO_KERN     ;1 stores to MMU_MODE_APPL
        .addr   GO_NOWHERE_STORE_GO_KERN  ;2 stores to MMU_MODE_KERN (stays in MMU_MODE_KERN)
        .addr   GO_RAM_STORE_GO_KERN      ;3 stores to MMU_MODE_RAM again
; ----------------------------------------------------------------------------
LCC67:  lda     #$CB
        .byte   $2C
LCC6A:  lda     #$C7
        .byte   $2C
LCC6D:  lda     #$D0
        phx
        jsr     LCC77
        plx
        eor     #$00
        rts
; ----------------------------------------------------------------------------
LCC77:  sta     SINNER
        sta     $0357
        lda     MON_MMU_MODE
        and     #$03
        asl     a
        tax
        jmp     (LCC87,x)                 ;MON_MMU_MODE:
LCC87:  .addr   GO_RAM_LOAD_GO_KERN       ;0 loads from MMU_MODE_RAM
        .addr   GO_APPL_LOAD_GO_KERN      ;1 loads from MMU_MODE_APPL
        .addr   GO_NOWHERE_LOAD_GO_KERN   ;2 loads from MMU_MODE_KERN (stays in MMU_MODE_KERN)
        .addr   GO_RAM_LOAD_GO_KERN       ;3 loads from MMU_MODE_RAM again
; ----------------------------------------------------------------------------
MON_CMD_DISASSEMBLE:
        bcs     LCC99
        jsr     LCB19
        jsr     MON_PARSE_HEX_WORD
        bcc     LCC9F
LCC99:  lda     #$14
        sta     $C7
        bne     DISA30
LCC9F:  jsr     SUB0M2
DISA30: jsr     PrintNewLine
        jsr     LFDB9_STOP
        beq     LCCBB
        jsr     LCCBE_DISASM_DOT_ADDR_OPCODE_MNEUMONIC
        inc     LENGTH
        lda     LENGTH
        jsr     ADDT2
        lda     LENGTH
        jsr     SUBT0
        bcs     DISA30
LCCBB:  jmp     MON_MAIN_INPUT
; ----------------------------------------------------------------------------
;". B000  25 F1    AND $F1"
LCCBE_DISASM_DOT_ADDR_OPCODE_MNEUMONIC:
        jsr     PRIMM
        .byte   ". ",0

;"B000  25 F1    AND $F1"
MON_DISASM_ADDR_OPCODE_MNEUMONIC:
        jsr     PrintHexWordAndSpaceFromMem

;" 25 F1    AND $F1"
MON_DISASM_OPCODE_MNEMONIC:
        jsr     PrintSpace
        ldy     #$00
        jsr     LCC67
        sta     $03A2
        jsr     LCD55
        pha
        ldx     LENGTH
        inx
LCCD9:  dex
        bpl     LCCE6
        jsr     PRIMM
        .byte   "   ",0
        jmp     LCCEC
; ----------------------------------------------------------------------------
LCCE6:  jsr     LCC67
        jsr     PrintHexByteAndSpace
LCCEC:  iny
        cpy     #$03
        bcc     LCCD9
        pla
        ldx     #$03
        jsr     LCD98
        ldx     #$06
LCCF9:  cpx     #$03
        bne     LCD11
        ldy     LENGTH
        beq     LCD11
LCD01:  lda     $03B4
        cmp     #$E8
        bcs     LCD39
        jsr     LCC67
        jsr     PrintHexByte
        dey
        bne     LCD01
LCD11:  asl     $03B4
        bcc     LCD35
        lda     LCE12,x
        jsr     KR_ShowChar_
        pha
        lda     $03A2
        cmp     #$7C
        bne     LCD2C
        pla
        lda     LCE1E,x
        beq     LCD35
        bra     LCD32
LCD2C:  pla
LCD2D:  lda     LCE18,x
        beq     LCD35
LCD32:  jsr     KR_ShowChar_
LCD35:  dex
        bne     LCCF9
        rts
; ----------------------------------------------------------------------------
LCD39:  jsr     LCC67
        jsr     LCD48
        clc
        adc     #$01
        bne     LCD45
        inx
LCD45:  jmp     PrintHexWordAndSpace
; ----------------------------------------------------------------------------
LCD48:  ldx     $CC
        tay
        bpl     LCD4E
        dex
LCD4E:  sec
        adc     $CB
        bcc     LCD54
        inx
LCD54:  rts
; ----------------------------------------------------------------------------
LCD55:  lsr     a
        tay
        bcc     LCD70
        lsr     a
        bcs     LCD7F
        tax
        cmp     #$22
        beq     LCD92
        lsr     a
        lsr     a
        lsr     a
        ora     #$80
        tay
        txa
        and     #$03
        bcc     LCD6E
        adc     #$03
LCD6E:  ora     #$80
LCD70:  lsr     a
        tax
        lda     LCDBF,x
        bcs     LCD7B
        lsr     a
        lsr     a
        lsr     a
        lsr     a
LCD7B:  and     #$0F
        bne     LCD83
LCD7F:  ldy     #$88
        lda     #$00
LCD83:  tax
        lda     LCE03,x
        sta     $03B4
        and     #$03
        sta     LENGTH
        tya
        ldy     #$00
        rts
; ----------------------------------------------------------------------------
LCD92:  ldy     #$16
        lda     #$01
        bra     LCD83
LCD98:  tay
        lda     LCEA7,y
        tay
        lda     LCE25,y
        sta     $C9
        iny
        lda     LCE25,y
        sta     $CA
LCDA8:  lda     #$00
        ldy     #$05
LCDAC:  asl     $CA
        rol     $C9
        rol     a
        dey
        bne     LCDAC
        adc     #$3F
        jsr     KR_ShowChar_
        dex
        bne     LCDA8
        jmp     PrintSpace
; ----------------------------------------------------------------------------
LCDBF:  .byte   $40,$22,$45,$33,$D8,$2F,$45,$39 ; CDBF 40 22 45 33 D8 2F 45 39  @"E3./E9
        .byte   $30,$22,$45,$33,$D8,$FF,$45,$99 ; CDC7 30 22 45 33 D8 FF 45 99  0"E3..E.
        .byte   $40,$02,$45,$33,$D8,$0F,$44,$09 ; CDCF 40 02 45 33 D8 0F 44 09  @.E3..D.
        .byte   $40,$22,$45,$B3,$D8,$FF,$44,$E9 ; CDD7 40 22 45 B3 D8 FF 44 E9  @"E...D.
        .byte   $D0,$22,$44,$33,$D8,$FC,$44,$39 ; CDDF D0 22 44 33 D8 FC 44 39  ."D3..D9
        .byte   $11,$22,$44,$33,$D8,$FC,$44,$9A ; CDE7 11 22 44 33 D8 FC 44 9A  ."D3..D.
        .byte   $10,$22,$44,$33,$D8,$0F,$44,$09 ; CDEF 10 22 44 33 D8 0F 44 09  ."D3..D.
        .byte   $10,$22,$44,$33,$D8,$0F,$44,$09 ; CDF7 10 22 44 33 D8 0F 44 09  ."D3..D.
        .byte   $62,$13,$7F,$A9                 ; CDFF 62 13 7F A9              b...
LCE03:  .byte   $00,$21,$81,$82,$00,$00,$59,$4D ; CE03 00 21 81 82 00 00 59 4D  .!....YM
        .byte   $49,$92,$86,$4A,$85,$9D,$4E     ; CE0B 49 92 86 4A 85 9D 4E     I..J..N
; Addressing mode characters for the monitor/(dis)assembler?
LCE12:  .byte   $91,$2C,$29,$2C,$23,$28         ; CE12 91 2C 29 2C 23 28        .,),#(
LCE18:  .byte   $24,$59,$00,$58,$24,$24         ; CE18 24 59 00 58 24 24        $Y.X$$
LCE1E:  .byte   $00,$58,$00,$58,$24,$24,$00     ; CE1E 00 58 00 58 24 24 00     .X.X$$.
; ----------------------------------------------------------------------------
;TODO this is probably data
LCE25:  ora     ($48),y                         ; CE25 11 48                    .H
        .byte   $13                             ; CE27 13                       .
        dex                                     ; CE28 CA                       .
        ora     $1A,x                           ; CE29 15 1A                    ..
        ora     $1908,y                         ; CE2B 19 08 19                 ...
        plp                                     ; CE2E 28                       (
        ora     $1AA4,y                         ; CE2F 19 A4 1A                 ...
        tax                                     ; CE32 AA                       .
        .byte   $1B                             ; CE33 1B                       .
        sty     $1B,x                           ; CE34 94 1B                    ..
        cpy     $5A1C                           ; CE36 CC 1C 5A                 ..Z
        trb     $1CC4                           ; CE39 1C C4 1C                 ...
        cld                                     ; CE3C D8                       .
        ora     $1DC8,x                         ; CE3D 1D C8 1D                 ...
        inx                                     ; CE40 E8                       .
        .byte   $23                             ; CE41 23                       #
        pha                                     ; CE42 48                       H
        .byte   $23                             ; CE43 23                       #
        lsr     a                               ; CE44 4A                       J
        .byte   $23                             ; CE45 23                       #
        .byte   $54                             ; CE46 54                       T
        .byte   $23                             ; CE47 23                       #
        ror     LA223                           ; CE48 6E 23 A2                 n#.
        bit     $72                             ; CE4B 24 72                    $r
        bit     $74                             ; CE4D 24 74                    $t
        and     #$88                            ; CE4F 29 88                    ).
        and     #$B2                            ; CE51 29 B2                    ).
        and     #$B4                            ; CE53 29 B4                    ).
        bit     $26,x                           ; CE55 34 26                    4&
        .byte   $53                             ; CE57 53                       S
        iny                                     ; CE58 C8                       .
        .byte   $53                             ; CE59 53                       S
        sbc     ($53)                           ; CE5A F2 53                    .S
        .byte   $F4                             ; CE5C F4                       .
        .byte   $5B                             ; CE5D 5B                       [
        ldx     #$5D                            ; CE5E A2 5D                    .]
        rol     $69                             ; CE60 26 69                    &i
        .byte   $44                             ; CE62 44                       D
        adc     #$72                            ; CE63 69 72                    ir
        adc     #$74                            ; CE65 69 74                    it
        adc     $7C26                           ; CE67 6D 26 7C                 m&|
        .byte   $22                             ; CE6A 22                       "
        sty     SA                      ; CE6B 84 C4                    ..
        txa                                     ; CE6D 8A                       .
        .byte   $44                             ; CE6E 44                       D
        txa                                     ; CE6F 8A                       .
        .byte   $62                             ; CE70 62                       b
        txa                                     ; CE71 8A                       .
        adc     ($8A)                           ; CE72 72 8A                    r.
        stz     $8B,x                           ; CE74 74 8B                    t.
        .byte   $44                             ; CE76 44                       D
        .byte   $8B                             ; CE77 8B                       .
        .byte   $62                             ; CE78 62                       b
        .byte   $8B                             ; CE79 8B                       .
        adc     ($8B)                           ; CE7A 72 8B                    r.
        stz     $9C,x                           ; CE7C 74 9C                    t.
        inc     a                               ; CE7E 1A                       .
        stz     L9D26                           ; CE7F 9C 26 9D                 .&.
        .byte   $54                             ; CE82 54                       T
        sta     LA068,x                         ; CE83 9D 68 A0                 .h.
        iny                                     ; CE86 C8                       .
        lda     ($88,x)                         ; CE87 A1 88                    ..
        lda     ($8A,x)                         ; CE89 A1 8A                    ..
        lda     ($94,x)                         ; CE8B A1 94                    ..
        lda     $44                             ; CE8D A5 44                    .D
        lda     $72                             ; CE8F A5 72                    .r
        lda     $74                             ; CE91 A5 74                    .t
        lda     $76                             ; CE93 A5 76                    .v
        tay                                     ; CE95 A8                       .
        lda     ($A8)                           ; CE96 B2 A8                    ..
        ldy     $AC,x                           ; CE98 B4 AC                    ..
        dec     MODKEY                     ; CE9A C6 AD                    ..
        asl     MODKEY                     ; CE9C 06 AD                    ..
        and     (FNADR)                      ; CE9E 32 AE                    2.
        .byte   $44                             ; CEA0 44                       D
        ldx     LAE68                           ; CEA1 AE 68 AE                 .h.
        sty     $00                             ; CEA4 84 00                    ..
        brk                                     ; CEA6 00                       .
LCEA7:  asl     $00,x                           ; CEA7 16 00                    ..
        ror     $04,x                           ; CEA9 76 04                    v.
        lsr     a                               ; CEAB 4A                       J
        tsb     $76                             ; CEAC 04 76                    .v
        tsb     $12                             ; CEAE 04 12                    ..
        lsr     $74                             ; CEB0 46 74                    Ft
        tsb     $1C                             ; CEB2 04 1C                    ..
        and     ($74)                           ; CEB4 32 74                    2t
        tsb     $3A                             ; CEB6 04 3A                    .:
        brk                                     ; CEB8 00                       .
        tsb     $5258                           ; CEB9 0C 58 52                 .XR
        cli                                     ; CEBC 58                       X
        tsb     $0E58                           ; CEBD 0C 58 0E                 .X.
        .byte   $02                             ; CEC0 02                       .
        tsb     $6258                           ; CEC1 0C 58 62                 .Xb
        rol     a                               ; CEC4 2A                       *
        tsb     $5C58                           ; CEC5 0C 58 5C                 .X\
        brk                                     ; CEC8 00                       .
        brk                                     ; CEC9 00                       .
        .byte   $42                             ; CECA 42                       B
        pha                                     ; CECB 48                       H
        .byte   $42                             ; CECC 42                       B
        sec                                     ; CECD 38                       8
        .byte   $42                             ; CECE 42                       B
        clc                                     ; CECF 18                       .
        bmi     LCED2                           ; CED0 30 00                    0.
LCED2:  .byte   $42                             ; CED2 42                       B
        jsr     L004E                           ; CED3 20 4E 00                  N.
        .byte   $42                             ; CED6 42                       B
        lsr     $6E00,x                         ; CED7 5E 00 6E                 ^.n
        phy                                     ; CEDA 5A                       Z
        bvc     $CF37                           ; CEDB 50 5A                    PZ
        sec                                     ; CEDD 38                       8
        phy                                     ; CEDE 5A                       Z
        inc     a                               ; CEDF 1A                       .
        brk                                     ; CEE0 00                       .
        ror     $665A                           ; CEE1 6E 5A 66                 nZf
        lsr     $38,x                           ; CEE4 56 38                    V8
        phy                                     ; CEE6 5A                       Z
        trb     $00                             ; CEE7 14 00                    ..
        jmp     (L2E6A)                         ; CEE9 6C 6A 2E                 lj.
; ----------------------------------------------------------------------------
        ply                                     ; CEEC 7A                       z
        jmp     (L066A)                         ; CEED 6C 6A 06                 lj.
; ----------------------------------------------------------------------------
        pla                                     ; CEF0 68                       h
        jmp     (L7E6A)                         ; CEF1 6C 6A 7E                 lj~
; ----------------------------------------------------------------------------
        jmp     (L6E6E,x)                       ; CEF4 7C 6E 6E                 |nn
        rti                                     ; CEF7 40                       @
; ----------------------------------------------------------------------------
        rol     $3E40,x                         ; CEF8 3E 40 3E                 >@>
        adc     ($70)                           ; CEFB 72 70                    rp
        rti                                     ; CEFD 40                       @
; ----------------------------------------------------------------------------
        rol     $3C08,x                         ; CEFE 3E 08 3C                 >.<
        rti                                     ; CF01 40                       @
; ----------------------------------------------------------------------------
        rol     $7822,x                         ; CF02 3E 22 78                 >"x
        rti                                     ; CF05 40                       @
; ----------------------------------------------------------------------------
        rol     a:$28,x                         ; CF06 3E 28 00                 >(.
        plp                                     ; CF09 28                       (
        rol     a                               ; CF0A 2A                       *
        rol     $2C,x                           ; CF0B 36 2C                    6,
        plp                                     ; CF0D 28                       (
        rol     a                               ; CF0E 2A                       *
        bpl     $CF35                           ; CF0F 10 24                    .$
        brk                                     ; CF11 00                       .
        rol     a                               ; CF12 2A                       *
        asl     a:$4C,x                         ; CF13 1E 4C 00                 .L.
        rol     a                               ; CF16 2A                       *
        rol     $00                             ; CF17 26 00                    &.
        rol     $32                             ; CF19 26 32                    &2
        bit     $44,x                           ; CF1B 34 44                    4D
        rol     $32                             ; CF1D 26 32                    &2
        asl     a                               ; CF1F 0A                       .
        rts                                     ; CF20 60                       `
; ----------------------------------------------------------------------------
        brk                                     ; CF21 00                       .
        and     ($64)                           ; CF22 32 64                    2d
        .byte   $54                             ; CF24 54                       T
        rol     $32                             ; CF25 26 32                    &2
        lsr     $02                             ; CF27 46 02                    F.
        bmi     LCF2B                           ; CF29 30 00                    0.
LCF2B:  pla                                     ; CF2B 68                       h
        bit     $6024,x                         ; CF2C 3C 24 60                 <$`
        bra     LCF3E                           ; CF2F 80 0D                    ..
        jsr     L2020                           ; CF31 20 20 20
; ----------------------------------------------------------------------------
MON_CMD_ASSEMBLE:
        bcc     LCF39
        jmp     MON_BAD_COMMAND
LCF39:  jsr     LCB19
LCF3C:  ldx     #$00
LCF3E:  stx     $0451
LCF41:  jsr     GNC
        bne     LCF4D
        cpx     #$00
        bne     LCF4D
        jmp     MON_MAIN_INPUT
; ----------------------------------------------------------------------------
LCF4D:  cmp     #$20                            ; CF4D C9 20                    .
        beq     LCF3C                           ; CF4F F0 EB                    ..
        sta     $D2,x                           ; CF51 95 D2                    ..
        inx                                     ; CF53 E8                       .
        cpx     #$03                            ; CF54 E0 03                    ..
        bne     LCF41                           ; CF56 D0 E9                    ..
LCF58:  dex                                     ; CF58 CA                       .
        bmi     LCF6E                           ; CF59 30 13                    0.
        lda     $D2,x                           ; CF5B B5 D2                    ..
        sec                                     ; CF5D 38                       8
        sbc     #$3F                            ; CF5E E9 3F                    .?
        ldy     #$05                            ; CF60 A0 05                    ..
LCF62:  lsr     a                               ; CF62 4A                       J
        ror     $0451                           ; CF63 6E 51 04                 nQ.
        ror     $0450                           ; CF66 6E 50 04                 nP.
        dey                                     ; CF69 88                       .
        bne     LCF62                           ; CF6A D0 F6                    ..
        bra     LCF58                           ; CF6C 80 EA                    ..
LCF6E:  stz     $C7                             ; CF6E 64 C7                    d.
        stz     $D5                             ; CF70 64 D5                    d.
        ldx     #$02                            ; CF72 A2 02                    ..
LCF74:  jsr     GNC                           ; CF74 20 FD CA                  ..
        beq     LCFC4                           ; CF77 F0 4B                    .K
        cmp     #$20                            ; CF79 C9 20                    .
        beq     LCF74                           ; CF7B F0 F7                    ..
        cmp     #$24                            ; CF7D C9 24                    .$
        beq     LCFAE                           ; CF7F F0 2D                    .-
        cmp     #$47                            ; CF81 C9 47                    .G
        bcs     LCFBC                           ; CF83 B0 37                    .7
        cmp     #$30                            ; CF85 C9 30                    .0
        bcc     LCFBC                           ; CF87 90 33                    .3
        cmp     #$3A                            ; CF89 C9 3A                    .:
LCF8B:  bcc     LCF93                           ; CF8B 90 06                    ..
        cmp     #$41                            ; CF8D C9 41                    .A
        bcc     LCFBC                           ; CF8F 90 2B                    .+
        adc     #$08                            ; CF91 69 08                    i.
LCF93:  and     #$0F                            ; CF93 29 0F                    ).
        ldy     #$03                            ; CF95 A0 03                    ..
LCF97:  asl     $C7                             ; CF97 06 C7                    ..
        rol     $C8                             ; CF99 26 C8                    &.
        dey                                     ; CF9B 88                       .
        bpl     LCF97                           ; CF9C 10 F9                    ..
        ora     $C7                             ; CF9E 05 C7                    ..
        sta     $C7                             ; CFA0 85 C7                    ..
        inc     $D5                             ; CFA2 E6 D5                    ..
        lda     $D5                             ; CFA4 A5 D5                    ..
        cmp     #$04                            ; CFA6 C9 04                    ..
        beq     LCFB6                           ; CFA8 F0 0C                    ..
        cmp     #$01                            ; CFAA C9 01                    ..
        bne     LCF74                           ; CFAC D0 C6                    ..
LCFAE:  inc     $D5                             ; CFAE E6 D5                    ..
        lda     #$24                            ; CFB0 A9 24                    .$
        sta     $0450,x                         ; CFB2 9D 50 04                 .P.
        inx                                     ; CFB5 E8                       .
LCFB6:  lda     #$30                            ; CFB6 A9 30                    .0
        sta     $0450,x                         ; CFB8 9D 50 04                 .P.
        inx                                     ; CFBB E8                       .
LCFBC:  sta     $0450,x                         ; CFBC 9D 50 04                 .P.
        inx                                     ; CFBF E8                       .
        cpx     #$10                            ; CFC0 E0 10                    ..
        bcc     LCF74                           ; CFC2 90 B0                    ..
LCFC4:  stx     $C9                             ; CFC4 86 C9                    ..
        ldx     #$00                            ; CFC6 A2 00                    ..
        stx     $D0                             ; CFC8 86 D0                    ..
LCFCA:  ldx     #$00                            ; CFCA A2 00                    ..
        stx     $D1                             ; CFCC 86 D1                    ..
        lda     $D0                             ; CFCE A5 D0                    ..
        jsr     LCD55                           ; CFD0 20 55 CD                  U.
        ldx     $03B4                           ; CFD3 AE B4 03                 ...
        stx     $CA                             ; CFD6 86 CA                    ..
        tax                                     ; CFD8 AA                       .
        lda     LCEA7,x                         ; CFD9 BD A7 CE                 ...
        tax                                     ; CFDC AA                       .
        inx                                     ; CFDD E8                       .
        lda     LCE25,x                         ; CFDE BD 25 CE                 .%.
        jsr     LD0B4                           ; CFE1 20 B4 D0                  ..
        dex                                     ; CFE4 CA                       .
        lda     LCE25,x                         ; CFE5 BD 25 CE                 .%.
        jsr     LD0B4                           ; CFE8 20 B4 D0                  ..
        ldx     #$06                            ; CFEB A2 06                    ..
LCFED:  cpx     #$03                            ; CFED E0 03                    ..
        bne     LD004                           ; CFEF D0 13                    ..
        ldy     LENGTH                          ; CFF1 A4 CF                    ..
        beq     LD004                           ; CFF3 F0 0F                    ..
LCFF5:  lda     $03B4                           ; CFF5 AD B4 03                 ...
        cmp     #$E8                            ; CFF8 C9 E8                    ..
        lda     #$30                            ; CFFA A9 30                    .0
        bcs     LD02F                           ; CFFC B0 31                    .1
;TODO this is probably a jsr
        .byte   $20                             ; CFFE 20
        .byte   $B1                             ; CFFF B1                       .
LD000:  bne     LCF8B-1                         ; D000 D0 88                    ..
        bne     LCFF5                           ; D002 D0 F1                    ..
LD004:  asl     $03B4                           ; D004 0E B4 03                 ...
        bcc     LD01D                           ; D007 90 14                    ..
        lda     #$7C                            ; D009 A9 7C                    .|
        cmp     $D0                             ; D00B C5 D0                    ..
        beq     LD022                           ; D00D F0 13                    ..
        lda     LCE12,x                         ; D00F BD 12 CE                 ...
        .byte   $20                             ; D012 20
LD013:  .byte   $B4                             ; D013 B4                       .
LD014:  .byte   $D0                             ; D014 D0                       .
LD015:  lda     LCE18,x                         ; D015 BD 18 CE                 ...
        .byte   $F0                             ; D018 F0                       .
LD019:  .byte   $03                             ; D019 03                       .
LD01A:  jsr     LD0B4                           ; D01A 20 B4 D0                  ..
LD01D:  dex                                     ; D01D CA                       .
LD01E:  bne     LCFED                           ; D01E D0 CD                    ..
        bra     LD035                           ; D020 80 13                    ..
LD022:  lda     LCE12,x                         ; D022 BD 12 CE                 ...
        jsr     LD0B4                           ; D025 20 B4 D0                  ..
        lda     LCE1E,x                         ; D028 BD 1E CE                 ...
        beq     LD01D                           ; D02B F0 F0                    ..
        bra     LD01A                           ; D02D 80 EB                    ..
LD02F:  jsr     LD0B1                           ; D02F 20 B1 D0                  ..
        jsr     LD0B1                           ; D032 20 B1 D0                  ..
LD035:  lda     $C9                             ; D035 A5 C9                    ..
        cmp     $D1                             ; D037 C5 D1                    ..
        beq     LD03E                           ; D039 F0 03                    ..
        jmp     LD0C0                           ; D03B 4C C0 D0                 L..
; ----------------------------------------------------------------------------
LD03E:  ldy     LENGTH
        beq     LD073
        lda     $CA
        cmp     #$9D
        bne     LD06A
        lda     $C7
        sbc     $CB
        tax
        lda     $C8
        sbc     $CC
        bcc     LD05B
        bne     LD0C7_JMP_MON_BAD_COMMAND
        cpx     #$82
        bcs     LD0C7_JMP_MON_BAD_COMMAND
        bcc     LD063
LD05B:  tay
        iny
        bne     LD0C7_JMP_MON_BAD_COMMAND
        cpx     #$82
        bcc     LD0C7_JMP_MON_BAD_COMMAND
LD063:  dex
        dex
        txa
        ldy     LENGTH
        bne     LD06D
LD06A:  lda     LA,y
LD06D:  jsr     LCC4B
        dey
        bne     LD06A
LD073:  lda     $D0
        jsr     LCC4B
        jsr     PRIMM
        .byte   $0D,$91,"A ",0
        jsr     MON_DISASM_ADDR_OPCODE_MNEUMONIC
        inc     LENGTH
        lda     LENGTH
        jsr     ADDT2
        jsr     LB4FB_RESET_KEYD_BUFFER
        lda     #'A'
        ldx     #' '
        jsr     LD0A9
        lda     $CC
        jsr     LD0A6
        lda     $CB
        jsr     LD0A6
        lda     #' '
        jsr     PUT_KEY_INTO_KEYD_BUFFER
        jmp     MON_MAIN_INPUT
; ----------------------------------------------------------------------------
LD0A6:  jsr     Byte2HexChars
LD0A9:  phx
        jsr     PUT_KEY_INTO_KEYD_BUFFER
        pla
        jmp     PUT_KEY_INTO_KEYD_BUFFER
; ----------------------------------------------------------------------------
LD0B1:  jsr     LD0B4
LD0B4:  stx     SXREG
        ldx     $D1
        cmp     $0450,x
        beq     LD0CA
        pla
        pla
LD0C0:  inc     $D0
        beq     LD0C7_JMP_MON_BAD_COMMAND
        jmp     LCFCA
; ----------------------------------------------------------------------------
LD0C7_JMP_MON_BAD_COMMAND:
        jmp     MON_BAD_COMMAND
; ----------------------------------------------------------------------------
LD0CA:  inx
        stx     $D1
        ldx     SXREG
        rts
; ----------------------------------------------------------------------------
MON_CMD_WALK:
        lda     #$01
        bcs     LD0D7
        lda     $C7
LD0D7:  sta     V1541_FILE_MODE
        jsr     MON_PRINT_HEADER_FOR_REGS
        bra     LD11C
LD0DF:  jsr     MON_PRINT_REGS_WITHOUT_HEADER
        jsr     LFDB9_STOP
        beq     LD0F9_JMP_MON_MAIN_INPUT
        dec     V1541_FILE_MODE
        bne     LD11C
        jsr     LB4FB_RESET_KEYD_BUFFER
        lda     #fmode_w_write
        jsr     PUT_KEY_INTO_KEYD_BUFFER
        lda     #' '
        jsr     PUT_KEY_INTO_KEYD_BUFFER
LD0F9_JMP_MON_MAIN_INPUT:
        jmp     MON_MAIN_INPUT
; ----------------------------------------------------------------------------
LD0FC:  tsx                                     ; D0FC BA                       .
        .byte   $D1                             ; D0FD D1                       .
LD0FE:  jsr     $D1D1                           ; D0FE 20 D1 D1                  ..
        rts                                     ; D101 60                       `
; ----------------------------------------------------------------------------
        ora     ($D2,x)                         ; D102 01 D2                    ..
        jmp     LD20B                           ; D104 4C 0B D2                 L..
; ----------------------------------------------------------------------------
        rti                                     ; D107 40                       @
; ----------------------------------------------------------------------------
        sbc     $D1                             ; D108 E5 D1                    ..
        jmp     (LD1E8)                         ; D10A 6C E8 D1                 l..
; ----------------------------------------------------------------------------
        .byte   $7C                             ; D10D 7C                       |
LD10E:  nop                                     ; D10E EA                       .
        nop                                     ; D10F EA                       .
        sta     MMU_MODE_KERN                   ; D110 8D 00 FA                 ...
        jmp     LD1A3                           ; D113 4C A3 D1                 L..
; ----------------------------------------------------------------------------
        sta     MMU_MODE_KERN                   ; D116 8D 00 FA                 ...
        jmp     LD17D                           ; D119 4C 7D D1                 L}.
; ----------------------------------------------------------------------------
LD11C:  ldx     #$0E                            ; D11C A2 0E                    ..
LD11E:  lda     LD10E,x                         ; D11E BD 0E D1                 ...
        sta     $0471,x                         ; D121 9D 71 04                 .q.
        dex                                     ; D124 CA                       .
        bpl     LD11E                           ; D125 10 F7                    ..
        jsr     LD216                           ; D127 20 16 D2                  ..
        sta     L0470                           ; D12A 8D 70 04                 .p.
        cmp     #$80                            ; D12D C9 80                    ..
        beq     LD139                           ; D12F F0 08                    ..
        bit     #$0F                            ; D131 89 0F                    ..
        bne     LD143                           ; D133 D0 0E                    ..
        bit     #$10                            ; D135 89 10                    ..
        beq     LD143                           ; D137 F0 0A                    ..
LD139:  lda     #$07                            ; D139 A9 07                    ..
        sta     $0471                           ; D13B 8D 71 04                 .q.
        jsr     LD216                           ; D13E 20 16 D2                  ..
        bra     LD168                           ; D141 80 25                    .%
LD143:  ldx     #$0F                            ; D143 A2 0F                    ..
LD145:  cmp     LD0FE,x                         ; D145 DD FE D0                 ...
        bne     LD14D                           ; D148 D0 03                    ..
        jmp     (LD0FC,x)                       ; D14A 7C FC D0                 |..
LD14D:  dex                                     ; D14D CA                       .
        dex                                     ; D14E CA                       .
        dex                                     ; D14F CA                       .
        bpl     LD145                           ; D150 10 F3                    ..
        jsr     LCD55                           ; D152 20 55 CD                  U.
        ldy     LENGTH                          ; D155 A4 CF                    ..
        beq     LD168                           ; D157 F0 0F                    ..
        jsr     LD216                           ; D159 20 16 D2                  ..
        sta     $0471                           ; D15C 8D 71 04                 .q.
        dey                                     ; D15F 88                       .
        beq     LD168                           ; D160 F0 06                    ..
        jsr     LD216                           ; D162 20 16 D2                  ..
        sta     $0472                           ; D165 8D 72 04                 .r.
LD168:  ldy     $03BA                           ; D168 AC BA 03                 ...
        lda     $03B8                           ; D16B AD B8 03                 ...
        ldx     $03BB                           ; D16E AE BB 03                 ...
        txs                                     ; D171 9A                       .
        ldx     L03B7                           ; D172 AE B7 03                 ...
        phx                                     ; D175 DA                       .
        ldx     $03B9                           ; D176 AE B9 03                 ...
        plp                                     ; D179 28                       (
        jmp     L0470                           ; D17A 4C 70 04                 Lp.
; ----------------------------------------------------------------------------
LD17D:  php                                     ; D17D 08                       .
        pha                                     ; D17E 48                       H
        phy                                     ; D17F 5A                       Z
        lda     $03B6                           ; D180 AD B6 03                 ...
        bne     LD188                           ; D183 D0 03                    ..
        dec     $03B5                           ; D185 CE B5 03                 ...
LD188:  dec     $03B6                           ; D188 CE B6 03                 ...
        jsr     LD216                           ; D18B 20 16 D2                  ..
        clc                                     ; D18E 18                       .
        tay                                     ; D18F A8                       .
        bpl     LD195                           ; D190 10 03                    ..
        dec     $03B5                           ; D192 CE B5 03                 ...
LD195:  adc     $03B6                           ; D195 6D B6 03                 m..
        bcc     LD19D                           ; D198 90 03                    ..
        inc     $03B5                           ; D19A EE B5 03                 ...
LD19D:  sta     $03B6                           ; D19D 8D B6 03                 ...
        ply                                     ; D1A0 7A                       z
        pla                                     ; D1A1 68                       h
        plp                                     ; D1A2 28                       (
LD1A3:  php                                     ; D1A3 08                       .
        stx     $03B9                           ; D1A4 8E B9 03                 ...
        plx                                     ; D1A7 FA                       .
        stx     L03B7                           ; D1A8 8E B7 03                 ...
        tsx                                     ; D1AB BA                       .
        stx     $03BB                           ; D1AC 8E BB 03                 ...
        sta     $03B8                           ; D1AF 8D B8 03                 ...
        sty     $03BA                           ; D1B2 8C BA 03                 ...
LD1B5:  cli                                     ; D1B5 58                       X
        cld                                     ; D1B6 D8                       .
        jmp     LD0DF                           ; D1B7 4C DF D0                 L..
; ----------------------------------------------------------------------------
        jsr     LD216                           ; D1BA 20 16 D2                  ..
        tax                                     ; D1BD AA                       .
        ldy     $03B5                           ; D1BE AC B5 03                 ...
        phy                                     ; D1C1 5A                       Z
        ldy     $03B6                           ; D1C2 AC B6 03                 ...
        phy                                     ; D1C5 5A                       Z
        jsr     LD216                           ; D1C6 20 16 D2                  ..
        dec     $03BB                           ; D1C9 CE BB 03                 ...
        dec     $03BB                           ; D1CC CE BB 03                 ...
        bra     LD1DD                           ; D1CF 80 0C                    ..
        plx                                     ; D1D1 FA                       .
        pla                                     ; D1D2 68                       h
        inx                                     ; D1D3 E8                       .
        bne     LD1D7                           ; D1D4 D0 01                    ..
        inc     a                               ; D1D6 1A                       .
LD1D7:  inc     $03BB                           ; D1D7 EE BB 03                 ...
        inc     $03BB                           ; D1DA EE BB 03                 ...
LD1DD:  sta     $03B5                           ; D1DD 8D B5 03                 ...
        stx     $03B6                           ; D1E0 8E B6 03                 ...
        bra     LD1B5                           ; D1E3 80 D0                    ..
        ldy     $03B9                           ; D1E5 AC B9 03                 ...
LD1E8:  ldy     #$00                            ; D1E8 A0 00                    ..
        jsr     LD216                           ; D1EA 20 16 D2                  ..
        pha                                     ; D1ED 48                       H
        jsr     LD216                           ; D1EE 20 16 D2                  ..
        sta     $D1                             ; D1F1 85 D1                    ..
        pla                                     ; D1F3 68                       h
        sta     $D0                             ; D1F4 85 D0                    ..
        jsr     LCC6D                           ; D1F6 20 6D CC                  m.
        pha                                     ; D1F9 48                       H
        iny                                     ; D1FA C8                       .
        jsr     LCC6D                           ; D1FB 20 6D CC                  m.
        plx                                     ; D1FE FA                       .
        bra     LD1DD                           ; D1FF 80 DC                    ..
        jsr     LD216                           ; D201 20 16 D2                  ..
        pha                                     ; D204 48                       H
        jsr     LD216                           ; D205 20 16 D2                  ..
        plx                                     ; D208 FA                       .
        bra     LD1DD                           ; D209 80 D2                    ..
LD20B:  pla                                     ; D20B 68                       h
        sta     L03B7                           ; D20C 8D B7 03                 ...
        plx                                     ; D20F FA                       .
        pla                                     ; D210 68                       h
        inc     $03BB                           ; D211 EE BB 03                 ...
        bra     LD1D7                           ; D214 80 C1                    ..
LD216:  phy                                     ; D216 5A                       Z
        ldy     #$00                            ; D217 A0 00                    ..
        lda     $03B6                           ; D219 AD B6 03                 ...
        sta     $D0                             ; D21C 85 D0                    ..
        lda     $03B5                           ; D21E AD B5 03                 ...
        sta     $D1                             ; D221 85 D1                    ..
        jsr     LCC6D                           ; D223 20 6D CC                  m.
        inc     $03B6                           ; D226 EE B6 03                 ...
        bne     LD22E                           ; D229 D0 03                    ..
        inc     $03B5                           ; D22B EE B5 03                 ...
LD22E:  ply                                     ; D22E 7A                       z
        rts                                     ; D22F 60                       `
; ----------------------------------------------------------------------------
LD230_JMP_LD233_PLUS_X:
        jmp     (LD233,x)
LD233:  .addr   LD247_X_00
        .addr   LD28C_X_02
        .addr   LD255_X_04
        .addr   LD297_X_06
        .addr   LD26A_X_08
        .addr   LD263_X_0A
        .addr   LD2B2_X_0C
        .addr   LD318_X_0E
        .addr   LD252_X_10
        .addr   LD294_X_12
; ----------------------------------------------------------------------------
LD247_X_00:
        stz     $041C
        sta     $F8
        sty     $F9
        stz     $041D
        rts
; ----------------------------------------------------------------------------
LD252_X_10:
        lda     #$10
        .byte   $2C
        ;Fall through
; ----------------------------------------------------------------------------
LD255_X_04:
        lda     #$20
        ldx     $041C
        beq     LD262
        tsb     $041C
        stz     $041D
LD262:  rts
; ----------------------------------------------------------------------------
LD263_X_0A:
        sta     $041D
        stz     $041E
        rts
; ----------------------------------------------------------------------------
LD26A_X_08:
        sty     $C0
        sta     $BF
        lda     $041C
        beq     LD277
        and     #$38
        beq     LD278
LD277:  rts

LD278:  lda     $041D
        beq     LD28A
        lda     FKEY_TO_INDEX-$85,x  ;-$85 for F1
        eor     $041C
        and     $07
        bne     LD28A
        stz     $041D
LD28A:  bra     LD297_X_06
; ----------------------------------------------------------------------------
LD28C_X_02:
        sty     $039C
        and     #$CF
        sta     $041C
        ;Fall through
; ----------------------------------------------------------------------------
LD294_X_12:
        lda     #$10
        .byte   $2C
        ;Fall through (skipping two bytes)
; ----------------------------------------------------------------------------
LD297_X_06:
        lda     #$20
        ldx     $041C
        beq     LD2AA
        trb     $041C
        lda     #$30
        bit     $041C
        bne     LD2AA
        bvs     LD327
LD2AA:  rts

LD2AB_UPDATE_041D_RTS:
        lda     $041D
        stz     $041D
        rts
; ----------------------------------------------------------------------------
LD2B2_X_0C:
        lda     $041D
        cmp     #$85  ;F1
        bcc     LD2AB_UPDATE_041D_RTS
        cmp     #$8D  ;F8 +1
        bcs     LD2AB_UPDATE_041D_RTS
        tay
        ldx     FKEY_TO_INDEX-$85,y  ;-$85 for F1
        lda     $041C
        bit     #$30
        bne     LD2AB_UPDATE_041D_RTS
        bit     #$08
        beq     LD2DB
        txa
        ;A now contains a 0-7 for keys F1-F8
        eor     $041C
        and     #$07
        bne     LD2DB
        lda     #$BF
        sta     $0357
        bra     LD2FC
LD2DB:  bit     $041C
        bvc     LD2AB_UPDATE_041D_RTS
        lda     #$F8
        sta     $0357
        ldy     $041E
        bne     LD2FC
LD2EA:  dex
        bmi     LD2F9
LD2ED:  jsr     GO_APPL_LOAD_GO_KERN
        iny
        beq     LD2F9
        cmp     #$00
        bne     LD2ED
        beq     LD2EA
LD2F9:  sty     $041E
LD2FC:  ldy     $041E
        inc     $041E
        beq     LD309
        jsr     GO_APPL_LOAD_GO_KERN
        bne     LD30F
LD309:  stz     $041E
        stz     $041D
LD30F:  rts
; ----------------------------------------------------------------------------
;F1->0, F2->1, F3->2, ... F8->7
FKEY_TO_INDEX:
        .byte 0   ;$85 F1
        .byte 2   ;$86 F3
        .byte 4   ;$85 F5
        .byte 6   ;$86 F7
        .byte 1   ;$89 F2
        .byte 3   ;$8A F4
        .byte 5   ;$8B F6
        .byte 7   ;$8C F8

LD318_X_0E:
        ldx     $039C
        phx
        sta     $039C
        jsr     LD329
        plx
        stx     $039C
        rts
; ----------------------------------------------------------------------------
LD327:  ldy     #$F8
LD329:  sty     $0357
        ldx     #$00
        ldy     #$00
LD330:  phx
        phy
        ldy     LD366_FKEY_COLUMNS,x
        ldx     $039C
        lda     #$89
        sec
        jsr     LB6F9_MAYBE_PUT_CHAR_IN_FKEY_BAR_SLOT
        lda     #$65
        ldy     #$09
        sta     ($BD),y
        ply
LD345:  jsr     GO_APPL_LOAD_GO_KERN
        beq     LD359
        cmp     #$08
        bcs     LD353
        jsr     LD36E_EXITQUITMORE
        bra     LD356
LD353:  jsr     LD3A9_CLC_JMP_LB6F9_MAYBE_PUT_CHAR_IN_FKEY_BAR_SLOT
LD356:  iny
        bne     LD345
LD359:  lda     #$0D
        jsr     LD3A9_CLC_JMP_LB6F9_MAYBE_PUT_CHAR_IN_FKEY_BAR_SLOT
        iny
        plx
        inx
        cpx     #$08
        bcc     LD330
        rts
LD366_FKEY_COLUMNS:
        ;      F1,F2,F3,F4,F5,F6,F7,F8
        .byte   0,10,20,30,40,50,60,70  ;Starting column on bottom screen line
; ----------------------------------------------------------------------------
LD36E_EXITQUITMORE:
        dec     a
        beq     LD382
        dec     a
        asl     a
        asl     a
        tax
LD375_LOOP:
        lda     LD391_EXITQUITMORE,x
        jsr     LD3A9_CLC_JMP_LB6F9_MAYBE_PUT_CHAR_IN_FKEY_BAR_SLOT
        inx
        txa
        and     #$03
        bne     LD375_LOOP
        rts
; ----------------------------------------------------------------------------
LD382:  phy
        ldy     #$00
LD385:  lda     ($BF),y
        beq     LD38F
        jsr     LD3A9_CLC_JMP_LB6F9_MAYBE_PUT_CHAR_IN_FKEY_BAR_SLOT
        iny
        bne     LD385
LD38F:  ply
        rts
; ----------------------------------------------------------------------------
LD391_EXITQUITMORE:
        .byte   "EXIT","QUIT","MORE"
        .byte   "exit","quit","more"
; ----------------------------------------------------------------------------
LD3A9_CLC_JMP_LB6F9_MAYBE_PUT_CHAR_IN_FKEY_BAR_SLOT:
        clc
        jmp     LB6F9_MAYBE_PUT_CHAR_IN_FKEY_BAR_SLOT
; ----------------------------------------------------------------------------
MEMBOT__:
        rol     a                               ; D3AD 2A                       *
        inc     a                               ; D3AE 1A                       .
        ror     a                               ; D3AF 6A                       j
        bcc     LD3E4                           ; D3B0 90 32                    .2
        phx                                     ; D3B2 DA                       .
        lda     #$FF                            ; D3B3 A9 FF                    ..
        sta     MemBotLoByte                    ; D3B5 8D 98 03                 ...
        lda     #$F7                            ; D3B8 A9 F7                    ..
        sta     MemBotHiByte                    ; D3BA 8D 99 03                 ...
        ldx     $020B                           ; D3BD AE 0B 02                 ...
        bne     LD3CE                           ; D3C0 D0 0C                    ..
        cmp     $020A                           ; D3C2 CD 0A 02                 ...
        bcc     LD3CE                           ; D3C5 90 07                    ..
        lda     $020A                           ; D3C7 AD 0A 02                 ...
        dec     a                               ; D3CA 3A                       :
        sta     MemBotHiByte                    ; D3CB 8D 99 03                 ...
LD3CE:  plx                                     ; D3CE FA                       .
        cpy     MemBotHiByte                    ; D3CF CC 99 03                 ...
        bcc     LD3DD                           ; D3D2 90 09                    ..
        bne     LD3E4                           ; D3D4 D0 0E                    ..
        cpx     MemBotLoByte                    ; D3D6 EC 98 03                 ...
        bcc     LD3DD                           ; D3D9 90 02                    ..
        bne     LD3E4                           ; D3DB D0 07                    ..
LD3DD:  stx     MemBotLoByte                    ; D3DD 8E 98 03                 ...
        sty     MemBotHiByte                    ; D3E0 8C 99 03                 ...
        clc                                     ; D3E3 18                       .
LD3E4:  php                                     ; D3E4 08                       .
        ldy     MemBotHiByte                    ; D3E5 AC 99 03                 ...
        stz     $020D                           ; D3E8 9C 0D 02                 ...
        sty     $020C                           ; D3EB 8C 0C 02                 ...
        jsr     LD3F6                           ; D3EE 20 F6 D3                  ..
        ldx     MemBotLoByte                    ; D3F1 AE 98 03                 ...
        plp                                     ; D3F4 28                       (
        rts                                     ; D3F5 60                       `
; ----------------------------------------------------------------------------
LD3F6:  cld                                     ; D3F6 D8                       .
        sec                                     ; D3F7 38                       8
        lda     $020A                           ; D3F8 AD 0A 02                 ...
        sbc     $020C                           ; D3FB ED 0C 02                 ...
        tax                                     ; D3FE AA                       .
LD400           := * + 1
LD401           := * + 2
        lda     $020B                           ; D3FF AD 0B 02                 ...
LD404           := * + 2
        sbc     $020D                           ; D402 ED 0D 02                 ...
        bcs     LD409                           ; D405 B0 02                    ..
        ldx     #$01                            ; D407 A2 01                    ..
LD409:  beq     LD40D                           ; D409 F0 02                    ..
        ldx     #$00                            ; D40B A2 00                    ..
LD40D:  dex                                     ; D40D CA                       .
        stx     $BC                             ; D40E 86 BC                    ..
        rts                                     ; D410 60                       `
; ----------------------------------------------------------------------------
LD411:  clc                                     ; D411 18                       .
        ldy     #$FF                            ; D412 A0 FF                    ..
        jsr     MEMBOT__                        ; D414 20 AD D3                  ..
        clc                                     ; D417 18                       .
        ldy     #$00                            ; D418 A0 00                    ..
MEMTOP__:
        bcs     LD42F                           ; D41A B0 13                    ..
        cpy     #$10                            ; D41C C0 10                    ..
        bcs     LD429                           ; D41E B0 09                    ..
        ldx     #$00                            ; D420 A2 00                    ..
        ldy     #$10                            ; D422 A0 10                    ..
        jsr     LD429                           ; D424 20 29 D4                  ).
        sec                                     ; D427 38                       8
        rts                                     ; D428 60                       `
; ----------------------------------------------------------------------------
LD429:  sty     MemTopHiByte                    ; D429 8C 9B 03                 ...
        stx     MemTopLoByte                    ; D42C 8E 9A 03                 ...
LD42F:  ldx     MemTopLoByte                    ; D42F AE 9A 03                 ...
        ldy     MemTopHiByte                    ; D432 AC 9B 03                 ...
        clc                                     ; D435 18                       .
        rts                                     ; D436 60                       `
; ----------------------------------------------------------------------------
LD437:  phx                                     ; D437 DA                       .
        phy                                     ; D438 5A                       Z
        cld                                     ; D439 D8                       .
        stz     $E5                             ; D43A 64 E5                    d.
        asl     a                               ; D43C 0A                       .
        sta     $E4                             ; D43D 85 E4                    ..
        asl     a                               ; D43F 0A                       .
        rol     $E5                             ; D440 26 E5                    &.
        adc     $E4                             ; D442 65 E4                    e.
        pha                                     ; D444 48                       H
        lda     $E5                             ; D445 A5 E5                    ..
        adc     #$F7                            ; D447 69 F7                    i.
        ldx     #$03                            ; D449 A2 03                    ..
        jsr     L8A87                           ; D44B 20 87 8A                  ..
        pla                                     ; D44E 68                       h
        sta     $E4                             ; D44F 85 E4                    ..
        ply                                     ; D451 7A                       z
        plx                                     ; D452 FA                       .
        stx     $DA                             ; D453 86 DA                    ..
        sty     $D9                             ; D455 84 D9                    ..
        lda     #$D9                            ; D457 A9 D9                    ..
        sta     SINNER                          ; D459 8D 4E 03                 .N.
        sta     $0360                           ; D45C 8D 60 03                 .`.
        ldx     #$07                            ; D45F A2 07                    ..
LD461:  lda     #$00                            ; D461 A9 00                    ..
        cpx     #$06                            ; D463 E0 06                    ..
        bcs     LD46B                           ; D465 B0 04                    ..
        txa                                     ; D467 8A                       .
        tay                                     ; D468 A8                       .
        lda     ($E4),y                         ; D469 B1 E4                    ..
LD46B:  ldy     #$07                            ; D46B A0 07                    ..
LD46D:  asl     a                               ; D46D 0A                       .
        pha                                     ; D46E 48                       H
        jsr     GO_RAM_LOAD_GO_KERN             ; D46F 20 4A 03                  J.
        ror     a                               ; D472 6A                       j
        jsr     GO_RAM_STORE_GO_KERN            ; D473 20 5C 03                  \.
        pla                                     ; D476 68                       h
        dey                                     ; D477 88                       .
        bpl     LD46D                           ; D478 10 F3                    ..
        dex                                     ; D47A CA                       .
        bpl     LD461                           ; D47B 10 E4                    ..
        jmp     L8A81                           ; D47D 4C 81 8A                 L..
; ----------------------------------------------------------------------------
;TODO probably data
        phx                                     ; D480 DA                       .
        ldx     #$7F                            ; D481 A2 7F                    ..
        brk                                     ; D483 00                       .
        brk                                     ; D484 00                       .
        brk                                     ; D485 00                       .
        brk                                     ; D486 00                       .
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
LD593:  jsr     L8E35_27_CHECKSUM_ERROR_IN_HEADER                           ; D593 20 35 8E                  5.
        ldy     #$FF                            ; D596 A0 FF                    ..
LD598:  iny                                     ; D598 C8                       .
        lda     stack,y                         ; D599 B9 00 01                 ...
        bne     LD598                           ; D59C D0 FA                    ..
        tya                                     ; D59E 98                       .
        jsr     $868C                           ; D59F 20 8C 86                  ..
        ldy     #$00                            ; D5A2 A0 00                    ..
        sta     LFF04                           ; D5A4 8D 04 FF                 ...
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
        sta     LFF03                           ; D5DA 8D 03 FF                 ...
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
        sta     LFF03                           ; D82A 8D 03 FF                 ...
        lda     $1205                           ; D82D AD 05 12                 ...
        jmp     L989E                           ; D830 4C 9E 98                 L..
; ----------------------------------------------------------------------------
LD833:  lda     stack+51                        ; D833 AD 33 01                 .3.
        jmp     L989E                           ; D836 4C 9E 98                 L..
; ----------------------------------------------------------------------------
LD839:  cmp     #$2E                            ; D839 C9 2E                    ..
        bne     LD846                           ; D83B D0 09                    ..
        sta     LFF03                           ; D83D 8D 03 FF                 ...
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
        sta     LFF03                           ; D8B2 8D 03 FF                 ...
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
        jsr     L9971                           ; D923 20 71 99                  q.
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
        sta     LFF03                           ; DA49 8D 03 FF                 ...
        pha                                     ; DA4C 48                       H
        lda     $03D8                           ; DA4D AD D8 03                 ...
        ldy     $03D9                           ; DA50 AC D9 03                 ...
        jsr     $8781                           ; DA53 20 81 87                  ..
        sta     LFF03                           ; DA56 8D 03 FF                 ...
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
        adc     L9F30,x                         ; DAA6 7D 30 9F                 }0.
        tay                                     ; DAA9 A8                       .
        pla                                     ; DAAA 68                       h
        bcc     LDA9C                           ; DAAB 90 EF                    ..
LDAAD:  pha                                     ; DAAD 48                       H
        ldx     #$00                            ; DAAE A2 00                    ..
        lda     $1149                           ; DAB0 AD 49 11                 .I.
        lsr     a                               ; DAB3 4A                       J
        bcs     LDAB8                           ; DAB4 B0 02                    ..
        ldx     #$02                            ; DAB6 A2 02                    ..
LDAB8:  pla                                     ; DAB8 68                       h
        sta     $114A,x                         ; DAB9 9D 4A 11                 .J.
        tya                                     ; DABC 98                       .
        sta     $114B,x                         ; DABD 9D 4B 11                 .K.
        rts                                     ; DAC0 60                       `
; ----------------------------------------------------------------------------
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
        jsr     L9D82                           ; DAD8 20 82 9D                  ..
        bcs     LDAE0                           ; DADB B0 03                    ..
LDADD:  jsr     L9DA1                           ; DADD 20 A1 9D                  ..
LDAE0:  plp                                     ; DAE0 28                       (
        bcs     LDAFE                           ; DAE1 B0 1B                    ..
        jmp     L9D91                           ; DAE3 4C 91 9D                 L..
; ----------------------------------------------------------------------------
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
        jsr     L87F3                           ; DAFF 20 F3 87                  ..
        cpx     #$02                            ; DB02 E0 02                    ..
        bcc     LDB16                           ; DB04 90 10                    ..
        beq     LDB0B                           ; DB06 F0 03                    ..
        jmp     L7D16                           ; DB08 4C 16 7D                 L.}
; ----------------------------------------------------------------------------
LDB0B:  jsr     L9C3C                           ; DB0B 20 3C 9C                  <.
        tay                                     ; DB0E A8                       .
        bcc     LDB13                           ; DB0F 90 02                    ..
        ldy     #$00                            ; DB11 A0 00                    ..
LDB13:  jmp     L84D0                           ; DB13 4C D0 84                 L..
; ----------------------------------------------------------------------------
LDB16:  txa                                     ; DB16 8A                       .
        asl     a                               ; DB17 0A                       .
        tax                                     ; DB18 AA                       .
        lda     $1131,x                         ; DB19 BD 31 11                 .1.
        tay                                     ; DB1C A8                       .
        lda     $1132,x                         ; DB1D BD 32 11                 .2.
LDB20:  jmp     L792A                           ; DB20 4C 2A 79                 L*y
; ----------------------------------------------------------------------------
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
        lda     $116C                           ; DBEE AD 6C 11                 .l.
        ora     $116B                           ; DBF1 0D 6B 11                 .k.
        beq     LDC0C                           ; DBF4 F0 16                    ..
        inc     $1131                           ; DBF6 EE 31 11                 .1.
        bne     LDBFE                           ; DBF9 D0 03                    ..
        inc     $1132                           ; DBFB EE 32 11                 .2.
LDBFE:  jsr     L9C0C                           ; DBFE 20 0C 9C                  ..
        ldx     $1131                           ; DC01 AE 31 11                 .1.
        bne     LDC09                           ; DC04 D0 03                    ..
        dec     $1132                           ; DC06 CE 32 11                 .2.
LDC09:  dec     $1131                           ; DC09 CE 31 11                 .1.
LDC0C:  jsr     L9D17                           ; DC0C 20 17 9D                  ..
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
        lda     LC033,x                         ; DC63 BD 33 C0                 .3.
        sta     $8C                             ; DC66 85 8C                    ..
        lda     L9CBD,x                         ; DC68 BD BD 9C                 ...
        sta     $8D                             ; DC6B 85 8D                    ..
        lda     $83                             ; DC6D A5 83                    ..
        bne     LDC79                           ; DC6F D0 08                    ..
        lda     $03E2                           ; DC71 AD E2 03                 ...
        bit     $D8                             ; DC74 24 D8                    $.
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
        sta     MMU_KERN_WINDOW                 ; DCA9 8D 00 FF                 ...
        sei                                     ; DCAC 78                       x
        lda     $01                             ; DCAD A5 01                    ..
        pha                                     ; DCAF 48                       H
        and     #$FE                            ; DCB0 29 FE                    ).
        sta     $01                             ; DCB2 85 01                    ..
        lda     $85                             ; DCB4 A5 85                    ..
        sta     ($8C),y                         ; DCB6 91 8C                    ..
        pla                                     ; DCB8 68                       h
        sta     $01                             ; DCB9 85 01                    ..
        cli                                     ; DCBB 58                       X
        rts                                     ; DCBC 60                       `
; ----------------------------------------------------------------------------
;TODO probably data
        trb     $1C1C                           ; DCBD 1C 1C 1C                 ...
        trb     $1C1C                           ; DCC0 1C 1C 1C                 ...
        trb     $1D1D                           ; DCC3 1C 1D 1D                 ...
        ora     $1D1D,x                         ; DCC6 1D 1D 1D                 ...
        ora     $1E1E,x                         ; DCC9 1D 1E 1E                 ...
        asl     $1E1E,x                         ; DCCC 1E 1E 1E                 ...
        asl     $1F1E,x                         ; DCCF 1E 1E 1F                 ...
        bbr1    $1F,LDCF4                       ; DCD2 1F 1F 1F                 ...
        bbr1    $20,LDCEF                       ; DCD5 1F 20 17                 . .
        sta     $33B0,x                         ; DCD8 9D B0 33                 ..3
        tya                                     ; DCDB 98                       .
        clc                                     ; DCDC 18                       .
        adc     LC033,x                         ; DCDD 7D 33 C0                 }3.
        sta     $8C                             ; DCE0 85 8C                    ..
        lda     LC04C,x                         ; DCE2 BD 4C C0                 .L.
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
        bit     $D8                             ; DCFB 24 D8                    $.
        php                                     ; DCFD 08                       .
        bpl     LDD01                           ; DCFE 10 01                    ..
        asl     a                               ; DD00 0A                       .
LDD01:  and     #$07                            ; DD01 29 07                    ).
        tax                                     ; DD03 AA                       .
        lda     L9D0F,x                         ; DD04 BD 0F 9D                 ...
        plp                                     ; DD07 28                       (
        bpl     LDD0E                           ; DD08 10 04                    ..
        inx                                     ; DD0A E8                       .
        ora     L9D0F,x                         ; DD0B 1D 0F 9D                 ...
LDD0E:  rts                                     ; DD0E 60                       `
; ----------------------------------------------------------------------------
        bra     LDD51                           ; DD0F 80 40                    .@
        jsr     L0810                           ; DD11 20 10 08                  ..
        tsb     $02                             ; DD14 04 02                    ..
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
        jsr     L9DA1                           ; DD4D 20 A1 9D                  ..
        .byte   $9D                             ; DD50 9D                       .
LDD51:  and     ($11),y                         ; DD51 31 11                    1.
        tya                                     ; DD53 98                       .
        inx                                     ; DD54 E8                       .
        sta     $1131,x                         ; DD55 9D 31 11                 .1.
        inx                                     ; DD58 E8                       .
LDD59:  rts                                     ; DD59 60                       `
; ----------------------------------------------------------------------------
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
LDD6F:  jsr     L9D82                           ; DD6F 20 82 9D                  ..
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
        lda     $1131,y                         ; DD82 B9 31 11                 .1.
        pha                                     ; DD85 48                       H
        lda     $1132,y                         ; DD86 B9 32 11                 .2.
        tay                                     ; DD89 A8                       .
        pla                                     ; DD8A 68                       h
        rts                                     ; DD8B 60                       `
; ----------------------------------------------------------------------------
        jsr     L9D6F                           ; DD8C 20 6F 9D                  o.
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
        ldy     #$00                            ; DDE5 A0 00                    ..
        jsr     L9DEC                           ; DDE7 20 EC 9D                  ..
        ldy     #$02                            ; DDEA A0 02                    ..
        lda     $1135,y                         ; DDEC B9 35 11                 .5.
        sta     $1131,y                         ; DDEF 99 31 11                 .1.
        lda     $1136,y                         ; DDF2 B9 36 11                 .6.
        sta     $1132,y                         ; DDF5 99 32 11                 .2.
        rts                                     ; DDF8 60                       `
; ----------------------------------------------------------------------------
        jsr     DFLTO                           ; DDF9 20 86 03                  ..
        beq     LDE0A                           ; DDFC F0 0C                    ..
        jsr     L794A                           ; DDFE 20 4A 79                  Jy
        cmp     #$2C                            ; DE01 C9 2C                    .,
        beq     LDE0A                           ; DE03 F0 05                    ..
        jsr     L880E                           ; DE05 20 0E 88                  ..
        sec                                     ; DE08 38                       8
        rts                                     ; DE09 60                       `
; ----------------------------------------------------------------------------
LDE0A:  lda     #$00                            ; DE0A A9 00                    ..
        tay                                     ; DE0C A8                       .
LDE0D:  clc                                     ; DE0D 18                       .
        rts                                     ; DE0E 60                       `
; ----------------------------------------------------------------------------
        ldx     #$00                            ; DE0F A2 00                    ..
        jsr     DFLTO                           ; DE11 20 86 03                  ..
        beq     LDE0D                           ; DE14 F0 F7                    ..
        jsr     L794A                           ; DE16 20 4A 79                  Jy
        cmp     #$2C                            ; DE19 C9 2C                    .,
        beq     LDE0D                           ; DE1B F0 F0                    ..
        jsr     L87F0                           ; DE1D 20 F0 87                  ..
        sec                                     ; DE20 38                       8
        rts                                     ; DE21 60                       `
; ----------------------------------------------------------------------------
        jsr     LA067                           ; DE22 20 67 A0                  g.
        ldx     #$01                            ; DE25 A2 01                    ..
        jsr     DFLTO                           ; DE27 20 86 03                  ..
        beq     LDE3F                           ; DE2A F0 13                    ..
        cmp     #$2C                            ; DE2C C9 2C                    .,
        beq     LDE3F                           ; DE2E F0 0F                    ..
        jsr     L87F0                           ; DE30 20 F0 87                  ..
        cpx     #$04                            ; DE33 E0 04                    ..
        bcs     LDE42                           ; DE35 B0 0B                    ..
        cpx     #$02                            ; DE37 E0 02                    ..
        bit     $D8                             ; DE39 24 D8                    $.
        bmi     LDE3F                           ; DE3B 30 02                    0.
        bcs     LDE42                           ; DE3D B0 03                    ..
LDE3F:  stx     $83                             ; DE3F 86 83                    ..
        rts                                     ; DE41 60                       `
; ----------------------------------------------------------------------------
LDE42:  jmp     L7D16                           ; DE42 4C 16 7D                 L.}
; ----------------------------------------------------------------------------
        jsr     DFLTO                           ; DE45 20 86 03                  ..
        beq     LDE51                           ; DE48 F0 07                    ..
        jsr     L794A                           ; DE4A 20 4A 79                  Jy
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
        .byte   $20                             ; DE60 20
LDE61:  lsr     a                               ; DE61 4A                       J
        .byte   $79                             ; DE62 79                       y
LDE63:  stx     $1178                           ; DE63 8E 78 11                 .x.
        jsr     L9EFB                           ; DE66 20 FB 9E                  ..
        jsr     DFLTO                           ; DE69 20 86 03                  ..
        cmp     #$2C                            ; DE6C C9 2C                    .,
        beq     LDEC6                           ; DE6E F0 56                    .V
        cmp     #$3B                            ; DE70 C9 3B                    .;
        beq     LDE77                           ; DE72 F0 03                    ..
        jmp     L795A                           ; DE74 4C 5A 79                 LZy
; ----------------------------------------------------------------------------
LDE77:  jsr     L0380                           ; DE77 20 80 03                  ..
        jsr     L880E                           ; DE7A 20 0E 88                  ..
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
LDEC6:  jsr     L0380                           ; DEC6 20 80 03                  ..
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
        jsr     L9D60                           ; DEE8 20 60 9D                  `.
        sta     $1131,x                         ; DEEB 9D 31 11                 .1.
        tya                                     ; DEEE 98                       .
        sta     $1132,x                         ; DEEF 9D 32 11                 .2.
LDEF2:  ldy     #$00                            ; DEF2 A0 00                    ..
        cpx     $1178                           ; DEF4 EC 78 11                 .x.
        beq     LDEE1                           ; DEF7 F0 E8                    ..
        clc                                     ; DEF9 18                       .
        rts                                     ; DEFA 60                       `
; ----------------------------------------------------------------------------
        jsr     DFLTO                           ; DEFB 20 86 03                  ..
        cmp     #$AA                            ; DEFE C9 AA                    ..
        beq     LDF07                           ; DF00 F0 05                    ..
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
        bbs7    $AA,LDF70                       ; DF18 FF AA 55                 ..U
        brk                                     ; DF1B 00                       .
        brk                                     ; DF1C 00                       .
        brk                                     ; DF1D 00                       .
        bit     $5771                           ; DF1E 2C 71 57                 ,qW
        sta     a:$80                           ; DF21 8D 80 00                 ...
        ldy     $8F                             ; DF24 A4 8F                    ..
        cpy     $19                             ; DF26 C4 19                    ..
        .byte   $DD                             ; DF28 DD                       .
LDF29:  lda     ($F0)                           ; DF29 B2 F0                    ..
        bcc     LDF29                           ; DF2B 90 FC                    ..
        trb     IRQ_VECTOR+1                    ; DF2D 1C FF FF                 ...
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
        lda     $76                             ; DF42 A5 76                    .v
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
        lda     $76                             ; E015 A5 76                    .v
        bne     LE01A                           ; E017 D0 01                    ..
        rts                                     ; E019 60                       `
; ----------------------------------------------------------------------------
LE01A:  ldy     #$00                            ; E01A A0 00                    ..
        sty     $76                             ; E01C 84 76                    .v
        sty     $24                             ; E01E 84 24                    .$
        sty     $26                             ; E020 84 26                    .&
        lda     #$1C                            ; E022 A9 1C                    ..
        sta     $25                             ; E024 85 25                    .%
        lda     #$40                            ; E026 A9 40                    .@
        sta     $27                             ; E028 85 27                    .'
LE02A:  jsr     L03C0                           ; E02A 20 C0 03                  ..
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
        bit     $76                             ; E057 24 76                    $v
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
        lda     $76                             ; E067 A5 76                    .v
        beq     LE06C                           ; E069 F0 01                    ..
        rts                                     ; E06B 60                       `
; ----------------------------------------------------------------------------
LE06C:  ldx     #$23                            ; E06C A2 23                    .#
        jmp     L4D39                           ; E06E 4C 39 4D                 L9M
; ----------------------------------------------------------------------------
        jsr     LA396                           ; E071 20 96 A3                  ..
        lda     $80                             ; E074 A5 80                    ..
        and     #$E6                            ; E076 29 E6                    ).
        beq     LE07D                           ; E078 F0 03                    ..
        jmp     L795A                           ; E07A 4C 5A 79                 LZy
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
        ldy     #$61                            ; E14A A0 61                    .a
LE14C:  iny                                     ; E14C C8                       .
        cpy     #$6F                            ; E14D C0 6F                    .o
        beq     LE15D                           ; E14F F0 0C                    ..
        jsr     LA81A                           ; E151 20 1A A8                  ..
        jsr     LFF5C                           ; E154 20 5C FF                  \.
        bcc     LE14C                           ; E157 90 F3                    ..
        sty     stack+29                        ; E159 8C 1D 01                 ...
        rts                                     ; E15C 60                       `
; ----------------------------------------------------------------------------
LE15D:  ldx     #$01                            ; E15D A2 01                    ..
        jmp     L4D39                           ; E15F 4C 39 4D                 L9M
; ----------------------------------------------------------------------------
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
        jmp     LFF4A                           ; E17C 4C 4A FF                 LJ.
; ----------------------------------------------------------------------------
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
        lda     #$01                            ; E197 A9 01                    ..
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
        jsr     LFF59                           ; E2DB 20 59 FF                  Y.
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
        jsr     LA396                           ; E2FE 20 96 A3                  ..
        ldy     #$FF                            ; E301 A0 FF                    ..
        lda     #$02                            ; E303 A9 02                    ..
        jsr     LA373                           ; E305 20 73 A3                  s.
        jmp     LA176                           ; E308 4C 76 A1                 Lv.
; ----------------------------------------------------------------------------
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
        jsr     LA396                           ; E33E 20 96 A3                  ..
        jsr     LA735                           ; E341 20 35 A7                  5.
        ldy     #$0D                            ; E344 A0 0D                    ..
        lda     #$0C                            ; E346 A9 0C                    ..
        bne     LE373                           ; E348 D0 29                    .)
        lda     #$E4                            ; E34A A9 E4                    ..
        jsr     LA398                           ; E34C 20 98 A3                  ..
        jsr     LA73B                           ; E34F 20 3B A7                  ;.
        ldy     #$2F                            ; E352 A0 2F                    ./
        lda     #$08                            ; E354 A9 08                    ..
        bne     LE373                           ; E356 D0 1B                    ..
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
        jmp     L9268                           ; E38C 4C 68 92                 Lh.
; ----------------------------------------------------------------------------
        .byte   $FF                             ; E38F FF                       .
        .byte   $FF                             ; E390 FF                       .
LE391:  .byte $ff, $ff, $00                     ; E391 FF FF 00                 ...
        php                                     ; E394 08                       .
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
LE3AD:  lda     LA38F,x                         ; E3AD BD 8F A3                 ...
        sta     stack+23,x                      ; E3B0 9D 17 01                 ...
        dex                                     ; E3B3 CA                       .
        bpl     LE3AD                           ; E3B4 10 F7                    ..
        ldx     $03D5                           ; E3B6 AE D5 03                 ...
        stx     stack+31                        ; E3B9 8E 1F 01                 ...
        jsr     DFLTO                           ; E3BC 20 86 03                  ..
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
LE414:  jsr     LA564                           ; E414 20 64 A5                  d.
        bne     LE411                           ; E417 D0 F8                    ..
LE419:  jsr     LA575                           ; E419 20 75 A5                  u.
        beq     LE411                           ; E41C F0 F3                    ..
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
        lda     #$02                            ; E48B A9 02                    ..
        jsr     LA5F7                           ; E48D 20 F7 A5                  ..
        jsr     LA5DA                           ; E490 20 DA A5                  ..
        sty     stack+23                        ; E493 8C 17 01                 ...
        sta     stack+24                        ; E496 8D 18 01                 ...
        lda     #$02                            ; E499 A9 02                    ..
LE49B:  ora     L0081                           ; E49B 05 81                    ..
        sta     L0081                           ; E49D 85 81                    ..
        bne     LE4D2                           ; E49F D0 31                    .1
LE4A1:  lda     #$04                            ; E4A1 A9 04                    ..
        jsr     LA5F7                           ; E4A3 20 F7 A5                  ..
        jsr     LA5DA                           ; E4A6 20 DA A5                  ..
        sty     stack+25                        ; E4A9 8C 19 01                 ...
        sta     stack+26                        ; E4AC 8D 1A 01                 ...
        lda     #$04                            ; E4AF A9 04                    ..
        bne     LE49B                           ; E4B1 D0 E8                    ..
        lda     #$01                            ; E4B3 A9 01                    ..
        jsr     LA590                           ; E4B5 20 90 A5                  ..
        sta     stack+17                        ; E4B8 8D 11 01                 ...
        ldy     #$00                            ; E4BB A0 00                    ..
LE4BD:  jsr     L03B7                           ; E4BD 20 B7 03                  ..
        sta     LFF03                           ; E4C0 8D 03 FF                 ...
        sta     $12B7,y                         ; E4C3 99 B7 12                 ...
        iny                                     ; E4C6 C8                       .
        cpy     stack+17                        ; E4C7 CC 11 01                 ...
        bcc     LE4BD                           ; E4CA 90 F1                    ..
        lda     #$01                            ; E4CC A9 01                    ..
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
LE5BE:  ldx     #$09                            ; E5BE A2 09                    ..
        bne     LE5C4                           ; E5C0 D0 02                    ..
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
        sta     LFF03                           ; E70C 8D 03 FF                 ...
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
        lda     $7A                             ; E74D A5 7A                    .z
        bne     LE76A                           ; E74F D0 19                    ..
        lda     #$28                            ; E751 A9 28                    .(
        sta     $7A                             ; E753 85 7A                    .z
        jsr     L928C                           ; E755 20 8C 92                  ..
        stx     $7B                             ; E758 86 7B                    .{
        sty     $7C                             ; E75A 84 7C                    .|
        ldy     #$28                            ; E75C A0 28                    .(
        sta     LFF04                           ; E75E 8D 04 FF                 ...
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
        sta     LFF04                           ; E790 8D 04 FF                 ...
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
        sta     LFF04                           ; E7EB 8D 04 FF                 ...
        sta     ($7B),y                         ; E7EE 91 7B                    .{
        iny                                     ; E7F0 C8                       .
        lda     #$FF                            ; E7F1 A9 FF                    ..
        sta     ($7B),y                         ; E7F3 91 7B                    .{
LE7F5:  lda     #$00                            ; E7F5 A9 00                    ..
        sta     LFF03                           ; E7F7 8D 03 FF                 ...
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
        jmp     LFF50                           ; EA28 4C 50 FF                 LP.
; ----------------------------------------------------------------------------
LEA2B:  jmp     L7D16                           ; EA2B 4C 16 7D                 L.}
; ----------------------------------------------------------------------------
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
        .byte   $FF,$7B,$E9,$77,$6A,$5F,$5E,$5D ; EE62 FF 7B E9 77 6A 5F 5E 5D  .{.wj_^]
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
        jmp     L84B0                           ; EF00 4C B0 84                 L..
; ----------------------------------------------------------------------------
        jmp     L792A                           ; EF03 4C 2A 79                 L*y
; ----------------------------------------------------------------------------
        jmp     L8E35_27_CHECKSUM_ERROR_IN_HEADER                           ; EF06 4C 35 8E                 L5.
; ----------------------------------------------------------------------------
        jmp     L8052                           ; EF09 4C 52 80                 LR.
; ----------------------------------------------------------------------------
        jmp     L8811                           ; EF0C 4C 11 88                 L..
; ----------------------------------------------------------------------------
        jmp     L8C68                           ; EF0F 4C 68 8C                 Lh.
; ----------------------------------------------------------------------------
        jmp     L882A                           ; EF12 4C 2A 88                 L*.
; ----------------------------------------------------------------------------
        jmp     L882D                           ; EF15 4C 2D 88                 L-.
; ----------------------------------------------------------------------------
        jmp     L8841                           ; EF18 4C 41 88                 LA.
; ----------------------------------------------------------------------------
        jmp     L8844                           ; EF1B 4C 44 88                 LD.
; ----------------------------------------------------------------------------
        jmp     L8A20                           ; EF1E 4C 20 8A                 L .
; ----------------------------------------------------------------------------
        jmp     L8A23                           ; EF21 4C 23 8A                 L#.
; ----------------------------------------------------------------------------
        jmp     L8B3C                           ; EF24 4C 3C 8B                 L<.
; ----------------------------------------------------------------------------
        jmp     L8B3F                           ; EF27 4C 3F 8B                 L?.
; ----------------------------------------------------------------------------
        jmp     L89C6                           ; EF2A 4C C6 89                 L..
; ----------------------------------------------------------------------------
        jmp     L8CEE                           ; EF2D 4C EE 8C                 L..
; ----------------------------------------------------------------------------
        jmp     L8FAA                           ; EF30 4C AA 8F                 L..
; ----------------------------------------------------------------------------
        jmp     L8FED                           ; EF33 4C ED 8F                 L..
; ----------------------------------------------------------------------------
        jmp     L8FB1                           ; EF36 4C B1 8F                 L..
; ----------------------------------------------------------------------------
        jmp     L8FB4                           ; EF39 4C B4 8F                 L..
; ----------------------------------------------------------------------------
        jmp     L9026                           ; EF3C 4C 26 90                 L&.
; ----------------------------------------------------------------------------
        jmp     L93FC                           ; EF3F 4C FC 93                 L..
; ----------------------------------------------------------------------------
        jmp     L9403                           ; EF42 4C 03 94                 L..
; ----------------------------------------------------------------------------
        jmp     L944C                           ; EF45 4C 4C 94                 LL.
; ----------------------------------------------------------------------------
        jmp     L94A6                           ; EF48 4C A6 94                 L..
; ----------------------------------------------------------------------------
        jmp     L8C3A                           ; EF4B 4C 3A 8C                 L:.
; ----------------------------------------------------------------------------
        jmp     L8C77                           ; EF4E 4C 77 8C                 Lw.
; ----------------------------------------------------------------------------
        jmp     L8C4A                           ; EF51 4C 4A 8C                 LJ.
; ----------------------------------------------------------------------------
        jmp     L8C7A                           ; EF54 4C 7A 8C                 Lz.
; ----------------------------------------------------------------------------
        jmp     L8433                           ; EF57 4C 33 84                 L3.
; ----------------------------------------------------------------------------
        jmp     L8AAF                           ; EF5A 4C AF 8A                 L..
; ----------------------------------------------------------------------------
        jmp     L8A84                           ; EF5D 4C 84 8A                 L..
; ----------------------------------------------------------------------------
        jmp     L7A73                           ; EF60 4C 73 7A                 Lsz
; ----------------------------------------------------------------------------
        jmp     L8BC7_73_DOS_MISMATCH                           ; EF63 4C C7 8B                 L..
; ----------------------------------------------------------------------------
        jmp     L8BF3                           ; EF66 4C F3 8B                 L..
; ----------------------------------------------------------------------------
        jmp     L8C1B                           ; EF69 4C 1B 8C                 L..
; ----------------------------------------------------------------------------
        jmp     L8C2B                           ; EF6C 4C 2B 8C                 L+.
; ----------------------------------------------------------------------------
        jmp     L4825                           ; EF6F 4C 25 48                 L%H
; ----------------------------------------------------------------------------
        jmp     L9B23                           ; EF72 4C 23 9B                 L#.
; ----------------------------------------------------------------------------
        jmp     L9BEE                           ; EF75 4C EE 9B                 L..
; ----------------------------------------------------------------------------
        jmp     L673E                           ; EF78 4C 3E 67                 L>g
; ----------------------------------------------------------------------------
        jmp     L5A93                           ; EF7B 4C 93 5A                 L.Z
; ----------------------------------------------------------------------------
        jmp     L51F0                           ; EF7E 4C F0 51                 L.Q
; ----------------------------------------------------------------------------
        jmp     L51F5                           ; EF81 4C F5 51                 L.Q
; ----------------------------------------------------------------------------
        jmp     L51D3                           ; EF84 4C D3 51                 L.Q
; ----------------------------------------------------------------------------
        jmp     L4F4C                           ; EF87 4C 4C 4F                 LLO
; ----------------------------------------------------------------------------
        jmp     L4307                           ; EF8A 4C 07 43                 L.C
; ----------------------------------------------------------------------------
        jmp     L5061                           ; EF8D 4C 61 50                 LaP
; ----------------------------------------------------------------------------
        jmp     L4AF3                           ; EF90 4C F3 4A                 L.J
; ----------------------------------------------------------------------------
        jmp     L78C5                           ; EF93 4C C5 78                 L.x
; ----------------------------------------------------------------------------
        jmp     L77DD                           ; EF96 4C DD 77                 L.w
; ----------------------------------------------------------------------------
        jmp     L5A9E                           ; EF99 4C 9E 5A                 L.Z
; ----------------------------------------------------------------------------
        jmp     L5A79                           ; EF9C 4C 79 5A                 LyZ
; ----------------------------------------------------------------------------
        jmp     L509D                           ; EF9F 4C 9D 50                 L.P
; ----------------------------------------------------------------------------
        jmp     L92DD                           ; EFA2 4C DD 92                 L..
; ----------------------------------------------------------------------------
        jmp     L4DCA                           ; EFA5 4C CA 4D                 L.M
; ----------------------------------------------------------------------------
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

;
;Start of second machine language monitor
;
;$F000-F6FF contains what looks like an entire second monitor
;that was assembled for $B000-B6FF.  It's not the same code
;as the monitor above and the commands are different.
;

        jmp     LF021-$4000                     ; F000 4C 21 B0                 L!.
; ----------------------------------------------------------------------------
        jmp     LF009-$4000                     ; F003 4C 09 B0                 L..
; ----------------------------------------------------------------------------
        jmp     LF0B2-$4000                     ; F006 4C B2 B0                 L..
; ----------------------------------------------------------------------------
LF009:  jsr     LFF7D ;somehow PRIMMs
        .byte   $0d,"BREAK",$07,0
        pla                                     ; F014 68                       h
        sta     $02                             ; F015 85 02                    ..
        ldx     #$05                            ; F017 A2 05                    ..
LF019:  pla                                     ; F019 68                       h
        sta     $03,x                           ; F01A 95 03                    ..
        dex                                     ; F01C CA                       .
        bpl     LF019                           ; F01D 10 FA                    ..
        bmi     LF046                           ; F01F 30 25                    0%
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
        jsr     LFF7D ;somehow PRIMMs
        .byte   $0d,"MONITOR",0
LF046:  cld                                     ; F046 D8                       .
        tsx                                     ; F047 BA                       .
        stx     $09                             ; F048 86 09                    ..
        lda     #$C0                            ; F04A A9 C0                    ..
        jsr     SetMsg                          ; F04C 20 90 FF                  ..
        cli                                     ; F04F 58                       X
; ----------------------------------------------------------------------------
;Registers command
LF050:
        jsr     LFF7D ;somehow PRIMMs
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
LF0B2:  ldx     #$15                            ; F0B2 A2 15                    ..
LF0B4:  cmp     LB0E7-1,x                       ; F0B4 DD E6 B0                 ...
        beq     LF0C5                           ; F0B7 F0 0C                    ..
        dex                                     ; F0B9 CA                       .
        bpl     LF0B4                           ; F0BA 10 F8                    ..
LF0BC:  jsr     LFF7D ;somehow PRIMMs
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
LF0E3:  jmp     (L0A00)                         ; F0E3 6C 00 0A                 l..
; ----------------------------------------------------------------------------
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
LF11A:  stx     $0AB2
        ldx     $68
        lda     #$66                            ; F11F A9 66                    .f
        sei                                     ; F121 78                       x
        jsr     LFF74                           ; F122 20 74 FF                  t.
        cli                                     ; F125 58                       X
        ldx     $0AB2                           ; F126 AE B2 0A                 ...
        rts                                     ; F129 60                       `
; ----------------------------------------------------------------------------
LF12A:  stx     $0AB2                           ; F12A 8E B2 0A                 ...
        ldx     #$66                            ; F12D A2 66                    .f
        stx     $02B9                           ; F12F 8E B9 02                 ...
        ldx     $68                             ; F132 A6 68                    .h
        sei                                     ; F134 78                       x
        jsr     LFF77 ; F135 20 77 FF                  w.
        cli                                     ; F138 58                       X
        ldx     $0AB2                           ; F139 AE B2 0A                 ...
        rts                                     ; F13C 60                       `
; ----------------------------------------------------------------------------
        stx     $0AB2                           ; F13D 8E B2 0A                 ...
        ldx     #$66                            ; F140 A2 66                    .f
LF142:  stx     $02C8                           ; F142 8E C8 02                 ...
        ldx     $68                             ; F145 A6 68                    .h
        sei                                     ; F147 78                       x
        jsr     LFF7A                           ; F148 20 7A FF                  z.
        cli                                     ; F14B 58                       X
        php                                     ; F14C 08                       .
        ldx     $0AB2                           ; F14D AE B2 0A                 ...
        plp                                     ; F150 28                       (
        rts                                     ; F151 60                       `
; ----------------------------------------------------------------------------
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
LF1C9:  jsr     LFF7D ;somehow PRIMMs
        .byte   $1B,"O",$91,0
        jsr     LF1E8-$4000                     ; F1D0 20 E8 B1                  ..
        jmp     LF08B-$4000                     ; F1D3 4C 8B B0                 L..
; ----------------------------------------------------------------------------
;Go command
LF1D6:  jsr     LB974                           ; F1D6 20 74 B9                  t.
        ldx     $09                             ; F1D9 A6 09                    ..
        txs                                     ; F1DB 9A                       .
        jmp     LFF71                           ; F1DC 4C 71 FF                 Lq.
; ----------------------------------------------------------------------------
;Jump to subroutine command
LF1DF:  jsr     LB974                           ; F1DF 20 74 B9                  t.
        jsr     LFF6E                           ; F1E2 20 6E FF                  n.
        jmp     LF08B-$4000                     ; F1E5 4C 8B B0                 L..
; ----------------------------------------------------------------------------
LF1E8:  jsr     LF8B4-$4000                     ; F1E8 20 B4 B8                  ..
        lda     #$3E                            ; F1EB A9 3E                    .>
        jsr     LFFD2_CHROUT                           ; F1ED 20 D2 FF                  ..
        jsr     LF892-$4000                     ; F1F0 20 92 B8                  ..
        ldy     #$00                            ; F1F3 A0 00                    ..
        beq     LF1FA                           ; F1F5 F0 03                    ..
LF1F7:  jsr     LF8A8-$4000                           ; F1F7 20 A8 B8                  ..
LF1FA:  jsr     LF11A-$4000                     ; F1FA 20 1A B1                  ..
        jsr     LF8C2-$4000                           ; F1FD 20 C2 B8                  ..
        iny                                     ; F200 C8                       .
        cpy     #$08                            ; F201 C0 08                    ..
        bit     $D7                             ; F203 24 D7                    $.
        bpl     LF209                           ; F205 10 02                    ..
        cpy     #$10                            ; F207 C0 10                    ..
LF209:  bcc     LF1F7                           ; F209 90 EC                    ..
        jsr     LFF7D ;somehow PRIMMs
        .byte   ":",$12,0
        ldy     #$00                            ; F211 A0 00                    ..
LF213:  jsr     LF11A-$4000                     ; F213 20 1A B1                  ..
        pha                                     ; F216 48                       H
        and     #$7F                            ; F217 29 7F                    ).
        cmp     #$20                            ; F219 C9 20                    .
        pla                                     ; F21B 68                       h
        bcs     LF220                           ; F21C B0 02                    ..
        lda     #$2E                            ; F21E A9 2E                    ..
LF220:  jsr     LFFD2_CHROUT                           ; F220 20 D2 FF                  ..
        iny                                     ; F223 C8                       .
        bit     $D7                             ; F224 24 D7                    $.
        bpl     LF22C                           ; F226 10 04                    ..
        cpy     #$10                            ; F228 C0 10                    ..
        bcc     LF213                           ; F22A 90 E7                    ..
LF22C:  cpy     #$08                            ; F22C C0 08                    ..
        bcc     LF213                           ; F22E 90 E3                    ..
        rts                                     ; F230 60                       `
; ----------------------------------------------------------------------------
;Compare command
LF231:  lda     #$00                            ; F231 A9 00                    ..
        .byte $2c
        ;Fall through
; ----------------------------------------------------------------------------
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
        jsr     LFF77                           ; F296 20 77 FF                  w.
LF299:  ldx     $62                             ; F299 A6 62                    .b
        jsr     LFF7A                           ; F29B 20 7A FF                  z.
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
LF2C3:  jsr     LB950                           ; F2C3 20 50 B9                  P.
LF2C6:  jsr     LB93C                           ; F2C6 20 3C B9                  <.
        bcs     LF27F                           ; F2C9 B0 B4                    ..
LF2CB:  jmp     LF08B-$4000                     ; F2CB 4C 8B B0                 L..
; ----------------------------------------------------------------------------
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
        jsr     LFF7D ;somehow PRIMMs
        .byte   " ERROR",0
        jmp     LF08B-$4000                           ; F3CE 4C 8B B0                 L..
; ----------------------------------------------------------------------------
LF3D1:  ldx     $66                             ; F3D1 A6 66                    .f
        ldy     $67                             ; F3D3 A4 67                    .g
        lda     #$00                            ; F3D5 A9 00                    ..
        sta     SAH                             ; F3D7 85 B9                    ..
        beq     LF3AB                           ; F3D9 F0 D0                    ..
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
        jsr     LFFE1_STOP                           ; F3F3 20 E1 FF                  ..
        beq     LF400                           ; F3F6 F0 08                    ..
        jsr     LB950                           ; F3F8 20 50 B9                  P.
        jsr     LB93C                           ; F3FB 20 3C B9                  <.
        bcs     LF3EE                           ; F3FE B0 EE                    ..
LF400:  jmp     LF08B-$4000                     ; F400 4C 8B B0                 L..
; ----------------------------------------------------------------------------
LF403:  jmp     LF0BC-$4000                     ; F403 4C BC B0                 L..
; ----------------------------------------------------------------------------
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
        jsr     LFF7D ;somehow PRIMMs
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
LF57C:  jsr     LF57F-$4000                     ; F57C 20 7F B5                  ..
LF57F:  stx     $0AAF                           ; F57F 8E AF 0A                 ...
        ldx     $9F                             ; F582 A6 9F                    ..
        cmp     $0AA0,x                         ; F584 DD A0 0A                 ...
        beq     LF593                           ; F587 F0 0A                    ..
        pla                                     ; F589 68                       h
        pla                                     ; F58A 68                       h
LF58B:  inc     $0AB1                           ; F58B EE B1 0A                 ...
        beq     LF579                           ; F58E F0 E9                    ..
        jmp     LF496-$4000                     ; F590 4C 96 B4                 L..
; ----------------------------------------------------------------------------
LF593:  inc     $9F                             ; F593 E6 9F                    ..
        ldx     $0AAF                           ; F595 AE AF 0A                 ...
        rts                                     ; F598 60                       `
; ----------------------------------------------------------------------------
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
LF5AE:  jsr     LFF7D ;somehow PRIMMs
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
        jsr     LFF7D ;somehow PRIMMs
        .byte   "   ",0
        jmp     LF602-$4000                     ; F5F9 4C 02 B6                 L..
; ----------------------------------------------------------------------------
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
LF64D:  ldx     $67                             ; F64D A6 67                    .g
        tay                                     ; F64F A8                       .
        bpl     LF653                           ; F650 10 01                    ..
        dex                                     ; F652 CA                       .
LF653:  adc     $66                             ; F653 65 66                    ef
        bcc     LF658                           ; F655 90 01                    ..
        inx                                     ; F657 E8                       .
LF658:  rts                                     ; F658 60                       `
; ----------------------------------------------------------------------------
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
        lda     LF6C3-$4000,x                   ; F66A BD C3 B6                 ...
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
        tay                                     ; F6A1 A8                       .
        lda     LF721-$4000,y                         ; F6A2 B9 21 B7                 .!.
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
LF6C3:  .byte $40, $02, $45, $03, $d0, $08, $40, $09
        .byte $30, $22, $45, $33, $d0, $08, $40, $09
        .byte $40, $02, $45, $33, $d0, $08, $40, $09
        .byte $40, $02, $45, $b3, $d0, $08, $40, $09
        .byte $00, $22, $44, $33, $d0, $8c, $44, $00
        .byte $11, $22, $44, $33, $d0, $8c, $44, $9a
        .byte $10, $22, $44, $33, $d0, $08, $40, $09
        .byte $10, $22, $44, $33, $d0
; ----------------------------------------------------------------------------

;
;End of second machine language monitor
;

CharacterSet:
; This is the character set. It contains 6 bytes for each characters, and the
; bitmap is "rotated", ie the on screen the resolution is 6*8, not 8*6.
; Character set area is from $F700 to $F9FF, for 128 characters (codes > 128
; would mean inverse text probably?). The area from the point of view of the
; CPU also contains the VIA registers, it seems (see below the character set).

        .byte $00 ;........
LF701:  .byte $3e ;..#####.
        .byte $41 ;.#.....#
        .byte $5d ;.#.###.#
        .byte $51 ;.#.#...#
        .byte $5e ;.#.####.

        .byte $00 ;........
        .byte $7e ;.######.
        .byte $09 ;....#..#
        .byte $09 ;....#..#
        .byte $09 ;....#..#
        .byte $7e ;.######.

        .byte $00 ;........
        .byte $7f ;.#######
        .byte $49 ;.#..#..#
        .byte $49 ;.#..#..#
        .byte $49 ;.#..#..#
        .byte $36 ;..##.##.

        .byte $00 ;........
        .byte $3e ;..#####.
LF714:  .byte $41 ;.#.....#
        .byte $41 ;.#.....#
        .byte $41 ;.#.....#
LF717:  .byte $22 ;..#...#.

        .byte $00 ;........
        .byte $7f ;.#######
LF71A:  .byte $41 ;.#.....#
        .byte $41 ;.#.....#
        .byte $41 ;.#.....#
        .byte $3e ;..#####.

        .byte $00 ;........
        .byte $7f ;.#######
        .byte $49 ;.#..#..#
LF721:  .byte $49 ;.#..#..#
        .byte $41 ;.#.....#
        .byte $41 ;.#.....#

        .byte $00 ;........
        .byte $7f ;.#######
        .byte $09 ;....#..#
        .byte $09 ;....#..#
        .byte $01 ;.......#
        .byte $01 ;.......#

        .byte $00 ;........
        .byte $3e ;..#####.
        .byte $41 ;.#.....#
        .byte $41 ;.#.....#
        .byte $49 ;.#..#..#
        .byte $3a ;..###.#.

        .byte $00 ;........
        .byte $7f ;.#######
        .byte $08 ;....#...
        .byte $08 ;....#...
        .byte $08 ;....#...
        .byte $7f ;.#######

        .byte $00 ;........
        .byte $00 ;........
        .byte $41 ;.#.....#
        .byte $7f ;.#######
        .byte $41 ;.#.....#
        .byte $00 ;........

        .byte $00 ;........
        .byte $20 ;..#.....
        .byte $40 ;.#......
        .byte $41 ;.#.....#
        .byte $3f ;..######
        .byte $01 ;.......#

        .byte $00 ;........
        .byte $7f ;.#######
        .byte $08 ;....#...
        .byte $14 ;...#.#..
        .byte $22 ;..#...#.
        .byte $41 ;.#.....#

        .byte $00 ;........
        .byte $7f ;.#######
        .byte $40 ;.#......
        .byte $40 ;.#......
        .byte $40 ;.#......
        .byte $40 ;.#......

        .byte $00 ;........
        .byte $7f ;.#######
        .byte $02 ;......#.
        .byte $04 ;.....#..
        .byte $02 ;......#.
        .byte $7f ;.#######

        .byte $00 ;........
        .byte $7f ;.#######
        .byte $04 ;.....#..
        .byte $08 ;....#...
        .byte $10 ;...#....
        .byte $7f ;.#######

        .byte $00 ;........
        .byte $3e ;..#####.
        .byte $41 ;.#.....#
        .byte $41 ;.#.....#
        .byte $41 ;.#.....#
        .byte $3e ;..#####.

        .byte $00 ;........
LF761:  .byte $7f ;.#######
        .byte $09 ;....#..#
        .byte $09 ;....#..#
        .byte $09 ;....#..#
        .byte $06 ;.....##.

        .byte $00 ;........
        .byte $3e ;..#####.
        .byte $41 ;.#.....#
        .byte $51 ;.#.#...#
        .byte $61 ;.##....#
        .byte $7e ;.######.

        .byte $00 ;........
        .byte $7f ;.#######
        .byte $09 ;....#..#
        .byte $09 ;....#..#
        .byte $09 ;....#..#
        .byte $76 ;.###.##.

        .byte $00 ;........
        .byte $26 ;..#..##.
        .byte $49 ;.#..#..#
        .byte $49 ;.#..#..#
        .byte $49 ;.#..#..#
        .byte $32 ;..##..#.

        .byte $00 ;........
        .byte $01 ;.......#
        .byte $01 ;.......#
        .byte $7f ;.#######
        .byte $01 ;.......#
        .byte $01 ;.......#

        .byte $00 ;........
        .byte $3f ;..######
        .byte $40 ;.#......
        .byte $40 ;.#......
        .byte $40 ;.#......
        .byte $3f ;..######

        .byte $00 ;........
        .byte $0f ;....####
        .byte $30 ;..##....
        .byte $40 ;.#......
        .byte $30 ;..##....
        .byte $0f ;....####

        .byte $00 ;........
        .byte $7f ;.#######
        .byte $20 ;..#.....
        .byte $10 ;...#....
        .byte $20 ;..#.....
        .byte $7f ;.#######

        .byte $00 ;........
        .byte $63 ;.##...##
        .byte $14 ;...#.#..
        .byte $08 ;....#...
        .byte $14 ;...#.#..
        .byte $63 ;.##...##

        .byte $00 ;........
        .byte $03 ;......##
        .byte $04 ;.....#..
        .byte $78 ;.####...
        .byte $04 ;.....#..
        .byte $03 ;......##

        .byte $00 ;........
        .byte $61 ;.##....#
        .byte $51 ;.#.#...#
        .byte $49 ;.#..#..#
        .byte $45 ;.#...#.#
        .byte $43 ;.#....##

        .byte $00 ;........
        .byte $00 ;........
        .byte $7f ;.#######
        .byte $41 ;.#.....#
        .byte $41 ;.#.....#
        .byte $00 ;........

        .byte $00 ;........
        .byte $03 ;......##
        .byte $04 ;.....#..
        .byte $08 ;....#...
        .byte $10 ;...#....
        .byte $60 ;.##.....

        .byte $00 ;........
        .byte $00 ;........
        .byte $41 ;.#.....#
        .byte $41 ;.#.....#
        .byte $7f ;.#######
        .byte $00 ;........

        .byte $00 ;........
        .byte $08 ;....#...
        .byte $04 ;.....#..
        .byte $02 ;......#.
        .byte $04 ;.....#..
        .byte $08 ;....#...

        .byte $00 ;........
        .byte $08 ;....#...
        .byte $04 ;.....#..
        .byte $08 ;....#...
        .byte $10 ;...#....
        .byte $08 ;....#...

        .byte $00 ;........
        .byte $00 ;........
        .byte $00 ;........
        .byte $00 ;........
        .byte $00 ;........
        .byte $00 ;........

        .byte $00 ;........
        .byte $00 ;........
        .byte $00 ;........
        .byte $5f ;.#.#####
        .byte $00 ;........
        .byte $00 ;........

        .byte $00 ;........
        .byte $00 ;........
        .byte $03 ;......##
        .byte $00 ;........
        .byte $03 ;......##
        .byte $00 ;........

        .byte $00 ;........
        .byte $14 ;...#.#..
        .byte $7f ;.#######
        .byte $14 ;...#.#..
        .byte $7f ;.#######
        .byte $14 ;...#.#..

        .byte $00 ;........
        .byte $26 ;..#..##.
        .byte $49 ;.#..#..#
        .byte $7f ;.#######
        .byte $49 ;.#..#..#
        .byte $32 ;..##..#.

        .byte $00 ;........
        .byte $63 ;.##...##
        .byte $13 ;...#..##
        .byte $08 ;....#...
        .byte $64 ;.##..#..
        .byte $63 ;.##...##

        .byte $00 ;........
        .byte $3a ;..###.#.
        .byte $45 ;.#...#.#
        .byte $2d ;..#.##.#
        .byte $12 ;...#..#.
        .byte $68 ;.##.#...

        .byte $00 ;........
        .byte $00 ;........
        .byte $04 ;.....#..
        .byte $02 ;......#.
        .byte $01 ;.......#
        .byte $00 ;........

        .byte $00 ;........
        .byte $00 ;........
        .byte $00 ;........
        .byte $3e ;..#####.
        .byte $41 ;.#.....#
        .byte $00 ;........

        .byte $00 ;........
        .byte $00 ;........
        .byte $41 ;.#.....#
        .byte $3e ;..#####.
        .byte $00 ;........
        .byte $00 ;........

        .byte $00 ;........
        .byte $2a ;..#.#.#.
        .byte $1c ;...###..
        .byte $08 ;....#...
        .byte $1c ;...###..
        .byte $2a ;..#.#.#.

        .byte $00 ;........
        .byte $08 ;....#...
        .byte $08 ;....#...
        .byte $3e ;..#####.
        .byte $08 ;....#...
        .byte $08 ;....#...

        .byte $00 ;........
        .byte $00 ;........
        .byte $80 ;#.......
        .byte $60 ;.##.....
        .byte $00 ;........
        .byte $00 ;........

        .byte $00 ;........
        .byte $08 ;....#...
        .byte $08 ;....#...
        .byte $08 ;....#...
        .byte $08 ;....#...
        .byte $08 ;....#...

        .byte $00 ;........
        .byte $00 ;........
        .byte $00 ;........
        .byte $60 ;.##.....
        .byte $60 ;.##.....
        .byte $00 ;........

        .byte $00 ;........
        .byte $60 ;.##.....
        .byte $10 ;...#....
        .byte $08 ;....#...
        .byte $04 ;.....#..
        .byte $03 ;......##

        .byte $00 ;........
        .byte $3e ;..#####.
        .byte $61 ;.##....#
        .byte $5d ;.#.###.#
        .byte $43 ;.#....##
        .byte $3e ;..#####.

        .byte $00 ;........
        .byte $00 ;........
        .byte $42 ;.#....#.
        .byte $7f ;.#######
        .byte $40 ;.#......
        .byte $00 ;........

        .byte $00 ;........
        .byte $62 ;.##...#.
        .byte $51 ;.#.#...#
        .byte $49 ;.#..#..#
        .byte $49 ;.#..#..#
        .byte $46 ;.#...##.

        .byte $00 ;........
        .byte $22 ;..#...#.
        .byte $41 ;.#.....#
        .byte $49 ;.#..#..#
        .byte $49 ;.#..#..#
        .byte $36 ;..##.##.

        .byte $00 ;........
        .byte $18 ;...##...
        .byte $14 ;...#.#..
        .byte $12 ;...#..#.
        .byte $7f ;.#######
        .byte $10 ;...#....

        .byte $00 ;........
        .byte $27 ;..#..###
        .byte $49 ;.#..#..#
        .byte $49 ;.#..#..#
        .byte $49 ;.#..#..#
        .byte $31 ;..##...#

        .byte $00 ;........
        .byte $3e ;..#####.
        .byte $49 ;.#..#..#
        .byte $49 ;.#..#..#
        .byte $49 ;.#..#..#
        .byte $32 ;..##..#.

        .byte $00 ;........
        .byte $03 ;......##
        .byte $01 ;.......#
        .byte $71 ;.###...#
        .byte $09 ;....#..#
        .byte $07 ;.....###

        .byte $00 ;........
        .byte $36 ;..##.##.
        .byte $49 ;.#..#..#
        .byte $49 ;.#..#..#
        .byte $49 ;.#..#..#
        .byte $36 ;..##.##.

        .byte $00 ;........
        .byte $26 ;..#..##.
        .byte $49 ;.#..#..#
        .byte $49 ;.#..#..#
        .byte $49 ;.#..#..#
        .byte $3e ;..#####.

        .byte $00 ;........
        .byte $00 ;........
        .byte $00 ;........
        .byte $24 ;..#..#..
        .byte $00 ;........
        .byte $00 ;........

        .byte $00 ;........
        .byte $00 ;........
        .byte $80 ;#.......
        .byte $44 ;.#...#..
        .byte $00 ;........
        .byte $00 ;........

        .byte $00 ;........
        .byte $08 ;....#...
        .byte $14 ;...#.#..
        .byte $22 ;..#...#.
        .byte $41 ;.#.....#
        .byte $00 ;........

        .byte $00 ;........
        .byte $14 ;...#.#..
        .byte $14 ;...#.#..
        .byte $14 ;...#.#..
        .byte $14 ;...#.#..
        .byte $00 ;........

        .byte $00 ;........
        .byte $41 ;.#.....#
        .byte $22 ;..#...#.
        .byte $14 ;...#.#..
        .byte $08 ;....#...
        .byte $00 ;........

        .byte $00 ;........
        .byte $02 ;......#.
        .byte $01 ;.......#
        .byte $51 ;.#.#...#
        .byte $09 ;....#..#
        .byte $06 ;.....##.

        .byte $18 ;...##...
        .byte $18 ;...##...
        .byte $18 ;...##...
        .byte $18 ;...##...
        .byte $18 ;...##...
        .byte $18 ;...##...

        .byte $00 ;........
        .byte $18 ;...##...
        .byte $4c ;.#..##..
        .byte $7e ;.######.
        .byte $4c ;.#..##..
        .byte $18 ;...##...

        .byte $00 ;........
        .byte $00 ;........
        .byte $ff ;########
        .byte $ff ;########
        .byte $00 ;........
        .byte $00 ;........

LF892:  .byte $18 ;...##...
        .byte $18 ;...##...
        .byte $18 ;...##...
        .byte $18 ;...##...
        .byte $18 ;...##...
        .byte $18 ;...##...

        .byte $0c ;....##..
        .byte $0c ;....##..
        .byte $0c ;....##..
        .byte $0c ;....##..
        .byte $0c ;....##..
        .byte $0c ;....##..

        .byte $06 ;.....##.
        .byte $06 ;.....##.
        .byte $06 ;.....##.
        .byte $06 ;.....##.
        .byte $06 ;.....##.
        .byte $06 ;.....##.

        .byte $60 ;.##.....
LF8A5:  .byte $60 ;.##.....
        .byte $60 ;.##.....
        .byte $60 ;.##.....
LF8A8:  .byte $60 ;.##.....
        .byte $60 ;.##.....

        .byte $00 ;........
        .byte $ff ;########
        .byte $ff ;########
        .byte $00 ;........
        .byte $00 ;........
        .byte $00 ;........

        .byte $00 ;........
        .byte $00 ;........
        .byte $00 ;........
        .byte $ff ;########
LF8B4:  .byte $ff ;########
        .byte $00 ;........

        .byte $18 ;...##...
        .byte $38 ;..###...
        .byte $f0 ;####....
        .byte $e0 ;###.....
        .byte $00 ;........
        .byte $00 ;........

        .byte $00 ;........
        .byte $00 ;........
        .byte $07 ;.....###
        .byte $0f ;....####
        .byte $1c ;...###..
        .byte $18 ;...##...

LF8C2:  .byte $18 ;...##...
        .byte $1c ;...###..
        .byte $0f ;....####
        .byte $07 ;.....###
        .byte $00 ;........
        .byte $00 ;........

        .byte $ff ;########
        .byte $ff ;########
        .byte $c0 ;##......
        .byte $c0 ;##......
        .byte $c0 ;##......
        .byte $c0 ;##......

        .byte $01 ;.......#
        .byte $06 ;.....##.
        .byte $08 ;....#...
        .byte $10 ;...#....
LF8D2:  .byte $60 ;.##.....
        .byte $80 ;#.......

        .byte $80 ;#.......
        .byte $60 ;.##.....
        .byte $10 ;...#....
        .byte $08 ;....#...
        .byte $06 ;.....##.
        .byte $01 ;.......#

        .byte $ff ;########
        .byte $ff ;########
        .byte $03 ;......##
        .byte $03 ;......##
        .byte $03 ;......##
        .byte $03 ;......##

        .byte $03 ;......##
        .byte $03 ;......##
        .byte $03 ;......##
        .byte $03 ;......##
        .byte $ff ;########
        .byte $ff ;########

        .byte $3c ;..####..
        .byte $7e ;.######.
        .byte $7e ;.######.
        .byte $7e ;.######.
        .byte $7e ;.######.
        .byte $3c ;..####..

        .byte $60 ;.##.....
        .byte $60 ;.##.....
        .byte $60 ;.##.....
        .byte $60 ;.##.....
        .byte $60 ;.##.....
        .byte $60 ;.##.....

        .byte $00 ;........
        .byte $0c ;....##..
        .byte $1e ;...####.
        .byte $3c ;..####..
        .byte $1e ;...####.
        .byte $0c ;....##..

        .byte $00 ;........
        .byte $ff ;########
        .byte $ff ;########
        .byte $00 ;........
        .byte $00 ;........
        .byte $00 ;........

        .byte $00 ;........
        .byte $00 ;........
        .byte $e0 ;###.....
LF901:  .byte $f0 ;####....
        .byte $38 ;..###...
        .byte $18 ;...##...

        .byte $81 ;#......#
        .byte $66 ;.##..##.
        .byte $18 ;...##...
        .byte $18 ;...##...
        .byte $66 ;.##..##.
        .byte $81 ;#......#

        .byte $3c ;..####..
        .byte $66 ;.##..##.
        .byte $42 ;.#....#.
        .byte $42 ;.#....#.
LF90E:  .byte $66 ;.##..##.
        .byte $3c ;..####..

        .byte $0c ;....##..
        .byte $4c ;.#..##..
        .byte $73 ;.###..##
        .byte $73 ;.###..##
        .byte $4c ;.#..##..
        .byte $0c ;....##..

        .byte $00 ;........
        .byte $00 ;........
        .byte $00 ;........
        .byte $ff ;########
        .byte $ff ;########
        .byte $00 ;........

        .byte $00 ;........
        .byte $08 ;....#...
        .byte $1c ;...###..
        .byte $3e ;..#####.
        .byte $1c ;...###..
        .byte $08 ;....#...

LF922:  .byte $18 ;...##...
        .byte $18 ;...##...
        .byte $ff ;########
        .byte $ff ;########
        .byte $18 ;...##...
        .byte $18 ;...##...

        .byte $00 ;........
        .byte $00 ;........
        .byte $00 ;........
        .byte $77 ;.###.###
        .byte $00 ;........
        .byte $00 ;........

        .byte $00 ;........
        .byte $00 ;........
        .byte $ff ;########
        .byte $ff ;########
        .byte $00 ;........
        .byte $00 ;........

        .byte $08 ;....#...
        .byte $7c ;.#####..
        .byte $04 ;.....#..
        .byte $04 ;.....#..
        .byte $7c ;.#####..
        .byte $02 ;......#.

        .byte $01 ;.......#
        .byte $07 ;.....###
        .byte $0f ;....####
        .byte $1f ;...#####
        .byte $7f ;.#######
        .byte $ff ;########

        .byte $00 ;........
        .byte $00 ;........
        .byte $00 ;........
        .byte $00 ;........
LF944:  .byte $00 ;........
        .byte $00 ;........

        .byte $ff ;########
        .byte $ff ;########
        .byte $ff ;########
        .byte $00 ;........
        .byte $00 ;........
        .byte $00 ;........

        .byte $f0 ;####....
        .byte $f0 ;####....
        .byte $f0 ;####....
        .byte $f0 ;####....
        .byte $f0 ;####....
        .byte $f0 ;####....

        .byte $01 ;.......#
        .byte $01 ;.......#
        .byte $01 ;.......#
        .byte $01 ;.......#
        .byte $01 ;.......#
        .byte $01 ;.......#

        .byte $80 ;#.......
        .byte $80 ;#.......
        .byte $80 ;#.......
        .byte $80 ;#.......
        .byte $80 ;#.......
        .byte $80 ;#.......

        .byte $ff ;########
        .byte $00 ;........
LF960:  .byte $00 ;........
        .byte $00 ;........
        .byte $00 ;........
        .byte $00 ;........

        .byte $00 ;........
        .byte $08 ;....#...
        .byte $08 ;....#...
        .byte $36 ;..##.##.
        .byte $41 ;.#.....#
        .byte $41 ;.#.....#

        .byte $00 ;........
        .byte $00 ;........
        .byte $00 ;........
        .byte $00 ;........
        .byte $00 ;........
        .byte $ff ;########

        .byte $00 ;........
        .byte $41 ;.#.....#
        .byte $41 ;.#.....#
        .byte $36 ;..##.##.
        .byte $08 ;....#...
        .byte $08 ;....#...

        .byte $ff ;########
        .byte $7f ;.#######
        .byte $1f ;...#####
        .byte $0f ;....####
        .byte $07 ;.....###
        .byte $01 ;.......#

        .byte $00 ;........
        .byte $00 ;........
        .byte $00 ;........
        .byte $00 ;........
        .byte $ff ;########
        .byte $ff ;########

        .byte $00 ;........
        .byte $00 ;........
        .byte $ff ;########
        .byte $ff ;########
        .byte $18 ;...##...
        .byte $18 ;...##...

        .byte $00 ;........
        .byte $00 ;........
        .byte $00 ;........
        .byte $f0 ;####....
        .byte $f0 ;####....
        .byte $f0 ;####....

        .byte $00 ;........
        .byte $00 ;........
        .byte $1f ;...#####
        .byte $1f ;...#####
        .byte $18 ;...##...
        .byte $18 ;...##...

        .byte $18 ;...##...
        .byte $18 ;...##...
        .byte $f8 ;#####...
        .byte $f8 ;#####...
        .byte $00 ;........
        .byte $00 ;........

        .byte $c0 ;##......
        .byte $c0 ;##......
        .byte $c0 ;##......
        .byte $c0 ;##......
        .byte $c0 ;##......
        .byte $c0 ;##......

        .byte $00 ;........
        .byte $00 ;........
        .byte $f8 ;#####...
        .byte $f8 ;#####...
        .byte $18 ;...##...
        .byte $18 ;...##...

        .byte $18 ;...##...
        .byte $18 ;...##...
        .byte $1f ;...#####
        .byte $1f ;...#####
        .byte $18 ;...##...
        .byte $18 ;...##...

        .byte $18 ;...##...
        .byte $18 ;...##...
        .byte $f8 ;#####...
        .byte $f8 ;#####...
        .byte $18 ;...##...
        .byte $18 ;...##...

        .byte $18 ;...##...
        .byte $18 ;...##...
        .byte $ff ;########
        .byte $ff ;########
        .byte $00 ;........
        .byte $00 ;........

        .byte $ff ;########
        .byte $ff ;########
        .byte $00 ;........
        .byte $00 ;........
        .byte $00 ;........
        .byte $00 ;........

        .byte $ff ;########
        .byte $ff ;########
        .byte $ff ;########
        .byte $00 ;........
        .byte $00 ;........
        .byte $00 ;........

        .byte $00 ;........
        .byte $00 ;........
        .byte $00 ;........
        .byte $ff ;########
        .byte $ff ;########
        .byte $ff ;########

        .byte $03 ;......##
        .byte $03 ;......##
        .byte $03 ;......##
        .byte $03 ;......##
        .byte $03 ;......##
        .byte $03 ;......##

        .byte $07 ;.....###
        .byte $07 ;.....###
        .byte $07 ;.....###
        .byte $07 ;.....###
        .byte $07 ;.....###
        .byte $07 ;.....###

        .byte $e0 ;###.....
        .byte $e0 ;###.....
        .byte $e0 ;###.....
        .byte $e0 ;###.....
        .byte $e0 ;###.....
        .byte $e0 ;###.....

        .byte $c0 ;##......
        .byte $c0 ;##......
        .byte $c0 ;##......
        .byte $c0 ;##......
        .byte $ff ;########
        .byte $ff ;########

        .byte $f0 ;####....
        .byte $f0 ;####....
        .byte $f0 ;####....
        .byte $00 ;........
        .byte $00 ;........
        .byte $00 ;........

        .byte $00 ;........
        .byte $00 ;........
        .byte $00 ;........
        .byte $0f ;....####
        .byte $0f ;....####
        .byte $0f ;....####

        .byte $18 ;...##...
        .byte $18 ;...##...
        .byte $1f ;...#####
        .byte $1f ;...#####
        .byte $00 ;........
        .byte $00 ;........

        .byte $0f ;....####
        .byte $0f ;....####
        .byte $0f ;....####
        .byte $00 ;........
        .byte $00 ;........
        .byte $00 ;........

        .byte $0f ;....####
        .byte $0f ;....####
        .byte $0f ;....####
        .byte $f0 ;####....
        .byte $f0 ;####....
        .byte $f0 ;####....

;These overlap the character set data above.

VIA1_PORTB    := $F800
VIA1_PORTA    := $F801
VIA1_DDRB     := $F802
VIA1_DDRA     := $F803
VIA1_T1CL     := $F804
VIA1_T1CH     := $F805
VIA1_T1LL     := $F806
VIA1_T1LH     := $F807
VIA1_T2CL     := $F808
VIA1_T2CH     := $F809
VIA1_SR       := $F80A
VIA1_ACR      := $F80B
VIA1_PCR      := $F80C
VIA1_IFR      := $F80D
VIA1_IER      := $F80E
VIA1_PORTANHS := $F80F

VIA2_PORTB    := $F880
VIA2_PORTA    := $F881
VIA2_DDRB     := $F882
VIA2_DDRA     := $F883
VIA2_T1CL     := $F884
VIA2_T1CH     := $F885
VIA2_T1LL     := $F886
VIA2_T1LH     := $F887
VIA2_T2CL     := $F888
VIA2_T2CH     := $F889
VIA2_SR       := $F88A
VIA2_ACR      := $F88B
VIA2_PCR      := $F88C
VIA2_IFR      := $F88D
VIA2_IER      := $F88E
VIA2_PORTANHS := $F88F

ACIA_DATA     := $F980
ACIA_ST       := $F981
ACIA_CMD      := $F982
ACIA_CTRL     := $F983


; ----------------------------------------------------------------------------
MMU_MODE_KERN:
        sei
        sta     MMU_MODE_KERN
        jmp     L87C5
; ----------------------------------------------------------------------------
; The actual RESET routine, pointed by the RESET hardware vector. Notice the
; usage $FA00, seems to be a dummy write (no actual LDA before it, etc).
; Maybe it's just for enabling the lower part of the KERNAL to be mapped, so
; we can jump there, or something like that.
RESET:  sei
        sta     MMU_MODE_KERN
        jmp     KL_RESET
; ----------------------------------------------------------------------------
; The IRQ routine, pointed by the IRQ hardware vector. Note about the usage
; of $FC00 and $FA80 locations, seems to be dummy write, as with the RESET
; routine, but different addresses ...
IRQ:    pha
        phx
        phy
        sta     MMU_MODE_SAVE
        sta     MMU_MODE_APPL
        tsx
        lda     stack+4,x
        and     #$10
        bne     LFA28
        lda     #>(RETURN_FROM_IRQ-1)
        pha
        lda     #<(RETURN_FROM_IRQ-1)
        pha
        jmp     (RAMVEC_IRQ)
; ----------------------------------------------------------------------------
LFA28:  jmp     (RAMVEC_BRK)
; ----------------------------------------------------------------------------
DEFVEC_BRK:
; Default BRK handler, drops into monitor
        sta     MMU_MODE_KERN
        jmp     MON_BRK
; ----------------------------------------------------------------------------
DEFVEC_IRQ:
; Default IRQ handler, where IRQ RAM vector ($314) points to by default.
        sta     MMU_MODE_KERN

        lda     ACIA_ST
        bpl     LFA3C               ;Branch if interrupt was not caused by ACIA
        jsr     ACIA_IRQ      ;Service ACIA, then come back here for VIA1

LFA3C:  bit     VIA1_IFR
        bpl     LFA43               ;Branch if IRQ was not caused by VIA1
        bvs     LFA44_VIA1_T1_IRQ   ;Branch if VIA1 Timer 1 caused the interrupt

LFA43:  rts
; ----------------------------------------------------------------------------
;VIA1 Timer 1 Interrupt Occurred
LFA44_VIA1_T1_IRQ:
        lda     VIA1_T1CL
        lda     VIA1_T1LL
        jsr     KL_SCNKEY
        jsr     BLINK
        jsr     UDTIM__
        jsr     UDBELL
        sta     MMU_MODE_APPL
        jmp     (RAMVEC_NMI)
; ----------------------------------------------------------------------------
DEFVEC_NMI:
        sta     MMU_MODE_KERN
        rts
; ----------------------------------------------------------------------------
RETURN_FROM_IRQ:
        ply
        plx
        pla
        sta     MMU_MODE_RECALL
NMI:    rti
; ----------------------------------------------------------------------------
LFA67:  jsr     LFA6D
        jmp     MMU_MODE_KERN_RTS
; ----------------------------------------------------------------------------
LFA6D:  phy
        pha
        jmp     LFD7A
; ----------------------------------------------------------------------------
GO_APPL_STORE_GO_KERN:
        sta     MMU_MODE_APPL
        jmp     GO_NOWHERE_STORE_GO_KERN
; ----------------------------------------------------------------------------
LFA78:  jsr     LFA7E
LFA7B:  jmp     MMU_MODE_KERN_RTS
; ----------------------------------------------------------------------------
LFA7E:
MMU_MODE_APPL   := * + 2
; An interesting example for addresses like $FA80 are write only registers,
; but on read, normal ROM content is read as opcodes, as $FA80 here is inside
; and opcode itself.
        sta     MMU_MODE_APPL
        jmp     (L0334)
; ----------------------------------------------------------------------------
LFA84:  jsr     LFA8A
LFA87:  jmp     MMU_MODE_KERN_RTS
; ----------------------------------------------------------------------------
LFA8A:  sta     MMU_MODE_APPL
        jmp     (L0336)  ;Contains LFA87 by default
; ----------------------------------------------------------------------------
; Default values of "RAM vectors" copied to $314 into the RAM. The "missing"
; vector in the gap seems to be "monitor" entry (according to C128's ROM) but
; points to RTS in CLCD. The the last two vectors are unknown, not exists on
; C128.
VECTSS: .addr   DEFVEC_IRQ
        .addr   DEFVEC_BRK
        .addr   DEFVEC_NMI
        .addr   DEFVEC_OPEN
        .addr   DEFVEC_CLOSE
        .addr   DEFVEC_CHKIN
        .addr   DEFVEC_CHKOUT
        .addr   DEFVEC_CLRCHN
        .addr   DEFVEC_CHRIN
        .addr   DEFVEC_CHROUT
        .addr   DEFVEC_STOP
        .addr   DEFVEC_GETIN
        .addr   DEFVEC_CLALL
        .addr   LFAB4
        .addr   DEFVEC_LOAD
        .addr   DEFVEC_SAVE
        .addr   LFA7B
        .addr   LFA87
; ----------------------------------------------------------------------------
LFAB4:  rts
; ----------------------------------------------------------------------------
LFAB5:  sta     MMU_MODE_KERN
        jsr     LD437
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
LFABF:  sta     MMU_MODE_KERN
        jsr     LC009_CHECK_MODKEY_AND_UNKNOWN_SECS_MINS
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
LFAC9:  sta     MMU_MODE_KERN
        jsr     LB6DF_GET_KEY_BLOCKING
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
LFAD3:  sta     MMU_MODE_KERN
        jsr     L821D
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
LFADD:  sta     MMU_MODE_KERN
        jsr     L8426
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
LFAE7:  sta     MMU_MODE_KERN
        jsr     L80E0_DRAW_FKEY_BAR_AND_WAIT_FOR_FKEY_OR_RETURN
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
LFAF1:  sta     MMU_MODE_KERN
        jsr     LAA53
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
LFAFB:  sta     MMU_MODE_KERN
MMU_MODE_RAM    := * + 2
        jsr     LA9E6                           ; FAFE 20 E6 A9                  ..
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
LFB05:  sta     MMU_MODE_KERN
        jsr     L84FB
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
LFB0F:  sta     MMU_MODE_KERN
        jsr     LBFF2
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
LFB19:  sta     MMU_MODE_KERN
        jsr     LB09B
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
LFB23:  sta     MMU_MODE_KERN
        jsr     L80C6
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
LFB2D:  sta     MMU_MODE_KERN
        jsr     L81FB
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
LFB37:  sta     MMU_MODE_KERN
        jsr     L8459
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
LFB41:  sta     MMU_MODE_KERN
        jsr     L9B1B
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
LFB4B:  sta     MMU_MODE_APPL
        jmp     (L0300)
; ----------------------------------------------------------------------------
PRIMM00:
; This stuff prints (zero terminated) string after the JSR to the screen (by
; using the return address from the stack). The multiple entry points seems
; to be about the fact that "kernal messages control byte" should be checked
; or not, and such ...
        pha
        lda     #$00
        bra     LFB5E

PRIMM80:
        pha
        lda     #$80
        bra     LFB5E

PRIMM:
        pha
        lda     #$01
LFB5E:  phx
        pha
        bra     LFB77
LFB62:  plx
        phx
        bpl     LFB6B
        bit     MSGFLG
        bpl     LFB71
LFB6B:  sta     MMU_MODE_KERN
        jsr     KR_ShowChar_
LFB71:  txa
        bne     LFB77
        sta     MMU_MODE_APPL
LFB77:  tsx
        inc     stack+4,x
        bne     MMU_MODE_RECALL
        inc     stack+5,x
MMU_MODE_RECALL:
        lda     stack+4,x
        sta     $F1
        lda     stack+5,x
        sta     $F2
        lda     ($F1)
        bne     LFB62
        plx
        plx
        pla
        rts
; ----------------------------------------------------------------------------
; Code from here clearly shows many examples for the need to "dummy write"
; some "MMU registers" - $FA00 - (maybe only a flip-flop) before jumping to
; lower address in the KERNAL ROM.  Usually there is even an operation like
; that after the call - $FA80. My guess: the top of the kernal is always (?)
; mapped into the CPU address space, but lower addresses are not; so you need
; to "page in" first. However I don't know _exactly_ what happens with
; $FA00/$FA80 (set/reset a flip-flop, but what memory region is affected then
; exactly).
KR_LB758:
        sta     MMU_MODE_KERN
        jsr     LB758
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
KR_LD230_JMP_LD233_PLUS_X:
        sta     MMU_MODE_KERN
        jsr     LD230_JMP_LD233_PLUS_X
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
KR_LB293:  sta     MMU_MODE_KERN
        jsr     LB293
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
WaitXticks:
        sta     MMU_MODE_KERN
        jsr     WaitXticks_
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
KR_JMP_BELL_RELATED_X:
        sta     MMU_MODE_KERN
        jsr     JMP_BELL_RELATED_X
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
LFBC4:  sta     MMU_MODE_KERN
        pha
        bcs     LFBCF
        jsr     LB2E4_HIDE_CURSOR
        bra     LFBD2

LFBCF:  jsr     LB2D6_SHOW_CURSOR
LFBD2:  pla
        jmp     LFD7A
; ----------------------------------------------------------------------------
KR_LB6F9_MAYBE_PUT_CHAR_IN_FKEY_BAR_SLOT:
        sta     MMU_MODE_KERN
        jsr     LB6F9_MAYBE_PUT_CHAR_IN_FKEY_BAR_SLOT
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
KR_ShowChar:
        sta     MMU_MODE_KERN
        jsr     KR_ShowChar_
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
KR_LCDsetupGetOrSet:
        sta     MMU_MODE_KERN
        jsr     LCDsetupGetOrSet
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
KR_LB684_STA_03F9:
        sta     MMU_MODE_KERN
        jsr     LB684_STA_03F9
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
KR_LB688_GET_KEY_NONBLOCKING:
MMU_MODE_SAVE   := * + 2
        sta     MMU_MODE_KERN                   ; FBFE 8D 00 FA                 ...
        jsr     LB688_GET_KEY_NONBLOCKING
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
KR_LFC08_JSR_LB4FB_RESET_KEYD_BUFFER:
        sta     MMU_MODE_KERN
        jsr     LB4FB_RESET_KEYD_BUFFER
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
KR_PUT_KEY_INTO_KEYD_BUFFER:
        sta     MMU_MODE_KERN
        jsr     PUT_KEY_INTO_KEYD_BUFFER
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
KR_SCINIT:
        sta     MMU_MODE_KERN
        jsr     KL_SCINIT
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
KL_SCINIT:
        ldx     #$00
        jsr     LD230_JMP_LD233_PLUS_X  ;-> LD247_X_00
        jmp     SCINIT_
; ----------------------------------------------------------------------------
KR_IOINIT:
        sta     MMU_MODE_KERN
        jsr     KL_IOINIT
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
KR_RAMTAS:
        sta     MMU_MODE_KERN
        jsr     KL_RAMTAS
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
KR_RESTOR:
        sta     MMU_MODE_KERN
        jsr     KL_RESTOR
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
KR_VECTOR:
        sta     MMU_MODE_KERN
        jsr     KL_VECTOR
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
SetMsg_:sta     MSGFLG
        rts
; ----------------------------------------------------------------------------
LSTNSA_:sta     MMU_MODE_KERN
        jsr     SECND
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
TALKSA_:sta     MMU_MODE_KERN
        jsr     TKSA
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
MEMBOT_:sta     MMU_MODE_KERN
        jsr     MEMBOT__
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
MEMTOP_:sta     MMU_MODE_KERN
        jsr     MEMTOP__
MME_MODE_TEST := *+2
        sta     MMU_MODE_APPL                   ; FC88 8D 80 FA                 ...
        rts
; ----------------------------------------------------------------------------
KR_SCNKEY:
        sta     MMU_MODE_KERN
        jsr     KL_SCNKEY
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
IECIN_: sta     MMU_MODE_KERN
        jsr     ACPTR
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
IECOUT_:sta     MMU_MODE_KERN
        jsr     CIOUT
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
UNTALK_:sta     MMU_MODE_KERN
        jsr     UNTLK
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
UNLSTN_:sta     MMU_MODE_KERN
        jsr     UNLSN
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
LISTEN_:sta     MMU_MODE_KERN
        jsr     LISTN
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
TALK_:  sta     MMU_MODE_KERN
        jsr     TALK__
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
READST_:lda     SATUS
UDST:   ora     SATUS
        sta     SATUS
        rts
; ----------------------------------------------------------------------------
SETLFS_:sta     LA
        stx     FA
        sty     SA
        rts
; ----------------------------------------------------------------------------
SETNAM_:sta     FNLEN
        stx     FNADR
        sty     FNADR+1
        rts
; ----------------------------------------------------------------------------
Open_:  sta     MMU_MODE_APPL
        jsr     Open
        jmp     MMU_MODE_KERN_RTS
; ----------------------------------------------------------------------------
DEFVEC_OPEN:
        sta     MMU_MODE_KERN
        jsr     Open__
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
LFCF1_APPL_CLOSE:
        sta     MMU_MODE_APPL
        jsr     LFFC3_CLOSE
        jmp     MMU_MODE_KERN_RTS
; ----------------------------------------------------------------------------
DEFVEC_CLOSE:
        sta     MMU_MODE_KERN
        jsr     CLOSE__
MMU_APPL_WINDOW1:
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
        sta     MMU_MODE_APPL
        jsr     LFFC6_CHKIN
        jmp     MMU_MODE_KERN_RTS
; ----------------------------------------------------------------------------
DEFVEC_CHKIN:
        sta     MMU_MODE_KERN
        jsr     CHKIN__
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
        sta     MMU_MODE_APPL
        jsr     LFFC9_CHKOUT
        jmp     MMU_MODE_KERN_RTS
; ----------------------------------------------------------------------------
DEFVEC_CHKOUT:
        sta     MMU_MODE_KERN
        jsr     CHKOUT__
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
CLRCH:  sta     MMU_MODE_APPL
        jsr     LFFCC_CLRCH
        jmp     MMU_MODE_KERN_RTS
; ----------------------------------------------------------------------------
DEFVEC_CLRCHN:
        sta     MMU_MODE_KERN
        jsr     CLRCHN__
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
LFD3D_CHRIN:
        sta     MMU_MODE_APPL
        jsr     LFFCF_CHRIN ;BASIN
        jmp     MMU_MODE_KERN_RTS
; ----------------------------------------------------------------------------
DEFVEC_CHRIN:
        sta     MMU_MODE_KERN
        jsr     CHRIN__
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
        sta     MMU_MODE_APPL
        jsr     LFFD2_CHROUT
        jmp     MMU_MODE_KERN_RTS
; ----------------------------------------------------------------------------
DEFVEC_CHROUT:
        sta     MMU_MODE_KERN
        jsr     CHROUT__
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
LFD63_LOAD_THEN_GO_KERN:
        jsr     LOAD_
        ;Fall through

MMU_MODE_KERN_RTS:
        sta     MMU_MODE_KERN
        rts
; ----------------------------------------------------------------------------
LOAD_:  stx     $B4
        sty     $B5
        sta     MMU_MODE_APPL
        jmp     (RAMVEC_LOAD)
; ----------------------------------------------------------------------------
DEFVEC_LOAD:
LFD75           := * + 1
        sta     MMU_MODE_KERN                   ; FD74 8D 00 FA                 ...
        jsr     LOAD__
LFD7A:  sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
MMU_APPL_WINDOW2:= * + 2
        sta     MMU_MODE_RAM                    ; FD7E 8D 00 FB                 ...
        rts
; ----------------------------------------------------------------------------
LFD82_SAVE_AND_GO_KERN:
        jsr     SAVE_
        jmp     MMU_MODE_KERN_RTS
; ----------------------------------------------------------------------------
SAVE_:  stx     EAL
        sty     EAH
        tax
        lda     $00,x
        sta     $B6
        lda     $01,x
        sta     STAH
        sta     MMU_MODE_APPL
        jmp     (RAMVEC_SAVE)
; ----------------------------------------------------------------------------
DEFVEC_SAVE:
        sta     MMU_MODE_KERN
        jsr     SAVE__
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
RDTIM_: sta     MMU_MODE_KERN
        jsr     LBFD8_RDTIM
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
SETTIM_:sta     MMU_MODE_KERN
        jsr     LBFCE_SETTIM
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
LFDB9_STOP:
        sta     MMU_MODE_APPL
        jsr     LFFE1_STOP
        jmp     MMU_MODE_KERN_RTS
; ----------------------------------------------------------------------------
DEFVEC_STOP:
        sta     MMU_MODE_KERN
        jsr     LB6E8_STOP
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
        sta     MMU_MODE_APPL
        jsr     LFFE4_GETIN
        jmp     MMU_MODE_KERN_RTS
; ----------------------------------------------------------------------------
DEFVEC_GETIN:
        sta     MMU_MODE_KERN
        jsr     LB918_CHRIN___OR_LB688_GET_KEY_NONBLOCKING
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
LFDDF_JSR_LFFE7_CLALL:
        sta     MMU_MODE_APPL
        jsr     LFFE7_CLALL
        jmp     MMU_MODE_KERN_RTS
; ----------------------------------------------------------------------------
DEFVEC_CLALL:
        sta     MMU_MODE_KERN
        jsr     CLALL__
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
UDTIM_: sta     MMU_MODE_KERN
        jsr     UDTIM__
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
; SCREEN. Fetch number of screen rows and columns.
; On CLCD the screen's resolution is 80*16 chars.
SCREEN_:ldx     #80
        ldy     #16
MMU_APPL_WINDOW3:
        rts
; ----------------------------------------------------------------------------
; PLOT.   Save or restore cursor position.
; Input:  Carry: 0 = Restore from input, 1 = Save to output; X = Cursor
; column
;         (if Carry = 0); Y = Cursor row (if Carry = 0).
; Output: X = Cursor column (if Carry = 1); Y = Cursor row (if Carry = 1).
;         Used registers: X, Y.
PLOT_:  bcs     LFE07
        sty     CursorX
        stx     CursorY
LFE07:  ldy     CursorX
        ldx     CursorY
        rts
; ----------------------------------------------------------------------------
; IOBASE. Fetch VIA #1 base address.
; Input: -
; Output: X/Y = VIA #1 base address .
; Used registers: X, Y.
IOBASE_:ldx     #<$F800                         ; FE0C A2 00                    ..
        ldy     #>$F800                         ; FE0E A0 F8                    ..
        rts                                     ; FE10 60                       `
; ----------------------------------------------------------------------------

; Seems to be an unused area.
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; FE11 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; FE19 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; FE21 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; FE29 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; FE31 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; FE39 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; FE41 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; FE49 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; FE51 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; FE59 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; FE61 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; FE69 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; FE71 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF     ; FE79 FF FF FF FF FF FF FF     .......
MMU_APPL_WINDOW4:
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; FE80 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; FE88 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; FE90 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; FE98 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; FEA0 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; FEA8 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; FEB0 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; FEB8 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; FEC0 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; FEC8 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; FED0 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; FED8 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; FEE0 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; FEE8 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; FEF0 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; FEF8 FF FF FF FF FF FF FF FF  ........
MMU_KERN_WINDOW:
        .byte   $FF,$FF,$FF                     ; FF00 FF FF FF                 ...
LFF03:  .byte   $FF                             ; FF03 FF                       .
LFF04:  .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; FF04 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF                 ; FF0C FF FF FF FF              ....
LFF10:  .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; FF10 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; FF18 FF FF FF FF FF FF FF FF  ........
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF     ; FF20 FF FF FF FF FF FF FF     .......
; ----------------------------------------------------------------------------
        jmp     LFAB5                           ; FF27 4C B5 FA                 L..
; ----------------------------------------------------------------------------
        jmp     LFABF                           ; FF2A 4C BF FA                 L..
; ----------------------------------------------------------------------------
        jmp     LFAC9                           ; FF2D 4C C9 FA                 L..
; ----------------------------------------------------------------------------
        jmp     LFAD3                           ; FF30 4C D3 FA                 L..
; ----------------------------------------------------------------------------
        jmp     LFADD                           ; FF33 4C DD FA                 L..
; ----------------------------------------------------------------------------
        jmp     LFAE7                           ; FF36 4C E7 FA                 L..
; ----------------------------------------------------------------------------
        jmp     LFAF1                           ; FF39 4C F1 FA                 L..
; ----------------------------------------------------------------------------
        jmp     LFAFB                           ; FF3C 4C FB FA                 L..
; ----------------------------------------------------------------------------
; Power off with saving the state.
        jmp     LFB05                           ; FF3F 4C 05 FB                 L..
; ----------------------------------------------------------------------------
        jmp     LFB0F                           ; FF42 4C 0F FB                 L..
; ----------------------------------------------------------------------------
        jmp     LFB19                           ; FF45 4C 19 FB                 L..
; ----------------------------------------------------------------------------
LFF4A           := * + 2
        jmp     LFB23                           ; FF48 4C 23 FB                 L#.
; ----------------------------------------------------------------------------
        jmp     LFB2D                           ; FF4B 4C 2D FB                 L-.
; ----------------------------------------------------------------------------
LFF50           := * + 2
        jmp     LFB37                           ; FF4E 4C 37 FB                 L7.
; ----------------------------------------------------------------------------
        jmp     LFB41                           ; FF51 4C 41 FB                 LA.
; ----------------------------------------------------------------------------
        jmp     PRIMM00                ; FF54 4C 51 FB                 LQ.
; ----------------------------------------------------------------------------
LFF59           := * + 2
        jmp     KR_LB758                           ; FF57 4C 92 FB                 L..
; ----------------------------------------------------------------------------
LFF5C           := * + 2
        jmp     KR_LD230_JMP_LD233_PLUS_X          ; FF5A 4C 9C FB                 L..
; ----------------------------------------------------------------------------
        jmp     KR_LB293                           ; FF5D 4C A6 FB                 L..
; ----------------------------------------------------------------------------
        jmp     WaitXticks                      ; FF60 4C B0 FB                 L..
; ----------------------------------------------------------------------------
        jmp     KR_JMP_BELL_RELATED_X                           ; FF63 4C BA FB                 L..
; ----------------------------------------------------------------------------
        jmp     LFBC4                           ; FF66 4C C4 FB                 L..
; ----------------------------------------------------------------------------
        jmp     KR_LB6F9_MAYBE_PUT_CHAR_IN_FKEY_BAR_SLOT                           ; FF69 4C D6 FB                 L..
; ----------------------------------------------------------------------------
LFF6E := * + 2
        jmp     KR_ShowChar                        ; FF6C 4C E0 FB                 L..
; ----------------------------------------------------------------------------
LFF71 := * + 2
        jmp     KR_LCDsetupGetOrSet                           ; FF6F 4C EA FB                 L..
; ----------------------------------------------------------------------------
LFF74 := * + 2
        jmp     KR_LB684_STA_03F9                           ; FF72 4C F4 FB                 L..
; ----------------------------------------------------------------------------
LFF77 := * + 2
        jmp     KR_LB688_GET_KEY_NONBLOCKING       ; FF75 4C FE FB                 L..
; ----------------------------------------------------------------------------
LFF7A := * + 2
        jmp     KR_LFC08_JSR_LB4FB_RESET_KEYD_BUFFER                           ; FF78 4C 08 FC                 L..
; ----------------------------------------------------------------------------
LFF7D := * + 2
        jmp     KR_PUT_KEY_INTO_KEYD_BUFFER        ; FF7B 4C 12 FC                 L..
; ----------------------------------------------------------------------------
        .byte   $FF                             ; FF7E FF                       .
        .byte   $FF                             ; FF7F FF                       .
        .byte   $FF                             ; FF80 FF                       .

;LCD Controller Registers $FF80-$FF83
LCDCTRL_REG0 := * -1   ;FF80
LCDCTRL_REG1 := *      ;FF81
LCDCTRL_REG2 := * + 1  ;FF82
LCDCTRL_REG3 := * + 2  ;FF83

; ------------------------------------------------------------------------------
; Begin of the table of the kernal vectors (well, compared with "standard
; KERNAL entries" on Commodore 64, I can just guess if there is not so much
; difference on the CLCD)
; ------------------------------------------------------------------------------
KJ_SCINIT:
        jmp     KR_SCINIT                       ; FF81 4C 1C FC                 L..
; ----------------------------------------------------------------------------
KJ_IOINIT:
        jmp     KR_IOINIT                       ; FF84 4C 2E FC                 L..
; ----------------------------------------------------------------------------
KJ_RAMTAS:
        jmp     KR_RAMTAS                       ; FF87 4C 38 FC                 L8.
; ----------------------------------------------------------------------------
KJ_RESTOR:
        jmp     KR_RESTOR                       ; FF8A 4C 42 FC                 LB.
; ----------------------------------------------------------------------------
KJ_VECTOR:
        jmp     KR_VECTOR                       ; FF8D 4C 4C FC                 LL.
; ----------------------------------------------------------------------------
SetMsg: jmp     SetMsg_                         ; FF90 4C 56 FC                 LV.
; ----------------------------------------------------------------------------
LSTNSA: jmp     LSTNSA_                         ; FF93 4C 5A FC                 LZ.
; ----------------------------------------------------------------------------
TALKSA: jmp     TALKSA_                         ; FF96 4C 64 FC                 Ld.
; ----------------------------------------------------------------------------
MEMBOT: jmp     MEMBOT_                         ; FF99 4C 6E FC                 Ln.
; ----------------------------------------------------------------------------
MEMTOP: jmp     MEMTOP_                         ; FF9C 4C 78 FC                 Lx.
; ----------------------------------------------------------------------------
KJ_SCNKEY:
        jmp     KR_SCNKEY                       ; FF9F 4C 82 FC                 L..
; ----------------------------------------------------------------------------
; The following entry (three bytes) would be "SETTMO. Unknown. (Set serial
; bus timeout.)" according to the C64 KERNAL, however on CLCD it is unused.
SETTMO: rts                                     ; FFA2 60                       `
        rts                                     ; FFA3 60                       `
        rts                                     ; FFA4 60                       `
; ----------------------------------------------------------------------------
IECIN:  jmp     IECIN_                          ; FFA5 4C 8C FC                 L..
; ----------------------------------------------------------------------------
IECOUT: jmp     IECOUT_                         ; FFA8 4C 96 FC                 L..
; ----------------------------------------------------------------------------
UNTALK: jmp     UNTALK_                         ; FFAB 4C A0 FC                 L..
; ----------------------------------------------------------------------------
UNLSTN: jmp     UNLSTN_                         ; FFAE 4C AA FC                 L..
; ----------------------------------------------------------------------------
LISTEN: jmp     LISTEN_                         ; FFB1 4C B4 FC                 L..
; ----------------------------------------------------------------------------
; TALK. Send TALK command to serial bus.
; Input: A = Device number.
TALK:   jmp     TALK_                           ; FFB4 4C BE FC                 L..
; ----------------------------------------------------------------------------
; READST. Fetch status of current input/output device, value of ST
; variable. (For RS232, status is cleared.)
; Output: A = Device status.
READST: jmp     READST_                          ; FFB7 4C C8 FC                 L..
; ----------------------------------------------------------------------------
; SETLFS. Set file parameters.
; Input: A = Logical number; X = Device number; Y = Secondary address.
SETLFS: jmp     SETLFS_                          ; FFBA 4C CF FC                 L..
; ----------------------------------------------------------------------------
; SETNAM. Set file name parameters.
; Input: A = File name length; X/Y = Pointer to file name.
SETNAM: jmp     SETNAM_                          ; FFBD 4C D6 FC                 L..
; ----------------------------------------------------------------------------
; "OPEN". Must call SETLFS_ and SETNAM_ beforehands.
; RAMVEC_OPEN points to $FCE7 in RAM by default.
Open:   jmp     (RAMVEC_OPEN)                   ; FFC0 6C 1A 03                 l..
; ----------------------------------------------------------------------------
LFFC3_CLOSE:  jmp     (RAMVEC_CLOSE)                  ; FFC3 6C 1C 03                 l..
; ----------------------------------------------------------------------------
LFFC6_CHKIN:  jmp     (RAMVEC_CHKIN)                  ; FFC6 6C 1E 03                 l..
; ----------------------------------------------------------------------------
LFFC9_CHKOUT:  jmp     (RAMVEC_CHKOUT)                 ; FFC9 6C 20 03                 l .
; ----------------------------------------------------------------------------
LFFCC_CLRCH:  jmp     (RAMVEC_CLRCHN)                 ; FFCC 6C 22 03                 l".
; ----------------------------------------------------------------------------
LFFCF_CHRIN:  jmp     (RAMVEC_CHRIN)                  ; FFCF 6C 24 03                 l$.
; ----------------------------------------------------------------------------
LFFD2_CHROUT:  jmp     (RAMVEC_CHROUT)                 ; FFD2 6C 26 03                 l&.
; ----------------------------------------------------------------------------
; ??LOAD. Load or verify file. (Must call SETLFS_ and SETNAM_ beforehands.)
; Input: A: 0 = Load, 1-255 = Verify; X/Y = Load address (if secondary
; address = 0).
; Output: Carry: 0 = No errors, 1 = Error; A = KERNAL error code (if Carry =
; 1); X/Y = Address of last byte loaded/verified (if Carry = 0).
; Used registers: A, X, Y.
; Real address: $F49E.
LOAD:   jmp     LOAD_                           ; FFD5 4C 6A FD                 Lj.
; ----------------------------------------------------------------------------
; ??SAVE. Save file. (Must call SETLFS_ and SETNAM_ beforehands.)
; Input: A = Address of zero page register holding start address of memory
; area to save; X/Y = End address of memory area plus 1.
; Output: Carry: 0 = No errors, 1 = Error; A = KERNAL error code (if Carry =
; 1).
; Used registers: A, X, Y.
; Real address: $F5DD.
SAVE:   jmp     SAVE_                           ; FFD8 4C 88 FD                 L..
; ----------------------------------------------------------------------------
; RDTIM. Read Time of Day
; Input: A/X/Y = New TOD value.
; Output: –
; Used registers: –
; Real address: $F6E4.
RDTIM:  jmp     RDTIM_                           ; FFDB 4C A5 FD                 L..
; ----------------------------------------------------------------------------
; SETTIM. Set Time of Day
; Input: –
; Output: A/X/Y = Current TOD value.
; Used registers: A, X, Y.
SETTIM: jmp     SETTIM_                           ; FFDE 4C AF FD                 L..
; ----------------------------------------------------------------------------
; ??STOP. Query Stop key indicator, at memory address $0091; if pressed, call
; CLRCHN and clear keyboard buffer.
; Input: –
; Output: Zero: 0 = Not pressed, 1 = Pressed; Carry: 1 = Pressed.
; Used registers: A, X.
; Vector in RAM ($328) seems to point to $FDC2
LFFE1_STOP:  jmp     (RAMVEC_STOP)                   ; FFE1 6C 28 03                 l(.
; ----------------------------------------------------------------------------
; GETIN. Read byte from default input. (If not keyboard, must call OPEN and
; CHKIN beforehands.)
; Input: –
; Output: A = Byte read.
; Used registers: A, X, Y.
LFFE4_GETIN:  jmp     (RAMVEC_GETIN)                  ; FFE4 6C 2A 03                 l*.
; ----------------------------------------------------------------------------
LFFE7_CLALL:  jmp     (RAMVEC_CLALL)                  ; FFE7 6C 2C 03                 l,.
; ----------------------------------------------------------------------------
; ??Might be UDTIM. Update Time of Day, at memory address $0390-$0392, and
; Stop key indicator
UDTIM:  jmp     UDTIM_                          ; FFEA 4C F2 FD                 L..
; ----------------------------------------------------------------------------
; SCREEN. Fetch number of screen rows and columns.
SCREEN: jmp     SCREEN_                         ; FFED 4C FC FD                 L..
; ----------------------------------------------------------------------------
; PLOT. Save or restore cursor position.
; Input: Carry: 0 = Restore from input, 1 = Save to output; X = Cursor column
; (if Carry = 0); Y = Cursor row (if Carry = 0).
; Output: X = Cursor column (if Carry = 1); Y = Cursor row (if Carry = 1).
; Used registers: X, Y.
PLOT:   jmp     PLOT_                           ; FFF0 4C 01 FE                 L..
; ----------------------------------------------------------------------------
; IOBASE. Fetch VIA #1 base address.
; Input: -
; Output: X/Y = VIA #1 base address .
; Used registers: X, Y.
IOBASE: jmp     IOBASE_                         ; FFF3 4C 0C FE                 L..
; ----------------------------------------------------------------------------
; Four unused bytes, this is the same as with C64.
        .byte   $FF                             ; FFF6 FF                       .
        .byte   $FF                             ; FFF7 FF                       .
        .byte   $FF                             ; FFF8 FF                       .
        .byte   $FF                             ; FFF9 FF                       .
NMI_VECTOR:
; The 65xx hardware vectors (NMI, RESET, IRQ).
        .addr   NMI                             ; FFFA 66 FA                    f.
RES_VECTOR:
; This is the RESET vector.
        .addr   RESET                           ; FFFC 07 FA                    ..
IRQ_VECTOR:
        .addr   IRQ                             ; FFFE 0E FA                    ..
