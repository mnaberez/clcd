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
; 0C000-0F7FF   14K     Banked  0C000-0F7FF     APPL Window 4   3C000-3F7FF     Offset 4/5     Configured via MMU
; 08000-0BFFF   16K     Banked  08000-0BFFF     APPL Window 3   38000-3BFFF     Offset 3       Configured via MMU
; 04000-07FFF   16K     Banked  04000-07FFF     APPL Window 2   KERN Window     Offset 2       Configured via MMU
; 01000-03FFF   12K     Banked  01000-03FFF     APPL Window 1   01000-03FFF     Offset 1       Configured via MMU
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
;                       FF00    KERN Window offset      (write only)    * Sets a pointer to any 1K boundary in the extended address range.
;                       FE80    APPL Window 4 offset    (write only)      The top 8 bits (A10-A17) of the extended address are written to
;                       FE00    APPL Window 3 offset    (write only)      any of these offset registers.
;                       FD80    APPL Window 2 offset    (write only)
;                       FD00    APPL Window 1 offset    (write only)

;                       FC80    Select TEST mode        (dummy write)   * Any write to these registers triggers the selected mode
;                       FC00    Save current mode       (dummy write)     (see above) or does a Save or Recall operation.
;                       FB80    Recall saved mode       (dummy write)
;                       FB00    Select RAM mode         (dummy write)
;                       FA80    Select APPL mode        (dummy write)
;                       FA00    Select KERN mode        (dummy write)

; 0F800-0F9FF   I/O     IO Chips and Expansion via rear connector
;                       F980    I/O#4   ACIA            RS-232, Modem
;                       F900    I/O#3                   External Expansion
;                       F880    I/O#2   VIA#2           Centronics, RTC, RS-232, Modem, Beeper, Barcode Reader
;                       F800    I/O#1   VIA#1           Keyboard, Battery Level, Alarm, RTC Enable, Power, IEC

; ----------------------------------------------------------------------------

        .setcpu "65C02"

        .org $8000

; ----------------------------------------------------------------------------
;Zero page locations used by the floating point math package (see
;MATH_DISPATCH).  They have the names of the same things in other CBM BASICs.
INTEGR          := $0000  ;2 bytes: low byte of the result of INT; scratch for the AND, OR and XOR operators
VALTYP          := $0002  ;Set to 0 (number) by GIVAYF
TANSGN          := $0004  ;Sign flag used by SIN and TAN
LINNUM          := $0006  ;2 bytes: unsigned integer result of GETADR
INDEX1          := $0008  ;2 bytes: pointer to a number or a string in memory
INDEX2          := $000A  ;2 bytes: pointer used by FCOMP and STRVAL
RESHO           := $000C  ;7 bytes: product or quotient being built by FMULTT and FDIVT
OLDOV           := $0014  ;Saved FACOV
TEMPF1          := $0015  ;8 bytes: temporary number
TEMPF2          := $001D  ;8 bytes: temporary number.  The last 4 bytes are also the 4 locations below.
DECCNT          := $0021  ;FIN: number of digits after the decimal point.  FOUT: decimal exponent.
TENEXP          := $0022  ;FIN, FOUT: exponent
DPTFLG          := $0023  ;FIN: bit 7 set = a decimal point has been seen
EXPSGN          := $0024  ;FIN: bit 7 set = the exponent is negative
FACEXP          := $0025  ;\ FAC, the floating point accumulator: exponent ($81 = 2^0; 0 = the number is zero)
FACHO           := $0026  ;   7 bytes of mantissa, most significant first; bit 7 of the first is always set
FACLO           := $002C  ;   last byte of mantissa
FACSGN          := $002D  ;/  sign in bit 7
SGNFLG          := $002E  ;FIN: bit 7 set = number is negative.  POLY: number of terms left to do.
BITS            := $002F  ;Byte that SHIFTR shifts into the top of a mantissa
ARGEXP          := $0030  ;\ ARG, the second operand, laid out like FAC: exponent
ARGHO           := $0031  ;   7 bytes of mantissa
ARGLO           := $0037  ;   last byte of mantissa
ARGSGN          := $0038  ;/  sign in bit 7
ARISGN          := $0039  ;Bit 7 set = the signs of FAC and ARG are different
FACOV           := $003A  ;Extra low byte of FAC's mantissa, used for rounding
FBUFPT          := $003B  ;2 bytes: FOUT's index into FBUFFR; POLY's pointer to coefficients; TXTPTR saved by STRVAL
FOUT_TMP        := $003D  ;FOUT: saved index into FOUTBL
TXTPTR          := $003F  ;2 bytes: pointer to the text being read by FIN (in RAM)
TEMPF3          := $0041  ;8 bytes: temporary number
ANDOR_MASK      := $0049  ;$00 for AND or $FF for OR (see ANDOP)
MEM_0081        := $0081
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
MEM_00AA        := $00AA  ;Screen editor or maybe keyboard related
MEM_00AB        := $00AB  ;Keyboard scan related
MEM_00AC        := $00AC  ;Keyboard scan related
MODKEY          := $00AD  ;"Modifier" key byte read directly from keyboard shift register
FNADR           := $00AE
EAL             := $00B2
EAH             := $00B3
MEMUSS          := $00B4  ;2 bytes: load address given to LOAD in X/Y, used when the secondary address is 0
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
T0              := $00C7  ;2 bytes
T1              := $00C9  ;2 bytes
T2              := $00CB  ;2 bytes
CHRPTR          := $00CD
BUFEND          := $00CE
LENGTH          := $00CF
WRAP            := $00D0
TMPC            := $00D1
MSAL            := $00D2
MAPPED_PAGE     := $00D9  ;2 bytes: number of the 256-byte RAM page selected by MAP_RAM_PAGE (also a scratch pointer)
V1541_TMP       := $00E0  ;2 bytes: scratch pointer and counter for the Virtual 1541
V1541_FNADR     := $00E2  ;2 bytes
MAPPED_PAGE_PTR := $00E4  ;2 bytes: pointer to the RAM page selected by MAP_RAM_PAGE, as seen in the KERN window
V1541_ACTIV_CHAN := $00E6   ;Number of the channel whose state is in the 4 bytes below
V1541_ACTIV_FLAGS := $00E7              ;\ State of the active channel: flags ($10 = open for reading, $20 = open for writing, $40 = PRG, $80 = special entry; 0 = closed)
V1541_ACTIV_ID    := $00E8  ;   id of the file (0=directory)
V1541_ACTIV_SEQ    := $00E9 ;   sequence number of the current block
V1541_ACTIV_OFFS    := $00EA ;/  offset in that block of the last byte read or written (0=none yet)
BLNCT             := $00EF  ;Counter for cursor blink
CHAR_UNDER_CURSOR := $00F0  ;Character under the cursor; used with blinking
MEM_00F4          := $00F4  ;Keyboard scan related
MEM_00F5          := $00F5  ;Keyboard scan related
stack             := $0100
FBUFFR            := $0100 ;FOUT builds its string at the bottom of the stack page
ROM_ENV_A         := $0204
ROM_ENV_X         := $0205
ROM_ENV_Y         := $0206
V1541_LAST_FILE_ID := $0207 ;Same location as SAVED_SP: file id most recently assigned by V1541_NEW_FILE_ID
RAM_PAGES         := $0208 ;2 bytes: size of RAM in 256-byte pages, as measured by KL_RAMTAS
V1541_BOTTOM_PAGE := $020A ;2 bytes: lowest RAM page used by the Virtual 1541, which grows down from the top of RAM
MEMTOP_PAGE       := $020C ;2 bytes: RAM page that holds the top of application memory
V1541_BLOCK_ID    := $020E ;File id from the header of the block at MAPPED_PAGE_PTR
V1541_BLOCK_SEQ   := $020F ;Sequence number from the header of the block at MAPPED_PAGE_PTR
V1541_ERR_CODE    := $0210 ;CBM DOS error number for the status message read from channel 15
V1541_ERR_TRACK   := $0211 ;"Track" number for the status message
V1541_ERR_SECTOR  := $0212 ;"Sector" number for the status message
V1541_DIR_CHKSUM  := $0213 ;3 bytes: checksum of the blocks of the directory
MAPPED_PAGE_OFFS  := $0216 ;KERN window offset that maps the page at MAPPED_PAGE_PTR
V1541_ERR_POS     := $0217 ;Position of the next character of the status message to be read
V1541_DATA_BUF    := $0218 ;32 bytes: directory entry, or a line of the directory listing
V1541_DIR_PATTERN := $0238 ;20 bytes: filename pattern for the directory listing, followed by a 0 if shorter
V1541_DIR_TYPE    := $024C ;File type given with the directory listing pattern (stored but never tested)
V1541_CHAN_BUF    := $024D ;72 bytes: 4 bytes of state for each of the 18 channels (see V1541_SELECT_CHANNEL_A)
V1541_CMD_BUF     := $0295 ;64 bytes: command sent to the command channel; bitmap of file ids during validate
V1541_CMD_LEN     := $02D5 ;Number of characters in V1541_CMD_BUF
V1541_DIR_STATE      := $02D6 ;Directory listing: part to produce next (0, 2, 4, 6, 8; see V1541_READ_DIR_BYTE)
V1541_DIR_LINE_POS      := $02D7 ;Directory listing: 1 + index in V1541_DATA_BUF of the next byte to return (0=line finished)
V1541_DIR_LINE_OK := $02D8 ;Directory listing: $FF if V1541_DATA_BUF still holds the line being returned, 0 if not
V1541_VARS_CHKSUM := $02D9 ;2 bytes: sum of $0208-02D9 made at power off; never verified
LAT             := $02DB
SAT             := $02F3
FAT             := $02E7
MEM_0300        := $0300
IERROR          := $0300   ;Error vector of the math package, called in APPL mode with a BASIC error number in X.  Applications must set it.
RAMVEC_IRQ      := $0314   ;KERNAL RAM vectors, 36 bytes: $0314-0337
RAMVEC_BRK      := $0316
RAMVEC_TIMER    := $0318   ;Called at the end of every 60 Hz timer interrupt.  (This is the NMI vector on other CBM machines.)
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
RAMVEC_MEM_0334 := $0334
RAMVEC_MEM_0336 := $0336
GO_RAM_LOAD_GO_APPL       := $0338  ;
GO_RAM_STORE_GO_APPL      := $0341  ; RAM-resident code loaded from:
GO_RAM_LOAD_GO_KERN       := $034A  ; MMU_HELPER_ROUTINES
GO_NOWHERE_LOAD_GO_KERN   := $034D  ;
SINNER                    := $034E  ; "SINNER" name is from TED-series KERNAL,
GO_APPL_LOAD_GO_KERN      := $0353  ; where similar RAM-resident code is
GO_RAM_STORE_GO_KERN      := $035C  ; modified at runtime.
GO_NOWHERE_STORE_GO_KERN  := $035F  ;
GO_APPL_LOAD_GO_KERN_ZP   := $0357  ;ZP address of the pointer that GO_APPL_LOAD_GO_KERN loads through
GO_RAM_STORE_GO_KERN_ZP   := $0360  ;ZP address of the pointer that GO_RAM_STORE_GO_KERN stores through
MEM_0365        := $0365  ;Keyboard related
MEM_0366        := $0366  ;Keyboard related
MEM_0367        := $0367  ;Keyboard related
LSTCHR          := $036E  ;Last char typed; used to test for ESC sequence
REVERSE         := $036C  ;0=Reverse Off, 0x80=Reverse On
BLNOFF          := $036F  ;0=Cursor Blink On, 0x80=Cursor Blink Off
TABMAP          := $0370
SETUP_LCD_A     := $037A
SETUP_LCD_X     := $037B
SETUP_LCD_Y     := $037C
CurMaxY         := $037E
MEM_0380        := $0380
CurMaxX         := $0381
MSGFLG          := $0383
DFLTN           := $0385
DFLTO           := $0386
FNLEN           := $0387
MEM_038E        := $038E  ;Keyboard related
JIFFIES         := $038F
TOD_SECS        := $0390
TOD_MINS        := $0391
TOD_HOURS       := $0392
ALARM_SECS      := $0393
ALARM_MINS      := $0394
ALARM_HOURS     := $0395
UNKNOWN_SECS    := $0396
UNKNOWN_MINS    := $0397
MemTopLoByte    := $0398
MemTopHiByte    := $0399
MemBotLoByte    := $039A
MemBotHiByte    := $039B
V1541_BYTE_TO_WRITE := $039E
V1541_FNLEN     := $039F
BAD             := $03A0
V1541_NAME_PREFIX := $03A0 ;Virtual 1541 filename parser: '$' or '@' if the name started with one, else 0
MON_MMU_MODE    := $03A1  ;0=MMU_MODE_RAM, 1=MMU_MODE_APPL, 2=MMU_MODE_KERN
V1541_NAME_START := $03A1 ;Virtual 1541 filename parser: index of the first character of the name itself
V1541_NAME_END  := $03A2  ;Virtual 1541 filename parser: index just past the last character of the name
V1541_FILE_MODE := $03A3  ;Virtual 1541 filename parser: mode given after a comma (R, W, A, M) or 0
V1541_FILE_TYPE := $03A4  ;Virtual 1541 filename parser: file type given after a comma (S, P) or 0
V1541_NAME_FLAGS := $03A5 ;Virtual 1541 filename parser: result flags (see V1541_PARSE_NAME)
V1541_SAVED_SEQ := $03A6  ;Block sequence number saved by V1541_DIR_READ_ENTRY (see V1541_SWAP_POSITION)
V1541_SAVED_OFFS := $03A7 ;Offset in block saved by V1541_DIR_READ_ENTRY (see V1541_SWAP_POSITION)
RNDX        := $03AC
SXREG           := $039D
V1541_EOF       := $039D  ;Same location as SXREG: bit 7 set = the byte just read was the last byte of the file
FORMAT          := $03B4
MEM_03B7        := $03B7
MEM_03C0        := $03C0
RAMVEC_BACKUP   := $03C3  ;Backs up KERNAL RAM vectors, 36 bytes: $03C3-$03E6
LSTP            := $03E8
LSXP            := $03E9
SavedCursorX    := $03EA
SavedCursorY    := $03EB
KEYD            := $03EC
MEM_03F6        := $03F6  ;Keyboard related
MEM_03F7        := $03F7  ;Keyboard related
MEM_03F8        := $03F8  ;Keyboard related
MEM_03F9        := $03F9  ;Keyboard related
MEM_03FA        := $03FA  ;Possibly Virtual 1541 or Keyboard related
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
RTC_DATA        := $0412  ;8 bytes (see RTC_ constants below)
HULP            := $0450
LINE_INPUT_BUF  := $0470  ;Buffer used for a line of input in the monitor and menu
MEM_04C0        := $04C0

;VIA #1 Registers
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

;VIA #2 Registers
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

;ACIA Registers
ACIA_DATA     := $F980
ACIA_ST       := $F981
ACIA_CMD      := $F982
ACIA_CTRL     := $F983

;MMU Registers
MMU_MODE_KERN    := $FA00   ;Any write here switches to the "KERN" MMU mode.
MMU_MODE_APPL    := $FA80   ;Any write here switches to the "APPL" MMU mode.
MMU_MODE_RAM     := $FB00   ;Any write here switches to the "RAM" MMU mode.
MMU_RECALL_MODE  := $FB80   ;Any write here recalls the previously saved mode.
MMU_SAVE_MODE    := $FC00   ;Any write here saves the current mode so it can be recalled.
MMU_MODE_TEST    := $FC80   ;Any write here switches to the "TEST" MMU mode. (Unused)
MMU_OFFS_APPL_W1 := $FD00   ;Sets offset for $1000-3FFF "APPL Window 1" in the "APPL" MMU mode.
MMU_OFFS_APPL_W2 := $FD80   ;Sets offset for $4000-7FFF "APPL Window 2" in the "APPL" MMU mode.
MMU_OFFS_APPL_W3 := $FE00   ;Sets offset for $8000-BFFF "APPL Window 3" in the "APPL" MMU mode.
MMU_OFFS_APPL_W4 := $FE80   ;Sets offset for $C000-F7FF "APPL Window 4" in the "APPL" MMU mode.
MMU_OFFS_KERN_W  := $FF00   ;Sets offset for $4000-7FFF "KERN Window" in the "KERN" MMU mode.

;LCD Controller Registers $FF80-$FF83
LCDCTRL_REG0 := $FF80
LCDCTRL_REG1 := $FF81
LCDCTRL_REG2 := $FF82
LCDCTRL_REG3 := $FF83

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
doserr_00_ok              = $00 ;00 ok
doserr_01_files_scratched = $01 ;01 files scratched (not an error)
doserr_20_read_err        = $14 ;20 read error (block header not found)
doserr_25_write_err       = $19 ;25 write error (write-verify error)
doserr_26_write_prot_on   = $1a ;26 write protect on
doserr_27_read_error      = $1b ;27 read error (checksum error in header)
doserr_31_invalid_cmd     = $1f ;31 invalid command
doserr_32_syntax_err      = $20 ;32 syntax error (long line)
doserr_33_syntax_err      = $21 ;33 syntax error (invalid filename)
doserr_34_syntax_err      = $22 ;34 syntax error (no file given)
doserr_39_syntax_err      = $27 ;39 syntax error (never reported by the Virtual 1541)
doserr_52_file_too_large  = $34 ;52 file too large
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

doschan_14_cmd_app   = $0e ;14 command file: a file of keystrokes read by GET_KEY_NONBLOCKING (see ROM_ENTRY_COMMAND)
doschan_15_command   = $0f ;15 normal cbm dos command channel
doschan_16_directory = $10 ;16 directory channel
doschan_17_load   = $11    ;17 internal channel used by LOAD

;Virtual 1541 file types and modes
ftype_p_prg     = 'P'   ;Program
ftype_s_seq     = 'S'   ;Sequential
fmode_r_read    = 'R'   ;Read
fmode_w_write   = 'W'   ;Write
fmode_a_append  = 'A'   ;Append
fmode_m_modify  = 'M'   ;Modify

;RTC_DATA offsets
RTC_HOURS = 0
RTC_MINUTES = 1
RTC_SECONDS = 2
RTC_24H_AMPM = 3
RTC_DOW = 4
RTC_DAY = 5
RTC_MONTH = 6
RTC_YEAR = 7

; ----------------------------------------------------------------------------
ROM_HEADER:
;Every ROM starts with an 8-byte header followed by the magic string
        .byte   $00 ;unknown
        .byte   $00 ;unknown
        .byte   $FF ;unknown
        .byte   $FF ;unknown
        .byte   16  ;number of kilobytes to be checked by RomCheckSum
        .byte   $DD ;unknown
        .byte   $DD ;unknown
        .byte   $DD ;unknown

ROM_MAGIC:
;SCAN_ROMS routine looks for this magic string
        .byte   "Commodore LCD"
ROM_MAGIC_SIZE = * - ROM_MAGIC

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
L8074:  stx     MEM_03C0
L8077:  dec     MEM_03C0
        ldx     MEM_03C0
        bpl     L8082
        sec
        bra     L80BB
L8082:  lda     ROM_ENV_A
        and     PowersOfTwo,x
        beq     L8077
        lda     ROM_START_KERN_W_OFFSETS,x
        sta     MMU_OFFS_KERN_W
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
        bne     L813A_SKIP_DRAW_AND_WAIT
        cmp     $03BF
        beq     L813A_SKIP_DRAW_AND_WAIT

        jsr     L815E_DRAW_FKEY_BAR
        bra     L8118_WAIT_FOR_FKEY_OR_RETURN_LOOP

L813A_SKIP_DRAW_AND_WAIT:
        clc
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
        lda     #$67 ;TODO graphics character
        ldy     #$09
        sta     ($BD),y
        rts

L81F3_FKEY_COLUMNS:
        ;      F1,F2,F3,F4,F5,F6,F7,F8
        .byte   0,10,20,30,40,50,60,70  ;Starting column on bottom screen line
; ----------------------------------------------------------------------------
L81FB:  stz     HULP
        jsr     L806B
        beq     L821C
        phx
        pha
        phy
        ldx     #$00
        ldy     #$06
L820A:  lda     ($DB),y
        sta     HULP,x
        inx
        iny
        tya
        cmp     ($DB)
        bne     L820A
        stz     HULP,x
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
        ldx     MEM_03C0
        lda     ROM_START_KERN_W_OFFSETS,x
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
        stz     MMU_OFFS_APPL_W1
        stz     MMU_OFFS_APPL_W2
        stz     MMU_OFFS_APPL_W3
        cmp     #$C0
        bcs     L82AE_APPL_W4
        cmp     #$80
        bcs     L82AB_APPL_W3
        cmp     #$40
        bcs     L82A8_APPL_W2
        stx     MMU_OFFS_APPL_W1
L82A8_APPL_W2:
        stx     MMU_OFFS_APPL_W2
L82AB_APPL_W3:
        stx     MMU_OFFS_APPL_W3
L82AE_APPL_W4:
        stx     MMU_OFFS_APPL_W4
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
        jsr     SCAN_ROMS
        sta     ROM_ENV_A
        stx     ROM_ENV_X
        sty     ROM_ENV_Y
        rts
; ----------------------------------------------------------------------------
ROM_START_KERN_W_OFFSETS:
;SCAN_ROMS uses this table to write offsets to MMU_OFFS_KERN_W ($FF00)
;to check for ROMs.  There are 8 offsets in the table, each corresponding
;to a 16K area.  SCAN_ROMS looks for a header (see the ROM_HEADER area)
;at the start of each 16K area.
;
;Although eight areas of 16K are scanned, the EPROMs found in Bil Herd's
;prototype are 32K each.  So, the two 16K halves of each 32K EPROM are scanned.
;The code in the EPROMs really is 32K, though.  Offset 0 in each EPROM contains
;a magic header while offset $4000 is just normal code.
;
;MMU_OFFS_KERN_W = (Physical address - KERN Window base address $4000) >> 10
;
        .byte ($20000-$4000)>>10  ;Physical address $20000 (ss-calc13apr-u105.bin: $0000)
        .byte ($24000-$4000)>>10  ;Physical address $24000 (ss-calc13apr-u105.bin: $4000)
        .byte ($28000-$4000)>>10  ;Physical address $28000 (sept-m-13apr-u104.bin: $0000)
        .byte ($2C000-$4000)>>10  ;Physical address $2C000 (sept-m-13apr-u104.bin: $4000)
        .byte ($30000-$4000)>>10  ;Physical address $30000 (sizapr-u103.bin: $0000)
        .byte ($34000-$4000)>>10  ;Physical address $34000 (sizapr-u103.bin: $4000)
        .byte ($38000-$4000)>>10  ;Physical address $38000 (kizapr-u102.bin: $0000)
        .byte ($3C000-$4000)>>10  ;Physical address $3C000 (kizapr-u102.bin: $4000)

ROM_START_KERN_W_OFFSETS_SIZE = * - ROM_START_KERN_W_OFFSETS
; ----------------------------------------------------------------------------
SCAN_ROMS:
; This routine scans ROMs, searching for the "Commodore LCD" string.
; This is done by using register at $FF00 which seems to tell the memory
; mapping at CPU address $4000.
        lda     #0
        pha
        pha
        pha
        ldy     #ROM_START_KERN_W_OFFSETS_SIZE-1
L82DA:  lda     ROM_START_KERN_W_OFFSETS,y
        sta     MMU_OFFS_KERN_W
        phy
        ldx     #ROM_MAGIC_SIZE-1
L82E3:  lda     ROM_MAGIC-$4000,x
        cmp     ROM_MAGIC,x
        bne     L8315
        dex
        bpl     L82E3
        ply
        phy
        lda     ROM_START_KERN_W_OFFSETS,y
; $4004 is the paged-in ROM, where the id string would be ($FF00 controls
; what can you see from $4000), it's compared with the kernal's image's id
; string ("Commodore LCD").
        ldx     ROM_HEADER-$4000+4
        pha
        jsr     RomCheckSum
        ply
        sty     MMU_OFFS_KERN_W
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
        ora     #'0'          ;convert ROM number to PETSCII
        jsr     KR_ShowChar_  ;print it
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
        sty     MMU_OFFS_KERN_W
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
        jsr     L8420_JSR_L8277_JMP_LFA67       ; 8403 20 20 84                   .
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
L8420_JSR_L8277_JMP_LFA67:
        jsr     L8277                           ; 8420 20 77 82                  w.
        jmp     LFA67                           ; 8423 4C 67 FA                 Lg.
; ----------------------------------------------------------------------------
MON_CMD_EXIT:
L8426:  stz     $0202                           ; 8426 9C 02 02                 ...
        ldx     $0203                           ; 8429 AE 03 02                 ...
        stx     $0200                           ; 842C 8E 00 02                 ...
        stz     $0203                           ; 842F 9C 03 02                 ...
        jsr     L840F                           ; 8432 20 0F 84                  ..
        bcc     L843A                           ; 8435 90 03                    ..
        jmp     L843F                           ; 8437 4C 3F 84                 L?.
; ----------------------------------------------------------------------------
L843A:  ldx     #$0A                            ; 843A A2 0A                    ..
        jsr     L8420_JSR_L8277_JMP_LFA67       ; 843C 20 20 84                   .
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
        beq     L84C3_CLC_RTS                           ; 8463 F0 5E                    .^
        bit     #$12                            ; 8465 89 12                    ..
        beq     L84C3_CLC_RTS                           ; 8467 F0 5A                    .Z
        ldy     $0200                           ; 8469 AC 00 02                 ...
        sty     $0203                           ; 846C 8C 03 02                 ...
        stz     $0200                           ; 846F 9C 00 02                 ...
L8472:  jsr     L840F                           ; 8472 20 0F 84                  ..
        beq     L84C3_CLC_RTS                           ; 8475 F0 4C                    .L
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
L8495:  jsr     L8420_JSR_L8277_JMP_LFA67       ; 8495 20 20 84                   .
        jmp     L8426                           ; 8498 4C 26 84                 L&.
; ----------------------------------------------------------------------------
L849B:  stx     $0202
        php
        sei
        jsr     SWAP_RAMVEC     ;Swap out the current vectors
        jsr     KL_RESTOR       ;Restore the KERNAL default ones
        ldx     #$08
        jsr     L8420_JSR_L8277_JMP_LFA67
        sei
        jsr     SWAP_RAMVEC     ;Swap the other vectors back in
        stz     $0202
        ldx     $0200
        jsr     L840F
        beq     L84C0_JMP_L8426
        jsr     L8277
        plp
        sec
        rts
; ----------------------------------------------------------------------------
L84C0_JMP_L8426:
        jmp     L8426
; ----------------------------------------------------------------------------
L84C3_CLC_RTS:
        clc
        rts
; ----------------------------------------------------------------------------
L84C5:  php
        sei
        ldx     $0202
        beq     L84DA
        jsr     SWAP_RAMVEC
        jsr     L84ED
        jsr     SWAP_RAMVEC
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
        jmp     L8420_JSR_L8277_JMP_LFA67
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
        jsr     V1541_PREPARE_FOR_POWER_OFF
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
        jsr     V1541_CHECK_DISK_INTACT
        bcs     L8582_COULD_NOT_RESTORE_STATE ;Branch if not intact
        jsr     SCAN_ROMS
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
L85C0:  jsr     V1541_CHECK_DISK_INTACT
        bcc     L85E2 ;branch if intact
        jsr     PRIMM
        .byte   "YOUR DISK IS NOT INTACT",$0d,$07,0
; ----------------------------------------------------------------------------
L85E2:  jsr     L82BE_CHECK_ROM_ENV
        beq     L8607 ;branch if no change
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
        jsr     CRLF
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
        jsr     V1541_I_INITIALIZE
        stz     $0384
; Set MEMTOP vector to $0FFF
        ldy     #>$0FFF
        ldx     #<$0FFF
        clc
        jmp     MEMTOP__
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

; Test rest of the RAM, using the KERN Window to page in the testable area.
L86C2:  lda     $D9
        ldx     $DA
        inc     a
        bne     L86CA
        inx
L86CA:  jsr     MAP_RAM_PAGE
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
;Called only from POWER_OFF.  Initializes the Virtual 1541 (the same as its
;"I" command) and checksums its variables.  Nothing ever verifies this
;checksum, but RAM_CHECKSUM, which POWER_OFF calls next, covers the same bytes.
V1541_PREPARE_FOR_POWER_OFF:
        jsr     V1541_I_INITIALIZE
        jsr     V1541_SUM_VARS
        sta     V1541_VARS_CHKSUM
        sty     V1541_VARS_CHKSUM+1
        rts

;Add up the 210 bytes of Virtual 1541 variables at $0208-02D9.
;Returns the sum in A (low) and Y (high), and Z=1 if it is the same as
;V1541_VARS_CHKSUM.  Called only from the routine directly above.
V1541_SUM_VARS:
        cld
        lda     #$00
        tay
        ldx     #$D1
L86FC_LOOP:
        clc
        adc     RAM_PAGES,x
        bcc     L8703
        iny
L8703:  dex
        bpl     L86FC_LOOP
        cmp     V1541_VARS_CHKSUM
        bne     L870E
        cpy     V1541_VARS_CHKSUM+1
L870E:  rts
; ----------------------------------------------------------------------------
;Check that the Virtual 1541's disk is still good.
;
;Returns:     Carry clear = intact
;             Carry set = not intact: its checksum is wrong, or its bounds do
;                         not make sense for the RAM that is present
V1541_CHECK_DISK_INTACT:
        jsr     V1541_VERIFY_DIR_CHECKSUM
        bcc     L8745_NOT_INTACT        ;Branch if the checksum is wrong
        lda     V1541_BOTTOM_PAGE
        ldx     V1541_BOTTOM_PAGE+1
        bne     L8720_BOTTOM_OK
        cmp     #$10
        bcc     L8745_NOT_INTACT        ;Branch if the disk starts inside the system RAM (below page $10)
L8720_BOTTOM_OK:
        jsr     KL_RAMTAS               ;A/X = number of RAM pages present now
        cmp     RAM_PAGES
        bne     L8745_NOT_INTACT        ;Branch if the amount of RAM has changed
        cpx     RAM_PAGES+1
        bne     L8745_NOT_INTACT
        cpx     V1541_BOTTOM_PAGE+1
        bcc     L8745_NOT_INTACT        ;Branch if the disk starts above the top of RAM
        bne     L8739_CHECK_MAX
        cmp     V1541_BOTTOM_PAGE
        bcc     L8745_NOT_INTACT
L8739_CHECK_MAX:
        cpx     #$02                    ;There can't be more than 128K ($0200 pages)
        bcc     L8743_INTACT
        bne     L8745_NOT_INTACT
        cmp     #$00
        bne     L8745_NOT_INTACT
L8743_INTACT:
        clc
        rts
; ----------------------------------------------------------------------------
L8745_NOT_INTACT:
        sec
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
                            ;PCR6=0  CB2 Control = Pulse Output (not in effect: the shift register uses CB2 for the keyboard data)
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
        lda     #%10101111
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
        stz     MEM_0300,x
        stz     $0400,x
        inx
        bne     L87CA
        jsr     L8685
        cli
        jsr     PRIMM
        .byte   "ESTABLISHING SYSTEM PARAMETERS ",$07,$0D,0
        jsr     L82BE_CHECK_ROM_ENV
        lda     #$0F
        sta     $020C
        jsr     KL_RAMTAS
        sta     $0208
        stx     $0209
        sta     $020A
        stx     $020B
        stx     $00
        lsr     $00
        ror     a
        lsr     $00
        ror     a
        jsr     PRINT_BCD_NIBS ;Print the "128" in "128 KBYTE SYSTEM ESTABLISHED"
        jsr     V1541_CHECKSUM_DIR
        jsr PRIMM
        .byte   " KBYTE SYSTEM ESTABLISHED",$0d,0
        jsr     LD411
        jsr     L8644_CHECK_BUTTON
        jmp     L843F
; ----------------------------------------------------------------------------
;Print BCD nibbles in YXA in PETSCII
;Y=$00, X=$03, A=$02 -> Prints "32"
;Y=$00, X=$06, A=$04 -> Prints "64"
;Y=$01, X=$02, A=$08 -> Prints "128"
PRINT_BCD_NIBS:
        jsr     BIN_TO_BCD_NIBS
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
L8865:  ora     #'0'
        jmp     KR_ShowChar_
; ----------------------------------------------------------------------------
;Convert binary number A to BCD nibbles in YXA:
;A=0   -> Y=$00, X=$00, A=$00
;A=32  -> Y=$00, X=$03, A=$02
;A=64  -> Y=$00, X=$06, A=$04
;A=128 -> Y=$01, X=$02, A=$08
;A=255 -> Y=$02, X=$05, A=$05
BIN_TO_BCD_NIBS:
        ldy     #$FF
        cld
        sec
L886E:  iny
        sbc     #100
        bcs     L886E
        adc     #100
        ldx     #$FF
L8877:  inx
        sbc     #10
        bcs     L8877
        adc     #10
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
L88C2:  ldx     #<MEM_04C0
        ldy     #>MEM_04C0
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
L88E5:  jsr     MAP_RAM_PAGE
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
; Virtual 1541 (RAM disk), device 1
;
; The disk is made of 256-byte blocks at the top of RAM.  It starts at page
; V1541_BOTTOM_PAGE and ends at the top of RAM (page RAM_PAGES).  It grows
; down, one page at a time, toward the top of application memory
; (MEMTOP_PAGE), and it shrinks again when blocks are deleted.  The blocks are
; in no particular order.  A new block is always added at the bottom.  A block
; is deleted by swapping it with the bottom block and then moving the bottom
; up.  To find a block, the whole disk is searched (V1541_FIND_BLOCK).
;
; Each block starts with a 3-byte header:
;   +0  File id.  The directory is file 0.  Other files are 1-255.
;   +1  Sequence number of this block within its file, counting from 0
;   +2  Offset in this block of the last byte in use (3-255), or 0 if the
;       block is full and another block follows it.  2 = no data yet.
;   +3  253 bytes of data
;
; The directory (file 0) is a list of entries:
;   +0  Flags:  $80 = special entry (see below)
;               $40 = PRG file (otherwise SEQ)
;               $20 = file is open for writing (shown as a "*" splat file)
;               $10 = never set by the KERNAL but treated like $20
;   +1  File id
;   +2  24-bit checksum of all the blocks of the file, low byte first
;   +5  Filename of up to 16 characters, followed by a 0
;
; Nothing in the KERNAL creates an entry with flag $80, but they are allowed
; for: such an entry owns no blocks, bytes 1-4 are copied to the channel as
; they are, it can't be read or written through a channel, it can't be
; replaced or appended to ("WRITE PROTECT"), and byte 3 is shown as its size
; in a directory listing.
;
; There are 18 channels.  Each has 4 bytes of state (see V1541_ACTIV_FLAGS).
; The state of the selected channel is kept in the zero page.  The state of
; the others is in V1541_CHAN_BUF.
;   0-13  Ordinary files, selected by the low 4 bits of the secondary address
;   14    Command file: a file of keystrokes read by GET_KEY_NONBLOCKING
;   15    Command channel
;   16    Used internally to read and write the directory
;   17    Used internally by LOAD
;
; The internal routines return carry set for success.  On failure they
; return carry clear and a CBM DOS error number in A.
; ----------------------------------------------------------------------------
;Make the disk one page bigger, if there is space.
;Returns carry set and MAPPED_PAGE_PTR pointing to the new bottom page, or
;carry clear and A=25 if there is no space.
; ----------------------------------------------------------------------------
V1541_GROW:
        jsr     V1541_CHECK_SPACE
        bcs     V1541_GROW_NO_CHECK ;branch if no error
        rts
;Make the disk one page bigger without checking that there is space.
; ----------------------------------------------------------------------------
V1541_GROW_NO_CHECK:
        lda     V1541_BOTTOM_PAGE
        bne     L89BD_NO_BORROW
        dec     V1541_BOTTOM_PAGE+1
L89BD_NO_BORROW:
        dec     V1541_BOTTOM_PAGE
        jsr     UPDATE_FREE_PAGES       ;Recalculate FREE_PAGES
        jmp     V1541_FIRST_BLOCK       ;Select the new bottom page
; ----------------------------------------------------------------------------
;Add a new, empty block for the file and sequence number of the active channel.
V1541_NEW_BLOCK:
        jsr     V1541_GROW
        bcc     L89E1_RTS               ;Branch if there is no space
        lda     V1541_ACTIV_ID
        sta     V1541_BLOCK_ID
        sta     (MAPPED_PAGE_PTR)       ;Header byte 0 = file id
        lda     V1541_ACTIV_SEQ
        sta     V1541_BLOCK_SEQ
        ldy     #$01
        sta     (MAPPED_PAGE_PTR),y     ;Header byte 1 = sequence number
        iny
        lda     #$02
        sta     (MAPPED_PAGE_PTR),y     ;Header byte 2 = offset of last byte in use (none yet)
        sec
L89E1_RTS:
        rts
; ----------------------------------------------------------------------------
;Delete every block of the file whose id is in V1541_DATA_BUF+1.
V1541_DELETE_FILE_BLOCKS:
        jsr     V1541_FIRST_BLOCK       ;Start (again) with the bottom block
L89E5_LOOP:
        lda     V1541_BLOCK_ID
        cmp     V1541_DATA_BUF+1
        bne     L89F2_NEXT
        jsr     V1541_DELETE_BLOCK      ;Delete this block; the bottom block takes its place
        bra     V1541_DELETE_FILE_BLOCKS
L89F2_NEXT:
        jsr     V1541_NEXT_BLOCK
        bcs     L89E5_LOOP              ;Loop until the top of the disk
        sec
        rts
; ----------------------------------------------------------------------------
;Find the block of the active channel (V1541_ACTIV_ID, V1541_ACTIV_SEQ)
;and delete it.  Returns carry clear if it does not exist.
V1541_FIND_AND_DELETE_BLOCK:
        jsr     V1541_FIND_BLOCK
        bcs     V1541_DELETE_BLOCK ;branch if no error
        rts
; ----------------------------------------------------------------------------
;Delete the block at MAPPED_PAGE_PTR: swap its contents with the bottom
;block, then make the disk one page smaller.  The deleted block's data is
;left in the page that is given up.
V1541_DELETE_BLOCK:
        lda     MAPPED_PAGE_OFFS
        pha                             ;Push KERN window offset of the block being deleted
        lda     MAPPED_PAGE_PTR+1
        pha                             ;Push high byte of its address in the KERN window
        jsr     V1541_FIRST_BLOCK       ;Select the bottom block
        stz     MAPPED_PAGE             ;MAPPED_PAGE is also used as a pointer to the block being deleted
        pla
        sta     MAPPED_PAGE+1
        ldy     #$00
L8A10_SWAP_LOOP:
        lda     (MAPPED_PAGE_PTR),y     ;Get a byte of the bottom block
        tax
        pla
        pha
        sta     MMU_OFFS_KERN_W         ;Map the block being deleted
        lda     (MAPPED_PAGE),y
        pha
        txa
        sta     (MAPPED_PAGE),y         ;Bottom block's byte goes into the block being deleted
        lda     MAPPED_PAGE_OFFS
        sta     MMU_OFFS_KERN_W         ;Map the bottom block
        pla
        sta     (MAPPED_PAGE_PTR),y     ;Deleted block's byte goes into the bottom block
        iny
        bne     L8A10_SWAP_LOOP
        pla
        inc     V1541_BOTTOM_PAGE       ;The disk now starts one page higher
        bne     L8A33_NO_CARRY
        inc     V1541_BOTTOM_PAGE+1
L8A33_NO_CARRY:
        jsr     UPDATE_FREE_PAGES       ;Recalculate FREE_PAGES
        jmp     V1541_FIRST_BLOCK       ;Select the new bottom page
; ----------------------------------------------------------------------------
;Check that the disk can grow by one page.
;Returns carry clear and A=25 if the page below the disk is not above the top
;page of application memory.
V1541_CHECK_SPACE:
        ldx     V1541_BOTTOM_PAGE+1
        lda     V1541_BOTTOM_PAGE
        bne     L8A42_NO_BORROW
        dex
L8A42_NO_BORROW:
        dec     a                       ;X/A = page below the bottom of the disk
        cpx     MEMTOP_PAGE+1
        bne     L8A4E_25_WRITE_ERROR    ;Branch unless the high bytes are equal.  Carry is set if the page is above MEMTOP_PAGE (free).
        cmp     MEMTOP_PAGE
        bne     L8A4E_25_WRITE_ERROR
        clc                             ;No space
L8A4E_25_WRITE_ERROR:
        lda     #doserr_25_write_err ;25 write error (write-verify error)
        rts
; ----------------------------------------------------------------------------
;Unused.  Returns the number of blocks on the disk in X (low) and A (high).
        cld
        sec
        lda     RAM_PAGES
        sbc     V1541_BOTTOM_PAGE
        tax
        lda     RAM_PAGES+1
        sbc     V1541_BOTTOM_PAGE+1
        rts
; ----------------------------------------------------------------------------
;Move on to the next block (the page above the current one).
;Returns carry clear if the current block is the last one before the top of RAM.
V1541_NEXT_BLOCK:
        ldx     MAPPED_PAGE+1
        lda     MAPPED_PAGE
        inc     a
        bne     L8A69_NO_CARRY
        inx
L8A69_NO_CARRY:
        cpx     RAM_PAGES+1
        bcc     L8A77_SELECT
        bne     L8A75_NO_MORE
        cmp     RAM_PAGES
        bcc     L8A77_SELECT
L8A75_NO_MORE:
        clc
        rts
; ----------------------------------------------------------------------------
L8A77_SELECT:
        stx     MAPPED_PAGE+1
        sta     MAPPED_PAGE
        inc     MAPPED_PAGE_PTR+1       ;Next page in the KERN window
        bmi     MAP_RAM_PAGE            ;Branch if past the end of the window: map the next 16K
        bra     V1541_REMAP_BLOCK       ;Otherwise just read the header of the block

;Select the bottom page of the disk.
;Returns Z=1 if the disk is empty.
V1541_FIRST_BLOCK:
        ldx     V1541_BOTTOM_PAGE+1

        lda     V1541_BOTTOM_PAGE

;Map a page of RAM into the KERN window.  The whole 16K that contains the
;page is mapped at $4000-7FFF.
;
;Call with:   A/X = page number (low/high); address in the 256K space / 256
;Returns:     MAPPED_PAGE = page number
;             MAPPED_PAGE_PTR = address of the page in the KERN window
;             MAPPED_PAGE_OFFS = KERN window offset that was set
;             V1541_BLOCK_ID, V1541_BLOCK_SEQ = bytes 0 and 1 of the page, or
;                 0 and $FF with Z=1 if the disk is empty
;             Carry set
MAP_RAM_PAGE:
        sta     MAPPED_PAGE
        stx     MAPPED_PAGE+1
        sec
        cld
        sbc     #$40                    ;The KERN window starts at $4000, so subtract $40 pages
        bcs     L8A92_NO_BORROW
        dex
L8A92_NO_BORROW:
        sta     MAPPED_PAGE_PTR+1
        txa
        asl     MAPPED_PAGE_PTR+1
        rol     a
        asl     MAPPED_PAGE_PTR+1
        rol     a                       ;A = number of the 16K (64 pages) holding the page, minus 1
        asl     a
        asl     a
        asl     a
        asl     a                       ;Times 16 = KERN window offset in kilobytes
        sta     MAPPED_PAGE_OFFS
        sec
        ror     MAPPED_PAGE_PTR+1
        lsr     MAPPED_PAGE_PTR+1       ;High byte of pointer = $40 + (page mod 64)
        stz     MAPPED_PAGE_PTR
;Map the page at MAPPED_PAGE_PTR again (something else may have changed the
;KERN window) and read the header of the block in it.
V1541_REMAP_BLOCK:
        lda     MAPPED_PAGE_OFFS
        sta     MMU_OFFS_KERN_W
        ldy     #$01
        lda     (MAPPED_PAGE_PTR)
        tax
        sta     V1541_BLOCK_ID          ;Redundant: it is stored again below
        lda     (MAPPED_PAGE_PTR),y
        tay
        lda     V1541_BOTTOM_PAGE
        eor     RAM_PAGES
        bne     L8ACD_STORE             ;Branch if the disk is not empty
        lda     V1541_BOTTOM_PAGE+1
        eor     RAM_PAGES+1
        bne     L8ACD_STORE
        ldy     #$FF                    ;The disk is empty: pretend the header is file 0, sequence $FF,
        tax                             ;which no search will match.  Z=1.
L8ACD_STORE:
        stx     V1541_BLOCK_ID
        sty     V1541_BLOCK_SEQ
        sec
        rts
; ----------------------------------------------------------------------------
;Find the block of the active channel: the one with file id V1541_ACTIV_ID
;and sequence number V1541_ACTIV_SEQ.  The block at MAPPED_PAGE_PTR is tried
;first, then the whole disk is searched from the bottom up.
;Returns carry set if found, or carry clear and A=20 if not.
V1541_FIND_BLOCK:
        jsr     V1541_REMAP_BLOCK
        jsr     V1541_IS_BLOCK_WANTED
        beq     L8AFA_RTS
        jsr     V1541_FIRST_BLOCK
L8AE0_LOOP:
        jsr     V1541_IS_BLOCK_WANTED
        beq     L8AFA_RTS
        jsr     V1541_NEXT_BLOCK
        bcs     L8AE0_LOOP
        clc
        lda     #doserr_20_read_err ;20 read error (block header not found)
        rts
; ----------------------------------------------------------------------------
;Returns Z=1 (and carry set) if the block at MAPPED_PAGE_PTR is the one that
;the active channel wants.
V1541_IS_BLOCK_WANTED:
        lda     V1541_ACTIV_ID
        cmp     V1541_BLOCK_ID
        bne     L8AFA_RTS
        lda     V1541_ACTIV_SEQ
        cmp     V1541_BLOCK_SEQ
L8AFA_RTS:
        rts
; ----------------------------------------------------------------------------
;Unused.  Maps page A/X (unless it is already selected) and forgets the
;header of the block in it.
        cpx     MAPPED_PAGE+1
        bne     L8B08
        cmp     MAPPED_PAGE
        bne     L8B08
        jsr     V1541_REMAP_BLOCK
        bra     L8B0B
L8B08:  jsr     MAP_RAM_PAGE
L8B0B:  stz     V1541_BLOCK_ID
        stz     V1541_BLOCK_SEQ
        sec
        rts
; ----------------------------------------------------------------------------
;Find a file id that is not in use and put it in V1541_DATA_BUF+1.  The
;search starts with the id most recently assigned and skips 0.
;Returns carry clear and A=72 if all 255 ids are in use.
V1541_NEW_FILE_ID:
        lda     V1541_LAST_FILE_ID
        bne     L8B1D_LOOP
        inc     V1541_LAST_FILE_ID
        bra     V1541_NEW_FILE_ID

L8B1D_LOOP:
        pha
        jsr     V1541_DIR_FIND_ID                                   ;Is there a directory entry with this id?
        pla
        bcs     L8B27_IN_USE            ;Branch if so
        sec                             ;Carry set = this id is free
        bra     L8B31_DONE

L8B27_IN_USE:
        inc     a
        bne     L8B2B_NOT_ZERO
        inc     a
L8B2B_NOT_ZERO:
        cmp     V1541_LAST_FILE_ID
        bne     L8B1D_LOOP              ;Loop until back at the starting id
        clc                             ;Carry clear = no free id
L8B31_DONE:
        sta     V1541_LAST_FILE_ID
        sta     V1541_DATA_BUF+1
        lda     #doserr_72_disk_full ;72 disk full
        rts
; ----------------------------------------------------------------------------
;CHRIN to Virtual 1541
V1541_CHRIN:
        jsr     V1541_INTERNAL_CHRIN
        jmp     V1541_KERNAL_CALL_DONE

V1541_INTERNAL_CHRIN:
        jsr     V1541_SELECT_CHANNEL_GIVEN_SA
        bcs     V1541_READ_BYTE ;branch if no error
        rts
; ----------------------------------------------------------------------------
;Read a byte from the active channel.
;Returns carry set and the byte in A.  V1541_EOF bit 7 is set if that was
;the last byte of the file.
V1541_READ_BYTE:
        lda     V1541_ACTIV_FLAGS
        bit     #$10                    ;Open for reading?
        bne     L8B50_OPEN
        lda     #doserr_61_file_not_open
        clc
        rts
; ----------------------------------------------------------------------------
L8B50_OPEN:
        lda     V1541_ACTIV_CHAN
        cmp     #doschan_15_command ;command channel?
        bne     L8B59_NOT_CMD_CHAN
        jmp     V1541_CHRIN_CMD_CHAN
; ----------------------------------------------------------------------------
L8B59_NOT_CMD_CHAN:
        lda     V1541_ACTIV_FLAGS
        bit     #$80                    ;Special ($80) entry?
        bne     L8BA0_CHRIN_EOF         ;Branch if so: it reads as an empty file
        ;not eof
        lda     V1541_ACTIV_ID
        bne     V1541_READ_FILE_BYTE
        jmp     V1541_READ_DIR_BYTE     ;File 0 is the directory: return a byte of the directory listing
; ----------------------------------------------------------------------------
;Read the next byte of the file of the active channel, with no checks.
V1541_READ_FILE_BYTE:
        stz     V1541_EOF
        lda     V1541_ACTIV_OFFS
        bne     L8B7F_IN_BLOCK          ;Branch if a block is being read
        jsr     V1541_FIND_BLOCK               ;Nothing read yet: find the first block
        bcs     L8B7B_CHRIN_NO_ERROR ;branch if no error
        dec     V1541_EOF               ;The file has no blocks at all: V1541_EOF = $FF
        lda     #$0D      ;carriage return if error or eof
        sec
        rts
; ----------------------------------------------------------------------------
L8B79_NEXT_BLOCK:
        inc     V1541_ACTIV_SEQ
L8B7B_CHRIN_NO_ERROR:
        lda     #$02                    ;Offset 2 = just before the first data byte
        sta     V1541_ACTIV_OFFS
L8B7F_IN_BLOCK:
        jsr     V1541_FIND_BLOCK
        bcc     L8B9F_RTS ;branch if error
        ldy     #$02
        lda     (MAPPED_PAGE_PTR),y     ;A = offset of the last byte in use, or 0 if the block is full
        beq     L8B8E_ADVANCE           ;Branch if full
        cmp     V1541_ACTIV_OFFS
        beq     L8B92_GET               ;Branch if already at the last byte: return it again
L8B8E_ADVANCE:
        inc     V1541_ACTIV_OFFS
        beq     L8B79_NEXT_BLOCK        ;Branch if past the end of the block
L8B92_GET:
        lda     V1541_ACTIV_OFFS
        cmp     (MAPPED_PAGE_PTR),y
        bne     L8B9B_NOT_LAST          ;Branch if this is not the last byte
        ror     V1541_EOF               ;Set bit 7 of V1541_EOF (carry is set by the compare)
L8B9B_NOT_LAST:
        tay
        lda     (MAPPED_PAGE_PTR),y
        sec
L8B9F_RTS:
        rts
; ----------------------------------------------------------------------------
L8BA0_CHRIN_EOF:
        lda     #$0D                    ;Return a carriage return, with V1541_EOF set
        stz     V1541_EOF
        dec     V1541_EOF
        sec
        rts
; ----------------------------------------------------------------------------
;CHROUT to Virtual 1541
V1541_CHROUT:
        jsr     V1541_INTERNAL_CHROUT
        jmp     V1541_KERNAL_CALL_DONE
; ----------------------------------------------------------------------------
V1541_INTERNAL_CHROUT:
        sta     V1541_BYTE_TO_WRITE
        jsr     V1541_SELECT_CHANNEL_GIVEN_SA
        bcs     L8BB9_SELECTED ;branch if no error
        rts

L8BB9_SELECTED:
        lda     V1541_ACTIV_FLAGS
        bit     #$20                    ;Open for writing?
        bne     L8BC3_OPEN
        lda     #doserr_61_file_not_open
L8BC1_CLC_RTS:
        clc
        rts

L8BC3_OPEN:
        bit     #$80
        beq     L8BCB_OK                ;Branch unless it is a special ($80) entry
L8BC7_73_DOS_MISMATCH:
        lda     #doserr_73_dos_mismatch
        bra     L8BC1_CLC_RTS

L8BCB_OK:
        lda     V1541_ACTIV_CHAN
        cmp     #doschan_15_command ;command channel?
        bne     L8BD7_WRITE
        jmp     V1541_CHROUT_CMD_CHAN   ;Never reached: see V1541_CHROUT_CMD_CHAN
; ----------------------------------------------------------------------------
;Write byte A to the file of the active channel, with no checks.
;
;BUG: if there is no space for a new block when a block fills up, the offset
;is left at 0 and the full block is not marked as full.  A later write then
;takes the "first block" path and adds a second block with the same sequence
;number.
;
;BUG: the sequence number is one byte, so a file of more than 256 blocks
;(64,768 bytes) wraps around to sequence 0.
V1541_WRITE_FILE_BYTE:
        sta     V1541_BYTE_TO_WRITE
        ;Fall through

L8BD7_WRITE:
        lda     V1541_ACTIV_OFFS
        bne     L8BE1_ADVANCE           ;Branch if the file already has a block
        jsr     V1541_CHECK_SPACE
        bcs     L8BF7_NEW_BLOCK         ;Branch if there is space for its first block
        rts
; ----------------------------------------------------------------------------
L8BE1_ADVANCE:
        inc     V1541_ACTIV_OFFS
        bne     L8BFE_STORE             ;Branch if there is still space in the current block
        jsr     V1541_CHECK_SPACE
        bcc     L8C0E_RTS ;branch if error
        jsr     V1541_FIND_BLOCK
        bcc     L8C0E_RTS ;branch if error
        ldy     #$02
        lda     #$00                    ;The current block is full: mark it as full with more to follow
        sta     (MAPPED_PAGE_PTR),y
        inc     V1541_ACTIV_SEQ         ;Next sequence number
L8BF7_NEW_BLOCK:
        ldy     #$03
        sty     V1541_ACTIV_OFFS        ;First data byte goes at offset 3
        jsr     V1541_NEW_BLOCK
L8BFE_STORE:
        jsr     V1541_FIND_BLOCK
        ldy     #$02
        lda     V1541_ACTIV_OFFS
        sta     (MAPPED_PAGE_PTR),y     ;Header byte 2 = offset of the last byte in use
        tay
        lda     V1541_BYTE_TO_WRITE
        sta     (MAPPED_PAGE_PTR),y
        sec
L8C0E_RTS:
        rts
; ----------------------------------------------------------------------------
;Overwrite the next byte of the file of the active channel with A.
;Unlike V1541_WRITE_FILE_BYTE, this never adds a block and it does not
;change the length of the file.  Used to close up the directory.
V1541_OVERWRITE_FILE_BYTE:
        pha
        lda     V1541_ACTIV_OFFS
L8C12_ADVANCE:
        inc     a
        bne     L8C17_SKIP_HEADER
        inc     V1541_ACTIV_SEQ         ;Wrapped around: go on to the next block
L8C17_SKIP_HEADER:
        cmp     #$03
        bcc     L8C12_ADVANCE           ;Skip offsets 0-2, the block header
        sta     V1541_ACTIV_OFFS
        jsr     V1541_FIND_BLOCK
        pla
        bcc     L8C27_71_DIR_ERROR ;branch if error
        ldy     V1541_ACTIV_OFFS
        sta     (MAPPED_PAGE_PTR),y
L8C27_71_DIR_ERROR:
        lda     #doserr_71_dir_error ;71 directory error
        rts

; ----------------------------------------------------------------------------
V1541_SELECT_LOAD_CHANNEL_AND_CLEAR_IT:
        jsr     V1541_SELECT_LOAD_CHANNEL
        jmp     V1541_CLEAR_ACTIVE_CHANNEL

V1541_SELECT_DIR_CHANNEL_AND_CLEAR_IT:
        jsr     V1541_SELECT_DIR_CHANNEL
        jmp     V1541_CLEAR_ACTIVE_CHANNEL
; ----------------------------------------------------------------------------

;Select a channel: swap the 4 bytes of state of the old active channel out
;to V1541_CHAN_BUF and those of the new one in.
;Returns carry set if the channel is open, or carry clear and A=70 if not.
V1541_SELECT_CHANNEL_GIVEN_SA:
        ;SA high nib is command, low nib is channel
        lda     SA
        and     #$0F
        .byte   $2C ;skip next 2 bytes

V1541_SELECT_LOAD_CHANNEL:
        lda     #doschan_17_load
        .byte   $2C ;skip next 2 bytes

V1541_SELECT_DIR_CHANNEL:
        lda     #doschan_16_directory

V1541_SELECT_CHANNEL_A:
        cmp     V1541_ACTIV_CHAN
        beq     L8C66_70_NO_CHANNEL

        pha                               ;Save the requested channel number
        lda     V1541_ACTIV_CHAN                  ;Get the current channel number
        jsr     V1541_SWAP_ACTIV_AND_BUF  ;Save the active channel in its slot in all-channels buf

        pla                               ;Get the requested channel number back
        sta     V1541_ACTIV_CHAN                  ;Set it as the active channel number
                                          ;Fall through to get data from all-channels buf into active

;Get buffer index from channel number
V1541_SWAP_ACTIV_AND_BUF:
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
        clc
        ldx     V1541_ACTIV_FLAGS
        beq     L8C6E_RTS
        sec
L8C6E_RTS:
        rts

; ----------------------------------------------------------------------------
;"I" command: close all channels except 14, empty the command buffer and set
;the status to 00,OK,000,000.  Channel 14 is selected first, so its state is
;kept in the zero page while the others are cleared: a command file that is
;being read stays open.
V1541_I_INITIALIZE:
        lda     #doschan_14_cmd_app
        jsr     V1541_SELECT_CHANNEL_A
        ldx     #$47
L8C76_LOOP:
        stz     V1541_CHAN_BUF,X
        dex
        bpl     L8C76_LOOP
        stz     V1541_CMD_LEN           ;Command buffer is empty
        inx     ;A=0
        txa     ;X=0
        tay     ;Y=0
        sec
        jmp     V1541_SET_STATUS
; ----------------------------------------------------------------------------
;Select the channel given by SA, then close it by zeroing its state.
;V1541_CLEAR_ACTIVE_CHANNEL closes the active channel.  Both return carry set.
V1541_SELECT_CHANNEL_AND_CLEAR_IT:
        jsr     V1541_SELECT_CHANNEL_GIVEN_SA

V1541_CLEAR_ACTIVE_CHANNEL:
        ldx     #$03
L8C8B_LOOP:
        stz     V1541_ACTIV_FLAGS,x
        dex
        bpl     L8C8B_LOOP
        sec
        rts
; ----------------------------------------------------------------------------
;Close every channel (0-15) that is reading the directory, because the
;directory is about to change.
V1541_CLOSE_DIR_READERS:
        lda     #$00                    ;File id 0 = the directory
        jsr     V1541_FIND_CHANNEL_WITH_FILE
        bcc     L8C9E_RTS               ;Branch if no more channels have it open
        jsr     V1541_CLEAR_ACTIVE_CHANNEL
        bra     V1541_CLOSE_DIR_READERS

L8C9E_RTS:
        rts
; ----------------------------------------------------------------------------
;Find a channel (15 down to 0) that has file id A open, skipping channels
;with flag $80.  Returns carry set with that channel selected, or carry clear.
V1541_FIND_CHANNEL_WITH_FILE:
        tay
        ldx     #doschan_15_command
L8CA2_LOOP:
        phy
        phx
        txa
        jsr     V1541_SELECT_CHANNEL_A
        plx
        ply
        lda     V1541_ACTIV_FLAGS
        beq     L8CB6_NEXT              ;Branch if this channel is closed
        bit     #$80
        bne     L8CB6_NEXT
        cpy     V1541_ACTIV_ID
        beq     L8CBA_RTS
L8CB6_NEXT:
        dex
        bpl     L8CA2_LOOP
        clc
L8CBA_RTS:
        rts
; ----------------------------------------------------------------------------
;Read the first directory entry into V1541_DATA_BUF.
;Returns the same as V1541_DIR_NEXT.
V1541_DIR_FIRST:
        stz     V1541_ACTIV_SEQ         ;Rewind the active channel to the start...
        stz     V1541_ACTIV_OFFS
        stz     V1541_ACTIV_ID          ;...of file 0, the directory
        bra     V1541_DIR_READ_AND_REWIND
; ----------------------------------------------------------------------------
;Read the next directory entry into V1541_DATA_BUF.
;
;Returns:     Carry set = V1541_DATA_BUF holds the entry, and the active
;                         channel is positioned at the start of that entry
;                         so that V1541_DIR_DELETE_ENTRY can remove it
;             Carry clear = no entry: there are no more (V1541_EOF bit 7 is
;                           set) or there was an error
V1541_DIR_NEXT:
        jsr     V1541_DIR_READ_ENTRY    ;Read the current entry again to get past it
        bcc     V1541_SWAP_POSITION ;branch if error
        clc
        bit     V1541_EOF
        bmi     V1541_SWAP_POSITION     ;Branch if it was the last one

;Read the entry at the position of the active channel, then put the
;channel back at the start of that entry.
V1541_DIR_READ_AND_REWIND:
        jsr     V1541_DIR_READ_ENTRY
;Swap the position of the active channel with the saved position.
V1541_SWAP_POSITION:
        ldx     V1541_ACTIV_OFFS
        ldy     V1541_SAVED_OFFS
        stx     V1541_SAVED_OFFS
        sty     V1541_ACTIV_OFFS
        ldx     V1541_ACTIV_SEQ
        ldy     V1541_SAVED_SEQ
        stx     V1541_SAVED_SEQ
        sty     V1541_ACTIV_SEQ
        rts
; ----------------------------------------------------------------------------
;Read a directory entry from the active channel into V1541_DATA_BUF and
;save the position where it started in V1541_SAVED_OFFS/V1541_SAVED_SEQ.
;An entry is 5 bytes followed by a filename that ends with a 0.
;Returns carry clear on a read error, if the directory ends in the first
;5 bytes, or with A=67 if no 0 is found within 25 bytes.
V1541_DIR_READ_ENTRY:
        ldx     V1541_ACTIV_OFFS
        ldy     V1541_ACTIV_SEQ
        stx     V1541_SAVED_OFFS
        sty     V1541_SAVED_SEQ
        stz     V1541_DIR_LINE_OK       ;V1541_DATA_BUF no longer holds a line of the directory listing
        ldx     #$FF
L8CF5_LOOP:
        inx
        cpx     #$19                    ;More than 25 bytes?
        beq     L8D13_67_ILLEGAL_SYS_TS
        phx
        jsr     V1541_READ_FILE_BYTE
        plx
        bcc     L8D15_CLC_RTS ;branch if error
        sta     V1541_DATA_BUF,x
        cpx     #$05
        bit     V1541_EOF               ;Was that the last byte of the directory?
        bmi     L8D12_RTS               ;Branch if so, with carry set only if more than the 5 fixed bytes were read
        bcc     L8CF5_LOOP              ;Branch to keep reading the 5 fixed bytes
        cmp     #$00
        bne     L8CF5_LOOP              ;Then loop until the 0 that ends the filename
        sec
L8D12_RTS:
        rts

L8D13_67_ILLEGAL_SYS_TS:
        lda     #doserr_67_illegal_sys_ts ;67 illegal system t or s
L8D15_CLC_RTS:
        clc
        rts
; ----------------------------------------------------------------------------
;Delete a directory entry.  The directory channel must be positioned at the
;start of the entry (see V1541_DIR_NEXT).  Everything after the entry is
;copied down over it, and the block at the end is deleted if it is no longer
;needed.  Leaves the directory channel closed.
V1541_DIR_DELETE_ENTRY:
        jsr     V1541_CLOSE_DIR_READERS
        jsr     V1541_SELECT_DIR_CHANNEL
        jsr     V1541_DIR_READ_ENTRY    ;Read the entry being deleted to get past it
        bcc     L8D3C_TRUNCATE          ;Branch if it can't be read
L8D22_CHECK_LAST:
        bit     V1541_EOF
        bmi     L8D3C_TRUNCATE          ;Branch if it was the last entry: nothing to copy
L8D27_COPY_LOOP:
        jsr     V1541_READ_FILE_BYTE               ;Read a byte from farther on
        bcc     L8D5A_RTS ;branch if error
        jsr     V1541_SWAP_POSITION     ;Go to the write position
        jsr     V1541_OVERWRITE_FILE_BYTE ;Store the byte there
        bcc     L8D5A_RTS
        jsr     V1541_SWAP_POSITION     ;Go back to the read position
        bit     V1541_EOF
        bpl     L8D27_COPY_LOOP         ;Loop until the end of the directory
L8D3C_TRUNCATE:
        jsr     V1541_SWAP_POSITION     ;Go to the write position, which is the new end of the directory
        jsr     V1541_FIND_BLOCK
        lda     #doserr_71_dir_error ;71 directory error
        bcc     L8D5A_RTS ;branch if error
        lda     V1541_ACTIV_OFFS
        beq     L8D50_DELETE_BLOCK      ;Branch if the directory is now completely empty
        ldy     #$02
        sta     (MAPPED_PAGE_PTR),y     ;Header byte 2 = offset of the last byte in use
        inc     V1541_ACTIV_SEQ         ;The block after this one is no longer needed
L8D50_DELETE_BLOCK:
        jsr     V1541_FIND_AND_DELETE_BLOCK
        jsr     V1541_SELECT_DIR_CHANNEL_AND_CLEAR_IT
        jsr     V1541_SET_DIR_CHECKSUM  ;Checksum the directory
        sec
L8D5A_RTS:
        rts
; ----------------------------------------------------------------------------
;Add the entry in V1541_DATA_BUF to the end of the directory, after setting
;its checksum to that of the file's blocks and clearing its "open" flags.
V1541_DIR_ADD_ENTRY:
        jsr     V1541_SET_ENTRY_CHECKSUM
        lda     #$30
        trb     V1541_DATA_BUF
;Add the entry in V1541_DATA_BUF to the end of the directory as it is.
V1541_DIR_APPEND_ENTRY:
        jsr     V1541_CHECK_SPACE_FOR_ENTRY
        bcc     L8D9E_ERROR_OR_DONE     ;Branch if there is no space for it
        jsr     V1541_CLOSE_DIR_READERS
        jsr     V1541_SELECT_DIR_CHANNEL_AND_CLEAR_IT
        lda     #$10                    ;Open the directory for reading...
        sta     V1541_ACTIV_FLAGS
L8D72_SKIP_LOOP:
        jsr     V1541_READ_FILE_BYTE
        bcs     L8D7A_NO_ERROR          ;Branch if a byte was read
        lda     #doserr_71_dir_error    ;The directory could not be read
        rts

L8D7A_NO_ERROR:
        lda     V1541_EOF
        bpl     L8D72_SKIP_LOOP         ;...and read to the end of it
        lda     #$20                    ;Then start writing there
        tsb     V1541_ACTIV_FLAGS
        ldx     #$FF
L8D85_LOOP:
        inx
        phx
        lda     V1541_DATA_BUF,x
        jsr     V1541_WRITE_FILE_BYTE   ;Write the 5 fixed bytes...
        plx
        cpx     #$05
        bcc     L8D85_LOOP
        lda     V1541_DATA_BUF,x
        bne     L8D85_LOOP              ;...then the filename, up to and including its 0
        jsr     V1541_SELECT_DIR_CHANNEL_AND_CLEAR_IT
        jsr     V1541_SET_DIR_CHECKSUM  ;Checksum the directory
        sec
L8D9E_ERROR_OR_DONE:
        rts
; ----------------------------------------------------------------------------
;Find the first directory entry whose filename matches the name that was
;parsed by V1541_PARSE_NAME (wildcards allowed).
;
;Returns:     Carry set = found.  A = flags of the entry, V1541_DATA_BUF holds
;                         the entry, and the directory channel is positioned
;                         at its start.
;             Carry clear = not found.  A=62.
V1541_DIR_FIND_NAME:
        jsr     V1541_SELECT_DIR_CHANNEL_AND_CLEAR_IT
        jsr     V1541_DIR_FIRST
        bra     L8DAA_CHECK

L8DA7_NEXT:
        jsr     V1541_DIR_NEXT

L8DAA_CHECK:
        bcc     L8DBA_62_FILE_NOT_FOUND ;Branch if there are no more entries
        jsr     V1541_MATCH_NAME
        bcc     L8DB5_NO_MATCH ;filename does not match
        lda     V1541_DATA_BUF
        rts

L8DB5_NO_MATCH:
        bit     V1541_EOF
        bpl     L8DA7_NEXT
L8DBA_62_FILE_NOT_FOUND:
        clc
        lda     #doserr_62_file_not_found
        rts
; ----------------------------------------------------------------------------
;Find the directory entry that has file id A, skipping special ($80) entries.
;Returns carry set if found, with V1541_DATA_BUF holding the entry and the
;directory channel positioned at its start, or carry clear if not.  A=62
;either way.
V1541_DIR_FIND_ID:
        pha
        jsr     V1541_SELECT_DIR_CHANNEL_AND_CLEAR_IT
        jsr     V1541_DIR_FIRST
        bra     L8DCA_CHECK

L8DC7_NEXT:
        jsr     V1541_DIR_NEXT

L8DCA_CHECK:
        bcc     L8DDC_DONE              ;Branch if there are no more entries
        lda     V1541_DATA_BUF
        bit     #$80
        bne     L8DC7_NEXT
        tsx
        lda     V1541_DATA_BUF+1
        cmp     stack+1,x
        bne     L8DC7_NEXT

L8DDC_DONE:
        pla
        lda     #doserr_62_file_not_found
        rts
; ----------------------------------------------------------------------------
;Count the blocks of a file.  The first entry point is for the file whose
;id is in V1541_DATA_BUF+1.  The second is for file 0, the directory.
;
;Returns:     A = number of blocks, with Z=1 if there are none
;             Y = byte 2 of the header of the file's last block (the offset
;                 of its last byte in use), or 0 if every block is full
V1541_COUNT_FILE_BLOCKS:
        lda     V1541_DATA_BUF+1
        .byte   $2C                     ;Skip next instruction
V1541_COUNT_DIR_BLOCKS:
        lda     #$00
        ldx     #$00
        phx                             ;Push value to return in Y
        phx                             ;Push block count
        pha                             ;Push file id
        jsr     V1541_FIRST_BLOCK
        beq     L8E0A_DONE              ;Branch if the disk is empty
L8DF0_LOOP:
        tsx
        lda     V1541_BLOCK_ID
        cmp     stack+1,x
        bne     L8E05_NEXT              ;Branch if this block belongs to another file
        inc     stack+2,x               ;Count it
        ldy     #$02
        lda     (MAPPED_PAGE_PTR),y
        beq     L8E05_NEXT              ;Branch if it is a full block
        sta     stack+3,x               ;Otherwise remember where its data ends
L8E05_NEXT:
        jsr     V1541_NEXT_BLOCK
        bcs     L8DF0_LOOP
L8E0A_DONE:
        pla
        pla                             ;A = number of blocks
        ply
        cmp     #$00
        rts
; ----------------------------------------------------------------------------
;Put the checksum of the file whose id is in V1541_DATA_BUF+1 into the
;directory entry in V1541_DATA_BUF.
V1541_SET_ENTRY_CHECKSUM:
        lda     V1541_DATA_BUF+1
        jsr     V1541_CHECKSUM_FILE
        sta     V1541_DATA_BUF+2
        stx     V1541_DATA_BUF+3
        sty     V1541_DATA_BUF+4
        rts
; ----------------------------------------------------------------------------
;Verify that the blocks of the file whose id is in V1541_DATA_BUF+1 still
;have the checksum that is in the directory entry in V1541_DATA_BUF.
;Returns carry set if so, or carry clear and A=27 if not.
V1541_VERIFY_FILE_CHECKSUM:
        lda     V1541_DATA_BUF+1
        jsr     V1541_CHECKSUM_FILE
        cmp     V1541_DATA_BUF+2
        bne     L8E35_BAD
        cpx     V1541_DATA_BUF+3
        bne     L8E35_BAD
        cpy     V1541_DATA_BUF+4
        beq     L8E36_DONE
L8E35_BAD:
        clc
L8E36_DONE:
        lda     #doserr_27_read_error ;27 read error (checksum error in header)
        rts
; ----------------------------------------------------------------------------
;Remember the checksum of the directory in V1541_DIR_CHKSUM.
V1541_SET_DIR_CHECKSUM:
        jsr     V1541_CHECKSUM_DIR
        sta     V1541_DIR_CHKSUM
        stx     V1541_DIR_CHKSUM+1
        sty     V1541_DIR_CHKSUM+2
        rts
; ----------------------------------------------------------------------------
;Verify that the directory still has the checksum in V1541_DIR_CHKSUM.
;Returns carry set if so, or carry clear and A=27 if not.
V1541_VERIFY_DIR_CHECKSUM:
        jsr     V1541_CHECKSUM_DIR
        cmp     V1541_DIR_CHKSUM
        bne     L8E58_BAD
        cpx     V1541_DIR_CHKSUM+1
        bne     L8E58_BAD
        cpy     V1541_DIR_CHKSUM+2
        beq     L8E59_DONE
L8E58_BAD:
        clc
L8E59_DONE:
        lda     #doserr_27_read_error
        rts
; ----------------------------------------------------------------------------
;Add up every byte (headers included) of every block of a file.
;The first entry point is for file 0, the directory.  The second is for
;the file whose id is in A.
;Returns the 24-bit sum in A (low), X (middle) and Y (high).
V1541_CHECKSUM_DIR:
        lda     #$00
V1541_CHECKSUM_FILE:
        ldx     #$00
        phx                             ;Push high byte of the sum
        phx                             ;Push middle byte of the sum
        pha                             ;Push file id
        jsr     V1541_FIRST_BLOCK
        beq     L8E8D_DONE              ;Branch if the disk is empty
        lda     #$00
L8E6A_BLOCK_LOOP:
        tsx
        ldy     stack+1,x
        cpy     V1541_BLOCK_ID
        bne     L8E86_NEXT              ;Branch if this block belongs to another file
        ldy     #$00
        clc
L8E76_BYTE_LOOP:
        adc     (MAPPED_PAGE_PTR),y
        bcc     L8E83_NO_CARRY
        clc
        inc     stack+2,x
        bne     L8E83_NO_CARRY
        inc     stack+3,x
L8E83_NO_CARRY:
        iny
        bne     L8E76_BYTE_LOOP
L8E86_NEXT:
        pha
        jsr     V1541_NEXT_BLOCK
        pla
        bcs     L8E6A_BLOCK_LOOP
L8E8D_DONE:
        plx                             ;Discard file id
        plx                             ;X = middle byte of the sum
        ply                             ;Y = high byte of the sum
        rts
; ----------------------------------------------------------------------------
;Check that there is space to add the entry in V1541_DATA_BUF to the
;directory.  Returns carry clear and A=25 if the directory needs another
;block and the disk can't grow.  Otherwise returns carry set, with A=1 if
;another block will be needed or A=0 if not.
;
;BUG: the loop that measures the filename reads V1541_DATA_BUF+5,X with X
;starting at 5, so it starts with the sixth character of the name instead of
;the first.  For a short name, it reads past the end into whatever follows.
V1541_CHECK_SPACE_FOR_ENTRY:
        jsr     V1541_COUNT_DIR_BLOCKS
        beq     L8EA7_NEED_BLOCK        ;Branch if the directory has no blocks yet: it needs one
        tya                             ;A = offset of the last byte in use in the directory's last block
        ldx     #$FF
L8E99_LOOP:
        inc     a
        beq     L8EA7_NEED_BLOCK        ;Branch if the entry will not fit in that block
        inx
        cpx     #$05
        bcc     L8E99_LOOP              ;Loop for the 5 fixed bytes
        lda     V1541_DATA_BUF+5,x
        bne     L8E99_LOOP              ;Then loop until the 0 that ends the filename
        rts

L8EA7_NEED_BLOCK:
        jsr     V1541_CHECK_SPACE
        bcc     L8EAE_RTS ;branch if error
        lda     #$01
L8EAE_RTS:
        rts
; ----------------------------------------------------------------------------
;Parse the filename at FNADR, FNLEN (in RAM).
;Returns the same as V1541_PARSE_NAME.
V1541_PARSE_FNADR:
        lda     FNADR
        ldx     FNADR+1
        ldy     FNLEN
;Parse the filename at address A (low), X (high) with length Y.
V1541_PARSE_NAME_AXY:
        sta     V1541_FNADR
        stx     V1541_FNADR+1
        sty     V1541_FNLEN
        ;Fall through
; ----------------------------------------------------------------------------
;Parse the filename at V1541_FNADR with length V1541_FNLEN.
;
;The syntax is:  [$ or @] [drive :] name [,type] [,mode] [= ...]
;The drive may only be made of "0" and spaces.  Type is S or P.  Mode is R,
;W, A or M.  Only the first letter of a type or mode word is allowed.
;
;Returns:     Carry clear = error; A = 33 (syntax error) 
;             Carry set = ok; A = V1541_NAME_FLAGS:
;                 $80 = there is a name (it is not empty)
;                 $40 = the name has a wildcard (? or *)
;                 $20 = the name is followed by "="
;                 $02 = something other than "0" and spaces came first (a colon
;                       counts too), so another colon is an error
;                 $01 = there was a colon
;             V1541_NAME_PREFIX = "$" or "@" if the filename started with it
;             V1541_NAME_START, V1541_NAME_END = where the name is
;             V1541_FILE_TYPE, V1541_FILE_MODE = letters given, or 0
V1541_PARSE_NAME:
        stz     V1541_NAME_FLAGS
        stz     V1541_FILE_MODE
        stz     V1541_FILE_TYPE
        stz     V1541_NAME_PREFIX
        lda     #V1541_FNADR ;ZP-address
        sta     SINNER                  ;Make GO_RAM_LOAD_GO_KERN read through V1541_FNADR
        lda     V1541_FNLEN
        bne     L8ED7_NOT_EMPTY

L8ED3_33_SYNTAX_ERROR:
        lda     #doserr_33_syntax_err ;33 invalid filename
        clc
        rts

L8ED7_NOT_EMPTY:
        ldy     #$00
        jsr     V1541_GET_NAME_CHAR
        dey                             ;Back to the first character
        bcc     L8ED3_33_SYNTAX_ERROR
        cmp     #'$'
        beq     L8EE7_GOT_PREFIX
        cmp     #'@'
        bne     L8EEB_SET_START
L8EE7_GOT_PREFIX:
        iny                             ;Skip the "$" or "@"
        sta     V1541_NAME_PREFIX
L8EEB_SET_START:
        sty     V1541_NAME_START        ;The name starts here (so far)

L8EEE_NEXT_CHAR:
        sty     V1541_NAME_END          ;The name ends here (so far)
        cpy     V1541_FNLEN
        bne     L8EF9_NAME_CHAR         ;Branch if there is more to look at
        jmp     L8F86_END

L8EF9_NAME_CHAR:
        jsr     V1541_GET_NAME_CHAR
        bcc     L8ED3_33_SYNTAX_ERROR
        tax
        cpx     #' '
        beq     L8EEE_NEXT_CHAR
        cpx     #'0'
        beq     L8EEE_NEXT_CHAR
        cpx     #'9'+1                  ;Is it a colon?
        bne     L8F14_NOT_COLON
        lda     #$03
        tsb     V1541_NAME_FLAGS
        bne     L8ED3_33_SYNTAX_ERROR   ;Branch if this is the second colon, or the first one came too late
        bra     L8EEB_SET_START         ;The name starts after the colon
L8F14_NOT_COLON:
        lda     #$02
        tsb     V1541_NAME_FLAGS
        cpx     #'='
        beq     L8F81_GOT_EQUALS
        cpx     #'?'
        beq     L8F25_GOT_WILDCARD
        cpx     #'*'
        bne     L8F2A_NOT_WILDCARD
L8F25_GOT_WILDCARD:
        lda     #$40
        tsb     V1541_NAME_FLAGS
L8F2A_NOT_WILDCARD:
        cpx     #','
        bne     L8EEE_NEXT_CHAR
        dey                             ;A comma ends the name
L8F2F_NEXT_CHAR:
        cpy     V1541_FNLEN
        beq     L8F86_END
        jsr     V1541_GET_NAME_CHAR
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
        jsr     V1541_GET_NAME_CHAR
        bcc     L8F5F_33_SYNTAX_ERROR
        cmp     #' '
        beq     L8F45_LOOP
        and     #$DF                    ;Make uppercase

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
        bcs     L8F71_RWAM              ;Branch if it is a mode (R, W, A, M); otherwise it is a type (S, P)
        ;PR
        ldx     V1541_FILE_TYPE
        bne     L8F5F_33_SYNTAX_ERROR   ;Branch if a type was already given
        sta     V1541_FILE_TYPE
        bra     L8F2F_NEXT_CHAR
L8F71_RWAM:
        ;RWAM
        ldx     V1541_FILE_MODE
        bne     L8F5F_33_SYNTAX_ERROR   ;Branch if a mode was already given
        sta     V1541_FILE_MODE
        bra     L8F2F_NEXT_CHAR

L8F7B_SPRWAM:
        .byte ftype_s_seq, ftype_p_prg
        .byte fmode_r_read, fmode_w_write, fmode_a_append, fmode_m_modify

L8F81_GOT_EQUALS:
        lda     #$20
        tsb     V1541_NAME_FLAGS
L8F86_END:
        lda     V1541_NAME_START
        cmp     V1541_NAME_END
        bcc     L8F96_HAVE_NAME         ;Branch if the name is not empty
        stz     V1541_NAME_END
        stz     V1541_NAME_START
        bcs     L8F9B_CHECK_LENGTH
L8F96_HAVE_NAME:
        lda     #$80
        tsb     V1541_NAME_FLAGS
L8F9B_CHECK_LENGTH:
        cld
        clc
        lda     #$10
        adc     V1541_NAME_START
        cmp     V1541_NAME_END
        lda     #doserr_33_syntax_err ;33 syntax error
        bcc     L8FAC_RTS               ;Branch if the name is longer than 16 characters
        lda     V1541_NAME_FLAGS
L8FAC_RTS:
        rts
; ----------------------------------------------------------------------------
;Get the next character of the filename being parsed and advance Y.
;Returns the character in A, with carry clear if it is a character that is
;not allowed in a filename.
V1541_GET_NAME_CHAR:
        jsr     GO_RAM_LOAD_GO_KERN  ;get the char
        iny
        ldx     #$03
L8FB3_LOOP:
        cmp     L8FBF_DISALLOWED_FNAME_CHARS,X
        bne     L8FBA_NOT_EQU
        clc ;Found a bad character
        rts
L8FBA_NOT_EQU:
        dex
        bpl     L8FB3_LOOP
        sec
        rts

L8FBF_DISALLOWED_FNAME_CHARS:
       .byte $00 ;null
       .byte $0d ;return
       .byte $22 ;quote
       .byte $8d ;shift-return
; ----------------------------------------------------------------------------
;Compare the name that was parsed by V1541_PARSE_NAME with the filename of
;the directory entry in V1541_DATA_BUF.  "?" in the parsed name matches any
;one character and "*" matches everything from there on.
;Returns carry set if they match.
V1541_MATCH_NAME:
        ldx     #$00
        ldy     V1541_NAME_START
        lda     #V1541_FNADR ;ZP-address
        sta     SINNER
L8FCD_LOOP:
        jsr     GO_RAM_LOAD_GO_KERN ;get char from filename
        cmp     #'*'
        beq     L8FE9_SUCCESS_FILENAME_MATCHES
        cmp     #'?'
        beq     L8FDD_ANY_ONE_CHAR
        cmp     V1541_DATA_BUF+5,x
        bne     L8FF1_FAIL_FILENAME_DOES_NOT_MATCH
L8FDD_ANY_ONE_CHAR:
        iny
        cpy     V1541_NAME_END
        bne     L8FEB_MORE              ;Branch if there is more of the parsed name
        inx
        lda     V1541_DATA_BUF+5,x
        bne     L8FF1_FAIL_FILENAME_DOES_NOT_MATCH ;Branch if the filename in the entry is longer
L8FE9_SUCCESS_FILENAME_MATCHES:
        sec
        rts
L8FEB_MORE:
        inx
        lda     V1541_DATA_BUF+5,X
        bne     L8FCD_LOOP              ;Loop unless the filename in the entry is shorter
L8FF1_FAIL_FILENAME_DOES_NOT_MATCH:
        clc
        rts
; ----------------------------------------------------------------------------
;Copy the name that was parsed by V1541_PARSE_NAME into the directory entry
;in V1541_DATA_BUF as its filename.
V1541_COPY_NAME_TO_ENTRY:
        stz     V1541_DIR_LINE_OK
        lda     #V1541_FNADR ;ZP-address
        sta     SINNER
        ldx     #$00
        ldy     V1541_NAME_START
L9000_LOOP:
        jsr     GO_RAM_LOAD_GO_KERN
        sta     V1541_DATA_BUF+5,x
        inx
        iny
        cpy     V1541_NAME_END
        bne     L9000_LOOP
        stz     V1541_DATA_BUF+5,x
        rts
; ----------------------------------------------------------------------------
;Check the type of the directory entry in V1541_DATA_BUF against the type
;that was requested, if any.
;Returns V1541_FILE_TYPE and X = type of the entry ("S" or "P"), with carry
;clear and A=64 if a different type was requested.
V1541_CHECK_FILE_TYPE:
        ldx     #ftype_s_seq
        lda     V1541_DATA_BUF
        bit     #$40                    ;Flag $40 = PRG
        beq     L901C_GOT_SEQ
        ldx     #ftype_p_prg
L901C_GOT_SEQ:
        lda     #doserr_64_file_type_mism
        cpx     V1541_FILE_TYPE
        beq     L9029_DONE               ;Branch if it is the type requested (carry is set)
        ldy     V1541_FILE_TYPE
        beq     L9029_DONE               ;Branch if no type was requested (carry is set)
        clc
L9029_DONE:
        stx     V1541_FILE_TYPE
        rts
; ----------------------------------------------------------------------------
;Copy the directory entry in V1541_DATA_BUF to the active channel: its flags
;and file id.  For a special ($80) entry, bytes 2-4 are copied as well, the
;last of them landing in the byte after the channel's state ($EB).
V1541_ENTRY_TO_CHANNEL:
        ldx     #$04
        lda     V1541_DATA_BUF
        bit     #$80
        bne     L9038_LOOP
        ldx     #$01
L9038_LOOP:
        lda     V1541_DATA_BUF,x
        sta     V1541_ACTIV_FLAGS,x
        dex
        bpl     L9038_LOOP
        rts
; ----------------------------------------------------------------------------
;Get ready for a directory listing.  The name that was parsed by
;V1541_PARSE_NAME becomes the pattern of the files to list.  The default is
;"*".  Only one listing can be in progress at a time.
V1541_SETUP_DIR_LISTING:
        jsr     V1541_CLOSE_DIR_READERS
        stz     V1541_DIR_STATE         ;Start with the header line
        lda     #'*'
        sta     V1541_DIR_PATTERN
        stz     V1541_DIR_PATTERN+1
        stz     V1541_DIR_TYPE
        lda     V1541_NAME_FLAGS
        bit     #$80
        beq     L907D_SEC_RTS           ;Branch if no name was given
        ldx     #$00
        ldy     V1541_NAME_START
L905E_COPY_LOOP:
        lda     #V1541_FNADR ;ZP-address
        sta     SINNER
        jsr     GO_RAM_LOAD_GO_KERN
        sta     V1541_DIR_PATTERN,x
        iny
        inx
        cpy     V1541_NAME_END
        bne     L905E_COPY_LOOP
        cpx     #$14
        bcs     L9077                   ;Branch if the pattern is the full 20 characters
        stz     V1541_DIR_PATTERN,x
L9077:  lda     V1541_FILE_TYPE
        sta     V1541_DIR_TYPE          ;BUG: stored, but never tested, so the type is ignored
L907D_SEC_RTS:
        sec
        rts
; ----------------------------------------------------------------------------
;Unused
        ldx     EAL
        ldy     EAH
        sec
        rts
; ----------------------------------------------------------------------------
;SAVE to the Virtual 1541.
;
;Call with:   STAL/STAH = start address ($0800 or above)
;             EAL/EAH = end address + 1 ($F800 or below)
;             FNADR, FNLEN = filename.  "@" in front replaces an existing
;                            file, which keeps its type.  Otherwise ",S" makes
;                            a SEQ file, which has no load address, and the
;                            default is a PRG.
;
;The memory is read in MMU RAM mode.  The file is written in one go, so it
;is never left open.
V1541_SAVE:
        jsr     V1541_INTERNAL_SAVE
        jmp     V1541_KERNAL_CALL_DONE
; ----------------------------------------------------------------------------
V1541_INTERNAL_SAVE:
        ldx     STAH
        lda     STAL
        sta     SAL                     ;The start address is the load address stored in a PRG file
        stx     SAH
        cpx     #$08
        bcc     L90DD_25_WRITE_ERROR    ;Branch if the start address is below $0800
        cpx     #$F8
        bcs     L90DD_25_WRITE_ERROR    ;Branch if the start address is $F800 or above
        lda     EAH
        cmp     #>$F800                 ;The end address + 1 must not be above $F800
        bcc     L90A7_RANGE_OK
        bne     L90DD_25_WRITE_ERROR
        lda     EAL
        bne     L90DD_25_WRITE_ERROR
L90A7_RANGE_OK:
        jsr     V1541_PARSE_FNADR
        bcc     L90DA_33_SYNTAX_ERROR
        bit     #$80
        beq     L90DA_33_SYNTAX_ERROR   ;Branch if there is no name
        bit     #$60
        bne     L90DA_33_SYNTAX_ERROR   ;Branch if it has a wildcard or an "="
        lda     V1541_FILE_MODE
        bne     L90DA_33_SYNTAX_ERROR   ;Branch if a mode was given
        lda     V1541_NAME_PREFIX
        beq     L90C2_PREFIX_OK         ;The only prefix allowed is "@"
        cmp     #$40 ;'@'
        bne     L90DA_33_SYNTAX_ERROR

L90C2_PREFIX_OK:
        jsr     V1541_DIR_FIND_NAME
        bcc     L90EC_NEW_FILE          ;Branch if there is no file with that name

        lda     V1541_NAME_PREFIX
        bne     L90D0_REPLACE           ;The file exists.  That is an error unless "@" was given.
        lda     #doserr_63_file_exists ;63 file exists
        bra     L90DF_ERROR

L90D0_REPLACE:
        lda     V1541_DATA_BUF
        and     #$80
        beq     L90E1_REPLACE_OK        ;Branch unless it is a special ($80) entry, which can't be replaced
        lda     #doserr_26_write_prot_on ;#26 write protect on
        .byte   $2C                     ;Skip next instruction
L90DA_33_SYNTAX_ERROR:
        lda     #doserr_33_syntax_err  ;33 syntax error (invalid filename)
        .byte   $2C                     ;Skip next instruction
L90DD_25_WRITE_ERROR:
        lda     #doserr_25_write_err ;25 write error (write-verify error)
L90DF_ERROR:
        clc
        rts

L90E1_REPLACE_OK:
        jsr     V1541_CHECK_FILE_TYPE   ;Is the old file of the type being saved?
        bcc     L90DF_ERROR             ;Branch if not
        jsr     V1541_COUNT_FILE_BLOCKS ;A = number of blocks that deleting the old file will free
        inc     a                       ;Plus 1: see below
        bra     L910D_CHECK_SPACE

L90EC_NEW_FILE:
        stz     V1541_NAME_PREFIX       ;No file is being replaced
        jsr     V1541_NEW_FILE_ID       ;Get a file id that is not in use
        bcc     L90DF_ERROR             ;Branch if there is none
        jsr     V1541_COPY_NAME_TO_ENTRY ;Put the name in the new directory entry
        stz     V1541_DATA_BUF          ;Flags = 0 for a SEQ file...
        lda     V1541_FILE_TYPE
        cmp     #ftype_s_seq
        beq     L9106_CHECK_DIR_SPACE
        lda     #$40                    ;...or $40 for a PRG
        sta     V1541_DATA_BUF
L9106_CHECK_DIR_SPACE:
        jsr     V1541_CHECK_SPACE_FOR_ENTRY
        bcc     L90DF_ERROR             ;Branch if the directory can't take the entry
        eor     #$01                    ;A = 1, less 1 if the directory needs another block
L910D_CHECK_SPACE:
        pha                             ;Push the number of blocks that are free to use, plus 1
        jsr     V1541_COUNT_SAVE_BLOCKS ;Y = number of blocks that the data needs
        sty     V1541_DATA_BUF+2
        pla                             ;Pull the number of blocks that are free to use, plus 1
        clc
        adc     V1541_BOTTOM_PAGE       ;Compute which page will be just below the disk afterwards:
        ldx     V1541_BOTTOM_PAGE+1
        bcc     L911F_NO_CARRY
        inx
L911F_NO_CARRY:
        clc
        sbc     V1541_DATA_BUF+2        ;bottom + blocks free to use - blocks needed - 1
        bcs     L9126_NO_BORROW
        dex
L9126_NO_BORROW:
        tay
        bne     L912A_NO_BORROW_2
        dex
L912A_NO_BORROW_2:
        dec     a
        cpx     MEMTOP_PAGE+1           ;That page must not be below the top page of application memory
        bcc     L9137_NO_SPACE
        bne     L913A_SPACE_OK
        cmp     MEMTOP_PAGE
        bcs     L913A_SPACE_OK
L9137_NO_SPACE:
        jmp     L90DD_25_WRITE_ERROR
; ----------------------------------------------------------------------------
L913A_SPACE_OK:
        cpx     #$00                    ;If the disk is going to grow down over the memory that is being
        bne     L9145_NOT_IN_THE_WAY
        cmp     STAH                    ;saved, move that memory down out of the way first
        bcs     L9145_NOT_IN_THE_WAY
        jsr     V1541_MOVE_SAVE_DATA
L9145_NOT_IN_THE_WAY:
        lda     V1541_NAME_PREFIX
        beq     L9150_WRITE             ;Branch if no file is being replaced
        jsr     V1541_DELETE_FILE_BLOCKS ;Delete the blocks of the old file...
        jsr     V1541_DIR_DELETE_ENTRY  ;...and its directory entry
L9150_WRITE:
        jsr     V1541_COUNT_SAVE_BLOCKS
        cpy     #$00
        beq     L91A1_ADD_ENTRY         ;Branch if there is no data at all: just add the directory entry
        dey
        sty     V1541_DATA_BUF+2        ;V1541_DATA_BUF+1 to +3 hold the header for each block: file id,
        sta     V1541_DATA_BUF+3        ;sequence number (last block first), offset of last byte in use
        lda     #V1541_TMP
        sta     SINNER                  ;Make GO_RAM_LOAD_GO_KERN read through V1541_TMP
L9163_BLOCK_LOOP:
        jsr     V1541_GROW              ;Add a block at the bottom of the disk
        ldy     #$FF
L9168_COPY_LOOP:
        jsr     GO_RAM_LOAD_GO_KERN
        sta     (MAPPED_PAGE_PTR),y     ;Copy 255 bytes from RAM.  Only offsets 3-255 are real data.
        dey
        bne     L9168_COPY_LOOP
        ldy     #$02
L9172_HEADER_LOOP:
        lda     V1541_DATA_BUF+1,y
        sta     (MAPPED_PAGE_PTR),y     ;Write the 3-byte header over offsets 0-2
        dey
        bpl     L9172_HEADER_LOOP
        sec
        lda     V1541_TMP
        sbc     #$FD                    ;The block before this one holds the 253 bytes below
        bcs     L9183_NO_BORROW
        dec     V1541_TMP+1
L9183_NO_BORROW:
        sta     V1541_TMP
        stz     V1541_DATA_BUF+3        ;Every block but the last is full
        ldy     V1541_DATA_BUF+2
        dec     V1541_DATA_BUF+2        ;Sequence number for the block before this one
        tya
        bne     L9163_BLOCK_LOOP        ;Loop until block 0 has been written
        bit     V1541_DATA_BUF
        bvc     L91A1_ADD_ENTRY         ;Branch if it is a SEQ file
        ldy     #$04
        lda     SAH
        sta     (MAPPED_PAGE_PTR),y     ;PRG: the first two data bytes of block 0 are the load address
        dey
        lda     SAL
        sta     (MAPPED_PAGE_PTR),y
L91A1_ADD_ENTRY:
        jmp     V1541_DIR_ADD_ENTRY     ;Checksum the file and add its directory entry
; ----------------------------------------------------------------------------
;Compute how many blocks are needed to save the memory from STAL/STAH up to
;but not including EAL/EAH.  A PRG file needs 2 more bytes for its load
;address.  Each block holds 253 bytes.
;
;Returns:     Y = number of blocks
;             A = offset of the last byte in use in the last block
;             V1541_TMP = address that goes with offset 0 of the last block
;             Carry clear and A=52 if 256 blocks or more would be needed
V1541_COUNT_SAVE_BLOCKS:
        ldx     STAH
        lda     STAL
        bit     V1541_DATA_BUF
        bvc     L91B3_COUNT             ;Branch if it is a SEQ file
        sec
        sbc     #$02                    ;PRG: start 2 bytes early to leave space for the load address
        bcs     L91B3_COUNT
        dex
L91B3_COUNT:
        ldy     #$00
L91B5_LOOP:
        cpx     EAH
        bcc     L91BD_ADD_BLOCK
        cmp     EAL
        bcs     L91C9_DONE              ;Branch if the end address has been reached
L91BD_ADD_BLOCK:
        adc     #$FD                    ;One more block: 253 bytes further on
        bcc     L91C2_NO_CARRY
        inx
L91C2_NO_CARRY:
        iny
        bne     L91B5_LOOP
        lda     #doserr_52_file_too_large
        clc
        rts
; ----------------------------------------------------------------------------
L91C9_DONE:
        dex                             ;X/A is 253 bytes past the data of the last block.  Subtract 256
        sta     V1541_TMP               ;to get the address that goes with offset 0 of the last block.
        stx     V1541_TMP+1
        clc
        lda     EAL
        sbc     V1541_TMP               ;A = end address - 1 - that address = offset of the last data byte
        sec
        rts
; ----------------------------------------------------------------------------
;Move the memory that is about to be saved down to the start of page A, out
;of the way of the pages that the disk is going to grow into.  STAL/STAH and
;EAL/EAH are changed to describe the memory at its new address.
;
;This does not work: see the bug noted below.
V1541_MOVE_SAVE_DATA:
        pha
        sta     V1541_TMP+1
        stz     V1541_TMP
        lda     #STAH                   ;BUG: #STAL was meant.  With STAH,...
        sta     SINNER                  ;...GO_RAM_LOAD_GO_KERN reads through $B7/$B8 and copies the wrong memory
        lda     #V1541_TMP
        sta     GO_RAM_STORE_GO_KERN_ZP ;Make GO_RAM_STORE_GO_KERN write through V1541_TMP
L91E4_LOOP:
        lda     STAH
        cmp     EAH
        bne     L91F0_COPY
        lda     STAL
        cmp     EAL
        beq     L9206_DONE
L91F0_COPY:
        ldy     #$00
        jsr     GO_RAM_LOAD_GO_KERN
        jsr     GO_RAM_STORE_GO_KERN
        inc     V1541_TMP
        bne     L91FE_NO_CARRY
        inc     V1541_TMP+1
L91FE_NO_CARRY:
        inc     STAL
        bne     L9204_NO_CARRY_2
        inc     STAH
L9204_NO_CARRY_2:
        bra     L91E4_LOOP
L9206_DONE:
        lda     V1541_TMP
        sta     EAL                     ;New end address + 1
        lda     V1541_TMP+1
        sta     EAH
        pla
        sta     STAH                    ;New start address
        stz     STAL
        rts
; ----------------------------------------------------------------------------
;CLOSE a file on the Virtual 1541.  The channel is the low 4 bits of SA.
V1541_CLOSE:
        jsr     V1541_INTERNAL_CLOSE
        jmp     V1541_KERNAL_CALL_DONE
; ----------------------------------------------------------------------------
V1541_INTERNAL_CLOSE:
        jsr     V1541_SELECT_CHANNEL_GIVEN_SA
        bcs     L9221_IS_OPEN           ;Branch if the channel is open
        sec                             ;Closing a channel that is not open is not an error
        rts
L9221_IS_OPEN:
        lda     V1541_ACTIV_CHAN
        cmp     #doschan_15_command ;command channel?
        beq     L9240_DONE
        lda     V1541_ACTIV_FLAGS
        bit     #$20 ;is file open for writing?
        beq     L9240_DONE
        bit     #$80
        bne     L9240_DONE              ;Branch if it is a special ($80) entry
        lda     V1541_ACTIV_ID
        beq     L9240_DONE              ;Branch if the file has no id
        jsr     V1541_DIR_FIND_ID       ;A file that was being written: find its directory entry,
        bcc     L9240_DONE              ;if it still has one,
        jsr     V1541_DIR_DELETE_ENTRY  ;delete it,
        jsr     V1541_DIR_ADD_ENTRY     ;and add it again with the new checksum and the splat flag cleared
L9240_DONE:
        jmp     V1541_SELECT_CHANNEL_AND_CLEAR_IT
; ----------------------------------------------------------------------------
;OPEN a file on the Virtual 1541.  The channel is the low 4 bits of SA and
;the filename is at FNADR, FNLEN.
;
;   "$name"     Directory listing of the files that match the name (all
;               files if there is no name).  It is read as a BASIC program.
;   "name"      Read.  Same as "name,R".  The checksum of the file is verified.
;   "name,W"    Create a file and write it.  The file must not exist yet.
;   "@name,W"   Replace: delete the file if it exists, then create and write.
;   "name,A"    Append to the file, or create it if it does not exist.
;   "name,M"    Read a file without verifying its checksum.  This is the only
;               way to read a file that was never closed (a "*" splat file).
;               Such a file keeps its "open for writing" flag in the channel,
;               so closing the channel gives it a new checksum and makes it
;               an ordinary file again.
;   ",S" ",P"   File type.  A new file is SEQ unless ",P" is given.
;
;A file can be open for reading on several channels at once, but not while
;it is open for writing.  Wildcards are only accepted if a mode is given.
;
;Opening channel 15, the command channel, performs the filename as a command.
V1541_OPEN:
        jsr     V1541_INTERNAL_OPEN
        jmp     V1541_KERNAL_CALL_DONE
; ----------------------------------------------------------------------------
V1541_INTERNAL_OPEN:
        jsr     V1541_SELECT_CHANNEL_GIVEN_SA
        lda     V1541_ACTIV_CHAN
        cmp     #doschan_15_command ;command channel
        bne     L9255_NOT_CMD_CHAN
        jmp     V1541_OPEN_CMD_CHAN

        ;not the command channel

L9255_NOT_CMD_CHAN:
        jsr     V1541_CLEAR_ACTIVE_CHANNEL ;Close the channel in case it was open
        jsr     V1541_PARSE_FNADR
        bcc     L9287_ERROR
        bit     #$20
        bne     L9282_SYNTAX_ERROR      ;Branch if the name is followed by "="
        ldx     V1541_NAME_PREFIX
        beq     L928C_NO_PREFIX         ;Branch if the filename has no prefix
        cpx     #'$'
        bne     L927B_AT_PREFIX
        ldx     V1541_FILE_MODE
        bne     L9287_ERROR             ;A mode is not allowed with "$"
        jsr     V1541_SELECT_CHANNEL_GIVEN_SA
        jsr     V1541_SETUP_DIR_LISTING ;Set the pattern of the names to list
        lda     #$50                    ;$10 = open for reading, $40 = PRG: the listing is a BASIC program
        sta     V1541_ACTIV_FLAGS
        sec
        rts
; ----------------------------------------------------------------------------
L927B_AT_PREFIX:
        ldy     V1541_FILE_MODE
        cpy     #fmode_w_write
        beq     L9289_REPLACE           ;"@" is only allowed with ",W"
L9282_SYNTAX_ERROR:
        lda     #doserr_33_syntax_err ;33 syntax error (invalid filename)
        .byte   $2C ;skip next two bytes
L9285:  lda     #$21                    ;The same error number again
L9287_ERROR:
        clc
        rts
; ----------------------------------------------------------------------------
L9289_REPLACE:
        stx     V1541_FILE_MODE         ;Mode "@" = replace
L928C_NO_PREFIX:
        bit     #$80
        beq     L9282_SYNTAX_ERROR      ;Branch if there is no name
        ldy     #fmode_r_read
        ldx     V1541_FILE_MODE
        bne     L929A_HAVE_MODE
        sty     V1541_FILE_MODE         ;The default mode is "R"
L929A_HAVE_MODE:
        bit     #$40
        beq     L92A3_FIND              ;Branch if the name has no wildcards
        cpx     V1541_FILE_MODE         ;BUG: (possible) X = mode as it was given, 0 if none.  This rejects wildcards
        bne     L9285                   ;only when no mode was given.  CPY may have been meant (Y = "R").

L92A3_FIND:
        jsr     V1541_DIR_FIND_NAME
        bcc     L9317_NOT_FOUND                        ;Branch if there is no file with that name

        jsr     V1541_CHECK_FILE_TYPE
        bcc     L92C7_ERROR             ;Branch if it is not of the type requested

        ldy     V1541_FILE_MODE
        lda     #doserr_63_file_exists ;63 file exists
        cpy     #fmode_w_write
        beq     L92C7_ERROR             ;"W" can't be used on a file that exists
        lda     V1541_DATA_BUF
        bit     #$80
        beq     L92C9_NORMAL_FILE       ;Branch unless it is a special ($80) entry
        lda     #doserr_26_write_prot_on ;26 write protect on
        cpy     #'@'                    ;A special entry can't be replaced...
        beq     L92C7_ERROR
        cpy     #fmode_a_append
        bne     L9315_EXISTING          ;...or appended to
L92C7_ERROR:
        clc
        rts
; ----------------------------------------------------------------------------
L92C9_NORMAL_FILE:
        lda     V1541_DATA_BUF+1
        jsr     V1541_FIND_CHANNEL_WITH_FILE ;Is the file open on another channel?
        bcc     L92E6_NOT_OPEN          ;Branch if not
        lda     V1541_ACTIV_FLAGS
        and     #$20
        beq     L92DB_OPEN_FOR_READ     ;Branch if that channel is only reading it
        lda     #doserr_60_write_file_open ;60 write file open
        bra     L92C7_ERROR
L92DB_OPEN_FOR_READ:
        ldy     V1541_FILE_MODE
        cpy     #fmode_r_read
        beq     L92F8_ACCESS_OK         ;A second reader is fine
L92E2_WRITE_FILE_OPEN:
        lda     #doserr_60_write_file_open ;60 write file open
        bra     L92C7_ERROR
L92E6_NOT_OPEN:
        lda     V1541_DATA_BUF
        bit     #$20
        beq     L92F8_ACCESS_OK         ;Branch unless the file was never closed (splat)
        ldy     V1541_FILE_MODE
        cpy     #fmode_m_modify
        beq     L92F8_ACCESS_OK         ;A splat file can only be opened with "M"...
        cpy     #'@'
        bne     L92E2_WRITE_FILE_OPEN   ;...or replaced
L92F8_ACCESS_OK:
        ldy     V1541_FILE_MODE
        cpy     #'@'                    ;"@" = replace
        bne     L930C_NOT_REPLACE
        jsr     V1541_DIR_DELETE_ENTRY  ;Delete the directory entry of the old file...
        jsr     V1541_DELETE_FILE_BLOCKS ;...and its blocks
        lda     #fmode_w_write
        sta     V1541_FILE_MODE         ;Then carry on as if "W" had been given
        bra     L9317_NOT_FOUND
L930C_NOT_REPLACE:
        cpy     #fmode_m_modify
        beq     L9315_EXISTING          ;"M" skips the checksum
        jsr     V1541_VERIFY_FILE_CHECKSUM
        bcc     L92C7_ERROR             ;Branch if the file's checksum is wrong
L9315_EXISTING:
        bra     L9335_CHECK_MODE

L9317_NOT_FOUND:
        ldy     V1541_FILE_MODE
        cpy     #fmode_r_read
        beq     L9322_ERROR             ;The file does not exist.  That is an error for "R" and "M".
        cpy     #fmode_m_modify
        bne     L9326_CREATE
L9322_ERROR:
        lda     #doserr_62_file_not_found ;62 file not found
        clc
        rts

L9326_CREATE:
        lda     #fmode_w_write
        sta     V1541_FILE_MODE         ;"A" and "@" create the file, like "W"
        lda     V1541_FILE_TYPE
        bne     L9335_CHECK_MODE
        lda     #ftype_s_seq
        sta     V1541_FILE_TYPE         ;A new file is SEQ unless a type was given
L9335_CHECK_MODE:
        ldy     V1541_FILE_MODE
        cpy     #fmode_w_write
        bne     L935A_SET_UP_CHANNEL    ;Branch unless a file is being created
        jsr     V1541_NEW_FILE_ID
        bcc     L9358_ERROR             ;Branch if there is no file id to give it
        jsr     V1541_COPY_NAME_TO_ENTRY ;Put the name in the new directory entry
        stz     V1541_DATA_BUF          ;Flags = 0 for a SEQ file...
        lda     V1541_FILE_TYPE
        cmp     #ftype_p_prg
        bne     L9353_CHECK_DIR_SPACE
        lda     #$40                    ;...or $40 for a PRG
        sta     V1541_DATA_BUF
L9353_CHECK_DIR_SPACE:
        jsr     V1541_CHECK_SPACE_FOR_ENTRY
        bcs     L935A_SET_UP_CHANNEL    ;Branch if the directory can take the entry
L9358_ERROR:
        clc
        rts

L935A_SET_UP_CHANNEL:
        jsr     V1541_SELECT_CHANNEL_GIVEN_SA
        jsr     V1541_ENTRY_TO_CHANNEL  ;Channel gets the flags and file id from the directory entry
        lda     #$10                    ;$10 = open for reading
        tsb     V1541_ACTIV_FLAGS
        ldy     V1541_FILE_MODE
L9367_CHECK_M:
        cpy     #fmode_m_modify
        beq     L9378_OK                ;"M": done
        cpy     #fmode_r_read
        bne     L937A_CHECK_APPEND      ;Branch if not "R": the file is going to be written
        lda     V1541_ACTIV_CHAN
        cmp     #doschan_14_cmd_app
        bne     L9378_OK                ;Branch unless this is the command file channel
        dec     LDTND                   ;The command file does not take up one of the KERNAL's logical files
L9378_OK:
        sec
        rts

L937A_CHECK_APPEND:
        cpy     #fmode_a_append
        bne     L938D_OPEN_FOR_WRITE    ;Branch if not "A"
        jsr     V1541_DIR_DELETE_ENTRY  ;Append: delete the directory entry (it is added again below)...
L9381_SKIP_LOOP:
        jsr     V1541_INTERNAL_CHRIN    ;...and read to the end of the file
        lda     #doserr_71_dir_error
        bcc     L9358_ERROR
        bit     V1541_EOF
        bpl     L9381_SKIP_LOOP
L938D_OPEN_FOR_WRITE:
        jsr     V1541_SELECT_CHANNEL_GIVEN_SA
        lda     #$20                    ;$20 = open for writing, in the channel...
        tsb     V1541_ACTIV_FLAGS
        tsb     V1541_DATA_BUF          ;...and in the directory entry, which marks it as a splat file
        jmp     V1541_DIR_APPEND_ENTRY  ;Add the directory entry

; ----------------------------------------------------------------------------

;Read the next byte of a directory listing.
;
;The listing is a BASIC program, produced one line at a time in
;V1541_DATA_BUF and returned byte by byte.  V1541_DIR_STATE selects the
;part that comes next:
;   0  Start: continues with 2
;   2  Load address ($1001) and header line.  Its line number is the
;      number of blocks used by the directory itself.
;   4  One line for each file that matches V1541_DIR_PATTERN.  The line
;      number is the size of the file in blocks.
;   6  "BLOCKS USED." line.  Its line number is the size of the whole disk.
;   8  The last zero byte, with V1541_EOF set
;
;If something else has used V1541_DATA_BUF since the last byte was read
;(V1541_DIR_LINE_OK = 0), the line is produced again before carrying on.
V1541_READ_DIR_BYTE:
        lda     V1541_DIR_STATE
        bne     L93A2_STARTED
        sta     V1541_DIR_LINE_POS
L93A2_STARTED:
        ldx     V1541_DIR_LINE_POS
        beq     L93C0_NEW_LINE          ;Branch if a new line is needed
        lda     V1541_DIR_LINE_OK
        beq     L941F_MAKE_LINE         ;Branch if the line in the buffer has been lost: make it again
        lda     V1541_DATA_BUF-1,x         ;Get the next byte of the line
        inx
        tay
        bne     L93B8_RETURN            ;Branch if it is not zero
        cpx     #$0A
        bcc     L93B8_RETURN            ;Branch if it is one of the zeros in the first 9 bytes
        tax                             ;The zero that ends the line: next time, start a new line
L93B8_RETURN:
        stx     V1541_DIR_LINE_POS
        stz     V1541_EOF
        sec
        rts

L93C0_NEW_LINE:
        ldx     V1541_DIR_STATE
        jmp     (L93C6_STATE_HANDLERS,x)
L93C6_STATE_HANDLERS:
        .addr   L9414_NEXT_STATE                            ;State 0: start
        .addr   L93E4_STATE_2           ;State 2: header line
        .addr   L93E9_STATE_4           ;State 4: file lines
        .addr   L93D0_STATE_6           ;State 6: first of the two zeros that end the program
        .addr   L93D6_STATE_8           ;State 8: second zero

L93D0_STATE_6:
        ldx     #$08                    ;Next is state 8
        lda     #$00                    ;Not the end yet
        bra     L93DA_RETURN_ZERO

L93D6_STATE_8:
        ldx     #$00                    ;Next is state 0
        lda     #$FF                    ;V1541_EOF = $FF: this is the last byte
L93DA_RETURN_ZERO:
        stx     V1541_DIR_STATE
        sta     V1541_EOF
        lda     #$00
        sec
        rts

L93E4_STATE_2:
        jsr     V1541_DIR_FIRST
        bra     L93EC_CHECK_ENTRY

L93E9_STATE_4:
        jsr     V1541_DIR_NEXT
L93EC_CHECK_ENTRY:
        ldx     #$04
        stx     V1541_DIR_STATE
        bcc     L9414_NEXT_STATE                            ;Branch if there are no more entries: state 6 comes next

        lda     #<V1541_DIR_PATTERN                 ;Compare the name of the entry with V1541_DIR_PATTERN
        sta     V1541_FNADR
        lda     #>V1541_DIR_PATTERN
        stz     V1541_NAME_START
        sta     V1541_FNADR+1
        ldx     #$00
L9400_LENGTH_LOOP:
        lda     V1541_DIR_PATTERN,x
        beq     L940A_COMPARE
        inx
        cpx     #$14
        bne     L9400_LENGTH_LOOP
L940A_COMPARE:
        stx     V1541_NAME_END
        jsr     V1541_MATCH_NAME
        bcc     L93E9_STATE_4           ;Branch if the name does not match: try the next entry
        bra     L941A_START_LINE

L9414_NEXT_STATE:
        inc     V1541_DIR_STATE
        inc     V1541_DIR_STATE

L941A_START_LINE:
        lda     #$01
        sta     V1541_DIR_LINE_POS

L941F_MAKE_LINE:
        jsr     V1541_DIR_READ_AND_REWIND ;Read the directory entry (again), staying at its start
        jsr     V1541_MAKE_DIR_LINE      ;Turn it into a line of BASIC
        dec     V1541_DIR_LINE_OK       ;V1541_DIR_LINE_OK = $FF
        jmp     V1541_READ_DIR_BYTE

V1541_MAKE_DIR_LINE:
        ldx     V1541_DIR_STATE
        jmp     (V1541_DIR_LINE_HANDLERS-2,x)
V1541_DIR_LINE_HANDLERS:
        .addr   V1541_MAKE_HEADER_LINE  ;State 2
        .addr   V1541_MAKE_FILE_LINE    ;State 4
        .addr   V1541_MAKE_BLOCKS_USED_LINE ;State 6

V1541_DIR_HEADER:
        .word $1001   ;load address
        .word $1001   ;pointer to next basic line
        .word 0       ;basic line number
        .byte $12,$22,"VIRTUAL 1541    ",$22," ID 00" ;basic line text
        .byte 0       ;end of basic line

;Put the start of the BASIC program and the first BASIC line
;with the disk header in the buffer
V1541_MAKE_HEADER_LINE:
        ldx     #$1F
L9459_LOOP:
        lda     V1541_DIR_HEADER,x
        sta     V1541_DATA_BUF,x
        dex
        bpl     L9459_LOOP
        jsr     V1541_COUNT_DIR_BLOCKS  ;A = number of blocks used by the directory
        sta     V1541_DATA_BUF+4  ;basic line number low byte
        rts

V1541_DIR_BLOCKS_USED:
        .word $1001   ;pointer to next basic line
        .word 0       ;basic line number
        .byte "BLOCKS USED.            "  ;basic line text
        .byte 0       ;end of basic line
        .byte 0,0     ;end of basic program

;Put a BASIC line with the "BLOCKS USED" in the buffer
V1541_MAKE_BLOCKS_USED_LINE:
        ldx     #$1E
L948A_LOOP:
        lda     V1541_DIR_BLOCKS_USED,x
        sta     V1541_DATA_BUF,x
        dex
        bpl     L948A_LOOP
        cld
        sec
        lda     RAM_PAGES               ;Line number = number of pages between the bottom of the disk and the top of RAM
        sbc     V1541_BOTTOM_PAGE
        sta     V1541_DATA_BUF+2  ;basic line number low byte
        lda     RAM_PAGES+1
        sbc     V1541_BOTTOM_PAGE+1
        sta     V1541_DATA_BUF+3  ;basic line number high byte
        rts

;Put a BASIC line with a file in the buffer
V1541_MAKE_FILE_LINE:
        ldx     #$04                    ;Find the end of the filename
L94AA_LOOP:
        inx
        lda     V1541_DATA_BUF,x
        beq     L94B4_END_OF_NAME
        cpx     #$15
        bne     L94AA_LOOP
L94B4_END_OF_NAME:
        lda     #'"'                    ;Closing quote, then pad with spaces
L94B6_PAD_LOOP:
        sta     V1541_DATA_BUF,x
        lda     #' '
        inx
        cpx     #' '
        bne     L94B6_PAD_LOOP

        lda     V1541_DATA_BUF
        bit     #$30                    ;Open for writing (never closed)?
        beq     L94CC_NOT_SPLAT
        ldx     #'*' ;splat file like "*PRG"
        stx     V1541_DATA_BUF+22

L94CC_NOT_SPLAT:
        bit     #$80
        bne     L94D5_SPECIAL           ;Branch if it is a special ($80) entry

        jsr     V1541_COUNT_FILE_BLOCKS
        bra     L94D8_SET_SIZE

L94D5_SPECIAL:
        lda     V1541_DATA_BUF+3        ;A special entry has its size in byte 3

L94D8_SET_SIZE:
        sta     V1541_DATA_BUF+2  ;Set number of blocks used by file
                                  ;as the line number low byte
        lda     V1541_DATA_BUF
        and     #$40
        beq     L94EA_SEQ
        lda     #'P' ;ftype_p_prg
        ldx     #'R'
        ldy     #'G'
        bra     L94F0_SET_TYPE
L94EA_SEQ:
        lda     #'S' ;ftype_s_seq
        ldx     #'E'
        ldy     #'Q'
L94F0_SET_TYPE:
        sta     V1541_DATA_BUF+23   ;P    S
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
        bcs     L9515_GE_100 ;branch if >= 100
        jsr     L9522_SHIFT_BASIC_TEXT_RIGHT
L9515_GE_100:
        lda     V1541_DATA_BUF+2    ;A = size of file in blocks again
        cmp     #10
        bcc     L951F_LT_10             ;BUG: branches if < 10, the wrong way around (see below)
        jsr     L9522_SHIFT_BASIC_TEXT_RIGHT
L951F_LT_10:
        jsr     L9522_SHIFT_BASIC_TEXT_RIGHT
        ;Fall through

;Prepend one space to the beginning of the BASIC text.  The number of blocks
;is shown as the BASIC line number.  It can vary (1-3 decimal digits) so these
;spaces are added to the BASIC text to keep the filenames aligned.
;
;Between them, the code above and the fall through here shift the text 3
;times for a size under 10, 4 times for 10-99 and 3 times for 100 and up.
;To line the names up, a size under 10 needs 5.  So in a listing, the files
;of fewer than 10 blocks have their names 2 columns to the left of the rest.
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
;LOAD or VERIFY.  Devices 1 (Virtual 1541) and 4-29 (IEC) are allowed.
;
;Call with:   A = 0 for LOAD, nonzero for VERIFY
;             MEMUSS = where to load if the secondary address is 0
;
;LOAD "@name" from the Virtual 1541 moves the file into memory instead of
;copying it: each block is deleted from the disk as soon as it has been
;loaded, and the file is gone afterwards (see V1541_LOAD_AND_DELETE).
LOAD__: sta     VERCHK
        stz     SATUS
        lda     FA
        bne     L9544_NOT_DEVICE_0
        ;Device 0
L9541_BAD_DEVICE:
        jmp     ERROR9 ;BAD DEVICE #
; ----------------------------------------------------------------------------
L9544_NOT_DEVICE_0:
        cmp     #$01
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
        beq     L957A_V1541             ;Branch if device 1
        lda     #$60
        sta     SA                      ;Secondary address $60 = load
        jsr     OPENI
        lda     FA
        jsr     TALK__
        lda     SA
        jsr     TKSA
        bra     L9592_GET_LOAD_ADDRESS
; ----------------------------------------------------------------------------
L957A_V1541:
        phx
        jsr     V1541_OPEN_FOR_LOAD
        plx
        lda     SATUS
        bit     #$0C                    ;Error from the Virtual 1541?
        beq     L9592_GET_LOAD_ADDRESS
L9585_NOT_FOUND:
        jmp     ERROR4 ;FILE NOT FOUND
; ----------------------------------------------------------------------------
L9588_CLSEI_OR_ERROR16_OOM:
        lda     SA
        beq     L958F_JMP_ERROR16
        jsr     CLSEI
L958F_JMP_ERROR16:
        jmp     ERROR16 ;OUT OF MEMORY
; ----------------------------------------------------------------------------
L9592_GET_LOAD_ADDRESS:
        jsr     LOAD_GET_BYTE           ;The first two bytes of the file are its load address
        sta     EAL
        lda     #$02
        bit     SATUS
        bne     L9585_NOT_FOUND
        jsr     LOAD_GET_BYTE
        sta     EAH
        lda     WRBASE  ;Recall SA before changes
        bne     L95AF_HAVE_ADDRESS      ;Branch if the load address in the file is to be used
        lda     MEMUSS
        sta     EAL
        lda     MEMUSS+1
        sta     EAH
L95AF_HAVE_ADDRESS:
        lda     VERCHK
        bne     L95E4_VERIFY
        jsr     PRIMM80
        .byte   "LOADING",$0d,0
        lda     EAH
        cmp     #$05
        bcc     L9588_CLSEI_OR_ERROR16_OOM ;Branch if loading below $0500
        cmp     #$F8
        bcs     L9588_CLSEI_OR_ERROR16_OOM ;Branch if loading at $F800 or above
        cmp     V1541_BOTTOM_PAGE       ;Branch if loading inside the Virtual 1541...
        bcc     L95D4_ADDRESS_OK
        lda     V1541_BOTTOM_PAGE+1
        beq     L9588_CLSEI_OR_ERROR16_OOM ;...which can only happen when it reaches down into the first 64K
L95D4_ADDRESS_OK:
        lda     SA
        bne     L95F0_BYTE_LOOP_START   ;Branch if loading from IEC
        lda     V1541_NAME_PREFIX
        cmp     #$40 ;'@'
        bne     L95F0_BYTE_LOOP_START   ;Branch unless the filename started with "@"
        jsr     V1541_LOAD_AND_DELETE
        bra     L9651_LOAD_OR_VERIFY_DONE
; ----------------------------------------------------------------------------
L95E4_VERIFY:
        jsr     PRIMM80
        .byte   $0d,"VERIFY ",0
L95F0_BYTE_LOOP_START:
        lda     #$02
        trb     SATUS
        jsr     STOP_FROM_KERN
        beq     L9657_STOP_PRESSED
L95F9_BYTE_LOOP:
        jsr     LOAD_GET_BYTE
        tax
        lda     SATUS
        lsr     a
        lsr     a
        bcs     L95F9_BYTE_LOOP         ;Loop if the byte timed out
        txa
        ldy     VERCHK
        beq     L9622_STORE             ;Branch if loading
        ldy     #$00
        sta     WRBASE                ;save .A
        lda     #EAL
        sta     SINNER                  ;Verifying: compare with the byte in RAM
        jsr     GO_RAM_LOAD_GO_KERN
        cmp     WRBASE                ;compare with old .A
        beq     L963D_NEXT
        lda     #$10                    ;$10 = verify error
        jsr     UDST
        bra     L963D_NEXT
L9622_STORE:
        ldx     #$B2
        stx     GO_RAM_STORE_GO_KERN_ZP ;Make GO_RAM_STORE_GO_KERN write through EAL
        ldx     EAH
        cpx     #$F8
        bcs     L9637_OUT_OF_MEMORY     ;Don't store at $F800 or above...
        cpx     V1541_BOTTOM_PAGE
        bcc     L963A_STORE_OK          ;...or inside the Virtual 1541
        ldx     V1541_BOTTOM_PAGE+1
        bne     L963A_STORE_OK
L9637_OUT_OF_MEMORY:
        jmp     L9588_CLSEI_OR_ERROR16_OOM
; ----------------------------------------------------------------------------
L963A_STORE_OK:
        jsr     GO_RAM_STORE_GO_KERN
L963D_NEXT:
        inc     EAL
        bne     L9643_NO_CARRY
        inc     EAH
L9643_NO_CARRY:
        bit     SATUS
        bvc     L95F9_BYTE_LOOP         ;Loop until end of file
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
        bne     L965E_JMP_ERROR0
        jsr     CLSEI
L965E_JMP_ERROR0:
        jmp     ERROR0  ;OK
; ----------------------------------------------------------------------------
;Get the next byte of the file being loaded.
LOAD_GET_BYTE:
        lda     SA
        beq     L9668_V1541
        jmp     ACPTR
L9668_V1541:
        jmp     V1541_LOAD_GET_BYTE
; ----------------------------------------------------------------------------
;Open a file on the Virtual 1541 for LOAD.  Channel 17 is used.
;The filename is at FNADR, FNLEN.  "$" loads a directory listing.
V1541_OPEN_FOR_LOAD:
        jsr     V1541_INTERNAL_OPEN_FOR_LOAD
        jmp     V1541_KERNAL_CALL_DONE
; ----------------------------------------------------------------------------
V1541_INTERNAL_OPEN_FOR_LOAD:
        jsr     V1541_PARSE_FNADR
        bcc     L969A_ERROR             ;Branch if the filename can't be parsed
        bit     #$20
        bne     L969A_ERROR             ;Branch if the name is followed by "="

        ldx     V1541_NAME_PREFIX
        cpx     #'$'
        bne     L969C_NOT_DIRECTORY

        ;Opening the directory

        ldx     V1541_FILE_MODE
        bne     L9698_ERROR_34_SYNTAX_ERROR ;A mode is not allowed with "$"

        jsr     V1541_SETUP_DIR_LISTING ;Set the pattern of the names to list
        jsr     V1541_SELECT_LOAD_CHANNEL_AND_CLEAR_IT
        lda     #$40                    ;$40 = PRG: the listing is a BASIC program
        tsb     V1541_ACTIV_FLAGS
        bra     L96C0_SET_READING

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

L969C_NOT_DIRECTORY:
        jsr     V1541_DIR_FIND_NAME
        bcc     L969A_ERROR             ;Branch if there is no file with that name

        lda     V1541_DATA_BUF
        bit     #$20
        bne     L9695_ERROR_60_WRITE_FILE_OPEN ;Branch if it is open for writing or was never closed
        bit     #$80
        bne     L96B1                   ;Branch if it is a special ($80) entry: it has no checksum
        jsr     V1541_VERIFY_FILE_CHECKSUM
        bcc     L969A_ERROR             ;Branch if the file's checksum is wrong
L96B1:  jsr     V1541_CHECK_FILE_TYPE
        bcc     L969A_ERROR
        cpx     #ftype_s_seq
        beq     L9692_ERROR_64_FILE_TYPE_MISMATCH ;Only a PRG file can be loaded
        jsr     V1541_SELECT_LOAD_CHANNEL_AND_CLEAR_IT
        jsr     V1541_ENTRY_TO_CHANNEL  ;Channel gets the flags and file id from the directory entry

L96C0_SET_READING:
        lda     #$10                    ;$10 = open for reading
        tsb     V1541_ACTIV_FLAGS
        lda     V1541_NAME_PREFIX
        cmp     #$40 ;'@'
        bne     L96D1_NO_PREFIX         ;Forget the prefix unless it is "@"...
        lda     V1541_ACTIV_FLAGS
        and     #$80
        beq     L96D4_DONE              ;...on an ordinary file, where it selects V1541_LOAD_AND_DELETE
L96D1_NO_PREFIX:
        stz     V1541_NAME_PREFIX
L96D4_DONE:
        sec
        rts
; ----------------------------------------------------------------------------
;Load a file from the Virtual 1541 by moving it: each block is deleted from
;the disk as soon as it has been copied to memory, so the file never needs
;space in memory and on the disk at the same time.  The file and its
;directory entry are gone afterwards.
;Called only from LOAD, for a filename that starts with "@".
;
;BUG: the bytes are stored with GO_RAM_STORE_GO_KERN, but nothing here makes it
;write through EAL.  It only stores in the right place if the last thing to
;set GO_RAM_STORE_GO_KERN_ZP was the byte loop of an ordinary LOAD.
V1541_LOAD_AND_DELETE:
        stz     V1541_ACTIV_SEQ
        dec     V1541_ACTIV_SEQ         ;Sequence number $FF, so the loop starts with block 0
L96DA_BLOCK_LOOP:
        inc     V1541_ACTIV_SEQ
        jsr     V1541_FIND_AND_DELETE_BLOCK ;Find the next block and delete it
        bcc     L9719_DONE              ;Branch if there are no more blocks
L96E1_COPY_BLOCK:
        ldx     V1541_BOTTOM_PAGE+1
        lda     V1541_BOTTOM_PAGE
        bne     L96EA
        dex
L96EA:  dec     a
        jsr     MAP_RAM_PAGE            ;Its data is now in the page just below the disk: map that page
        ldy     #$02
        lda     (MAPPED_PAGE_PTR),y
        bne     L96F5_SET_END           ;A = offset of the last byte in use, or $FF for a full block
        dec     a
L96F5_SET_END:
        sta     V1541_TMP
        lda     V1541_ACTIV_SEQ
        bne     L9703_BYTE_LOOP         ;Branch unless this is block 0
L96FB_BLOCK_0:
        lda     V1541_ACTIV_FLAGS
        and     #$40
        beq     L9703_BYTE_LOOP         ;Branch if it is not a PRG
        iny
        iny                             ;Skip the load address
L9703_BYTE_LOOP:
        iny
        lda     (MAPPED_PAGE_PTR),y
        phy
        ldy     #$00
        jsr     GO_RAM_STORE_GO_KERN
        inc     EAL
        bne     L9712_NO_CARRY
        inc     EAH
L9712_NO_CARRY:
        ply
        cpy     V1541_TMP
        bne     L9703_BYTE_LOOP
        bra     L96DA_BLOCK_LOOP
; ----------------------------------------------------------------------------
L9719_DONE:
        jsr     V1541_DELETE_FILE_BLOCKS ;Delete any blocks that are left...
        jmp     V1541_DIR_DELETE_ENTRY  ;...and the directory entry

;Read the next byte of the file being loaded from the Virtual 1541.
V1541_LOAD_GET_BYTE:
        jsr     V1541_INTERNAL_LOAD_GET_BYTE
        jmp     V1541_KERNAL_CALL_DONE
; ----------------------------------------------------------------------------
V1541_INTERNAL_LOAD_GET_BYTE:
        jsr     V1541_SELECT_LOAD_CHANNEL ;Select the channel used by LOAD
        bcc     L972D_RTS ;branch if error
        jsr     V1541_READ_BYTE         ;Read a byte from it
L972D_RTS:
        rts
; ----------------------------------------------------------------------------
;Check that there is space in V1541_CMD_BUF for another character.
;Call with Y = number of characters in the buffer.
;Returns carry set if Y < 60, or carry clear and A=32 if not.
V1541_CHECK_CMD_LEN:
        lda     #doserr_32_syntax_err
        cpy     #$3C                    ;Carry set if Y >= 60
        rol     a                       ;Invert the carry without changing A
        eor     #$01
        ror     a
        rts
; ----------------------------------------------------------------------------
;OPEN the command channel (15).  The filename, if any, is a command.
V1541_OPEN_CMD_CHAN:
        jsr     V1541_SELECT_CHANNEL_GIVEN_SA
        lda     #$10
        tsb     V1541_ACTIV_FLAGS       ;BUG: $10 = open for reading (the status message), not for writing.  See V1541_CHROUT_CMD_CHAN.
        ldy     FNLEN
        sty     V1541_CMD_LEN
        jsr     V1541_CHECK_CMD_LEN
        bcs     L974A_COPY_COMMAND ;branch if no error
L9749_RTS:
        rts
; ----------------------------------------------------------------------------
L974A_COPY_COMMAND:
        lda     #FNADR
        sta     SINNER
        dey
        bmi     L9749_RTS               ;Branch if there is no command
L9752_LOOP:
        jsr     GO_RAM_LOAD_GO_KERN
        sta     V1541_CMD_BUF,y
        dey
        bpl     L9752_LOOP
        bra     V1541_PERFORM_CMD

;CHROUT to the command channel (15).  Characters would collect in
;V1541_CMD_BUF until a carriage return, which performs the command.
;
;This is never reached, because of the bug in V1541_OPEN_CMD_CHAN: it marks
;channel 15 as open for reading only ($10), and V1541_INTERNAL_CHROUT stops
;with error 61, FILE NOT OPEN, for a channel that is not open for writing
;($20).  So a command sent with PRINT# fails, and commands can only be sent
;as the filename of an OPEN.  $30 was probably meant in V1541_OPEN_CMD_CHAN.
;
;BUG: (latent) if this code were reached, it would have two problems of its
;own.  The carriage return is left in the buffer and counted, so the commands
;that parse a filename (R and S) would reject it as a bad character and fail.
;And the buffer is only emptied by I and by opening channel 15, so the next
;command would be added to the end of the buffer.
V1541_CHROUT_CMD_CHAN:
        ldy     V1541_CMD_LEN
        jsr     V1541_CHECK_CMD_LEN
        bcs     L9766_STORE                      ;branch if no error
        rts
; ----------------------------------------------------------------------------
L9766_STORE:
        sta     V1541_CMD_BUF,Y
        inc     V1541_CMD_LEN
        cmp     #$0D ;CR?
        beq     V1541_PERFORM_CMD
        sec
        rts

;Perform the command in V1541_CMD_BUF.  The first character selects the
;command.  The rest is parsed as a filename before the handler is called,
;so the handler gets the result of V1541_PARSE_NAME in A and the carry.
V1541_PERFORM_CMD:
        lda     V1541_CMD_BUF
        ldx     #(4*2)-1 ;4 cmds in table, two chars each
L9777_SEARCH_LOOP:
        cmp     V1541_CMDS,x
        beq     L9783_FOUND
        dex
        bpl     L9777_SEARCH_LOOP
        lda     #doserr_31_invalid_cmd
        clc
        rts

L9783_FOUND:
        txa
        and     #$FE                    ;X = index of the handler (each command letter is in the table twice: uppercase and lowercase)
        pha
        jsr     V1541_PARSE_CMD_ARG
        plx
        jmp     (V1541_CMD_HANDLERS,x)

V1541_CMDS:
        .byte "Ii", "Rr", "Ss", "Vv"
V1541_CMD_HANDLERS:
        .addr V1541_I_INITIALIZE
        .addr V1541_R_RENAME
        .addr V1541_S_SCRATCH
        .addr V1541_V_VALIDATE

;Parse everything after the first character of V1541_CMD_BUF as a filename.
V1541_PARSE_CMD_ARG:
        ldy     V1541_CMD_LEN
        dey
        lda     #<(V1541_CMD_BUF+1)
        ldx     #>(V1541_CMD_BUF+1)
        jmp     V1541_PARSE_NAME_AXY

;Find the old file for rename: parse the part of the command that follows
;the "=" as a filename and look it up in the directory.
;Returns the same as V1541_DIR_FIND_NAME, or carry clear and A=33.
V1541_FIND_OLD_NAME:
        jsr     V1541_PARSE_CMD_ARG
L97AC_LOOP:
        lda     (V1541_FNADR)
        inc     V1541_FNADR
        bne     L97B4_NO_CARRY
        inc     V1541_FNADR+1
L97B4_NO_CARRY:
        dec     V1541_FNLEN
        beq     L97D2_33_SYNTAX_ERROR   ;Branch if there is no "=", or nothing after it
        cmp     #'='
        bne     L97AC_LOOP
        jsr     V1541_PARSE_NAME
        bcc     L97D4_CLC_RTS
        and     #$40
        ora     V1541_FILE_TYPE
        ora     V1541_FILE_MODE
        ora     V1541_NAME_PREFIX
        bne     L97D2_33_SYNTAX_ERROR   ;Branch if it has a wildcard, a type, a mode or a prefix
        jmp     V1541_DIR_FIND_NAME
; ----------------------------------------------------------------------------

L97D2_33_SYNTAX_ERROR:
        lda     #doserr_33_syntax_err ;Invalid filename
L97D4_CLC_RTS:
        clc
        rts
; ----------------------------------------------------------------------------
;"S" command: scratch (delete) every file that matches the name.
;The status afterwards is 01, FILES SCRATCHED, with the number of files
;deleted as the track number.
V1541_S_SCRATCH:
        bcs     L97DC_PARSED_OK
L97D8_SCRATCH_NO_FILENAME:
        lda     #doserr_34_syntax_err ;34 No file given
        clc
        rts

L97DC_PARSED_OK:
        bit     #$80
        beq     L97D8_SCRATCH_NO_FILENAME ;Branch if there is no name
        and     #$20
        ora     V1541_FILE_TYPE
        ora     V1541_FILE_MODE
        bne     L97D8_SCRATCH_NO_FILENAME ;Branch if there is an "=", a type or a mode
        lda     #$00
        pha                             ;Push the count of files scratched
L97ED_LOOP:
        jsr     V1541_DIR_FIND_NAME
        bcc     L9805_DONE              ;Branch if there are no more files that match
        tsx
        inc     stack+1,x               ;Count it
        jsr     V1541_DIR_DELETE_ENTRY  ;Delete its directory entry
        lda     V1541_DATA_BUF
        and     #$80
        bne     L97ED_LOOP              ;Branch if it is a special ($80) entry: it has no blocks
        jsr     V1541_DELETE_FILE_BLOCKS ;Delete its blocks
        bra     L97ED_LOOP

L9805_DONE:
        pla                             ;A = number of files scratched, reported as the track
        ldx     #doserr_01_files_scratched
        ldy     #$00
        sec
        jmp     V1541_SET_STATUS

; ----------------------------------------------------------------------------
;"R" command: rename a file.  The command is R[0:]newname=oldname.
V1541_R_RENAME:
        bcc     L9840_RENAME_ERROR
        bit     #$80
        beq     L983E_RENAME_INVALID_FILENAME ;Branch if there is no new name
        and     #$40
        ora     V1541_NAME_PREFIX
        ora     V1541_FILE_MODE
        ora     V1541_FILE_TYPE
        bne     L983E_RENAME_INVALID_FILENAME ;Branch if the new name has a wildcard, a prefix, a mode or a type

        jsr     V1541_DIR_FIND_NAME     ;The new name must not be in use
        lda     #doserr_63_file_exists
        bcs     L9840_RENAME_ERROR ;branch if no error (file exists, which is an error here)

        jsr     V1541_FIND_OLD_NAME     ;Find the old file
        bcc     L9840_RENAME_ERROR

        jsr     V1541_PARSE_CMD_ARG     ;Parse the new name again...
        jsr     V1541_COPY_NAME_TO_ENTRY ;...and put it in the old file's directory entry

L9833_ADD:
        jsr     V1541_DIR_ADD_ENTRY     ;Add that entry to the directory
        bcc     L9840_RENAME_ERROR

        jsr     V1541_FIND_OLD_NAME     ;Find the old entry again...
        jmp     V1541_DIR_DELETE_ENTRY  ;...and delete it

L983E_RENAME_INVALID_FILENAME:
        lda     #doserr_33_syntax_err ;33 Invalid filename
L9840_RENAME_ERROR:
        clc
        rts

; ----------------------------------------------------------------------------
;"V" command: validate.  In practice this erases the disk.
;
;  - If the amount of RAM has changed, or the bottom of the disk is out of
;    bounds, the disk is made empty.
;    BUG: the bounds check compares X, the high byte of the RAM size, with
;    the low byte of V1541_BOTTOM_PAGE where the high byte was meant (compare
;    V1541_CHECK_DISK_INTACT).  On a 128K machine this erases any disk that
;    holds between 1 and 254 blocks.
;
;  - Otherwise four passes are made, and they have bugs of their own:
;
;    1. Meant to cut off a damaged end of the directory.
;       BUG: as written, it cuts the directory off after its second entry.
;    2. Meant to delete the entries of files that have blocks missing.
;       BUG: for the first entry, the file id is never loaded, so the blocks
;       of the directory itself are counted.  After that, V1541_DIR_NEXT is
;       called on the channel that was used to check the file, so it reads
;       that file instead of the directory.
;    3. Meant to make a bitmap of the file ids in use, delete entries with
;       duplicate ids, and bring the checksums and splat flags up to date.
;       BUG: A is never loaded with the file id before it is looked up in the
;       bitmap.  It holds 0, the id of the directory, which is always marked
;       as in use, so every entry is taken for a duplicate and deleted.
;    4. Deletes every block whose file id is not in the bitmap.  After
;       pass 3 that is every block except the directory.
;
;  - BUG: the first passes read the directory through channel 14, which
;    V1541_I_INITIALIZE leaves selected.  That is also the channel of a
;    command file, so a command file that is being read continues from the
;    wrong position.
V1541_V_VALIDATE:
        jsr     V1541_I_INITIALIZE      ;Close all channels but 14, which stays selected and is used by the passes below
        jsr     KL_RAMTAS               ;A/X = number of RAM pages present
        cpx     RAM_PAGES+1
        beq     L985B_SAME_HIGH         ;Branch if the high byte is the same as before

L984D_ERASE:
        stx     RAM_PAGES+1
        sta     RAM_PAGES
        stx     V1541_BOTTOM_PAGE+1
        sta     V1541_BOTTOM_PAGE       ;Empty disk: its bottom is the top of RAM
        sec
        rts

L985B_SAME_HIGH:
        cmp     RAM_PAGES
        bne     L984D_ERASE             ;Branch if the amount of RAM has changed
        cpx     V1541_BOTTOM_PAGE       ;BUG: should compare with V1541_BOTTOM_PAGE+1
        bcc     L984D_ERASE
        bne     L986C_PASS_1
        cmp     V1541_BOTTOM_PAGE
        bcc     L984D_ERASE
L986C_PASS_1:
        jsr     V1541_DIR_FIRST
        bne     L9890_PASS_2            ;BUG: never branches, because V1541_DIR_FIRST always returns Z=1
L9871_LOOP:
        jsr     V1541_DIR_NEXT
        bcc     L988B_NO_ENTRY          ;Branch if no entry was read
        jsr     V1541_SWAP_POSITION
        jsr     V1541_FIND_BLOCK
        ldy     #$02
        lda     V1541_ACTIV_OFFS
        sta     (MAPPED_PAGE_PTR),y     ;Make this the end of the directory...
L9882_DELETE_LOOP:
        inc     V1541_ACTIV_SEQ
        beq     L9890_PASS_2
        jsr     V1541_FIND_AND_DELETE_BLOCK ;...and delete all of its blocks that follow
        bra     L9882_DELETE_LOOP
L988B_NO_ENTRY:
        bit     V1541_EOF
        bpl     L9871_LOOP              ;Loop unless that was the end of the directory
L9890_PASS_2:
        jsr     V1541_DIR_FIRST
        bcc     L98D0_PASS_3
        bra     L98AB_BLOCK_LOOP
L9897_NEXT_ENTRY:
        jsr     V1541_DIR_NEXT
        bcc     L98D0_PASS_3 ;branch if error
        jsr     V1541_SELECT_LOAD_CHANNEL_AND_CLEAR_IT
        lda     V1541_DATA_BUF
        bit     #$80
        bne     L98B4_DELETE_ENTRY      ;Branch if it is a special ($80) entry: delete it
        lda     V1541_DATA_BUF+1
        sta     V1541_ACTIV_ID
L98AB_BLOCK_LOOP:
        jsr     V1541_FIND_BLOCK
        bcs     L98B9_BLOCK_FOUND       ;Branch if the block exists
        ;error
        lda     V1541_ACTIV_SEQ
        beq     L9897_NEXT_ENTRY        ;Branch if the file has no blocks at all: that is allowed
L98B4_DELETE_ENTRY:
        jsr     V1541_DIR_DELETE_ENTRY
        bra     L9890_PASS_2

L98B9_BLOCK_FOUND:
        inc     V1541_ACTIV_SEQ
        ldy     #$02
        lda     (MAPPED_PAGE_PTR),y
        beq     L98AB_BLOCK_LOOP        ;Loop if it is a full block: there should be another
        lda     V1541_ACTIV_SEQ
        pha
        jsr     V1541_COUNT_FILE_BLOCKS
        sta     V1541_ACTIV_SEQ ;store number of blocks used
        pla
        cmp     V1541_ACTIV_SEQ         ;The last block's number + 1 must be the number of blocks the file has
        bne     L98B4_DELETE_ENTRY
        bra     L9897_NEXT_ENTRY
L98D0_PASS_3:
        ldx     #$3F
L98D2_CLEAR_LOOP:
        stz     V1541_CMD_BUF,x         ;Clear the bitmap of file ids in use (512 bits; only 256 are needed)
        dex
        bpl     L98D2_CLEAR_LOOP
        inc     V1541_CMD_BUF           ;File 0, the directory, is in use
        jsr     V1541_DIR_FIRST
        bcc     L9917_PASS_4
        bra     L98E5_FIRST
L98E2_DELETE_DUPLICATE:
        jsr     V1541_DIR_DELETE_ENTRY
L98E5_FIRST:
        jsr     V1541_DIR_FIRST
        bra     L98ED_CHECK
L98EA_NEXT:
        jsr     V1541_DIR_NEXT
L98ED_CHECK:
        bcc     L9917_PASS_4            ;Branch if there are no more entries
        jsr     V1541_ID_TO_BIT         ;BUG: A should be the file id (V1541_DATA_BUF+1), but it is 0
        and     V1541_CMD_BUF,y
        bne     L98E2_DELETE_DUPLICATE  ;Branch if the id is already marked: delete the entry and start over
        lda     PowersOfTwo,x
        ora     V1541_CMD_BUF,y
        sta     V1541_CMD_BUF,y         ;Mark the id as in use
        lda     #$30
        trb     V1541_DATA_BUF
        bne     L990F_REWRITE_ENTRY     ;Branch if the file was never closed
        lda     V1541_DATA_BUF+1
        jsr     V1541_VERIFY_FILE_CHECKSUM
        bcs     L98EA_NEXT              ;Branch if the file's checksum is right
        ;error occurred
L990F_REWRITE_ENTRY:
        jsr     V1541_DIR_DELETE_ENTRY  ;Delete the entry...
        jsr     V1541_DIR_ADD_ENTRY     ;...and add it again with a new checksum and the splat flag cleared
        bra     L98D0_PASS_3
L9917_PASS_4:
        jsr     V1541_FIRST_BLOCK
        beq     L9930_DONE
L991C_LOOP:
        lda     (MAPPED_PAGE_PTR)       ;A = file id of this block
        jsr     V1541_ID_TO_BIT
        and     V1541_CMD_BUF,y
        bne     L992B_KEEP              ;Branch if its id is in use
        jsr     V1541_DELETE_BLOCK      ;Delete the block and start over from the bottom
        bra     L9917_PASS_4
L992B_KEEP:
        jsr     V1541_NEXT_BLOCK
        bcs     L991C_LOOP
L9930_DONE:
        sec
        rts
; ----------------------------------------------------------------------------
;Turn a file id into a position in the bitmap of ids.
;Call with A = id.  Returns Y = index of the byte, X = number of the bit,
;A = mask for the bit.
V1541_ID_TO_BIT:
        pha
        lsr     a
        lsr     a
        lsr     a
        tay
        pla
        and     #$07
        tax
        lda     PowersOfTwo,x
        rts
; ----------------------------------------------------------------------------
;Every Virtual 1541 call made by the KERNAL (open, close, chrin, chrout,
;save, load) ends up here to turn the result of the internal routine into
;what the KERNAL expects.
;
;Call with:   Carry set = success; A = the byte that was read, if any
;             Carry clear = failure; A = CBM DOS error number
;Returns:     Carry clear
;             A = the byte that was read, or a carriage return on failure
;             SATUS = $40 if V1541_EOF was set (end of file), plus $04 on
;                     failure, plus $08 if the failure was error 25
;             On failure the error number, file id and block sequence
;             number become the status message (see V1541_CHRIN_CMD_CHAN).
V1541_KERNAL_CALL_DONE:
        tax ;Save error code in X
        lda     #$00
        bcs     L9955_SET_STATUS ;branch if no error

        ;error occurred
        lda     V1541_ACTIV_ID
        ldy     V1541_ACTIV_SEQ
        jsr     V1541_SET_STATUS           ;Error number, with the file id and sequence number as track and sector
        lda     #$04
        cpx     #doserr_25_write_err ;25 write-verify error
        bne     L9953_NOT_25
        ora     #$08
L9953_NOT_25:
        ldx     #$0D                    ;Return a carriage return
L9955_SET_STATUS:
        bit     V1541_EOF
        bpl     L995C_NOT_EOF
        ora     #$40 ;EOF
L995C_NOT_EOF:
        sta     SATUS
        stz     V1541_EOF
        txa
L9962_CLC_RTS:
        clc
        rts
; ----------------------------------------------------------------------------
;Set the status that will be read from the command channel:
;X = error number, A = track, Y = sector.
V1541_SET_STATUS:
        stx     V1541_ERR_CODE
        sta     V1541_ERR_TRACK
        sty     V1541_ERR_SECTOR

        stz     V1541_ERR_POS           ;The next read starts at the beginning of the message
        rts
; ----------------------------------------------------------------------------
;Words used in the status messages.  Each errw_ constant is the offset of a
;word from V1541_ERROR_WORDS-1, which is how V1541_ERROR_MSGS refers to it.
V1541_ERROR_WORDS:
errw_channel   = * - V1541_ERROR_WORDS + 1
        .byte   "CHANNEL",0
errw_command   = * - V1541_ERROR_WORDS + 1
        .byte   "COMMAND",0
errw_directory = * - V1541_ERROR_WORDS + 1
        .byte   "DIRECTORY",0
errw_disk      = * - V1541_ERROR_WORDS + 1
        .byte   "DISK",0
errw_dos       = * - V1541_ERROR_WORDS + 1
        .byte   "DOS",0
errw_error     = * - V1541_ERROR_WORDS + 1
        .byte   "ERROR",0
errw_exists    = * - V1541_ERROR_WORDS + 1
        .byte   "EXISTS",0
errw_file      = * - V1541_ERROR_WORDS + 1
        .byte   "FILE",0
errw_files     = * - V1541_ERROR_WORDS + 1
        .byte   "FILES",0
errw_found     = * - V1541_ERROR_WORDS + 1
        .byte   "FOUND",0
errw_full      = * - V1541_ERROR_WORDS + 1
        .byte   "FULL",0
errw_illegal   = * - V1541_ERROR_WORDS + 1
        .byte   "ILLEGAL",0
errw_invalid   = * - V1541_ERROR_WORDS + 1
        .byte   "INVALID",0
errw_large     = * - V1541_ERROR_WORDS + 1
        .byte   "LARGE",0
errw_line      = * - V1541_ERROR_WORDS + 1
        .byte   "LINE",0
errw_long      = * - V1541_ERROR_WORDS + 1
        .byte   "LONG",0
errw_mismatch  = * - V1541_ERROR_WORDS + 1
        .byte   "MISMATCH",0
errw_no        = * - V1541_ERROR_WORDS + 1
        .byte   "NO",0
errw_not       = * - V1541_ERROR_WORDS + 1
        .byte   "NOT",0
errw_ok        = * - V1541_ERROR_WORDS + 1
        .byte   "OK",0
errw_open      = * - V1541_ERROR_WORDS + 1
        .byte   "OPEN",0
errw_protect   = * - V1541_ERROR_WORDS + 1
        .byte   "PROTECT",0
errw_read      = * - V1541_ERROR_WORDS + 1
        .byte   "READ",0
errw_scratched = * - V1541_ERROR_WORDS + 1
        .byte   "SCRATCHED",0
errw_syntax    = * - V1541_ERROR_WORDS + 1
        .byte   "SYNTAX",0
errw_system    = * - V1541_ERROR_WORDS + 1
        .byte   "SYSTEM",0
errw_ts        = * - V1541_ERROR_WORDS + 1
        .byte   "T&S",0
errw_too       = * - V1541_ERROR_WORDS + 1
        .byte   "TOO",0
errw_type      = * - V1541_ERROR_WORDS + 1
        .byte   "TYPE",0
errw_verify    = * - V1541_ERROR_WORDS + 1
        .byte   "VERIFY",0
errw_write     = * - V1541_ERROR_WORDS + 1
        .byte   "WRITE",0

;Status messages.  Each is an error number followed by the offsets of up to
;three words (0 = no word).  There is no end marker.  For an error number
;that is not here, the search in V1541_CHRIN_CMD_CHAN continues through
;whatever follows, until a byte happens to match or its index wraps around.
;Every error that the Virtual 1541 reports is in the table, though.
V1541_ERROR_MSGS:
        .byte   doserr_00_ok, errw_ok, 0, 0                                         ;00, OK
        .byte   doserr_01_files_scratched, errw_files, errw_scratched, 0            ;01, FILES SCRATCHED
        .byte   doserr_20_read_err, errw_illegal, errw_ts, 0                        ;20, ILLEGAL T&S
        .byte   doserr_25_write_err, errw_write, errw_verify, errw_error            ;25, WRITE VERIFY ERROR
        .byte   doserr_26_write_prot_on, errw_write, errw_protect, errw_error       ;26, WRITE PROTECT ERROR
        .byte   doserr_27_read_error, errw_read, errw_error, 0                      ;27, READ ERROR
        .byte   doserr_31_invalid_cmd, errw_invalid, errw_command, 0                ;31, INVALID COMMAND
        .byte   doserr_32_syntax_err, errw_long, errw_line, 0                       ;32, LONG LINE
        .byte   doserr_33_syntax_err, errw_syntax, errw_error, 0                    ;33, SYNTAX ERROR
        .byte   doserr_33_syntax_err, errw_syntax, errw_error, 0                    ;33 again (never reached)
        .byte   doserr_34_syntax_err, errw_syntax, errw_error, 0                    ;34, SYNTAX ERROR
        .byte   doserr_39_syntax_err, errw_syntax, errw_error, 0                    ;39, SYNTAX ERROR
        .byte   doserr_52_file_too_large, errw_file, errw_too, errw_large           ;52, FILE TOO LARGE
        .byte   doserr_60_write_file_open, errw_write, errw_file, errw_open         ;60, WRITE FILE OPEN
        .byte   doserr_61_file_not_open, errw_file, errw_not, errw_open             ;61, FILE NOT OPEN
        .byte   doserr_62_file_not_found, errw_file, errw_not, errw_found           ;62, FILE NOT FOUND
        .byte   doserr_63_file_exists, errw_file, errw_exists, 0                    ;63, FILE EXISTS
        .byte   doserr_64_file_type_mism, errw_file, errw_type, errw_mismatch       ;64, FILE TYPE MISMATCH
        .byte   doserr_67_illegal_sys_ts, errw_illegal, errw_system, errw_ts        ;67, ILLEGAL SYSTEM T&S
        .byte   doserr_70_no_channel, errw_no, errw_channel, 0                      ;70, NO CHANNEL
        .byte   doserr_71_dir_error, errw_directory, errw_error, 0                  ;71, DIRECTORY ERROR
        .byte   doserr_71_dir_error, errw_directory, errw_error, 0                  ;71 again (never reached)
        .byte   doserr_72_disk_full, errw_disk, errw_full, 0                        ;72, DISK FULL
        .byte   doserr_73_dos_mismatch, errw_dos, errw_mismatch, errw_error         ;73, DOS MISMATCH ERROR

;Positions in the status message that are not part of the words.  Positions
;3 and up are the words.  When the words run out, the position jumps to $80.
V1541_STATUS_POSITIONS:
        .byte   $00,$01,$02             ;Error number and a comma
        .byte   $80,$81,$82,$83         ;Track and a comma
        .byte   $84,$85,$86,$87         ;Sector and the end
        .byte   $88                     ;Never reached

;What to return at each of the positions above:
;  Bits 0-1: which number (1 = error, 2 = track, 3 = sector)
;  Bit 7 = its ones digit, bit 6 = its tens digit, neither = its hundreds digit
;  Bit 4 = a comma instead
;  $00 = carriage return, end of message
V1541_STATUS_FORMATS:
        .byte   $41,$81,$10             ;Error number (2 digits) and a comma
        .byte   $22,$42,$82,$10         ;Track (3 digits) and a comma
        .byte   $23,$43,$83,$00         ;Sector (3 digits) and the end
; ----------------------------------------------------------------------------
;CHRIN from the command channel (15): return the next character of the
;status message.  The message looks like this:
;
;   62,FILE NOT FOUND,000,000
;
;The two-digit error number, the words that go with it, a three-digit track
;and a three-digit sector, then a carriage return with V1541_EOF set.  After
;the carriage return the status is reset to 00,OK,000,000.
V1541_CHRIN_CMD_CHAN:
        lda     V1541_ERR_POS
        inc     V1541_ERR_POS
        ldy     #$0B
L9AAD_SEARCH_LOOP:
        cmp     V1541_STATUS_POSITIONS,y
        beq     L9AB8_FOUND
        dey
        bpl     L9AAD_SEARCH_LOOP
        jmp     L9AE8_WORDS              ;Branch if this position is part of the words
; ----------------------------------------------------------------------------
L9AB8_FOUND:
        lda     V1541_STATUS_FORMATS,y
        bne     L9ACD_NOT_END           ;Branch unless this is the end of the message
        tax
        tay
        jsr     V1541_SET_STATUS           ;Reset the status to 00,OK,000,000
        sec
        ror     V1541_EOF                   ;V1541_EOF bit 7 = this is the last character
        lda     #$0d ;cr
        .byte $2c
L9AC9_COMMA:
        lda     #$2C ;,
        sec
        rts
; ----------------------------------------------------------------------------
L9ACD_NOT_END:
        bit     #$10
        bne     L9AC9_COMMA             ;Branch if this position is a comma
        sta     V1541_TMP
        and     #$03                    ;X = which number: 1 = error, 2 = track, 3 = sector
        tax
        lda     V1541_ERR_CODE-1,x
        jsr     BIN_TO_BCD_NIBS
        bit     V1541_TMP
        bmi     L9AE4_DIGIT             ;Branch if this position is the ones digit
        txa
        bvs     L9AE4_DIGIT             ;Branch if this position is the tens digit
        tya                             ;Otherwise it is the hundreds digit
L9AE4_DIGIT:
        ora     #$30
        sec
        rts
; ----------------------------------------------------------------------------
L9AE8_WORDS:
        dec     a                       ;V1541_TMP counts down to the character wanted.  The space before the
        sta     V1541_TMP               ;first word would be position 2, which is the comma, so it never appears.
        ldx     #$00
        lda     V1541_ERR_CODE
L9AF0_FIND_MSG_LOOP:
        inx
        inx
        inx
        inx
        beq     L9B12_END_OF_WORDS      ;Branch if the error number is not in the table: no words
        cmp     V1541_ERROR_MSGS-4,x
        bne     L9AF0_FIND_MSG_LOOP
L9AFB_WORD_LOOP:
        lda     #$20                    ;Each word is preceded by a space
        ldy     V1541_ERROR_MSGS-3,x
        beq     L9B12_END_OF_WORDS      ;Branch if there are no more words
L9B02_CHAR_LOOP:
        dec     V1541_TMP
        beq     L9B19_RETURN            ;Branch if this is the character wanted
        iny
        lda     V1541_ERROR_WORDS-2,y
        bne     L9B02_CHAR_LOOP         ;Loop until the 0 that ends the word
        inx
        txa
        and     #$03
        bne     L9AFB_WORD_LOOP         ;Loop for up to 3 words
L9B12_END_OF_WORDS:
        lda     #$80                    ;Position $80 is the first digit of the track
        sta     V1541_ERR_POS
        lda     #$2C                    ;Return the comma that follows the words
L9B19_RETURN:
        sec
        rts
; ----------------------------------------------------------------------------
;Floating point math package.  This is jump table entry $FF51.
;
;Call with X = a function code from the table below.  A, Y and the flags
;are passed on to the function.
;
;This is the floating point code of Microsoft BASIC, as found in other CBM
;machines, but with the mantissa widened from 4 bytes to 7 (about 16 decimal
;digits).  The routines are named after their counterparts in those BASICs.
;
;FAC is the accumulator and ARG is the second operand.  A number in memory
;is packed into 8 bytes: the exponent, then the 7 bytes of the mantissa with
;the sign in bit 7 of the first one.
;
;Where a function takes a number or a string in memory, its address is given
;in A (low) and Y (high).  Most functions read it in MMU RAM mode, where all
;64K is RAM.  The ones marked "KERN" read it as the KERNAL sees memory (for
;the constants in this ROM), and the ones marked "APPL" read it as the
;application sees memory (for constants in an application's ROM).
;
;An error jumps through the vector at IERROR, in MMU APPL mode, with the
;BASIC error number in X: 14 = illegal quantity, 15 = overflow, 20 = division
;by zero.  It is up to the application to set that vector.
MATH_DISPATCH:
        jmp     (MATH_FUNCTIONS,x)
MATH_FUNCTIONS:
        .addr AYINT                     ;$00 FAC to signed 16-bit integer in FACHO+5 (high) and FACLO (low)
        .addr GIVAYF                    ;$02 FAC = signed 16-bit integer in A (high) and Y (low)
        .addr FOUT                      ;$04 FAC to string at FBUFFR; returns its address in A/Y
        .addr STRVAL                    ;$06 FAC = value of the string at INDEX1 with length A
        .addr GETADR                    ;$08 FAC to unsigned 16-bit integer in LINNUM, A (high) and Y (low)
        .addr FLOATC_Y                  ;$0A FAC = 16-bit integer in FACHO, FACHO+1 with exponent Y; carry clear = negate
        .addr FSUB                      ;$0C FAC = number in memory - FAC
        .addr FSUBT                     ;$0E FAC = ARG - FAC
        .addr FADD                      ;$10 FAC = number in memory + FAC
        .addr FADDT                     ;$12 FAC = ARG + FAC
        .addr FMULT                     ;$14 FAC = number in memory * FAC
        .addr FMULTT                    ;$16 FAC = ARG * FAC
        .addr FDIV                      ;$18 FAC = number in memory / FAC
        .addr FDIVT                     ;$1A FAC = ARG / FAC
        .addr LOG                       ;$1C FAC = natural logarithm of FAC
        .addr INT                       ;$1E FAC = integer part of FAC, rounding down
        .addr SQR                       ;$20 FAC = square root of FAC
        .addr NEGOP                     ;$22 FAC = -FAC
        .addr FPWR                      ;$24 FAC = ARG to the power of the number in memory
        .addr FPWRT                     ;$26 FAC = ARG to the power of FAC
        .addr EXP                       ;$28 FAC = e to the power of FAC
        .addr COS                       ;$2A FAC = cosine of FAC
        .addr SIN                       ;$2C FAC = sine of FAC
        .addr TAN                       ;$2E FAC = tangent of FAC
        .addr ATN                       ;$30 FAC = arctangent of FAC
        .addr ROUND                     ;$32 Round FAC using FACOV
        .addr ABS                       ;$34 FAC = absolute value of FAC
        .addr SIGN                      ;$36 A = $FF, 0 or 1 for FAC negative, zero or positive
        .addr FCOMP                                 ;$38 Compare FAC with number in memory (KERN): A = $FF, 0 or 1 for FAC less, equal or greater
        .addr RND_A                     ;$3A Same as $5C, but the flags must already be set for the sign of FAC
        .addr CONUPK                    ;$3C ARG = number in memory
        .addr ROMUPK                    ;$3E ARG = number in memory (KERN)
        .addr MOVFM                     ;$40 FAC = number in memory
        .addr MOVFRM                        ;$42 FAC = number in memory (KERN)
        .addr MOVMF_AY                  ;$44 Number in memory = FAC, rounded
        .addr MOVFA                     ;$46 FAC = ARG
        .addr MOVAF                     ;$48 ARG = FAC, rounded
        .addr FLOAT                     ;$4A FAC = signed byte in A
        .addr FLOATB_Y                  ;$4C FAC = 56-bit integer in FACHO-FACLO with exponent Y; A must be 0; carry clear = negate
        .addr FLOATS_Y                  ;$4E FAC = signed 16-bit integer in FACHO, FACHO+1 with exponent Y
        .addr QINT                      ;$50 FAC to signed integer filling FACHO-FACLO
        .addr FINLOG                    ;$52 FAC = FAC + signed byte in A
        .addr FIN                       ;$54 FAC = number read from the text at TXTPTR; A and carry as left by CHRGET
        .addr MOVMF_AY2                 ;$56 Same as $44
        .addr FOUTC                     ;$58 Same as $04, but the string starts at FBUFFR-1+Y
        .addr SGN                       ;$5A FAC = -1, 0 or 1 for the sign of FAC
        .addr RND                       ;$5C FAC = random number, depending on the sign of FAC
        .addr FSUB_APPL                 ;$5E FAC = number in memory (APPL) - FAC
        .addr FADD_APPL                 ;$60 FAC = number in memory (APPL) + FAC
        .addr FMULT_APPL                ;$62 FAC = number in memory (APPL) * FAC
        .addr FDIV_APPL                 ;$64 FAC = number in memory (APPL) / FAC
        .addr FPWR_APPL                 ;$66 Same as $26: the code to get the number from memory first is missing
        .addr CONUPK_APPL               ;$68 ARG = number in memory (APPL)
        .addr MOVFM_APPL                ;$6A FAC = number in memory (APPL)
        .addr NOTOP                     ;$6C FAC = NOT FAC, as 16-bit integers
        .addr ANDOP_MEM                 ;$6E FAC = number in memory AND FAC, as 16-bit integers
        .addr ANDOP                     ;$70 FAC = ARG AND FAC, as 16-bit integers
        .addr OROP_MEM                  ;$72 FAC = number in memory OR FAC, as 16-bit integers
        .addr OROP                      ;$74 FAC = ARG OR FAC, as 16-bit integers
        .addr XOROP_MEM                 ;$76 FAC = number in memory XOR FAC, as 16-bit integers
        .addr XOROP                     ;$78 FAC = ARG XOR FAC, as 16-bit integers

;OR and AND operators.  Both operands are converted to signed 16-bit
;integers.  OR is done as NOT (NOT a AND NOT b).
OROP_MEM:
        jsr     CONUPK
OROP:   ldy     #$FF                    ;$FF = OR
        bra     L9BA4_AND_OR
ANDOP_MEM:
        jsr     CONUPK
ANDOP:  ldy     #$00                    ;$00 = AND
L9BA4_AND_OR:
        sty     ANDOR_MASK
        jsr     AYINT                   ;Second operand to integer
        lda     FACHO+5
        eor     ANDOR_MASK
        sta     INTEGR
        lda     FACLO
        eor     ANDOR_MASK
        sta     INTEGR+1
        jsr     MOVFA                   ;FAC = ARG
        jsr     AYINT                   ;First operand to integer
        lda     FACLO
        eor     ANDOR_MASK
        and     INTEGR+1
        eor     ANDOR_MASK
        tay
        lda     FACHO+5
        eor     ANDOR_MASK
        and     INTEGR
        eor     ANDOR_MASK
        bra     GIVAYF                  ;Result back to floating point
;NOT operator
NOTOP:  jsr     AYINT
        lda     FACLO
        eor     #$FF
        tay
        lda     FACHO+5
        eor     #$FF
; ----------------------------------------------------------------------------
; ----------------------------------------------------------------------------
;FAC = signed 16-bit integer in A (high byte) and Y (low byte)
GIVAYF: jsr     L9C60_SET_INTEGER
        jmp     FLOATS
; ----------------------------------------------------------------------------
;Convert FAC to an unsigned 16-bit integer (0-65535) in LINNUM.
;Returns it in A (high byte) and Y (low byte) too.
GETADR: lda     FACSGN
        bmi     FCERR                   ;Branch if negative: illegal quantity
        lda     FACEXP
        cmp     #$91
        bcs     FCERR                   ;Branch if 65536 or more: illegal quantity
        jsr     QINT
        lda     FACHO+5
        ldy     FACLO
        sty     LINNUM
        sta     LINNUM+1
L9BF5_RTS:
        rts
; ----------------------------------------------------------------------------
;Convert FAC to a signed 16-bit integer (-32768 to 32767), left in FACHO+5
;(high byte) and FACLO (low byte).
AYINT:  lda     FACEXP
        cmp     #$90
        bcc     L9C0A_JMP_QINT          ;Branch if its magnitude is less than 32768
        lda     #<N32768
        ldy     #>N32768
        jsr     FCOMP
        beq     L9C0A_JMP_QINT          ;Branch if it is exactly -32768
;?ILLEGAL QUANTITY ERROR
FCERR:  ldx     #$0E                    ;BASIC error number
        jmp     JMP_IERROR
; ----------------------------------------------------------------------------
L9C0A_JMP_QINT:
        jmp     QINT
;Get the next character of the text at TXTPTR (which is in RAM), skipping
;spaces.  Returns it in A, with carry clear if it is a digit and Z=1 if it
;is a colon or a zero byte.  CHRGOT gets the current character again.
CHRGET: inc     TXTPTR
        bne     CHRGOT
        inc     TXTPTR+1
CHRGOT: sei
        ldy     #$00
        lda     #TXTPTR
        sta     SINNER
        jsr     GO_RAM_LOAD_GO_KERN
        cli
        cmp     #$3A
        bcs     L9C2D_RTS
        cmp     #$20
        beq     CHRGET
        sec
        sbc     #$30
        sec
        sbc     #$D0
L9C2D_RTS:
        rts
; ----------------------------------------------------------------------------
;Small routines to read or write memory in another MMU mode through one of
;the pointers.  All of them use Y as the index.
GET_TXTPTR_RAM:
        lda     #TXTPTR
        sta     SINNER
        jmp     GO_RAM_LOAD_GO_KERN
; ----------------------------------------------------------------------------
GET_INDEX1_RAM:
        lda     #INDEX1
        sta     SINNER
        jmp     GO_RAM_LOAD_GO_KERN
GET_INDEX1_APPL:
        lda     #INDEX1
        sta     GO_APPL_LOAD_GO_KERN_ZP
        jmp     GO_APPL_LOAD_GO_KERN
; ----------------------------------------------------------------------------
GET_INDEX2_RAM:
        lda     #INDEX2
        sta     SINNER
        jmp     GO_RAM_LOAD_GO_KERN
; ----------------------------------------------------------------------------
PUT_INDEX2_RAM:
        pha
        lda     #INDEX2
        sta     GO_RAM_STORE_GO_KERN_ZP
        pla
        jmp     GO_RAM_STORE_GO_KERN
; ----------------------------------------------------------------------------
N32768:
        .byte   $90,$80,$00,$00,$00,$00,$00,$00 ;-32768
;First part of GIVAYF: put the integer in the top of FAC's mantissa and
;return X = the exponent that goes with a 16-bit integer.
L9C60_SET_INTEGER:
        ldx     #$00
        stx     VALTYP
        sta     FACHO
        sty     FACHO+1
        ldx     #$90
        rts
; ----------------------------------------------------------------------------
;FAC = value of the number written in the string at INDEX1 with length A.
;The string is in RAM.  The byte after it is replaced with a zero while FIN
;reads it, and is put back afterwards.
STRVAL: ldx     TXTPTR
        ldy     TXTPTR+1
        stx     FBUFPT                  ;Save TXTPTR
        sty     FBUFPT+1
        ldx     INDEX1
        stx     TXTPTR                  ;TXTPTR = start of string
        clc
        adc     INDEX1
        sta     INDEX2                  ;INDEX2 = address of the byte after the string
        ldx     INDEX1+1
        stx     TXTPTR+1
        bcc     L9C83_NO_CARRY
        inx
L9C83_NO_CARRY:
        stx     INDEX2+1
        ldy     #$00
        jsr     GET_INDEX2_RAM
        pha                             ;Push the byte after the string
        tya
        jsr     PUT_INDEX2_RAM          ;Put a zero there instead
        jsr     CHRGOT
        jsr     FIN
        pla
        ldy     #$00
        jsr     PUT_INDEX2_RAM          ;Put the byte back
        ldx     FBUFPT
        ldy     FBUFPT+1
        stx     TXTPTR                  ;Restore TXTPTR
        sty     TXTPTR+1
L9CA3_RTS:
        rts
; ----------------------------------------------------------------------------
;FAC = number in memory - FAC
FSUB:   jsr     CONUPK
;FAC = ARG - FAC
FSUBT:  lda     FACSGN
        eor     #$FF
        sta     FACSGN                  ;Negate FAC, then add
        eor     ARGSGN
        sta     ARISGN
        lda     FACEXP
        jmp     FADDT
; ----------------------------------------------------------------------------
FADD5:  jsr     SHIFTR
        bcc     FADD4
;FAC = number in memory + FAC
FADD:   jsr     CONUPK
;FAC = ARG + FAC.  Call with A = FACEXP and the flags set from it.
FADDT:  bne     L9CC3_NOT_ZERO          ;Branch if FAC is not zero
        jmp     MOVFA                   ;FAC is zero: the result is ARG
; ----------------------------------------------------------------------------
L9CC3_NOT_ZERO:
        ldx     FACOV
        stx     OLDOV
        ldx     #$30
        lda     ARGEXP
FADDC:  tay
        beq     L9CA3_RTS               ;Branch if ARG is zero: the result is FAC
        sec
        sbc     FACEXP
        beq     FADD4                   ;Branch if the exponents are the same
        bcc     FADDA                   ;Branch if FAC has the bigger exponent
        sty     FACEXP
        ldy     ARGSGN
        sty     FACSGN
        eor     #$FF
        adc     #$00
        ldy     #$00
        sty     OLDOV
        ldx     #$25
        bne     FADD1
FADDA:  ldy     #$00
        sty     FACOV
FADD1:  cmp     #$F9
        bmi     FADD5
        tay
        lda     FACOV
        lsr     $01,x
        jsr     ROLSHF
FADD4:  bit     ARISGN
        bpl     FADD2                   ;Branch if the signs are the same: add the mantissas
        ldy     #$25
        cpx     #$30
        beq     SUBIT
        ldy     #$30
SUBIT:  sec
        eor     #$FF
        adc     OLDOV
        sta     FACOV
        lda     7,y
        sbc     7,x
        sta     FACLO
        lda     6,y
        sbc     6,x
        sta     FACHO+5
        lda     5,y
        sbc     5,x
        sta     FACHO+4
        lda     4,y
        sbc     4,x
        sta     FACHO+3
        lda     3,y
        sbc     3,x
        sta     FACHO+2
        lda     2,y
        sbc     2,x
        sta     FACHO+1
        lda     1,y
        sbc     1,x
        sta     FACHO
FADFLT: bcs     NORMAL                  ;Branch if the result is positive
        jsr     NEGFAC
;Normalize FAC: shift the mantissa left until bit 7 of FACHO is set.
NORMAL: ldy     #$00
        tya
        clc
NORM3:  ldx     FACHO
        bne     NORM1                   ;Branch if the top byte is not zero
        ldx     FACHO+1
        stx     FACHO
        ldx     FACHO+2
        stx     FACHO+1
        ldx     FACHO+3
        stx     FACHO+2
        ldx     FACHO+4
        stx     FACHO+3
        ldx     FACHO+5
        stx     FACHO+4
        ldx     FACLO
        stx     FACHO+5
        ldx     FACOV
        stx     FACLO
        sty     FACOV
        adc     #$08                    ;Shift left a whole byte at a time...
        cmp     #$38                    ;...up to 7 times (56 bits)
        bne     NORM3
;FAC = 0
ZEROFC: lda     #$00
ZEROF1: sta     FACEXP
ZEROML: sta     FACSGN
        rts
; ----------------------------------------------------------------------------
FADD2:  adc     OLDOV
        sta     FACOV
        lda     FACLO
        adc     ARGLO
        sta     FACLO
        lda     FACHO+5
        adc     ARGHO+5
        sta     FACHO+5
        lda     FACHO+4
        adc     ARGHO+4
        sta     FACHO+4
        lda     FACHO+3
        adc     ARGHO+3
        sta     FACHO+3
        lda     FACHO+2
        adc     ARGHO+2
        sta     FACHO+2
        lda     FACHO+1
        adc     ARGHO+1
        sta     FACHO+1
        lda     FACHO
        adc     ARGHO
        sta     FACHO
        jmp     SQUEEZ
; ----------------------------------------------------------------------------
NORM2:  adc     #$01
        asl     FACOV
        rol     FACLO
        rol     FACHO+5
        rol     FACHO+4
        rol     FACHO+3
        rol     FACHO+2
        rol     FACHO+1
        rol     FACHO
NORM1:  bpl     NORM2                   ;Loop until bit 7 of FACHO is set
        sec
        sbc     FACEXP
        bcs     ZEROFC                  ;Branch if the exponent underflowed: the result is 0
        eor     #$FF
        adc     #$01
        sta     FACEXP
SQUEEZ: bcc     RNDRTS                  ;Branch if the mantissa did not overflow
RNDSHF: inc     FACEXP
        beq     OVERR                   ;Branch if the exponent overflowed
        ror     FACHO
        ror     FACHO+1
        ror     FACHO+2
        ror     FACHO+3
        ror     FACHO+4
        ror     FACHO+5
        ror     FACLO
        ror     FACOV
RNDRTS: rts
; ----------------------------------------------------------------------------
;Negate FAC: flip its sign and two's complement the mantissa.
NEGFAC: lda     FACSGN
        eor     #$FF
        sta     FACSGN
NEGFCH: lda     FACHO
        eor     #$FF
        sta     FACHO
        lda     FACHO+1
        eor     #$FF
        sta     FACHO+1
        lda     FACHO+2
        eor     #$FF
        sta     FACHO+2
        lda     FACHO+3
        eor     #$FF
        sta     FACHO+3
        lda     FACHO+4
        eor     #$FF
        sta     FACHO+4
        lda     FACHO+5
        eor     #$FF
        sta     FACHO+5
        lda     FACLO
        eor     #$FF
        sta     FACLO
        lda     FACOV
        eor     #$FF
        sta     FACOV
        inc     FACOV
        bne     INCFRT
;Add 1 to the mantissa of FAC.
INCFAC: inc     FACLO
        bne     INCFRT
        inc     FACHO+5
        bne     INCFRT
        inc     FACHO+4
        bne     INCFRT
        inc     FACHO+3
        bne     INCFRT
        inc     FACHO+2
        bne     INCFRT
        inc     FACHO+1
        bne     INCFRT
        inc     FACHO
INCFRT: rts
; ----------------------------------------------------------------------------
;?OVERFLOW ERROR
OVERR:  ldx     #$0F                    ;BASIC error number
        jmp     JMP_IERROR
; ----------------------------------------------------------------------------
;Shift a mantissa right.  SHIFTR is called with X = the address of the
;exponent byte, which is just before the mantissa (FACEXP for FAC, ARGEXP for
;ARG), A = minus the number of bits, and carry clear.  Whole bytes are moved
;first, bringing in BITS at the top.  MULSHF shifts the product in RESHO
;right by one byte.
MULSHF: ldx     #$0B
SHFTR2: ldy     $07,x
        sty     FACOV
        ldy     $06,x
        sty     $07,x
        ldy     $05,x
        sty     $06,X
        ldy     $04,X
        sty     $05,X
        ldy     $03,X
        sty     $04,X
        ldy     $02,X
        sty     $03,x
        ldy     $01,x
        sty     $02,x
        ldy     BITS
        sty     $01,x
SHIFTR: adc     #$08
        bmi     SHFTR2
        beq     SHFTR2
        sbc     #$08
        tay
        lda     FACOV
        bcs     SHFTRT
SHFTR3: asl     $01,x
        bcc     SHFTR4
        inc     $01,x
SHFTR4: ror     $01,x
        ror     $01,x
ROLSHF: ror     $02,x
        ror     $03,x
        ror     $04,x
        ror     $05,x
        ror     $06,x
        ror     $07,x
        ror     a
        iny
        bne     SHFTR3
SHFTRT: clc
        rts
; ----------------------------------------------------------------------------
FONE:
        .byte   $81,$00,$00,$00,$00,$00,$00,$00 ;1

;Coefficients for LOG
LOGCN2:
        .byte   $08                     ;Degree of the polynomial: 9 coefficients follow
        .byte   $7E,$2D,$CD,$64,$DB,$A1,$F8,$68 ;0.16972882833987804
        .byte   $7E,$44,$F9,$D8,$B4,$A6,$7F,$F4 ;0.19235933878519512
        .byte   $7E,$63,$47,$AB,$46,$98,$BB,$04 ;0.22195308321368667
        .byte   $7F,$06,$4D,$42,$4C,$A0,$11,$66 ;0.2623081892525388
        .byte   $7F,$24,$25,$89,$EB,$E0,$15,$46 ;0.3205988979753252
        .byte   $7F,$53,$0B,$B1,$53,$D6,$F6,$CC ;0.41219858311113244
        .byte   $80,$13,$BB,$62,$87,$7C,$DF,$EE ;0.5770780163555853
        .byte   $80,$76,$38,$4E,$E1,$D0,$1F,$E8 ;0.9617966939259756
        .byte   $82,$38,$AA,$3B,$29,$5C,$17,$EE ;2.8853900817779268

SQR05:
        .byte   $80,$35,$04,$F3,$33,$F9,$DE,$68 ;0.7071067811865476 = 1/SQR(2)
SQRTWO:
        .byte   $81,$35,$04,$F3,$33,$F9,$DE,$68 ;1.4142135623730951 = SQR(2)
NEGHLF:
        .byte   $80,$80,$00,$00,$00,$00,$00,$00 ;-0.5
LOG2:
        .byte   $80,$31,$72,$17,$F7,$D1,$CF,$7C ;0.6931471805599454 = LOG(2)
; ----------------------------------------------------------------------------
;FAC = natural logarithm of FAC
LOG:    jsr     SIGN
        beq     LOGERR                  ;Branch if FAC is zero: illegal quantity
        bpl     LOG1
LOGERR: jmp     FCERR
; ----------------------------------------------------------------------------
LOG1:   lda     FACEXP
        sbc     #$7f
        pha
        lda     #$80
        sta     FACEXP
        lda     #<SQR05
        ldy     #>SQR05
        jsr     FADD_ROM
        lda     #<SQRTWO
        ldy     #>SQRTWO
        jsr     FDIV_ROM
        lda     #<FONE
        ldy     #>FONE
        jsr     FSUB_ROM
        lda     #<LOGCN2
        ldy     #>LOGCN2
        jsr     POLYX
        lda     #<NEGHLF
        ldy     #>NEGHLF
        jsr     FADD_ROM
        pla
        jsr     FINLOG
        lda     #<LOG2
        ldy     #>LOG2
;FAC = number in memory (KERN) * FAC
FMULT_ROM:
        jsr     ROMUPK
        bra     FMULTT
;FAC = number in memory (APPL) * FAC
FMULT_APPL:
        jsr     CONUPK_APPL
        bra     FMULTT
;FAC = FAC + 0.5
FADDH:  lda     #<FHALF
        ldy     #>FHALF
;FAC = number in memory (KERN) + FAC
FADD_ROM:
        jsr     ROMUPK
        jmp     FADDT
; ----------------------------------------------------------------------------
;FAC = number in memory (APPL) + FAC
FADD_APPL:
        jsr     CONUPK_APPL
        jmp     FADDT
; ----------------------------------------------------------------------------
;FAC = number in memory (KERN) - FAC
FSUB_ROM:
        jsr     ROMUPK
        jmp     FSUBT
; ----------------------------------------------------------------------------
;FAC = number in memory (APPL) - FAC
FSUB_APPL:
        jsr     CONUPK_APPL
        jmp     FSUBT
; ----------------------------------------------------------------------------
;FAC = number in memory (KERN) / FAC
FDIV_ROM:
        jsr     ROMUPK
        jmp     FDIVT
; ----------------------------------------------------------------------------
;FAC = number in memory (APPL) / FAC
FDIV_APPL:
        jsr     CONUPK_APPL
        jmp     FDIVT
; ----------------------------------------------------------------------------
;FAC = number in memory * FAC
FMULT:  jsr     CONUPK
;FAC = ARG * FAC.  Call with A = FACEXP and the flags set from it.
FMULTT: bne     L9F68_NOT_ZERO          ;Branch if FAC is not zero
        jmp     MULTRT
; ----------------------------------------------------------------------------
L9F68_NOT_ZERO:
        jsr     MULDIV                  ;Add the exponents
        lda     #$00
        sta     RESHO                   ;Clear the product
        sta     RESHO+1
        sta     RESHO+2
        sta     RESHO+3
        sta     RESHO+4
        sta     RESHO+5
        sta     RESHO+6
        lda     FACOV
        jsr     MLTPLY                  ;Multiply by each byte of FAC, lowest first
        lda     FACLO
        jsr     MLTPLY
        lda     FACHO+5
        jsr     MLTPLY
        lda     FACHO+4
        jsr     MLTPLY
        lda     FACHO+3
        jsr     MLTPLY
        lda     FACHO+2
        jsr     MLTPLY
        lda     FACHO+1
        jsr     MLTPLY
        lda     FACHO
        jsr     MLTPL1
        jmp     MOVFR                   ;FAC = product, normalized
; ----------------------------------------------------------------------------
;Multiply ARG by the byte in A and add it into the product in RESHO.
MLTPLY: bne     MLTPL1
        jmp     MULSHF
; ----------------------------------------------------------------------------
MLTPL1: lsr     a
        ora     #$80
MLTPL2: tay
        bcc     MLTPL3
        clc
        lda     RESHO+6
        adc     ARGLO
        sta     RESHO+6
        lda     RESHO+5
        adc     ARGHO+5
        sta     RESHO+5
        lda     RESHO+4
        adc     ARGHO+4
        sta     RESHO+4
        lda     RESHO+3
        adc     ARGHO+3
        sta     RESHO+3
        lda     RESHO+2
        adc     ARGHO+2
        sta     RESHO+2
        lda     RESHO+1
        adc     ARGHO+1
        sta     RESHO+1
        lda     RESHO
        adc     ARGHO
        sta     RESHO
MLTPL3: ror     RESHO
        ror     RESHO+1
        ror     RESHO+2
        ror     RESHO+3
        ror     RESHO+4
        ror     RESHO+5
        ror     RESHO+6
        ror     FACOV
        tya
        lsr     a
        bne     MLTPL2
MULTRT: rts
; ----------------------------------------------------------------------------
;ARG = number in memory, as the KERNAL sees memory.  The address is in A (low
;byte) and Y (high byte).  Returns A = FACEXP with the flags set from it, and
;ARISGN set for the signs of FAC and ARG, ready for FADDT, FMULTT and so on.
ROMUPK:
        sta     INDEX1
        sty     INDEX1+1
        ldy     #$07
        lda     (INDEX1),y
        sta     ARGLO
        dey
        lda     (INDEX1),y
        sta     ARGHO+5
        dey
        lda     (INDEX1),y
        sta     ARGHO+4
        dey
        lda     (INDEX1),y
        sta     ARGHO+3
        dey
        lda     (INDEX1),y
        sta     ARGHO+2
        dey
        lda     (INDEX1),y
        sta     ARGHO+1
        dey
        lda     (INDEX1),y
        sta     ARGSGN
        eor     FACSGN                  ;ARISGN bit 7 = the signs are different
        sta     ARISGN
        lda     ARGSGN
        ora     #$80                    ;Bit 7 of the first mantissa byte is the sign in memory; set it for ARG
        sta     ARGHO
        dey
        lda     (INDEX1),y
        sta     ARGEXP
        lda     FACEXP
        rts
; ----------------------------------------------------------------------------
;ARG = number in memory (in RAM).  See ROMUPK.
CONUPK: sta     INDEX1
        sty     INDEX1+1
        ldy     #$07
        jsr     GET_INDEX1_RAM
        sta     ARGLO
        dey
        jsr     GET_INDEX1_RAM
        sta     ARGHO+5
        dey
        jsr     GET_INDEX1_RAM
        sta     ARGHO+4
        dey
        jsr     GET_INDEX1_RAM
        sta     ARGHO+3
        dey
        jsr     GET_INDEX1_RAM
        sta     ARGHO+2
        dey
        jsr     GET_INDEX1_RAM
        sta     ARGHO+1
        dey
        jsr     GET_INDEX1_RAM
        sta     ARGSGN
        eor     FACSGN
        sta     ARISGN
        lda     ARGSGN
        ora     #$80
        sta     ARGHO
        dey
        jsr     GET_INDEX1_RAM
        sta     ARGEXP
        lda     FACEXP
        rts
; ----------------------------------------------------------------------------
;ARG = number in memory, as the application sees memory.  See ROMUPK.
CONUPK_APPL:
        sta     INDEX1
        sty     INDEX1+1
        ldy     #$07
LA073_LOOP:
        jsr     GET_INDEX1_APPL
        sta     ARGEXP,y
        dey
        cpy     #$02
        bcs     LA073_LOOP
        jsr     GET_INDEX1_APPL
        sta     ARGSGN
        eor     FACSGN
        sta     ARISGN
        lda     ARGSGN
        ora     #$80
        sta     ARGHO
        dey
        jsr     GET_INDEX1_APPL
        sta     ARGEXP
        lda     FACEXP
        rts
; ----------------------------------------------------------------------------
;Add the exponent of ARG to that of FAC for multiply or divide, and set
;the sign of the result.  If the result under- or overflows, the caller's
;return address is thrown away and FAC is set to zero, or OVERR is taken.
MULDIV: lda     ARGEXP
MLDEXP: beq     ZEREMV
        clc
        adc     FACEXP
        bcc     TRYOFF
        bmi     GOOVER
        clc
        .byte   $2C
TRYOFF: bpl     ZEREMV
        adc     #$80
        sta     FACEXP
        bne     LA0AE_SET_SIGN
        jmp     ZEROML
; ----------------------------------------------------------------------------
LA0AE_SET_SIGN:
        lda     ARISGN
        sta     FACSGN
        rts
; ----------------------------------------------------------------------------
MLDVEX: lda     FACSGN
        eor     #$FF
        bmi     GOOVER
ZEREMV: pla
        pla
        jmp     ZEROFC
; ----------------------------------------------------------------------------
GOOVER: jmp     OVERR
; ----------------------------------------------------------------------------
;FAC = FAC * 10
MUL10:  jsr     MOVAF
        tax
        beq     MUL10R
        clc
        adc     #$02
        bcs     GOOVER
        ldx     #$00
        stx     ARISGN
        jsr     FADDC
        inc     FACEXP
        beq     GOOVER
MUL10R: rts
; ----------------------------------------------------------------------------
TENC:
        .byte   $84,$20,$00,$00,$00,$00,$00,$00 ;10
;?DIVISION BY ZERO ERROR
DVERR:  ldx     #$14                    ;BASIC error number
        jmp     JMP_IERROR
; ----------------------------------------------------------------------------
;FAC = FAC / 10
DIV10:  jsr     MOVAF
        lda     #<TENC
        ldy     #>TENC
        ldx     #$00
FDIVF:  stx     ARISGN
        jsr     MOVFRM
        jmp     FDIVT
; ----------------------------------------------------------------------------
;FAC = number in memory / FAC
FDIV:   jsr     CONUPK
;FAC = ARG / FAC.  Call with A = FACEXP and the flags set from it.
FDIVT:  beq     DVERR                   ;Branch if FAC is zero
        jsr     ROUND
        lda     #$00
        sec
        sbc     FACEXP
        sta     FACEXP
        jsr     MULDIV
        inc     FACEXP
        beq     GOOVER
        ldx     #$f9                    ;X counts the 7 bytes of the quotient
        lda     #$01
DIVIDE: ldy     ARGHO
        cpy     FACHO
        bne     SAVQUO
        ldy     ARGHO+1
        cpy     FACHO+1
        bne     SAVQUO
        ldy     ARGHO+2
        cpy     FACHO+2
        bne     SAVQUO
        ldy     ARGHO+3
        cpy     FACHO+3
        bne     SAVQUO
        ldy     ARGHO+4
        cpy     FACHO+4
        bne     SAVQUO
        ldy     ARGHO+5
        cpy     FACHO+5
        bne     SAVQUO
        ldy     ARGLO
        cpy     FACLO
SAVQUO: php
        rol     a
        bcc     QSHFT
        inx
        sta     RESHO+6,x
        beq     LA18B_LAST_BITS
        bpl     DIVNRM
        lda     #$01
QSHFT:  plp
        bcs     DIVSUB
SHFARG: asl     ARGLO
        rol     ARGHO+5
        rol     ARGHO+4
        rol     ARGHO+3
        rol     ARGHO+2
        rol     ARGHO+1
        rol     ARGHO
        bcs     SAVQUO
        bmi     DIVIDE
        bpl     SAVQUO
DIVSUB: tay
        lda     ARGLO
        sbc     FACLO
        sta     ARGLO
        lda     ARGHO+5
        sbc     FACHO+5
        sta     ARGHO+5
        lda     ARGHO+4
        sbc     FACHO+4
        sta     ARGHO+4
        lda     ARGHO+3
        sbc     FACHO+3
        sta     ARGHO+3
        lda     ARGHO+2
        sbc     FACHO+2
        sta     ARGHO+2
        lda     ARGHO+1
        sbc     FACHO+1
        sta     ARGHO+1
        lda     ARGHO
        sbc     FACHO
        sta     ARGHO
        tya
        jmp     SHFARG
; ----------------------------------------------------------------------------
LA18B_LAST_BITS:
        lda     #$40
        bne     QSHFT
DIVNRM: asl     a
        asl     a
        asl     a
        asl     a
        asl     a
        asl     a
        sta     FACOV
        plp
;FAC = the product or quotient in RESHO, normalized.
MOVFR:  lda     RESHO
        sta     FACHO
        lda     RESHO+1
        sta     FACHO+1
        lda     RESHO+2
        sta     FACHO+2
        lda     RESHO+3
        sta     FACHO+3
        lda     RESHO+4
        sta     FACHO+4
        lda     RESHO+5
        sta     FACHO+5
        lda     RESHO+6
        sta     FACLO
        jmp     NORMAL
; ----------------------------------------------------------------------------
;FAC = number in memory, as the application sees memory.
MOVFM_APPL:
        sec
        sta     INDEX1
        sty     INDEX1+1
        ldy     #$07
LA1BE_LOOP:
        jsr     GET_INDEX1_APPL
        sta     FACEXP,y
        dey
        cpy     #$02
        bcs     LA1BE_LOOP
        jsr     GET_INDEX1_APPL
        sta     FACSGN
        ora     #$80
        sta     FACHO
        dey
        jsr     GET_INDEX1_APPL
        sta     FACEXP
        sty     FACOV
        rts
; ----------------------------------------------------------------------------
;FAC = number in memory (in RAM).  The address is in A (low byte) and Y
;(high byte).  Returns with the flags set from FACEXP.
MOVFM:  clc                             ;Carry clear = read in MMU RAM mode
        .byte   $24                     ;Skip next instruction
;FAC = number in memory, as the KERNAL sees memory.
MOVFRM:
        sec                             ;Carry set = read directly
        sta     INDEX1
        sty     INDEX1+1
        ldy     #$07
        jsr     GET_INDEX1_ROM_OR_RAM
        sta     FACLO
        dey
        jsr     GET_INDEX1_ROM_OR_RAM
        sta     FACHO+5
        dey
        jsr     GET_INDEX1_ROM_OR_RAM
        sta     FACHO+4
        dey
        jsr     GET_INDEX1_ROM_OR_RAM
        sta     FACHO+3
        dey
        jsr     GET_INDEX1_ROM_OR_RAM
        sta     FACHO+2
        dey
        jsr     GET_INDEX1_ROM_OR_RAM
        sta     FACHO+1
        dey
        jsr     GET_INDEX1_ROM_OR_RAM
        sta     FACSGN
        ora     #$80
        sta     FACHO
        dey
        jsr     GET_INDEX1_ROM_OR_RAM
        sta     FACEXP
        sty     FACOV
        rts
; ----------------------------------------------------------------------------
;Number in memory = FAC, rounded.  The address is in A (low byte) and Y
;(high byte), and the number is written in MMU RAM mode.
MOVMF_AY:
        tax
        bra     MOVMF
;TEMPF2 = FAC, rounded
MOV2F:  ldx     #TEMPF2
        .byte   $2C                     ;Skip next instruction
;TEMPF1 = FAC, rounded
MOV1F:  ldx     #TEMPF1
        ldy     #$00
        beq     MOVMF
;Number in memory = FAC, rounded.  A second copy of MOVMF_AY.
MOVMF_AY2:
        tax
;Number in memory = FAC, rounded.  The address is in X (low byte) and Y
;(high byte).
MOVMF:  jsr     ROUND
        stx     INDEX1
        sty     INDEX1+1
        ldy     #$07
        lda     #INDEX1
        sta     GO_RAM_STORE_GO_KERN_ZP ;Make GO_RAM_STORE_GO_KERN write through INDEX1
        lda     FACLO
        jsr     GO_RAM_STORE_GO_KERN
        dey
        lda     FACHO+5
        jsr     GO_RAM_STORE_GO_KERN
        dey
        lda     FACHO+4
        jsr     GO_RAM_STORE_GO_KERN
        dey
        lda     FACHO+3
        jsr     GO_RAM_STORE_GO_KERN
        dey
        lda     FACHO+2
        jsr     GO_RAM_STORE_GO_KERN
        dey
        lda     FACHO+1
        jsr     GO_RAM_STORE_GO_KERN
        dey
        lda     FACSGN
        ora     #$7F                    ;The sign goes in bit 7 of the first mantissa byte
        and     FACHO
        jsr     GO_RAM_STORE_GO_KERN
        dey
        lda     FACEXP
        jsr     GO_RAM_STORE_GO_KERN
        sty     FACOV
        rts
; ----------------------------------------------------------------------------
;FAC = ARG
MOVFA:  lda     ARGSGN
MOVFA1: sta     FACSGN
        ldx     #$08
LA271_LOOP:
        lda     ARGEXP-1,x
        sta     FACEXP-1,x
        dex
        bne     LA271_LOOP
        stx     FACOV
        rts
; ----------------------------------------------------------------------------
;ARG = FAC, rounded
MOVAF:  jsr     ROUND
MOVEF:  ldx     #$09
LA280_LOOP:
        lda     FACEXP-1,x
        sta     ARGEXP-1,x
        dex
        bne     LA280_LOOP
        stx     FACOV
MOVRTS: rts
; ----------------------------------------------------------------------------
;Round FAC: add 1 to the mantissa if the top bit of FACOV is set.
ROUND:  lda     FACEXP
        beq     MOVRTS
        asl     FACOV
        bcc     MOVRTS
INCRND: jsr     INCFAC
        bne     MOVRTS
        jmp     RNDSHF
; ----------------------------------------------------------------------------
;Get the sign of FAC.  Returns A = $FF, 0 or 1 for negative, zero or positive.
SIGN:   lda     FACEXP
        beq     SIGNRT
FCSIGN: lda     FACSGN
FCOMPS: rol     a
        lda     #$FF
        bcs     SIGNRT
        lda     #$01
SIGNRT: rts
; ----------------------------------------------------------------------------
;FAC = -1, 0 or 1 for the sign of FAC
SGN:    jsr     SIGN
;FAC = signed byte in A
FLOAT:  sta     FACHO
        lda     #$00
        sta     FACHO+1
        ldx     #$88                    ;Exponent for an 8-bit integer
FLOATS: lda     FACHO
        eor     #$FF
        rol     a                       ;Carry set if the integer is positive
FLOATC: lda     #$00
        sta     FACLO
        sta     FACHO+5
        sta     FACHO+4
        sta     FACHO+3
        sta     FACHO+2
FLOATB: stx     FACEXP
        sta     FACOV
        sta     FACSGN
        jmp     FADFLT                  ;Negate if carry is clear, then normalize
;The next three entries are FLOATB, FLOATC and FLOATS with the exponent taken
;from Y instead of X.
FLOATB_Y:
        phy
        plx
        bra     FLOATB
FLOATC_Y:
        phy
        plx
        bra     FLOATC
FLOATS_Y:
        phy
        plx
        bra     FLOATS
;FAC = absolute value of FAC
ABS:    lsr     FACSGN
        rts
; ----------------------------------------------------------------------------
;Compare FAC with a number in memory, as the KERNAL sees memory.
;The address is in A (low byte) and Y (high byte).
;Returns A = $FF if FAC is less, 0 if they are equal, 1 if FAC is greater.
FCOMP:
        sta     INDEX2
        sty     INDEX2+1
        ldy     #$00
        lda     (INDEX2),y
        iny
        tax
        beq     SIGN                    ;Branch if the number in memory is zero: the result is the sign of FAC
        lda     (INDEX2),y
        eor     FACSGN
        bmi     FCSIGN                  ;Branch if the signs are different
        cpx     FACEXP
        bne     FCOMPC
        lda     (INDEX2),y
        ora     #$80
        cmp     FACHO
        bne     FCOMPC
        iny
        lda     (INDEX2),y
        cmp     FACHO+1
        bne     FCOMPC
        iny
        lda     (INDEX2),y
        cmp     FACHO+2
        bne     FCOMPC
        iny
        lda     (INDEX2),y
        cmp     FACHO+3
        bne     FCOMPC
        iny
        lda     (INDEX2),y
        cmp     FACHO+4
        bne     FCOMPC
        iny
        lda     (INDEX2),y
        cmp     FACHO+5
        bne     FCOMPC
        iny
        lda     #$7F
        cmp     FACOV
        lda     (INDEX2),y
        sbc     FACLO
        beq     QINTRT
FCOMPC: lda     FACSGN
        bcc     FCOMPD
        eor     #$FF
FCOMPD: jmp     FCOMPS
; ----------------------------------------------------------------------------
;Get the byte at (INDEX1),Y as the KERNAL sees memory if carry is set, or
;from RAM if carry is clear.
GET_INDEX1_ROM_OR_RAM:
        lda     (INDEX1),y
        bcs     QINTRT
        jmp     GET_INDEX1_RAM
; ----------------------------------------------------------------------------
;Convert FAC to a signed integer that fills its 7 mantissa bytes.
QINT:   lda     FACEXP
        beq     CLRFAC
        sec
        sbc     #$B8
        bit     FACSGN
        bpl     LA34C_POSITIVE
        tax
        lda     #$FF
        sta     BITS
        jsr     NEGFCH
        txa
LA34C_POSITIVE:
        ldx     #$25
        cmp     #$F9
        bpl     QISHFT
        jsr     SHIFTR
        sty     BITS
QINTRT: rts
; ----------------------------------------------------------------------------
QISHFT: tay
        lda     FACSGN
        and     #$80
        lsr     FACHO
        ora     FACHO
        sta     FACHO
        jsr     ROLSHF
        sty     BITS
        rts
; ----------------------------------------------------------------------------
;FAC = integer part of FAC, rounding down.  The low byte of the integer is
;left in INTEGR.
INT:    lda     FACEXP
        cmp     #$B8
        bcs     INTRTS                  ;Branch if FAC is too big to have a fraction
        jsr     QINT
        sty     FACOV
        lda     FACSGN
        sty     FACSGN
        eor     #$80
        rol     a
        lda     #$B8
        sta     FACEXP
        lda     FACLO
        sta     INTEGR
        jmp     FADFLT
; ----------------------------------------------------------------------------
CLRFAC: sta     FACHO
        sta     FACHO+1
        sta     FACHO+2
        sta     FACHO+3
        sta     FACHO+4
        sta     FACHO+5
        sta     FACLO
        tay
INTRTS: rts
; ----------------------------------------------------------------------------
;FAC = number read from the text at TXTPTR.
;
;Call with A = first character and carry clear if it is a digit, which is
;how CHRGET and CHRGOT return.  Digits, a sign, a decimal point and an
;exponent (E) are accepted.  In the exponent, the sign may also be a BASIC
;token: $AA for + or $AB for -.
FIN:    ldy     #$00
        ldx     #$0D                    ;Clear DECCNT through SGNFLG, which includes FAC
LA39A_CLEAR_LOOP:
        sty     DECCNT,x
        dex
        bpl     LA39A_CLEAR_LOOP
        bcc     FINDGQ
        cmp     #'-'
        bne     QPLUS
        stx     SGNFLG
        beq     FINC
QPLUS:  cmp     #'+'
        bne     FIN1
FINC:   jsr     CHRGET
FINDGQ: bcc     FINDIG
FIN1:   cmp     #'.'
        beq     FINDP
        cmp     #'E'
        bne     FINE
        jsr     CHRGET
        bcc     FNEDG1
        cmp     #$AB                    ;Token for -
        beq     FINEC1
        cmp     #'-'
        beq     FINEC1
        cmp     #$AA                    ;Token for +
        beq     FINEC
        cmp     #'+'
        beq     FINEC
        bne     FINEC2
FINEC1: ror     EXPSGN
FINEC:  jsr     CHRGET
FNEDG1: bcc     FINEDG
FINEC2: bit     EXPSGN
        bpl     FINE
        lda     #$00
        sec
        sbc     TENEXP
        jmp     FINE1
; ----------------------------------------------------------------------------
FINDP:  ror     DPTFLG
        bit     DPTFLG
        bvc     FINC
FINE:   lda     TENEXP
FINE1:  sec
        sbc     DECCNT
        sta     TENEXP
        beq     FINQNG
        bpl     FINMUL
FINDIV: jsr     DIV10
        inc     TENEXP
        bne     FINDIV
        beq     FINQNG
FINMUL: jsr     MUL10
        dec     TENEXP
        bne     FINMUL
FINQNG: lda     SGNFLG
        bmi     NEGXQS
        rts
; ----------------------------------------------------------------------------
NEGXQS: jmp     NEGOP
; ----------------------------------------------------------------------------
FINDIG: pha
        bit     DPTFLG
        bpl     LA414_MUL10
        inc     DECCNT
LA414_MUL10:
        jsr     MUL10
        pla
        sec
        sbc     #$30
        jsr     FINLOG
        jmp     FINC
; ----------------------------------------------------------------------------
;FAC = FAC + signed byte in A
FINLOG: pha
        jsr     MOVAF
        pla
        jsr     FLOAT
        lda     ARGSGN
        eor     FACSGN
        sta     ARISGN
        ldx     FACEXP
        jmp     FADDT
; ----------------------------------------------------------------------------
FINEDG: lda     TENEXP
        cmp     #$0A                    ;Branch if the exponent so far is under 10
        bcc     MLEX10
        lda     #$64
        bit     EXPSGN
        bmi     MLEXMI
        jmp     OVERR
; ----------------------------------------------------------------------------
MLEX10: asl     a
        asl     a
        clc
        adc     TENEXP
        asl     a
        clc
        ldy     #$00
        sta     TENEXP
        jsr     GET_TXTPTR_RAM
        adc     TENEXP
        sec
        sbc     #$30
MLEXMI: sta     TENEXP
        jmp     FINEC
; ----------------------------------------------------------------------------
;Limits used by FOUT to scale a number until it is a 15-digit integer
N0999:
        .byte   $AF,$35,$E6,$20,$F4,$7F,$FF,$CC ;99999999999999.9
N9999:
        .byte   $B2,$63,$5F,$A9,$31,$9F,$FF,$E8 ;999999999999999.6
NMIL:
        .byte   $B2,$63,$5F,$A9,$31,$9F,$FF,$FC ;999999999999999.9375
; ----------------------------------------------------------------------------
; ----------------------------------------------------------------------------
;Convert FAC to a string of characters at FBUFFR ($0100), ending with a
;zero byte.  Returns the address of the string in A (low) and Y (high).
;
;The string starts with a space or a minus sign.  Up to 15 digits are
;produced.  Scientific notation is used for numbers of 1E+15 and up and for
;numbers below 0.01.  FOUTC is the same, but starts at FBUFFR-1+Y.
FOUT:   ldy     #$01
FOUTC:  lda     #$20                    ;Start with a space...
        bit     FACSGN
        bpl     LA47D_PUT_SIGN
        lda     #$2d                    ;...or a minus sign for a negative number
LA47D_PUT_SIGN:
        sta     FBUFFR-1,y
        sta     FACSGN
        sty     FBUFPT
        iny
        lda     #$30
        ldx     FACEXP
        bne     FOUT37                  ;Branch if FAC is not zero
; ----------------------------------------------------------------------------
LA48B_ZERO:
        jmp     FOUT19
; ----------------------------------------------------------------------------
FOUT37: lda     #$00
        cpx     #$80
        beq     LA496_SMALL
        bcs     LA49F_SET_DECCNT        ;Branch if FAC is 1 or more
LA496_SMALL:
        lda     #<NMIL
        ldy     #>NMIL
        jsr     FMULT_ROM                            ;FAC is less than 1: multiply it by 1E15
        lda     #$F1                    ;And start the decimal exponent at -15
LA49F_SET_DECCNT:
        sta     DECCNT
FOUT4:  lda     #<N9999
        ldy     #>N9999
        jsr     FCOMP
        beq     BIGGES
        bpl     FOUT9
FOUT3:  lda     #<N0999
        ldy     #>N0999
        jsr     FCOMP
        beq     FOUT38
        bpl     FOUT5
FOUT38: jsr     MUL10
        dec     DECCNT
        bne     FOUT3
FOUT9:  jsr     DIV10
        inc     DECCNT
        bne     FOUT4
FOUT5:  jsr     FADDH
BIGGES: jsr     QINT                    ;FAC is now a 15-digit integer
        ldx     #$01
        lda     DECCNT
        clc
        adc     #$10
        bmi     FOUTPI
        cmp     #$11
        bcs     FOUT6
        adc     #$FF
        tax
        lda     #$02
FOUTPI: sec
FOUT6:  sbc     #$02
        sta     TENEXP
        stx     DECCNT
        txa
        beq     FOUT39
        bpl     LA4FC_DIGITS
FOUT39: ldy     FBUFPT
        lda     #$2E
        iny
        sta     FBUFFR-1,y
        txa
        beq     FOUT16
        lda     #$30
        iny
        sta     FBUFFR-1,y
FOUT16: sty     FBUFPT
LA4FC_DIGITS:
        ldy     #$00
        ldx     #$80
FOULDY: lda     FACLO
        clc
        adc     FOUTBL+6,y
        sta     FACLO
        lda     FACHO+5
        adc     FOUTBL+5,y
        sta     FACHO+5
        lda     FACHO+4
        adc     FOUTBL+4,y
        sta     FACHO+4
        lda     FACHO+3
        adc     FOUTBL+3,y
        sta     FACHO+3
        lda     FACHO+2
        adc     FOUTBL+2,y
        sta     FACHO+2
        lda     FACHO+1
        adc     FOUTBL+1,y
        sta     FACHO+1
        lda     FACHO
        adc     FOUTBL,y
        sta     FACHO
        inx
        bcs     LA539_NEGATIVE
        bpl     FOULDY
        bmi     LA53B_GOT_DIGIT
LA539_NEGATIVE:
        bmi     FOULDY
LA53B_GOT_DIGIT:
        txa
        bcc     LA542_POSITIVE
        eor     #$ff
        adc     #$0a
LA542_POSITIVE:
        adc     #$2F
        iny
        iny
        iny
        iny
        iny
        iny
        iny
LA54B_STORE_DIGIT:
        sty     FOUT_TMP
        ldy     FBUFPT
        iny
        tax
        and     #$7F
        sta     FBUFFR-1,y
        dec     DECCNT
        bne     LA560
        lda     #$2e
        iny
        sta     FBUFFR-1,y
LA560:  sty     FBUFPT
        ldy     FOUT_TMP
LA564_NEXT_POWER:
        txa
        eor     #$FF
        and     #$80
        tax
        cpy     #FDCEND-FOUTBL
        beq     LA572_DIGITS_DONE
        cpy     #TIMEND-FOUTBL
        bne     FOULDY
LA572_DIGITS_DONE:
        ldy     FBUFPT
LA574_STRIP_ZEROS:
        lda     FBUFFR-1,y
        dey
        cmp     #$30
        beq     LA574_STRIP_ZEROS
        cmp     #$2E
        beq     LA581_EXPONENT
        iny
LA581_EXPONENT:
        lda     #$2B
        ldx     TENEXP
        beq     FOUT17
        bpl     LA591_PUT_EXPONENT
        lda     #$00
        sec
        sbc     TENEXP
        tax
        lda     #$2d
LA591_PUT_EXPONENT:
        sta     FBUFFR+1,y
        lda     #$45
        sta     FBUFFR,y
        txa
        ldx     #$2F
        sec
LA59D_TENS_LOOP:
        inx
        sbc     #$0A
        bcs     LA59D_TENS_LOOP
        adc     #$3A
        sta     FBUFFR+3,y
        txa
        sta     FBUFFR+2,y
        lda     #$00
        sta     FBUFFR+4,y
        beq     FOUT20
FOUT19: sta     FBUFFR-1,y
FOUT17: lda     #$00
        sta     FBUFFR,y
FOUT20: lda     #$00
        ldy     #$01
        rts
; ----------------------------------------------------------------------------
FHALF:
        .byte   $80,$00,$00,$00,$00,$00,$00,$00 ;0.5

;Powers of ten, as 7-byte integers of alternating sign, that FOUT adds
;to FAC to peel off one decimal digit at a time
FOUTBL:
        .byte   $FF,$A5,$0C,$EF,$85,$C0,$00 ;-100000000000000
        .byte   $00,$09,$18,$4E,$72,$A0,$00 ;10000000000000
        .byte   $FF,$FF,$17,$2B,$5A,$F0,$00 ;-1000000000000
        .byte   $00,$00,$17,$48,$76,$E8,$00 ;100000000000
        .byte   $FF,$FF,$FD,$AB,$F4,$1C,$00 ;-10000000000
        .byte   $00,$00,$00,$3B,$9A,$CA,$00 ;1000000000
        .byte   $FF,$FF,$FF,$FA,$0A,$1F,$00 ;-100000000
        .byte   $00,$00,$00,$00,$98,$96,$80 ;10000000
        .byte   $FF,$FF,$FF,$FF,$F0,$BD,$C0 ;-1000000
        .byte   $00,$00,$00,$00,$01,$86,$A0 ;100000
        .byte   $FF,$FF,$FF,$FF,$FF,$D8,$F0 ;-10000
        .byte   $00,$00,$00,$00,$00,$03,$E8 ;1000
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$9C ;-100
        .byte   $00,$00,$00,$00,$00,$00,$0A ;10
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF ;-1
;Like FOUTBL, but for peeling off hours, minutes and seconds from a count
;of jiffies (for TI$ in other CBM BASICs).  FOUT can stop at the end of
;this table, but nothing in the KERNAL makes it start here.
FDCEND:
        .byte   $FF,$FF,$FF,$FF,$DF,$0A,$80 ;-2160000
        .byte   $00,$00,$00,$00,$03,$4B,$C0 ;216000
        .byte   $FF,$FF,$FF,$FF,$FF,$73,$60 ;-36000
        .byte   $00,$00,$00,$00,$00,$0E,$10 ;3600
        .byte   $FF,$FF,$FF,$FF,$FF,$FD,$A8 ;-600
        .byte   $00,$00,$00,$00,$00,$00,$3C ;60
TIMEND:
; ----------------------------------------------------------------------------
;FAC = ARG to the power of the number in memory
FPWR:   jsr     MOVFM
        bra     FPWRT
; ----------------------------------------------------------------------------
;FAC = ARG to the power of the number in memory (APPL).
;BUG: the call that would get the number from memory is missing, so this is
;the same as function $26, FAC = ARG to the power of FAC.
FPWR_APPL:
        bra     FPWRT
; ----------------------------------------------------------------------------
;FAC = square root of FAC, done as FAC to the power of 0.5
SQR:    jsr     MOVAF
        lda     #<FHALF
        ldy     #>FHALF
        jsr     MOVFRM
;FAC = ARG to the power of FAC.  Call with the flags set from FACEXP.
FPWRT:  bne     LA670_NOT_ZERO          ;Branch if the exponent (FAC) is not zero
        jmp     EXP
; ----------------------------------------------------------------------------
LA670_NOT_ZERO:
        lda     ARGEXP
        bne     FPWRT1                  ;Branch if the base (ARG) is not zero
        jmp     ZEROF1
; ----------------------------------------------------------------------------
FPWRT1: ldx     #TEMPF3
        ldy     #$00
        jsr     MOVMF                   ;TEMPF3 = the exponent
        lda     ARGSGN
        bpl     FPWR1                   ;Branch if the base is positive
        jsr     INT                     ;A negative base needs a whole number for an exponent
        lda     #<TEMPF3
        ldy     #>TEMPF3
        jsr     FCOMP
        bne     FPWR1
        tya
        ldy     INTEGR
FPWR1:  jsr     MOVFA1
        tya
        pha
        jsr     LOG                     ;e ^ (LOG(base) * exponent)
        lda     #TEMPF3
        ldy     #$00
        jsr     FMULT
        jsr     EXP
        pla
        lsr     a
        bcc     NEGRTS
;FAC = -FAC
NEGOP:  lda     FACEXP
        beq     NEGRTS
        lda     FACSGN
        eor     #$FF
        sta     FACSGN
NEGRTS: rts
; ----------------------------------------------------------------------------
LOGEB2:
        .byte   $81,$38,$AA,$3B,$29,$5C,$17,$EE ;1.4426950408889634 = 1/LOG(2)

;Coefficients for EXP
EXPCON:
        .byte   $0D                     ;Degree of the polynomial: 14 coefficients follow
        .byte   $59,$4A,$00,$00,$00,$00,$00,$00 ;1.4352963262354024e-12
        .byte   $5D,$61,$DE,$B2,$87,$E1,$4C,$1C ;2.56784359934882e-11
        .byte   $61,$74,$65,$63,$9A,$8D,$D9,$14 ;4.44553827187081e-10
        .byte   $65,$72,$67,$A8,$AC,$5C,$76,$44 ;7.054911620801122e-09
        .byte   $69,$5A,$92,$9E,$9C,$AF,$3E,$0C ;1.0178086009239697e-07
        .byte   $6D,$31,$60,$11,$1D,$2E,$41,$0E ;1.3215486790144305e-06
        .byte   $70,$7F,$E5,$FE,$2C,$45,$86,$24 ;1.5252733804059836e-05
        .byte   $74,$21,$84,$89,$7C,$36,$3C,$30 ;0.00015403530393381606
        .byte   $77,$2E,$C3,$FF,$3C,$53,$39,$82 ;0.0013333558146428441
        .byte   $7A,$1D,$95,$5B,$7D,$D2,$73,$84 ;0.009618129107628465
        .byte   $7C,$63,$58,$46,$B8,$25,$05,$F8 ;0.055504108664821576
        .byte   $7E,$75,$FD,$EF,$FC,$16,$2C,$74 ;0.2402265069591007
        .byte   $80,$31,$72,$17,$F7,$D1,$CF,$7C ;0.6931471805599454
        .byte   $81,$00,$00,$00,$00,$00,$00,$00 ;1
; ----------------------------------------------------------------------------
;FAC = e to the power of FAC
EXP:
        lda     #<LOGEB2
        ldy     #>LOGEB2
        jsr     FMULT_ROM
        lda     FACOV
        adc     #$50
        bcc     STOLD
        jsr     INCRND
STOLD:  sta     OLDOV
        jsr     MOVEF
        lda     FACEXP
        cmp     #$88
        bcc     EXP1
GOMLDV: jsr     MLDVEX
EXP1:   jsr     INT
        lda     INTEGR
        clc
        adc     #$81
        beq     GOMLDV
        sec
        sbc     #$01
        pha
        ldx     #$08
SWAPLP: lda     ARGEXP,x
        ldy     FACEXP,x
        sta     FACEXP,x
        sty     ARGEXP,x
        dex
        bpl     SWAPLP
        lda     OLDOV
        sta     FACOV
        jsr     FSUBT
        jsr     NEGOP
        lda     #<EXPCON
        ldy     #>EXPCON
        jsr     POLY
        lda     #$00
        sta     ARISGN
        pla
        jsr     MLDEXP
        rts
; ----------------------------------------------------------------------------
;Evaluate a polynomial in FAC squared, then multiply by FAC.
;The address of the coefficients is in A (low byte) and Y (high byte).  They
;are read as the KERNAL sees memory.  The first byte is the degree.
POLYX:
        sta     FBUFPT
        sty     FBUFPT+1
        jsr     MOV1F
        lda     #TEMPF1
        jsr     FMULT
        jsr     POLY1
        lda     #TEMPF1
        ldy     #$00
        jmp     FMULT
; ----------------------------------------------------------------------------
;Evaluate a polynomial in FAC.  See POLYX.
POLY:   sta     FBUFPT
        sty     FBUFPT+1
POLY1:  jsr     MOV2F
        lda     (FBUFPT),y
        sta     SGNFLG
        ldy     FBUFPT
        iny
        tya
        bne     POLY3
        inc     FBUFPT+1
POLY3:  sta     FBUFPT
        ldy     FBUFPT+1
POLY2:  jsr     FMULT_ROM
        lda     FBUFPT
        ldy     FBUFPT+1
        clc
        adc     #$08
        bcc     LA7B8
        iny
LA7B8:  sta     FBUFPT
        sty     FBUFPT+1
        jsr     FADD_ROM
        lda     #TEMPF2
        ldy     #$00
        dec     SGNFLG
        bne     POLY2
        rts
; ----------------------------------------------------------------------------
;Multiplier and increment for RND
RMULC:
        .byte   $98,$35,$44,$7A,$00,$00,$00,$00 ;11879546
RADDC:
        .byte   $68,$28,$B1,$46,$00,$00,$00,$00 ;3.927677738602142e-08
;FAC = random number between 0 and 1.
;
;If FAC is positive, the next number in the sequence is made from the seed
;in RNDX.  If FAC is zero, the number is made from the VIA timers.  If FAC
;is negative, FAC itself is scrambled to make the number, which starts a
;repeatable sequence.  The result is always saved in RNDX as the next seed.
RND:    jsr     SIGN
RND_A:  bmi     RND1                    ;Branch if FAC is negative
        bne     QSETNR                  ;Branch if FAC is positive
        lda     VIA1_T1CL
        sta     FACHO
        lda     VIA1_T1CH
        sta     FACHO+5
        lda     VIA1_T2CL
        sta     FACHO+4
        lda     VIA2_T2CL
        sta     FACHO+3
        lda     VIA2_T1CL
        sta     FACHO+2
        lda     VIA1_T2CL
        sta     FACHO+1
        lda     VIA1_T2CH
        sta     FACLO
        jmp     STRNEX
; ----------------------------------------------------------------------------
QSETNR: lda     #<RNDX
        ldy     #>RNDX
        jsr     MOVFRM
        lda     #<RMULC
        ldy     #>RMULC
        jsr     FMULT_ROM
        lda     #<RADDC
        ldy     #>RADDC
        jsr     FADD_ROM
RND1:   ldx     FACLO                   ;Swap bytes of the mantissa around
        lda     FACHO
        sta     FACLO
        stx     FACHO
        ldx     FACHO+4
        lda     FACHO+3
        sta     FACHO+4
        stx     FACHO+3
        ldx     FACHO+1
        lda     FACHO+5
        sta     FACHO+1
        stx     FACHO+5
STRNEX: lda     #$00
        sta     FACSGN
        lda     FACEXP
        sta     FACOV
        lda     #$80
        sta     FACEXP
        jsr     NORMAL
        ldx     #<RNDX
        ldy     #>RNDX
GMOVMF: jmp     MOVMF
; ----------------------------------------------------------------------------
;FAC = cosine of FAC
COS:    lda     #<PI2
        ldy     #>PI2
        jsr     FADD_ROM
;FAC = sine of FAC
SIN:    jsr     MOVAF
        lda     #<TWOPI
        ldy     #>TWOPI
        ldx     ARGSGN
        jsr     FDIVF
        jsr     MOVAF
        jsr     INT
        lda     #$00
        sta     ARISGN
        jsr     FSUBT
        lda     #<FR4
        ldy     #>FR4
        jsr     FSUB_ROM
        lda     FACSGN
        pha
        bpl     SIN1
        jsr     FADDH
        lda     FACSGN
        bmi     SIN2
        lda     TANSGN
        eor     #$FF
        sta     TANSGN
SIN1:   jsr     NEGOP
SIN2:   lda     #<FR4
        ldy     #>FR4
        jsr     FADD_ROM
        pla
        bpl     SIN3
        jsr     NEGOP
SIN3:   lda     #<SINCON
        ldy     #>SINCON
        jmp     POLYX
; ----------------------------------------------------------------------------
;FAC = tangent of FAC
TAN:    jsr     MOV1F
        lda     #$00
        sta     TANSGN
        jsr     SIN
        ldx     #TEMPF3
        ldy     #$00
        jsr     GMOVMF
        lda     #<TEMPF1
        ldy     #>TEMPF1
        jsr     MOVFRM
        lda     #$00
        sta     FACSGN
        lda     TANSGN
        jsr     COSC
        lda     #TEMPF3
        ldy     #$00
        jmp     FDIV
; ----------------------------------------------------------------------------
COSC:   pha
        jmp     SIN1
; ----------------------------------------------------------------------------
PI2:
        .byte   $81,$49,$0F,$DA,$A2,$21,$68,$C8 ;1.5707963267948968 = PI/2
TWOPI:
        .byte   $83,$49,$0F,$DA,$A2,$21,$68,$C8 ;6.283185307179587 = 2*PI
FR4:
        .byte   $7F,$00,$00,$00,$00,$00,$00,$00 ;0.25

;Coefficients for SIN
SINCON:
        .byte   $09                     ;Degree of the polynomial: 10 coefficients follow
        .byte   $7A,$C5,$20,$21,$08,$FC,$AA,$14 ;-0.012031585942120619
        .byte   $7D,$55,$76,$19,$57,$C9,$9A,$AC ;0.1042291622081398
        .byte   $80,$B7,$D6,$DC,$F8,$AA,$B9,$FE ;-0.7181223017785001
        .byte   $82,$74,$7A,$1A,$68,$0C,$6A,$F4 ;3.81995258484828
        .byte   $84,$F1,$83,$A7,$EF,$44,$38,$DC ;-15.094642576822984
        .byte   $86,$28,$3C,$1A,$43,$F7,$3B,$F8 ;42.058693944897634
        .byte   $87,$99,$69,$66,$73,$15,$EC,$23 ;-76.70585975306136
        .byte   $87,$23,$35,$E3,$3B,$AD,$57,$00 ;81.60524927607503
        .byte   $86,$A5,$5D,$E7,$31,$2D,$F2,$90 ;-41.341702240399755
        .byte   $83,$49,$0F,$DA,$A2,$21,$68,$C8 ;6.283185307179587
; ----------------------------------------------------------------------------
;FAC = arctangent of FAC
ATN:    lda     FACSGN
        pha
        bpl     ATN1
        jsr     NEGOP
ATN1:   lda     FACEXP
        pha
        cmp     #$81
        bcc     ATN2
        lda     #<FONE
        ldy     #>FONE
        jsr     FDIV_ROM
ATN2:   lda     #<ATNCON
        ldy     #>ATNCON
        jsr     POLYX
        pla
        cmp     #$81
        bcc     ATN3
        lda     #<PI2
        ldy     #>PI2
        jsr     FSUB_ROM
ATN3:   pla
        bpl     ATN4
        jmp     NEGOP
; ----------------------------------------------------------------------------
ATN4:   rts
; ----------------------------------------------------------------------------
;Coefficients for ATN
ATNCON:
        .byte   $0C                     ;Degree of the polynomial: 13 coefficients follow
        .byte   $75,$62,$FE,$BA,$07,$14,$3A,$A8 ;0.0004329586526045
        .byte   $78,$D6,$D8,$CE,$16,$51,$4D,$14 ;-0.0032783034460567998
        .byte   $7A,$3E,$D1,$7D,$BD,$4C,$36,$88 ;0.0116466262745151
        .byte   $7B,$D7,$C4,$23,$CB,$01,$6B,$9C ;-0.026338643940147802
        .byte   $7C,$34,$17,$0A,$3A,$DC,$41,$78 ;0.0439672851187115
        .byte   $7C,$F7,$81,$A3,$C1,$36,$27,$00 ;-0.0604263683957329
        .byte   $7D,$19,$AE,$61,$16,$EA,$BA,$4D ;0.075039633285397
        .byte   $7D,$B9,$60,$8F,$78,$5D,$0B,$BA ;-0.0905162056548131
        .byte   $7D,$63,$72,$12,$44,$A1,$85,$B4 ;0.11105741760201479
        .byte   $7E,$92,$47,$FB,$62,$16,$0D,$43 ;-0.1428527144066838
        .byte   $7E,$4C,$CC,$BF,$F0,$C0,$7A,$64 ;0.19999980837757858
        .byte   $7F,$AA,$AA,$AA,$8E,$7D,$B0,$C0 ;-0.3333333300532515
        .byte   $80,$7F,$FF,$FF,$FF,$F5,$B9,$2C ;0.9999999999906535
; ----------------------------------------------------------------------------
;XOR operator.  Both operands are converted to signed 16-bit integers.
XOROP_MEM:
        jsr     CONUPK
; ----------------------------------------------------------------------------
XOROP:  jsr     AYINT
        lda     FACLO
        sta     INTEGR
        lda     FACHO+5
        sta     INTEGR+1
        jsr     MOVFA
        jsr     AYINT
        lda     FACLO
        eor     INTEGR
        tay
        lda     FACHO+5
        eor     INTEGR+1
        jmp     GIVAYF
; ----------------------------------------------------------------------------
LA9E6:  php                                     ; A9E6 08                       .
        sty     BAD                           ; A9E7 8C A0 03                 ...
        cpx     #$50                            ; A9EA E0 50                    .P
        bcs     LAA17                           ; A9EC B0 29                    .)
        stx     V1541_FNLEN                     ; A9EE 8E 9F 03                 ...
        tax                                     ; A9F1 AA                       .
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
        cpy     BAD                           ; AA4C CC A0 03                 ...
        bcs     LAA25                           ; AA4F B0 D4                    ..
        bra     LAA0C                           ; AA51 80 B9                    ..
; ----------------------------------------------------------------------------
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
LAA6A := *+1
        ora     #$07
        sta     MON_MMU_MODE
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
        .byte   $24  ;skip 1 byte               ; AA9B 24                       $
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
        ;TODO probably data
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
        lda     MEM_00AA
        and     $036D
        and     #$02
        beq     LABED
        ldx     #$02
        jsr     WaitXticks_
        bra     LABD7
LABED:  pla
        ldx     LSTCHR        ;X = last char
        sta     LSTCHR        ;Store this char as the last one for next time

        cmp     #$0D          ;Char = Return?
        beq     LAC2F
        cmp     #$8D          ;Char = Shift-Return?
        beq     LAC2F

        cpx     #$1B          ;Last char = ESC?
        bne     LAC03
        jmp     LB10E_ESC
; ----------------------------------------------------------------------------
LAC03:  cmp     #$1B          ;Char = Escape?
        bne     LAC08
        rts
; ----------------------------------------------------------------------------
LAC08:  bit     MEM_00AA
        bpl     LAC24
        ldy     INSRT
        beq     LAC19
        cmp     #$94          ;Char = Insert?
        beq     LAC2F
        dec     INSRT
        jmp     LAC3A
; ----------------------------------------------------------------------------
LAC19:  jsr     LB08E
        ldy     QTSW
        beq     LAC24
        cmp     #$14          ;Char = Delete?
        bne     LAC3A
LAC24:  cmp     #$13          ;Char = Home?
        bne     LAC2F
        cpx     #$13          ;Last char = Home?
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
        beq     LAC4D_RVS_OFF

        ;Reverse is on
        ora     #$80

LAC4D_RVS_OFF:
        ldx     INSFLG
        beq     LAC4D_AUTO_INSRT_OFF

        ;Auto-insert (ESC-A) is on
        pha
        jsr     CODE_94_INSERT
        pla

LAC4D_AUTO_INSRT_OFF:
        jsr     PutCharAtCursorXY
LAC50:  ldx     CursorX
        cpx     WIN_BTM_RGHT_X
        beq     LAC59_EOL_REACHED
        inc     CursorX
LAC58_RTS:
        rts

LAC59_EOL_REACHED:
        lda     MEM_00AA
        bit     #$04
        beq     JMP_CTRL_1D_CRSR_RIGHT
        bit     #$20
        beq     LAC58_RTS
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
LAC88:  jsr     LB393_SET_LSXP_FF_SET_CARRY
LAC8B:  jmp     SCROLL_WIN_UP

LAC8E:  inc     CursorY
        jmp     SCROLL_WIN_DOWN

JMP_CTRL_1D_CRSR_RIGHT:
        jmp     CTRL_1D_CRSR_RIGHT
; ----------------------------------------------------------------------------
CTRL_CODES_AND_HANDLERS:
        .byte   $07 ;CHR$(7) Bell
        .addr   CODE_07_BELL

        .byte   $09 ;CHR$(9) Tab
        .addr   CODE_09_TAB

        .byte   $0A ;CHR$(10) Linefeed
        .addr   CODE_0A_LINEFEED

        .byte   $0D ;CHR$(13) Carriage Return
        .addr   CODE_0D_RETURN

        .byte   $0E ;CHR$(14) Lowercase Mode
        .addr   CODE_0E_LOWERCASE

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
LACD4_LOOP:
        cmp     CTRL_CODES_AND_HANDLERS,x
        beq     JMP_TO_CTRL_CODE
        dex
        dex
        dex
        bpl     LACD4_LOOP
        rts
; ----------------------------------------------------------------------------
JMP_TO_CTRL_CODE:
        jmp     (CTRL_CODES_AND_HANDLERS+1,x)
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
CODE_0E_LOWERCASE:
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
        lda     MEM_00AA
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
        jsr     LB393_SET_LSXP_FF_SET_CARRY
LAD89:  rts

LAD8A:  lda     #$10
        bit     MEM_00AA
        bne     LAD91
        rts

LAD91:  jsr     LB393_SET_LSXP_FF_SET_CARRY
        bit     MEM_00AA
        bvc     LADA0
        jsr     SCROLL_WIN_DOWN
        ldy     WIN_TOP_LEFT_Y
        sty     CursorY
        rts

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
        jsr     LB393_SET_LSXP_FF_SET_CARRY
LADB3:  inc     CursorY
        rts

LADB6:  lda     #$08
        bit     MEM_00AA
        bne     LADBD
        rts

LADBD:  jsr     LB393_SET_LSXP_FF_SET_CARRY
        bit     MEM_00AA
        bvc     LADCC
        jsr     SCROLL_WIN_UP
        ldy     WIN_BTM_RGHT_Y
        sty     CursorY
        rts

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

LADDA:  ldy     CursorY
        cpy     WIN_BTM_RGHT_Y
        beq     LADEF
        jsr     LB059
        bcs     LADE8
        jsr     LB393_SET_LSXP_FF_SET_CARRY
LADE8:  inc     CursorY
        ldx     WIN_TOP_LEFT_X
        stx     CursorX
        rts

LADEF:  lda     MEM_00AA
        bit     #$08
        bne     LADF6
        rts
LADF6:  ldx     WIN_TOP_LEFT_X
        stx     CursorX
        jsr     LB393_SET_LSXP_FF_SET_CARRY
        bit     #$40
        bne     LAE04
        jmp     CODE_13_HOME

LAE04:  ldy     CursorY
        jmp     SCROLL_WIN_UP
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
        dec     CursorY
        ldx     WIN_BTM_RGHT_X
        stx     CursorX
        dey
        jsr     LB059
        bcs     LAE27
        jsr     LB393_SET_LSXP_FF_SET_CARRY
LAE27:  rts
; ----------------------------------------------------------------------------
LAE28:  lda     MEM_00AA
        bit     #$10
        bne     LAE2F
        rts
; ----------------------------------------------------------------------------
LAE2F:  jsr     LB393_SET_LSXP_FF_SET_CARRY
        ldx     WIN_BTM_RGHT_X
        stx     CursorX
        bit     MEM_00AA
        bvc     LAE42
        jsr     SCROLL_WIN_DOWN
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
LAE5B:  ldx     MEM_0380
        stx     WIN_TOP_LEFT_X
        ldx     CurMaxX
        stx     WIN_BTM_RGHT_X
        ldy     $037F
        sty     WIN_TOP_LEFT_Y
        ldy     CurMaxY
        sty     WIN_BTM_RGHT_Y
; ----------------------------------------------------------------------------
;CHR$(19) Home
CODE_13_HOME:
        jsr     LB393_SET_LSXP_FF_SET_CARRY
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
        lda     MEM_00AA
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
        jsr     RegistersXY_to_VidPtr
        pla
        sta     (VidPtrLo)
        rts
; ----------------------------------------------------------------------------
;Set VidPtr to point to cursor position (CursorX, CursorY)
CursorXY_to_VidPtr:
        ldy     CursorY
        ldx     CursorX

;Set VidPtr to point to cursor position (X, Y)
RegistersXY_to_VidPtr:
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
        jsr     RegistersXY_to_VidPtr
        lda     (VidPtrLo)
        rts
; ----------------------------------------------------------------------------
;Scroll the current window up one line
SCROLL_WIN_UP:
        ldy     WIN_TOP_LEFT_Y
        cpy     CursorY
        beq     LAF7C
        ldx     WIN_TOP_LEFT_X
        jsr     RegistersXY_to_VidPtr
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
;Scroll the current window down one line
SCROLL_WIN_DOWN:
        ldy     CursorY
        cpy     WIN_BTM_RGHT_Y
        beq     ESC_D_DELETE_LINE
        jsr     LAF3A
        sta     $F3
        ldy     WIN_BTM_RGHT_Y
LAF96:  phy
        ldx     WIN_TOP_LEFT_X
        jsr     RegistersXY_to_VidPtr
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
        jsr     RegistersXY_to_VidPtr
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
        ror     $036a,X
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
        and     MEM_00AA
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
LB07B:  jsr     LB030
        eor     #$ff
        and     $036A,x
        sta     $036A,x
        rts
; ----------------------------------------------------------------------------
LB087:  stz     $036A
        stz     $036B
        rts
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
        bne     LB0A2_NOT_FF
        lda     #$5E    ;PETSCII up-arrow
        rts

LB0A2_NOT_FF:
        phx
        pha
        lsr     a       ;
        lsr     a       ;Shift bits 7-5 into bits 2-0
        lsr     a       ;   %11111111 -> %00000111
        lsr     a       ;To make index for LB0B0_BITS_TO_FLIP
        lsr     a       ;
        tax
        pla
        eor     LB0B0_BITS_TO_FLIP,x
        plx
        rts

LB0B0_BITS_TO_FLIP:
        .byte   $80     ;%000xxxxx  $00-1F
        .byte   $00     ;%001xxxxx  $20-3F
        .byte   $40     ;%010xxxxx  $40-5F
        .byte   $20     ;%011xxxxx  $60-7F
        .byte   $40     ;%100xxxxx  $80-9F
        .byte   $C0     ;%101xxxxx  $A0-BF
        .byte   $80     ;%110xxxxx  $C0-DF
        .byte   $80     ;%111xxxxx  $E0-EF
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
ESC_KEYS_AND_HANDLERS:
        .byte   "A"
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

        .byte   "I"
        .addr   ESC_I_INSERT_LINE

        .byte   "J"
        .addr   ESC_J_MOVE_TO_START_OF_LINE

        .byte   "K"
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

        .byte   "Q"
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
LB10E_ESC:
        bit     LSTCHR
        bmi     LB126_RTS
        bvc     LB126_RTS
        lda     LSTCHR
        and     #$DF
        ldx     #$36
LB11C_LOOP:
        cmp     ESC_KEYS_AND_HANDLERS,x
        beq     LB127_JMP_TO_HANDLER
        dex
        dex
        dex
        bpl     LB11C_LOOP
LB126_RTS:
        rts
LB127_JMP_TO_HANDLER:
        jmp     (ESC_KEYS_AND_HANDLERS+1,x)
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
        jsr     SCROLL_WIN_DOWN
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
        tsb     MEM_00AA
        rts
; ----------------------------------------------------------------------------
;ESC-M Disable scrolling
ESC_M_SCROLLING_OFF:
        lda     #$40
        trb     MEM_00AA
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
        jsr     SCROLL_WIN_UP
        bra     LB1D4

;ESC-W Scroll down
ESC_W_SCROLL_DOWN:
        jsr     SaveCursorXY
        ldy     WIN_TOP_LEFT_Y
        sty     CursorY
        jsr     SCROLL_WIN_DOWN

LB1D4:  jsr     LB393_SET_LSXP_FF_SET_CARRY
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
        stz     MEM_0380
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
        stz     LSTCHR
        stz     INSFLG
        lda     #$ED
        sta     MEM_00AA
        stz     BLNOFF ;Blink = on
        jsr     ESC_Y_SET_DEFAULT_TABS
        ;Fall through to set initial modes

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
        .word   CursorX,CursorY,WIN_TOP_LEFT_X,WIN_BTM_RGHT_X
        .word   WIN_BTM_RGHT_Y,WIN_TOP_LEFT_Y,QTSW
        .word   $037D  ;TODO name
        .word   INSRT,INSFLG
        .word   $00AA ;TODO name
        .word   BLNOFF,REVERSE
        .word   $036D,$036A,$036B ;TODO names
        .word   LSTCHR,TABMAP,TABMAP+1,TABMAP+2
        .word   TABMAP+3,TABMAP+4,TABMAP+5,TABMAP+6
        .word   TABMAP+7,TABMAP+8,TABMAP+9
        .word   VidMemHi,SETUP_LCD_A,SETUP_LCD_X,SETUP_LCD_Y
EDITOR_LOCS_SIZE = * - EDITOR_LOCS

;Given a pointer to a 62-byte area in MMU RAM mode, swap the state
;of the screen editor (the locations in EDITOR_LOCS) with values in
;that area.  If called twice, the first call will swap in a new editor
;state and the second call will restore the original state.
LB293_SWAP_EDITOR_STATE:
        stx     $F1
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

        lda     (VidPtrLo)              ;A = value in editor location (in MMU KERNAL mode)
        pha                             ;Push it onto the stack
        jsr     GO_RAM_LOAD_GO_KERN     ;Load value from MMU RAM mode
        sta     (VidPtrLo)              ;Store it in the editor location (in MMU KERNAL mode)
        pla                             ;Pop value that was there originally
        jsr     GO_RAM_STORE_GO_KERN    ;Save value in MMU RAM mode

        iny                             ;Increment indirect pointer
        inx                             ;Increment index to editor locations table
        inx                             ;  twice because each is a 16-bin address
        cpx     #EDITOR_LOCS_SIZE
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
        jsr     CursorXY_to_VidPtr
        lda     (VidPtrLo)
        sta     CHAR_UNDER_CURSOR
        sec
        ror     BLNCT
        rts
; ----------------------------------------------------------------------------
LB2E4_HIDE_CURSOR:
        lda     #$FF
        trb     BLNCT
        beq     LB2EE
        lda     CHAR_UNDER_CURSOR
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

LB305:  lda     CHAR_UNDER_CURSOR
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
        jsr     LB393_SET_LSXP_FF_SET_CARRY
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
LB393_SET_LSXP_FF_SET_CARRY:
        stz     LSXP
        dec     LSXP
        rts

; ----------------------------------------------------------------------------
; Keyboard Matrix Tables
; There are 5 tables representing combinations of the MODIFIER keys:
; 1. NO MODIFIER                                NOTE:
; 2. SHIFT                                          Keys shown assume TEXT mode
; 3. CAPS-LOCK                                  IE: $41 is "a" (which is opposite to ASCII)
; 4. COMMODORE
; 5. CTRL
;
; KEY: GR=Graphic Symbol                        Character Changes:
;      S- Shifted                                     126/$7E = PI
;      C- Control                                     127/$7F = "|" (pipe)
;      {} Unknown Code                          166/$A6 = "{"
;                                                                 168/$A8 = "}"
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
        .byte   $AA,$B9,$A1,$A7,$5F,$B5,$A2,$29 ; GR    GR    GR    GR    ~?    GR    GR    )           ; ? "~" not in original set
        .byte   $2C,$5C,$A6,$2E,$91,$B6,$AF,$11 ; ,     \     {     .     UP    GR    GR    DOWN
        .byte   $A4,$7C,$FF,$1B,$1D,$A8,$7F,$9D ; GR    |     PI    ESC   RIGHT }     GR    LEFT        ; $7C=Pipe
        .byte   $8B,$AB,$8A,$A0,$32,$89,$93,$31 ; F6    GR    F4?   GR    2     F2    CLS   1           ; ? Is F4 an error?

;CTRL key                                         C0    C1    C2    C3    C4    C5    C6    C7
KBD_MATRIX_CTRL:                                ; ----- ----- ----- ----- ----- ----- ----- -----
        .byte   $80,$87,$86,$85,$88,$09,$0D,$14 ; @     F5    F3    F1    F7    TAB   RETRN DEL
        .byte   $8A,$05,$13,$1A,$34,$01,$17,$33 ; F4    CT-E  HOME  CT-Z  4     CT-A  CT-W  3
        .byte   $18,$14,$06,$03,$36,$04,$12,$35 ; CT-Z  DEL   CT-F  STOP  6     CT-D  RVS   5
        .byte   $16,$15,$08,$02,$38,$07,$19,$37 ; CT-V  CT-U  LOCK  CT-B  8     CT-G  CT-Y  7
        .byte   $0E,$0F,$0B,$0D,$1E,$0A,$09,$39 ; TEXT  CT-O  CT-K  RETRN UARRW CT-J  CT-I  9
        .byte   $12,$1C,$1B,$92,$91,$0C,$10,$11 ; RVS   CT-\  ESC   R-OFF UP    CT-L  CT-P  DOWN
        .byte   $1F,$2B,$3D,$1B,$1D,$1D,$2A,$9D ; {$1F} +     =     ESC   RIGHT RIGHT *     LEFT        ; Why CTRL-] = RIGHT?
        .byte   $8B,$11,$8C,$20,$32,$89,$13,$31 ; F6    CT-Q  F8    SPACE 2     F2    HOME  1
; ------------------------------------------------------------------------------------------------

KEYB_INIT:
        lda     #$09
        sta     MEM_03F6
        lda     #$1E
        sta     MEM_0367
        lda     #$01
        sta     MEM_0366
        sta     MEM_0365
        lda     #$FF
        sta     MEM_038E
        lda     #<LFA87_JMP_RTS_IN_KERN_MODE
        sta     RAMVEC_MEM_0336
        lda     #>LFA87_JMP_RTS_IN_KERN_MODE
        sta     RAMVEC_MEM_0336+1
        ;Fall through

;looks like clearing the keyboard buffer
LB4FB_RESET_KEYD_BUFFER:
        php
        sei
        stz     MEM_03F7
        stz     MEM_03F8
        stz     MEM_03F9
        plp
        rts
; ----------------------------------------------------------------------------
;Called at 60 Hz by the default IRQ handler (see LFA44_VIA1_T1_IRQ).
;Scan the keyboard
KL_SCNKEY:
        lda     MEM_00F4
        beq     LB54C
        dec     MEM_00F4
        lda     MEM_00AB
        and     #$07
        tax
        lda     PowersOfTwo,x
        eor     #$FF
        sta     VIA1_PORTA
        lda     MEM_00AB
        lsr     a
        lsr     a
        lsr     a
        tay
        jsr     KBD_TRIGGER_AND_READ_NORMAL_KEYS
        and     PowersOfTwo,y
        beq     LB52E
        lda     MEM_0365
        sta     MEM_00F4
LB52E:  lda     MEM_00AB
        eor     #$07
        tax
        lda     KBD_MATRIX_NORMAL,x
        cmp     #$85   ;F1
        bcc     LB53E
        cmp     #$8C+1 ;F8 +1
        bcc     LB549  ;Branch if key is F1-F8
LB53E:  dec     MEM_00F5
        bpl     LB549
        lda     MEM_0366
        sta     MEM_00F5
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
        sta     MEM_00AB
        lda     MEM_0365
        sta     MEM_00F4
        lda     MEM_0367
        sta     MEM_00F5
LB585:  lda     MEM_00AB
        eor     #$07
        tax

        jsr     KBD_READ_MODIFIER_KEYS_DO_SWITCH_AND_CAPS
        and     #MOD_CTRL ;CTRL-key pressed?
        beq     LB5AC_NO_CTRL ;Branch if no

        ;TODO what does MEM_00AA do?
        lda     #$02
        and     MEM_00AA
        beq     LB5AC_NO_CTRL

        ;Check for CTRL-Q
        ldy     KBD_MATRIX_NORMAL,x
        cpy     #$51;'Q'
        bne     LB5A3_CHECK_CTRL_S

        ;CTRL-Q pressed (in BASIC, performs cursor down)
        ;reset bit 1 of 036D
        trb     $036D
        bra     LB5E1_JMP_LBFBE ;UNKNOWN_SECS/MINS

LB5A3_CHECK_CTRL_S:
        ;Check for CTRL-S
        cpy     #$53;'S'
        bne     LB5AC_NO_CTRL

        ;CTRL-S pressed (in BASIC, performs Home)
        ;set bit 1 of $036D
        tsb     $036D
        bra     LB5E1_JMP_LBFBE ;UNKNOWN_SECS/MINS

;No CTRL-key combination pressed
LB5AC_NO_CTRL:
        lda     MODKEY
        and     MEM_038E

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

        ldy     MEM_03FA
LB5D4:  bne     LB5E1_JMP_LBFBE       ;UNKNOWN_SECS/MINS

        ldy     KBD_MATRIX_NORMAL,x
        jsr     LFA84
        sta     MEM_00AC
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
        ldx     MEM_03F7                        ; B643 AE F7 03                 ...
        dex                                     ; B646 CA                       .
        bpl     LB64C                           ; B647 10 03                    ..
        ldx     MEM_03F6                        ; B649 AE F6 03                 ...
LB64C:  cpx     MEM_03F8                        ; B64C EC F8 03                 ...
        bne     LB655                           ; B64F D0 04                    ..
        plx                                     ; B651 FA                       .
        plp                                     ; B652 28                       (
        sec                                     ; B653 38                       8
        rts                                     ; B654 60                       `
LB655:  and     #$FF                            ; B655 29 FF                    ).
        beq     LB668                           ; B657 F0 0F                    ..
LB659:  ldx     MEM_03F7                        ; B659 AE F7 03                 ...
        sta     KEYD,x                          ; B65C 9D EC 03                 ...
        dex                                     ; B65F CA                       .
        bpl     LB665                           ; B660 10 03                    ..
        ldx     MEM_03F6                        ; B662 AE F6 03                 ...
LB665:  stx     MEM_03F7                        ; B665 8E F7 03                 ...
LB668:  plx                                     ; B668 FA                       .
        plp                                     ; B669 28                       (
        clc                                     ; B66A 18                       .
        rts                                     ; B66B 60                       `
; ----------------------------------------------------------------------------
;todo probably get key from buffer
GET_KEY_FROM_KEYD_BUFFER:
        ldx     MEM_03F8                        ; B66C AE F8 03                 ...
        lda     #$00                            ; B66F A9 00                    ..
        cpx     MEM_03F7                        ; B671 EC F7 03                 ...
        beq     LB683                           ; B674 F0 0D                    ..
        lda     KEYD,x                          ; B676 BD EC 03                 ...
        dex                                     ; B679 CA                       .
        bpl     LB67F                           ; B67A 10 03                    ..
        ldx     MEM_03F6                        ; B67C AE F6 03                 ...
LB67F:  stx     MEM_03F8                        ; B67F 8E F8 03                 ...
        clc                                     ; B682 18                       .
LB683:  rts                                     ; B683 60                       `
; ----------------------------------------------------------------------------
LB684_STA_03F9:
        sta     MEM_03F9                        ; B684 8D F9 03                 ...
        rts                                     ; B687 60                       `
; ----------------------------------------------------------------------------
LB688_GET_KEY_NONBLOCKING:
        phx
        phy

        lda     MEM_03F9
        stz     MEM_03F9
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

        rol     MEM_03FA

        lda     MODKEY
        lsr     a ;Bit 0 = MOD_STOP
        bcs     LB6BD_STOP_OR_V1541_L8B46_ERROR ;Branch if STOP pressed

        jsr     V1541_READ_BYTE ;maybe returns a cbm dos error code
        bcc     LB6BD_STOP_OR_V1541_L8B46_ERROR

        bit     SXREG
        bpl     LB6BB_BRA_LD294_LD233_0A_THEN_0C

        jsr     V1541_CLEAR_ACTIVE_CHANNEL

LB6BB_BRA_LD294_LD233_0A_THEN_0C:
        bra     LD294_LD233_0A_THEN_0C

LB6BD_STOP_OR_V1541_L8B46_ERROR:
        jsr     V1541_CLEAR_ACTIVE_CHANNEL

LB6C0_V1541_SELECT_ERROR:
        stz     MEM_03FA
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
        cmp     #$92 ;Reverse off
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
LB788_LOOP:
        lda     LINE_INPUT_BUF,x
        beq     LB799
        cpx     $03FE
        beq     LB795
        inx
        bne     LB788_LOOP
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
        bne     LB7C3
LB7CF:  pha
        jsr     LB8B3
        ldx     $0402
        lda     #$00
        sta     LINE_INPUT_BUF,x
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
        sta     LINE_INPUT_BUF,x
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
LB852:  lda     LINE_INPUT_BUF,x
        sta     LINE_INPUT_BUF+1,x
        cpx     $0403
        beq     LB861
        dex
        jmp     LB852

LB861:  lda     #$20
        sta     LINE_INPUT_BUF,x
        inc     $0402
LB869:  jmp     LB8B3
; ----------------------------------------------------------------------------
LB86C_14_DELETE:
        ldx     $0403
        beq     LB886
        dec     $0403
        dex
LB875:  lda     LINE_INPUT_BUF+1,x
        sta     LINE_INPUT_BUF,x
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
        lda     LINE_INPUT_BUF,X
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
        jmp     TRANSL_INCOMING_CHAR  ;Translate char before returning it

LB948_NOT_RS232:
        bcs     LB94D ;Device >= 2
        ;Device 1 Virtual 1541
        jmp     V1541_CHRIN

LB94D:  cmp     #$03 ;Screen
        bne     LB954_NOT_SCREEN

        ;Device 3 Screen
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
        cpx     #$01  ;1 = Virtual 1541
        bne     LB983
        jmp     V1541_CHROUT ;CHROUT to Virtual 1541

LB983:  bcs     LB988
LB985:  jmp     KR_ShowChar_ ;X=0

LB988:  cpx     #$03
        beq     LB985 ;X=3 (Screen)
        bcs     LB994

        ;Device = 2 (ACIA)
        jsr     TRANSL_OUTGOING_CHAR_GIVEN_SA
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
        jsr     TRANSL_OUTGOING_CHAR_GIVEN_SA  ;Translate char before sending it
        jmp     CENTRONICS_CHROUT

LB9A7:  bcc     LB9AC
        jmp     RTC_CHROUT

LB9AC:  sec
        jmp     CIOUT ;IEC

; ----------------------------------------------------------------------------

;Translate character before sending it to ACIA TX or Centronics out
;Translation mode is set by secondary address
;Set X=SA & $0F, A=char to translate
TRANSL_OUTGOING_CHAR_GIVEN_SA:
        pha
LB9B1:  lda     SA
        and     #$0F
        tax
        pla
        jmp     TRANSL_OUTGOING_CHAR

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
LB9FE:  jsr     L9962_CLC_RTS
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
        jsr     L9962_CLC_RTS
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
        jmp     V1541_OPEN

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
LBBBC:  jmp     CRLF
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
        jmp     V1541_SAVE
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
        jsr     STOP_FROM_KERN
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
        jsr     PRINT_BCD_NIBS
        jsr     CRLF
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

        bit     VIA1_PORTB    ;XXX The C64 KERNAL does not have this
        bvs     NODEV         ;XXX but the TED-series KERNAL does.

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
        sta     MEM_04C0,x
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
        lda     MEM_04C0,x
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
LBFCE_RDTIM:
        sei
        lda     TOD_HOURS
        ldx     TOD_MINS
        ldy     TOD_SECS
        ;Fall through into LBFD8_SETTIM
; ----------------------------------------------------------------------------
LBFD8_SETTIM:
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
        lda     #T0+1
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

LC211_RTC_REGISTERS:
      .assert (* - LC211_RTC_REGISTERS) = RTC_HOURS, error
      .byte $04   ;$04=H1
                  ;$05=H10

      .assert (* - LC211_RTC_REGISTERS) = RTC_MINUTES, error
      .byte $02   ;$02=MI1
                  ;$03=MI10

      .assert (* - LC211_RTC_REGISTERS) = RTC_SECONDS, error
      .byte $00   ;$00=S1
                  ;$01=S10

      .assert (* - LC211_RTC_REGISTERS) = RTC_24H_AMPM, error
      .byte $04   ;$04=H1
                  ;$05=H10

      .assert (* - LC211_RTC_REGISTERS) = RTC_DOW, error
      .byte $06   ;$06=W
                  ;$07=don't care

      .assert (* - LC211_RTC_REGISTERS) = RTC_DAY, error
      .byte $07   ;$07=D1
                  ;$08=D10

      .assert (* - LC211_RTC_REGISTERS) = RTC_MONTH, error
      .byte $09   ;$09=MO1
                  ;$0A=MO10

      .assert (* - LC211_RTC_REGISTERS) = RTC_YEAR, error
      .byte $0B   ;$0B=Y1
                  ;$0C=Y10

RTC_DATA_SIZE = * - LC211_RTC_REGISTERS

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

        ;Copy the 8 bytes of the filename into RTC_DATA
        ldy     #RTC_DATA_SIZE-1
LC233_LOOP:
        jsr     GO_RAM_LOAD_GO_KERN ;Get byte from filename
        sta     RTC_DATA,y
        dey
        bpl     LC233_LOOP

        lda     RTC_DATA+RTC_24H_AMPM
        ror     a
        ror     a
        ror     a
        and     #%11000000
        ora     RTC_DATA
        sta     RTC_DATA+RTC_24H_AMPM

        jsr     RTC_ENABLE ;Enable RTC (clears data & control, then CS2=1)
        lda     #%10000000
        tsb     VIA2_PORTA
        php
        sei
        ldy     #$0E ;RTC register $0e??? TODO what is this???
        lda     #%01000000 ;PB6 = RTC Address Write (AW)
        jsr     RTC_SET_AND_CLEAR_BITS
        ldx     #RTC_MINUTES
LC25D_LOOP:
        lda     RTC_DATA,x
        jsr     RTC_WRITE_BYTE_TO_HW
        inx
        cpx     #RTC_DATA_SIZE
        bne     LC25D_LOOP
        jsr     RTC_DISABLE ;Disable RTC (CS2=0)
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
        jsr     RTC_READ_ALL_RTC_DATA_FROM_HW ;Read 8 bytes of time data from the RTC into RTC_DATA
        php
        sei
        sed
        lda     RTC_DATA
        ldx     RTC_DATA+RTC_24H_AMPM
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

        lda     RTC_DATA+RTC_MINUTES
        jsr     RTC_SHIFT_LOOKUP_SUBTRACT
        sta     TOD_MINS

        lda     RTC_DATA+RTC_SECONDS
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
        beq     RTC_READ_ALL_RTC_DATA_AND_GET_FIRST_VALUE
        cpx     #RTC_DATA_SIZE
        bcc     RTC_GET_NEXT_VALUE
        lda     #$0D ;Carriage return
        stz     RTC_IDX
        clc
        rts
; ----------------------------------------------------------------------------
RTC_READ_ALL_RTC_DATA_AND_GET_FIRST_VALUE:
        jsr     RTC_READ_ALL_RTC_DATA_FROM_HW
        stz     RTC_IDX
        ;Fall through
; ----------------------------------------------------------------------------
RTC_GET_NEXT_VALUE:
        ldx     RTC_IDX
        lda     RTC_DATA,x
        inc     RTC_IDX
        clc
        rts
; ----------------------------------------------------------------------------
;Read 8 bytes of time data from the RTC chip into RTC_DATA
RTC_READ_ALL_RTC_DATA_FROM_HW:

        ;Read 8 bytes of data from the RTC

        jsr     RTC_ENABLE ;Enable RTC (clears data & control, then CS2=1)
        ldx     #RTC_DATA_SIZE-1
LC2D3_LOOP:
        jsr     RTC_READ_BYTE_FROM_HW
        sta     RTC_DATA,x
        dex
        bpl     LC2D3_LOOP
        jsr     RTC_DISABLE ;Disable RTC (CS2=0)

        ;Compare the 8 bytes we just read by reading them again.  If they
        ;don't read back the same, start over from the top.  This is needed
        ;because the time might change mid-reading, and a rollover (e.g. minutes
        ;into hours) would give an invalid time.

        jsr     RTC_ENABLE ;Enable RTC (clears data & control, then CS2=1)
        ldx     #RTC_DATA_SIZE-1
LC2E4_LOOP:
        jsr     RTC_READ_BYTE_FROM_HW
        cmp     RTC_DATA,x
        bne     RTC_READ_ALL_RTC_DATA_FROM_HW
        dex
        bne     LC2E4_LOOP
        jsr     RTC_DISABLE ;Disable RTC (CS2=0)

        lda     RTC_DATA+RTC_HOURS
        and     #%00111111
        sta     RTC_DATA+RTC_HOURS

        lda     RTC_DATA+RTC_DOW
        and     #%00001111
        sta     RTC_DATA+RTC_DOW

        lda     RTC_DATA+RTC_24H_AMPM
        rol     a
        rol     a
        rol     a
        and     #%00000011
        sta     RTC_DATA+RTC_24H_AMPM

        rts
; ----------------------------------------------------------------------------
;X = offset to LC211_RTC_REGISTERS table
;Returns value in A
RTC_READ_BYTE_FROM_HW:
        ldy     LC211_RTC_REGISTERS,x ;Y = RTC register number
        phy
        jsr     RTC_READ_REGISTER_NIB ;Read low nibble into bits 3-0 of A
        sta     RTC_IDX               ;Store low nibble temporarily
        ply
        iny                           ;Increment to next RTC register number
        jsr     RTC_READ_REGISTER_NIB ;Read high nibble into bits 3-0 of A
        asl     a                     ;Rotate into high nibble of A
        asl     a
        asl     a
        asl     a
        ora     RTC_IDX               ;Add low nibble
        rts

; ----------------------------------------------------------------------------

RTC_WRITE_BYTE_TO_HW:
        pha
        and     #$0F
        ldy     LC211_RTC_REGISTERS,x
        jsr     LC337_RTC_WRITE_REGISTER_NIB
        pla
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        ldy     LC211_RTC_REGISTERS,x
        iny
        ;Fall through

LC337_RTC_WRITE_REGISTER_NIB:
        pha
        lda     #%01000000 ;PA6 = RTC Address Write (AW)
        jsr     RTC_SET_AND_CLEAR_BITS
        ply
        lda     #%00100000 ;PA5 = RTC Write (WR)
        ;Fall through

; ----------------------------------------------------------------------------
;Called with RTC register number in Y
;Called with bits to strobe high->low in A
;       pa7 = rtc "stop"
;       pa6 = rtc "address write"
;       pa5 = rtc "write"
;       pa4 = rtc "read"
;       pa0-3 = rtc data
;Set RTC bits in Y, then Set->Clear RTC bits in A
RTC_SET_AND_CLEAR_BITS:
        pha

        lda     #%01111111
        trb     VIA2_PORTA ;Clear all bits except for STOP

        tya
        tsb     VIA2_PORTA ;Set bits specified by Y (RTC register number)

        pla
        tsb     VIA2_PORTA ;Set bits specified by A (assert RTC control signals)
        trb     VIA2_PORTA ;Clear bits specified by A (release RTC control signals)
        rts
; ----------------------------------------------------------------------------
; Read a register from the RTC chip.  A register is a nibble.
; $40 is for AW (address write) signal for the RTC.
; Input: Y = RTC register number
; Output: A = nibble read
RTC_READ_REGISTER_NIB:
        lda     #%01000000 ;PB6 = RTC Address Write (AW)
        jsr     RTC_SET_AND_CLEAR_BITS
        lda     #%00011111
        tsb     VIA2_PORTA
        ldy     VIA2_PORTA
        trb     VIA2_PORTA
        tya
        and     #$0F
        rts
; ----------------------------------------------------------------------------
;Enable RTC (clears data & control, then CS2=1)
RTC_ENABLE:
        stz     VIA2_PORTA ;PA7=0 Don't care (not connected to MSM58321)
                           ;PA6=0 MSM58321 AW (Address Write)
                           ;PA5=0 MSM58321 WR (Write)
                           ;PA4=0 MSM58321 RD (Read)
                           ;PA3=0 MSM58321 DATA3
                           ;PA2=0 MSM58321 DATA2
                           ;PA1=0 MSM58321 DATA1
                           ;PA0=0 MSM58321 DATA0

        lda     #%00000010 ;PB1=RTCEN
        tsb     VIA1_PORTB ;Set PB1=1 to set MSM58321 CS1=1 (RTC enabled)
        rts
; ----------------------------------------------------------------------------
;Disable RTC (CS2=0)
RTC_DISABLE:
        lda     #%00000010 ;PB1=RTCEN
        trb     VIA1_PORTB ;Set PB1=0 to set MSM58321 CS1=0 (RTC disabled)
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
;
;XXX CLCD Version Differences
;
;  /BUSY
;   - On Bil Herd's prototype (this firmware), Centronics /BUSY is PB6.
;   - On the schematics, PB6 is Barcode Data In and Centronics /BUSY is PB2.
;
;  74HC374 CP
;   - On Bil Herd's prototype (this firmware), 74HC374 CP is PB5.
;   - On the schematics, PB5 is Modem-related and 74HC374 CP is PB1.
;
CENTRONICS_CHROUT:
        ldx     SATUS
        bne     LC3AC

        pha                 ;Save byte to send
        ldy     #$F0        ;Y = number of loops before timeout
LC393:  lda     VIA2_PORTB
        and     #%01000000  ;PB6 = Centronics /BUSY input (XXX See "version differences" above)
        bne     LC3B0       ;Branch if /BUSY=high

        lda     MODKEY
        lsr     a           ;Bit 0 = MOD_STOP
        lda     #$00
        bcs     LC3AB       ;Return early if pressed

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

        ;PA0-7 = 74HC374 inputs 0-7 (data lines)
        pla                 ;A = byte to send
        sta     VIA2_PORTA  ;Put byte on 74HC374 input lines

        ;Pulse 74HC374 CP low->high so 74HC374 latches its input lines.
        ;This puts the byte on the Centronics data lines.
        ;PB5 = 74HC374 CP input (XXX See "version differences" above)
        lda     #%00100000
        trb     VIA2_PORTB  ;PB5 = low
        tsb     VIA2_PORTB  ;PB5 = high (74HC374 latches on rising edge)

        ;Pulse Centronics /STB high -> low.
        ;This signals the printer that a byte is ready on the data lines.
        ;CA2 = Centronics /STB
        lda     #$02
        tsb     VIA2_PCR    ;CA2 = high
        trb     VIA2_PCR    ;CA2 = low (Centronics latches on falling edge)

        clc
        rts

; ----------------------------------------------------------------------------

;Translate a character received from the ACIA RX
;Called with A = char, X = channel (from secondary address & $0F)
;Channel number specifies translation mode (0-6, 0=no translation)
;Returns translated char in A, destroys X, preserves Y
;        carry set if channel number is bad, otherwise carry clear.
TRANSL_INCOMING_CHAR:
        pha     ;Push original char onto stack
        lda     LC44A_INCOMING_CHAR_OFFSETS_TABLE_POS-1,x
        bra     TRANSLATE

;Translate a character before sending it to ACIA TX or Centronics
;Called with A = char, X = channel (from secondary address & $0F)
;Returns translated char in A, destroys X, preserves Y
;Channel number specifies translation mode (0-6, 0=no translation)
;Returns translated char in A, destroys X, preserves Y
;        carry set if channel number is bad, otherwise carry clear.
TRANSL_OUTGOING_CHAR:
        pha     ;Push original char onto stack
        lda     TRANSL_OUTGOING_CHAR_OFFSETS_TABLE_POS-1,x
        ;Fall through

;Translate a character
;Called with:
; A = starting index to TRANSL_HANDLER_OFFSETS table
; X = Channel number
; Byte on top of stack is original char to translate
;Returns:
; A = translated character
; carry = set if bad channel (not 0-6), otherwise carry clear
TRANSLATE:
        cpx     #$00 ;Channel = 0?
        bne     LC3DC_NONZERO
        clc                   ;Carry clear = channel ok
LC3DA_NO_CHANGE:
        pla                   ;Pull original character off stack
        rts

LC3DC_NONZERO:
        cpx     #$07
        bcs     LC3DA_NO_CHANGE  ;Branch if channel number >= 7 (carry set = bad channel)

        ;Channel number is 1-6
        plx                   ;X = Pull original character to translate
        phy                   ;Push whatever Y was on entry
        tay                   ;Y = starting index to TRANSL_HANDLER_OFFSETS table
        txa                   ;A = original character to translate

LC3E4_TRY_NEXT_HANDLER:
        phy                               ;Save handler-to-try index to handler we're trying
        ldx     TRANSL_HANDLER_OFFSETS,y  ;Get the handler's offset in the address table
        jsr     JMP_TO_TRANSL_HANDLER_X   ;Call the handler
        ply                               ;Get the handler-to-try index back
        iny                               ;Increment to try the next handler
        bcs     LC3E4_TRY_NEXT_HANDLER    ;Keep trying until a handler returns carry clear

        ply                               ;Pull whatever Y was on entry
        rts

JMP_TO_TRANSL_HANDLER_X:
        jmp     (TRANSL_HANDLERS,x)
TRANSL_HANDLERS:
        .addr   TRANSL_HANDLER_X00
        .addr   TRANSL_HANDLER_X02
        .addr   TRANSL_HANDLER_X04
        .addr   TRANSL_HANDLER_X06
        .addr   TRANSL_HANDLER_X08
        .addr   TRANSL_HANDLER_X0A
        .addr   TRANSL_HANDLER_X0C
        .addr   TRANSL_HANDLER_X0E
        .addr   TRANSL_HANDLER_X10
        .addr   TRANSL_HANDLER_X12
        .addr   TRANSL_HANDLER_X14
        .addr   TRANSL_HANDLER_X16
        .addr   TRANSL_HANDLER_X18
        .addr   TRANSL_HANDLER_X1A
        .addr   TRANSL_HANDLER_X1C
        .addr   TRANSL_HANDLER_X1E
        .addr   TRANSL_HANDLER_X20

TRANSL_HANDLER_OFFSETS:
;Each is an offset to the TRANSL_HANDLERS table above
;The handlers are called in order until one returns carry clear
;Last handler is always TRANSL_HANDLER_X00 which just returns carry clear
        .byte   $02,$04,$06,$08,$0A,$0C,0     ;$00-06  Outgoing char on Channel 1
        .byte   $02,$06,$08,$0A,$0C,0         ;$07-0C  Outgoing char on Channel 2
        .byte   $02,$18,$06,$1E,$0A,$1C,$10,0 ;$0D-14  Outgoing char on Channel 3
        .byte   $02,$16,$0E,0                 ;$15-18  Outgoing char on Channel 4,5
        .byte   $02,$1A,$1C,$10,0             ;$19-1D  Outgoing char on Channel 6
        .byte   $04,$06,$14,0                 ;$1E-21  Incoming char on Channel 1
        .byte   $04,$12,0                     ;$22-24  Incoming char on Channel 2
        .byte   $04,$20,0                     ;$25-27  Incoming char on Channel 3
        .byte   $06,$14,0                     ;$28-2A  Incoming char on Channel 4
        .byte   $12,0                         ;$2B-2C  Incoming char on Channel 5
        .byte   $20,0                         ;$2B-2E  Incoming char on Channel 6

TRANSL_OUTGOING_CHAR_OFFSETS_TABLE_POS:
;Each is a starting position in the TRANSL_HANDLER_OFFSETS table above
        .byte   $00   ;Outgoing char on Channel 1
        .byte   $07   ;Outgoing char on Channel 2
        .byte   $0D   ;Outgoing char on Channel 3
        .byte   $15   ;Outgoing char on Channel 4
        .byte   $15   ;Outgoing char on Channel 5
        .byte   $19   ;Outgoing char on Channel 6

LC44A_INCOMING_CHAR_OFFSETS_TABLE_POS:
;Each is a starting position in the TRANSL_HANDLER_OFFSETS table above
        .byte   $1E   ;Incoming char on Channel 1
        .byte   $22   ;Incoming char on Channel 2
        .byte   $25   ;Incoming char on Channel 3
        .byte   $28   ;Incoming char on Channel 4
        .byte   $2B   ;Incoming char on Channel 5
        .byte   $2D   ;Incoming char on Channel 6

; ----------------------------------------------------------------------------
TRANSL_HANDLER_X20:
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
TRANSL_HANDLER_X04:
        cmp     #'A'
        bcc     LC494
        cmp     #'Z'+1
        bcs     LC494
        eor     #$20  ;swap upper/lower
        clc
        rts
LC494:  sec
        rts
; ----------------------------------------------------------------------------
TRANSL_HANDLER_X06:
        cmp     #'a'
        bcc     LC4A2
        cmp     #'z'+1
        bcs     LC4A2
        eor     #$20  ;swap lower/upper
        clc
        rts
LC4A2:  sec
        rts
; ----------------------------------------------------------------------------
TRANSL_HANDLER_X14:
        ldx     #$04
LC4A6_LOOP:
        cmp     LC4B5,x
        beq     LC4B0_FOUND
        dex
        bpl     LC4A6_LOOP
        sec
        rts
LC4B0_FOUND:
        lda     LC4BD,x
        clc
        rts
LC4B5:  .byte   $7B,$7D,$7E,$60,$5F,$7B,$7D,$60
LC4BD:  .byte   $A6,$A8,$5F,$BA,$A4,$E6,$E8,$FA
; ----------------------------------------------------------------------------
TRANSL_HANDLER_X02:
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
TRANSL_HANDLER_X1A:
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
TRANSL_HANDLER_X1C:
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
TRANSL_HANDLER_X10:
        cmp     #$FF
        bne     LC55B
        lda     #$7F
        clc
        rts
LC55B:  sec
        rts
; ----------------------------------------------------------------------------
TRANSL_HANDLER_X12:
        cmp     #$5F
        bne     LC565
        lda     #$A4
        clc
        rts
LC565:  sec
        rts
; ----------------------------------------------------------------------------
TRANSL_HANDLER_X18:
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
TRANSL_HANDLER_X16:
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
TRANSL_HANDLER_X1E:
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
TRANSL_HANDLER_X0A:
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
TRANSL_HANDLER_X08:
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
TRANSL_HANDLER_X0C:
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
TRANSL_HANDLER_X0E:
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
MMU_HELPER_ROUTINES_SIZE = * - MMU_HELPER_ROUTINES


KL_RESTOR:
        ldx     #<VECTSS
        ldy     #>VECTSS
        clc
KL_VECTOR:
        php
        sei
        stx     FNADR
        sty     FNADR+1
        ldx     #MMU_HELPER_ROUTINES_SIZE-1
LC6A3_LOOP:
        lda     MMU_HELPER_ROUTINES,x   ;from this ROM
        sta     GO_RAM_LOAD_GO_APPL,x   ;into RAM
        dex
        bpl     LC6A3_LOOP
        ldy     #FNADR
        sty     SINNER
        sty     $0360
        ldy     #36-1 ;36 bytes (18 vectors)
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
;Back up the KERNAL RAM vectors
;Swap 36 bytes between RAMVEC_IRQ and RAMVEC_BACKUP
SWAP_RAMVEC:
        sei
        ldx     #36-1 ;36 bytes (18 vectors)
LC6CE_LOOP:
        ldy     RAMVEC_IRQ,x
        lda     RAMVEC_BACKUP,x
        sta     RAMVEC_IRQ,x
        tya
        sta     RAMVEC_BACKUP,x
        dex
        bpl     LC6CE_LOOP
        rts
; ----------------------------------------------------------------------------

;
; Start of the machine language monitor
;

; ----------------------------------------------------------------------------
MON_START:
        stz     MEM_03B7
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
        sta     T2
        sta     T2+1
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
        jsr     CRLF
        stz     CHRPTR
        ldx     #$00
LC76E_GET_NEXT_CHAR:
        jsr     LFD3D_CHRIN ;BASIN
        sta     LINE_INPUT_BUF,x
        stx     BUFEND
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
        ldx     #MON_CMD_COUNT-1 ;X = point to last entry in commands table
LC78A_CMD_SEARCH_LOOP:
        cmp     MON_COMMANDS,x
        beq     LC794_FOUND_CMD
        dex
        bpl     LC78A_CMD_SEARCH_LOOP
        bmi     MON_BAD_COMMAND
LC794_FOUND_CMD:
        cpx     #MON_CMD_LOAD_IDX
        bcs     LC7A6_FOUND_CMD_L_S_V ;Branch if >= "L" index (command is L,S,V)
        ;Command is not L,S,V
        txa
        asl     a
        tax
        lda     MON_CMD_ENTRIES+1,x
        pha
        lda     MON_CMD_ENTRIES,x
        pha
        jmp     PARSE
LC7A6_FOUND_CMD_L_S_V:
        sta     V1541_FNLEN
        jsr     CRLF
        jmp     MON_CMD_LOAD_SAVE_VERIFY
; ----------------------------------------------------------------------------
MON_CMD_MEMORY:
        bcs     LC7B9
        jsr     T0TOT2
        jsr     PARSE
        bcc     LC7BF
LC7B9:  lda     #8-1  ;8 lines of memory to print
        sta     T0
        bne     LC7D0_LOOP
LC7BF:  jsr     SUB0M2
        lsr     a
        ror     T0
        lsr     a
        ror     T0
        lsr     a
        ror     T0
        lsr     a
        ror     T0
        sta     T0+1
LC7D0_LOOP:
        jsr     STOP_FROM_KERN
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
        lda     T0
        ldy     T0+1
        sta     $03B6 ;PC low
        sty     $03B5 ;PC high

        ;Set new SR, AC, XR, YR, SP
        ldy     #$00
LC7F3_LOOP:
        jsr     PARSE
        bcs     LC81B_DONE
        lda     T0
        sta     MEM_03B7,y
        iny
        cpy     #$05 ;0=SR, 1=AC, 2=XR,3=YR,4=SP
        bcc     LC7F3_LOOP

        ;Set new MODE
        ;Valid values are 0, 1, 2.  Any other value leaves mode unchanged.
        jsr     PARSE
        bcs     LC81B_DONE
        lda     T0
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
        jsr     T0TOT2
        ldy     #$00
LC82B_LOOP:
        jsr     PARSE
        bcs     LC83A_MODFIY_DONE ;Branch if no input
        lda     T0
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
        lda     T0
        sta     $03B6
        lda     T0+1
        sta     $03B5
LC854:  jsr     CRLF
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
        lda     MEM_03B7
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
MON_CMD_LOAD_IDX = * - MON_COMMANDS
        .byte   "L" ;Load     \
        .byte   "S" ;Save      | L,S,V are handled separately, not in the table below
        .byte   "V" ;Verify   /
MON_CMD_COUNT = * - MON_COMMANDS

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
        jsr     PUTT2
        ldy     #0
LC8C4:  tya
        and     #$03
        bne     LC8CF
        jsr     PRIMM
        .byte   "  ",0
LC8CF:  jsr     PICK1
        jsr     PUTHXS
        iny
        cpy     #$10
        bcc     LC8C4
        jsr     PRIMM
        .byte   ":",$12,$00
        ldy     #$00
LC8E2:  jsr     PICK1
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
        stz     TMPC
        lda     #$00
        sta     WRAP
        bra     LC909_TRANSFER_OR_COMPARE
; ----------------------------------------------------------------------------
MON_CMD_TRANSFER:
        lda     #$80
        sta     WRAP
        jsr     LCB7E
        bcs     LC952_TRANSFER_BAD_ARG
        bra     LC913

LC909_TRANSFER_OR_COMPARE:
        jsr     LCB67
        bcs     LC952_TRANSFER_BAD_ARG
        jsr     PARSE
        bcs     LC952_TRANSFER_BAD_ARG
LC913:  jsr     CRLF
        ldy     #$00
LC918:  jsr     PICK1
        bit     WRAP
        bpl     LC922
        jsr     LCC46
LC922:  pha
        jsr     LCC6A
        sta     MSAL
        pla
        cmp     MSAL
        beq     LC935
        jsr     STOP_FROM_KERN
        beq     LC94F_TRANSFER_DONE
        jsr     PUTT2
LC935:  lda     TMPC
        beq     LC941
        jsr     DECT0
        jsr     LCB52
        bra     LC94A
LC941:  inc     T0
        bne     LC947
        inc     T0+1
LC947:  jsr     INCT2
LC94A:  jsr     DECT1
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
        bne     HT50
        jsr     GNC
HT30:  sta     HULP,y  ;TODO TED-series monitor source says HULP here is a bug; see ht30 there
        iny
        jsr     GNC
        beq     LC98A
        cpy     #$20
        bne     HT30
        beq     LC98A
HT50:  sty     BAD
        jsr     PARGOT
HT60:  lda     T0
        sta     HULP,y ;TODO TED-series monitor source says HULP here is a bug; see ht60 there
        iny
        jsr     PARSE
        bcs     LC98A
        cpy     #$20
        bne     HT60
LC98A:  sty     V1541_FNLEN
        jsr     CRLF
LC990:  ldx     #$00
        ldy     #$00
LC994:  jsr     PICK1
        cmp     HULP,x
        bne     LC9AB
        iny
        inx
        cpx     V1541_FNLEN
        bne     LC994
        jsr     STOP_FROM_KERN
        beq     LC9B3_HUNT_DONE
        jsr     PUTT2
LC9AB:  jsr     INCT2
        jsr     DECT1
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
        lda     #>HULP
        sta     FNADR+1
        lda     #<HULP
        sta     FNADR
LC9D0:  jsr     GNC
        beq     LCA33_TRY_LOAD_OR_VERIFY
        cmp     #' '
        beq     LC9D0
        cmp     #'"'
        bne     LC9F5_LSV_BAD_ARG
        ldx     CHRPTR
LC9DF_LOOP:
        cpx     BUFEND
        bcs     LCA33_TRY_LOAD_OR_VERIFY
        lda     LINE_INPUT_BUF,x
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
        stx     CHRPTR
        jsr     GNC
        jsr     PARSE
        bcs     LCA33_TRY_LOAD_OR_VERIFY
        lda     T0
        beq     LC9F5_LSV_BAD_ARG
        cmp     #$03
        beq     LC9F5_LSV_BAD_ARG
        sta     FA
        jsr     PARSE
        bcs     LCA33_TRY_LOAD_OR_VERIFY
        jsr     T0TOT2
        jsr     PARSE
        bcs     LC9F5_LSV_BAD_ARG
        jsr     CRLF
        ldx     T0
        ldy     T0+1
        lda     V1541_FNLEN
        cmp     #'S' ;SAVE
        bne     LC9F5_LSV_BAD_ARG
        lda     #$00
        sta     SA
        lda     #T2
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
        jsr     PARSE
        bcs     LCA70_FILL_BAD_ARG
        ldy     #$00
LCA60_FILL_LOOP:
        lda     T0
        jsr     LCC4B
        jsr     INCT2
        jsr     DECT1
        bcs     LCA60_FILL_LOOP
        jmp     MON_MAIN_INPUT
LCA70_FILL_BAD_ARG:
        jmp     MON_BAD_COMMAND
; ----------------------------------------------------------------------------
;Decrement CHRPTR then parse 16-bit hex value from user input
PARGOT:
        dec     CHRPTR

;Parse 16-bit hex value from user input
PARSE:
        lda     #$00
        sta     T0
        sta     T0+1
        sta     V1541_BYTE_TO_WRITE ;not really; location has multiple uses
                                    ;it's called SYREG here
PAR005:
        jsr     GNC
        beq     PAR040
        cmp     #' '
        beq     PAR005
PAR006:
        cmp     #' '
        beq     PAR030
        cmp     #','
        beq     PAR030
        cmp     #'0'
        bcc     PARERR
        cmp     #'F'+1
        bcs     PARERR
        cmp     #'9'+1
        bcc     PAR010
        cmp     #'A'
        bcc     PARERR
        sbc     #$08
PAR010: sbc     #$2F
        asl     a
        asl     a
        asl     a
        asl     a
        ldx     #$04
PAR015: asl     a
        rol     T0
        rol     T0+1
        dex
        bne     PAR015
        inc     V1541_BYTE_TO_WRITE ;not really; location has multiple uses
        jsr     GNC
        bne     PAR006
PAR030:
        lda     V1541_BYTE_TO_WRITE ;not really; location has multiple uses
        clc
PAR040:
        rts
PARERR:
        pla
        pla
        jmp     MON_BAD_COMMAND
; ----------------------------------------------------------------------------
;print t2 as 4 hex digits: .x destroyed, .y preserved
;Print a hex word given at ZP locs and then a space.
PUTT2:
        lda     T2
        ldx     T2+1

;Print a hex word and then a space.
;Input: X = high byte, A = low byte
PUTWRD:
        pha
        txa
        jsr     PUTHEX
        pla

;Print a hex byte and a space
PUTHXS:
        jsr     PUTHEX

;Print a space
PUTSPC:
        lda     #$20
        .byte   $2C

;Print a carriage return
CRLF:
        lda     #$0D ;CHR$(13) Carriage Return
        jmp     KR_ShowChar_
; ----------------------------------------------------------------------------
;  print .a as 2 hex digits
; Byte as hex print function, prints byte in A as hex number.
; X is saved to $39D and loaded back then.
PUTHEX:
        stx     SXREG
        jsr     MAKHEX
        jsr     KR_ShowChar_
        txa
        ldx     SXREG
        jmp     KR_ShowChar_
; ----------------------------------------------------------------------------
;  convert .a to 2 hex digits & put msb in .a, lsb in .x
; Byte to hex converter
; Input: A = byte
; Output: A = high nibble hex ASCII digit, X = low nibble hex ASCII digit
MAKHEX:
        pha
        jsr     MAKHX1
        tax
        pla
        lsr     a
        lsr     a
        lsr     a
        lsr     a

MAKHX1:
; Nibble to hex converter
; Input: A = byte (low nibble is used only)
; Output: A = hex ASCII digit
        and     #$0F
        cmp     #$0A
        bcc     MAKHX2
        adc     #$06
MAKHX2:  adc     #'0'
        rts
; ----------------------------------------------------------------------------
;Get next character
GNC:
        stx     SXREG
        ldx     CHRPTR
        cpx     BUFEND
        bcs     GNC99
        lda     LINE_INPUT_BUF,x
        cmp     #':'                ;eol-return with z=1
        beq     GNC99
        inc     CHRPTR
GNC98:  php
        ldx     SXREG
        plp
        rts
GNC99:  lda     #$00
        beq     GNC98

T0TOT2:  lda     T0
        sta     T2
        lda     T0+1
        sta     T2+1
        rts
; ----------------------------------------------------------------------------
SUB0M2: sec
        lda     T0
        sbc     T2
        sta     T0
        lda     T0+1
        sbc     T2+1
        sta     T0+1
        rts
; ----------------------------------------------------------------------------
DECT0:  lda     #$01
SUBT0:  sta     SXREG
        sec
        lda     T0
        sbc     SXREG
        sta     T0
        lda     T0+1
        sbc     #$00
        sta     T0+1
        rts
; ----------------------------------------------------------------------------
DECT1:  sec
        lda     T1
        sbc     #$01
        sta     T1
        lda     T1+1
        sbc     #$00
        sta     T1+1
        rts
; ----------------------------------------------------------------------------
LCB52:  lda     T2
        bne     LCB58
        dec     T2+1
LCB58:  dec     T2
        rts
; ----------------------------------------------------------------------------
INCT2:  lda     #$01
ADDT2:  clc
        adc     T2
        sta     T2
        bcc     LCB66
        inc     T2+1
LCB66:  rts
; ----------------------------------------------------------------------------
LCB67:  bcs     LCB7D
        jsr     T0TOT2
        jsr     PARSE
        bcs     LCB7D
        jsr     SUB0M2
        lda     T0
        sta     T1
        lda     T0+1
        sta     T1+1
        clc
LCB7D:  rts
; ----------------------------------------------------------------------------
LCB7E:  bcs     LCBE0
        jsr     T0TOT2
        jsr     PARSE
        bcs     LCBE0
        lda     T0
        sta     MSAL
        lda     T0+1
        sta     $D3
        jsr     PARSE
        lda     T0+1
        pha
        lda     T0
        pha
        cmp     T2
        bcc     LCBAB
        bne     LCBA5
        lda     T0+1
        cmp     T2+1
        bcc     LCBAB
LCBA5:  lda     #$01
        sta     TMPC
        bra     LCBAD
LCBAB:  stz     TMPC
LCBAD:  lda     MSAL
        sta     T0
        lda     $D3
        sta     T0+1
        jsr     SUB0M2
        lda     T0
        sta     T1
        lda     T0+1
        sta     T1+1
        lda     TMPC
        beq     LCBD9
        lda     MSAL
        sta     T2
        lda     $D3
        sta     T2+1
        pla
        clc
        adc     T1
        sta     T0
        pla
        adc     T1+1
        sta     T0+1
        clc
        rts
; ----------------------------------------------------------------------------
LCBD9:  pla
        sta     T0
        pla
        sta     T0+1
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
        jsr     PUTHEX

        ldy     #$00
LCC25_LOOP:
        lda     $03B5+1,y
        jsr     PUTHXS ;0=PC low, 1=SR, 2=AC, 3=XR, 4=YR, 5=SP
        iny
        cpy     #$06
        bcc     LCC25_LOOP

        jsr     PUTSPC
        lda     MON_MMU_MODE
        jsr     PUTHXS

        lda     $03B6 ;PC low
        sta     T2
        lda     $03B5 ;PC high
        sta     T2+1
        jmp     MON_DISASM_OPCODE_MNEMONIC
; ----------------------------------------------------------------------------
LCC46:  pha
        lda     #T0
        bra     LCC4E
LCC4B:  pha
LCC4C:  lda     #T2
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
PICK1:  lda     #T2
        .byte   $2C
LCC6A:  lda     #T0
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
        jsr     T0TOT2
        jsr     PARSE
        bcc     LCC9F
LCC99:  lda     #$14
        sta     T0
        bne     DISA30
LCC9F:  jsr     SUB0M2
DISA30: jsr     CRLF
        jsr     STOP_FROM_KERN
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
;DIS300
LCCBE_DISASM_DOT_ADDR_OPCODE_MNEUMONIC:
        jsr     PRIMM
        .byte   ". ",0

;"B000  25 F1    AND $F1"
;DIS400
MON_DISASM_ADDR_OPCODE_MNEUMONIC:
        jsr     PUTT2

;" 25 F1    AND $F1"
MON_DISASM_OPCODE_MNEMONIC:
        jsr     PUTSPC
        ldy     #$00
        jsr     PICK1
        sta     $03A2
        jsr     DSET
        pha
        ldx     LENGTH
        inx
PRADR0:  dex
        bpl     PRADRL
        jsr     PRIMM
        .byte   "   ",0
        jmp     PRADRM
; ----------------------------------------------------------------------------
PRADRL: jsr     PICK1
        jsr     PUTHXS
PRADRM: iny
        cpy     #$03
        bcc     PRADR0
        pla
        ldx     #$03
        jsr     PRNME
        ldx     #$06
PRADR1: cpx     #$03
        bne     PRADR3
        ldy     LENGTH
        beq     PRADR3
PRADR2: lda     FORMAT
        cmp     #$E8
        bcs     RELADR
        jsr     PICK1
        jsr     PUTHEX
        dey
        bne     PRADR2
PRADR3: asl     FORMAT
        bcc     PRADR4
        lda     CHAR1-1,x
        jsr     KR_ShowChar_
        pha
        lda     $03A2
        cmp     #$7C
        bne     LCD2C
        pla
        lda     CHAR2_7C-1,x            ;JMP (abs,X) has a table of its own
        beq     PRADR4
        bra     LCD32
LCD2C:  pla
LCD2D:  lda     CHAR2-1,x
        beq     PRADR4
LCD32:  jsr     KR_ShowChar_
PRADR4:  dex
        bne     PRADR1
        rts
; ----------------------------------------------------------------------------
RELADR:  jsr     PICK1
        jsr     PCADJ3
        clc
        adc     #$01
        bne     RELAD2
        inx
RELAD2:  jmp     PUTWRD
; ----------------------------------------------------------------------------
PCADJ3:  ldx     T2+1
        tay
        bpl     PCADJ4
        dex
PCADJ4:  sec
        adc     T2
        bcc     PCRTS
        inx
PCRTS:  rts
; ----------------------------------------------------------------------------
DSET:  lsr     a
        tay
        bcc     IEVEN
        lsr     a
        bcs     ERR
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
IEVEN:  lsr     a
        tax
        lda     NMODE,x
        bcs     RTMODE
        lsr     a
        lsr     a
        lsr     a
        lsr     a
RTMODE:  and     #$0F
        bne     GETFMT
ERR:  ldy     #$88
        lda     #$00
GETFMT:  tax
        lda     NMODE2,x
        sta     FORMAT
        and     #$03
        sta     LENGTH
        tya
        ldy     #$00
        rts
; ----------------------------------------------------------------------------
LCD92:  ldy     #$16
        lda     #$01
        bra     GETFMT
; ----------------------------------------------------------------------------
; print mnemonic
; enter x=3 characters
PRNME:  tay
        lda     LCEA7_PRNME,y
        tay
        lda     LCE25_PRNME,y
        sta     T1
        iny
        lda     LCE25_PRNME,y
        sta     T1+1
PRMN1:  lda     #$00
        ldy     #$05
PRMN2:  asl     T1+1
        rol     T1
        rol     a
        dey
        bne     PRMN2
        adc     #$3F
        jsr     KR_ShowChar_
        dex
        bne     PRMN1
        jmp     PUTSPC
; ----------------------------------------------------------------------------
NMODE:  .byte   $40,$22,$45,$33,$D8,$2F,$45,$39 ; CDBF 40 22 45 33 D8 2F 45 39  @"E3./E9
        .byte   $30,$22,$45,$33,$D8,$FF,$45,$99 ; CDC7 30 22 45 33 D8 FF 45 99  0"E3..E.
        .byte   $40,$02,$45,$33,$D8,$0F,$44,$09 ; CDCF 40 02 45 33 D8 0F 44 09  @.E3..D.
        .byte   $40,$22,$45,$B3,$D8,$FF,$44,$E9 ; CDD7 40 22 45 B3 D8 FF 44 E9  @"E...D.
        .byte   $D0,$22,$44,$33,$D8,$FC,$44,$39 ; CDDF D0 22 44 33 D8 FC 44 39  ."D3..D9
        .byte   $11,$22,$44,$33,$D8,$FC,$44,$9A ; CDE7 11 22 44 33 D8 FC 44 9A  ."D3..D.
        .byte   $10,$22,$44,$33,$D8,$0F,$44,$09 ; CDEF 10 22 44 33 D8 0F 44 09  ."D3..D.
        .byte   $10,$22,$44,$33,$D8,$0F,$44,$09 ; CDF7 10 22 44 33 D8 0F 44 09  ."D3..D.
        .byte   $62,$13,$7F,$A9                 ; CDFF 62 13 7F A9              b...
NMODE2: .byte   $00,$21,$81,$82,$00,$00,$59,$4D ; CE03 00 21 81 82 00 00 59 4D  .!....YM
        .byte   $49,$92,$86,$4A,$85,$9D,$4E,$91
;Characters printed around an operand: a pair for each of the six mode bits
;in FORMAT.  The bits are taken with X = 6 down to 1, so the tables are read
;at CHAR1-1,X and CHAR2-1,X, as in the TED-series monitor.
CHAR1:  .byte   $2C,$29,$2C,$23,$28,$24         ;,  )  ,  #  (  $
CHAR2:  .byte   $59,$00,$58,$24,$24,$00         ;Y     X  $  $
;CHAR2 for JMP (abs,X), opcode $7C, which is new in the 65C02.  It has the
;same mode as an (indirect),Y operand, with X in place of Y, so the monitor
;shows it as JMP ($nnnn),X and expects it to be typed that way.
CHAR2_7C:
        .byte   $58,$00,$58,$24,$24,$00         ;X     X  $  $
LCE25_PRNME:
        .byte   $11, $48, $13, $ca, $15, $1a, $19, $08
        .byte   $19, $28, $19, $a4, $1a, $aa, $1b, $94
        .byte   $1b, $cc, $1c, $5a, $1c, $c4, $1c, $d8
        .byte   $1d, $c8, $1d, $e8, $23, $48, $23, $4a
        .byte   $23, $54, $23, $6e, $23, $a2, $24, $72
        .byte   $24, $74, $29, $88, $29, $b2, $29, $b4
        .byte   $34, $26, $53, $c8, $53, $f2, $53, $f4
        .byte   $5b, $a2, $5d, $26, $69, $44, $69, $72
        .byte   $69, $74, $6d, $26, $7c, $22, $84, $c4
        .byte   $8a, $44, $8a, $62, $8a, $72, $8a, $74
        .byte   $8b, $44, $8b, $62, $8b, $72, $8b, $74
        .byte   $9c, $1a, $9c, $26, $9d, $54, $9d, $68
        .byte   $a0, $c8, $a1, $88, $a1, $8a, $a1, $94
        .byte   $a5, $44, $a5, $72, $a5, $74, $a5, $76
        .byte   $a8, $b2, $a8, $b4, $ac, $c6, $ad, $06
        .byte   $ad, $32, $ae, $44, $ae, $68, $ae, $84
        .byte   $00, $00
LCEA7_PRNME:
        .byte   $16, $00, $76, $04, $4a, $04, $76, $04
        .byte   $12, $46, $74, $04, $1c, $32, $74, $04
        .byte   $3a, $00, $0c, $58, $52, $58, $0c, $58
        .byte   $0e, $02, $0c, $58, $62, $2a, $0c, $58
        .byte   $5c, $00, $00, $42, $48, $42, $38, $42
        .byte   $18, $30, $00, $42, $20, $4e, $00, $42
        .byte   $5e, $00, $6e, $5a, $50, $5a, $38, $5a
        .byte   $1a, $00, $6e, $5a, $66, $56, $38, $5a
        .byte   $14, $00, $6c, $6a, $2e, $7a, $6c, $6a
        .byte   $06, $68, $6c, $6a, $7e, $7c, $6e, $6e
        .byte   $40, $3e, $40, $3e, $72, $70, $40, $3e
        .byte   $08, $3c, $40, $3e, $22, $78, $40, $3e
        .byte   $28, $00, $28, $2a, $36, $2c, $28, $2a
        .byte   $10, $24, $00, $2a, $1e, $4c, $00, $2a
        .byte   $26, $00, $26, $32, $34, $44, $26, $32
        .byte   $0a, $60, $00, $32, $64, $54, $26, $32
        .byte   $46, $02, $30, $00, $68, $3c, $24, $60
        .byte   $80, $0d, $20, $20, $20
; ----------------------------------------------------------------------------
;ASSEM
MON_CMD_ASSEMBLE:
        bcc     AS005
        jmp     MON_BAD_COMMAND
AS005:  jsr     T0TOT2
AS010:  ldx     #$00
        stx     HULP+1
AS020:  jsr     GNC
        bne     AS025
        cpx     #$00
        bne     AS025
        jmp     MON_MAIN_INPUT
; ----------------------------------------------------------------------------
AS025:  cmp     #$20                            ; CF4D C9 20                    .
        beq     AS010                           ; CF4F F0 EB                    ..
        sta     MSAL,x                           ; CF51 95 D2                    ..
        inx                                     ; CF53 E8                       .
        cpx     #$03                            ; CF54 E0 03                    ..
        bne     AS020                           ; CF56 D0 E9                    ..
AS030:  dex                                     ; CF58 CA                       .
        bmi     LCF6E                           ; CF59 30 13                    0.
        lda     MSAL,x                           ; CF5B B5 D2                    ..
        sec                                     ; CF5D 38                       8
        sbc     #$3F                            ; CF5E E9 3F                    .?
        ldy     #$05                            ; CF60 A0 05                    ..
AS040:  lsr     a                               ; CF62 4A                       J
        ror     HULP+1                           ; CF63 6E 51 04                 nQ.
        ror     HULP                           ; CF66 6E 50 04                 nP.
        dey                                     ; CF69 88                       .
        bne     AS040                           ; CF6A D0 F6                    ..
        bra     AS030                           ; CF6C 80 EA                    ..
; ----------------------------------------------------------------------------
LCF6E:  stz     T0                             ; CF6E 64 C7                    d.
        stz     $D5                             ; CF70 64 D5                    d.
        ldx     #$02                            ; CF72 A2 02                    ..
AS050:  jsr     GNC                           ; CF74 20 FD CA                  ..
        beq     LCFC4                           ; CF77 F0 4B                    .K
        cmp     #' '                            ; CF79 C9 20                    .
        beq     AS050                           ; CF7B F0 F7                    ..
        cmp     #'$'                            ; CF7D C9 24                    .$
        beq     LCFAE                           ; CF7F F0 2D                    .-
        cmp     #'F'+1                          ; CF81 C9 47                    .G
        bcs     AS070                           ; CF83 B0 37                    .7
        cmp     #'0'                            ; CF85 C9 30                    .0
        bcc     AS070                           ; CF87 90 33                    .3
        cmp     #'9'+1                          ; CF89 C9 3A                    .:
LCF8B:  bcc     LCF93                           ; CF8B 90 06                    ..
        cmp     #'A'                            ; CF8D C9 41                    .A
        bcc     AS070                           ; CF8F 90 2B                    .+
        adc     #$08                            ; CF91 69 08                    i.
LCF93:  and     #$0F                            ; CF93 29 0F                    ).
        ldy     #$03                            ; CF95 A0 03                    ..
LCF97:  asl     T0                             ; CF97 06 C7                    ..
        rol     T0+1                             ; CF99 26 C8                    &.
        dey                                     ; CF9B 88                       .
        bpl     LCF97                           ; CF9C 10 F9                    ..
        ora     T0                             ; CF9E 05 C7                    ..
        sta     T0                             ; CFA0 85 C7                    ..
        inc     $D5                             ; CFA2 E6 D5                    ..
        lda     $D5                             ; CFA4 A5 D5                    ..
        cmp     #$04                            ; CFA6 C9 04                    ..
        beq     LCFB6                           ; CFA8 F0 0C                    ..
        cmp     #$01                            ; CFAA C9 01                    ..
        bne     AS050                           ; CFAC D0 C6                    ..
LCFAE:  inc     $D5                             ; CFAE E6 D5                    ..
        lda     #$24                            ; CFB0 A9 24                    .$
        sta     HULP,x                         ; CFB2 9D 50 04                 .P.
        inx                                     ; CFB5 E8                       .
LCFB6:  lda     #$30                            ; CFB6 A9 30                    .0
        sta     HULP,x                         ; CFB8 9D 50 04                 .P.
        inx                                     ; CFBB E8                       .
AS070:  sta     HULP,x                         ; CFBC 9D 50 04                 .P.
        inx                                     ; CFBF E8                       .
        cpx     #$10                            ; CFC0 E0 10                    ..
        bcc     AS050                           ; CFC2 90 B0                    ..
LCFC4:  stx     T1                             ; CFC4 86 C9                    ..
        ldx     #$00                            ; CFC6 A2 00                    ..
        stx     WRAP                             ; CFC8 86 D0                    ..
AS110:  ldx     #$00                            ; CFCA A2 00                    ..
        stx     TMPC                             ; CFCC 86 D1                    ..
        lda     WRAP                             ; CFCE A5 D0                    ..
        jsr     DSET                           ; CFD0 20 55 CD                  U.
        ldx     FORMAT                           ; CFD3 AE B4 03                 ...
        stx     T1+1                             ; CFD6 86 CA                    ..
        tax                                     ; CFD8 AA                       .
        lda     LCEA7_PRNME,x                         ; CFD9 BD A7 CE                 ...
        tax                                     ; CFDC AA                       .
        inx                                     ; CFDD E8                       .
        lda     LCE25_PRNME,x                         ; CFDE BD 25 CE                 .%.
        jsr     TSTRX                           ; CFE1 20 B4 D0                  ..
        dex                                     ; CFE4 CA                       .
        lda     LCE25_PRNME,x                         ; CFE5 BD 25 CE                 .%.
        jsr     TSTRX                           ; CFE8 20 B4 D0                  ..
        ldx     #$06                            ; CFEB A2 06                    ..
AS210:  cpx     #$03                            ; CFED E0 03                    ..
        bne     AS230                           ; CFEF D0 13                    ..
        ldy     LENGTH                          ; CFF1 A4 CF                    ..
        beq     AS230                           ; CFF3 F0 0F                    ..
AS220:  lda     FORMAT                           ; CFF5 AD B4 03                 ...
        cmp     #$E8                            ; CFF8 C9 E8                    ..
        lda     #'0'                            ; CFFA A9 30                    .0
        bcs     AS250                           ; CFFC B0 31                    .1
        jsr     TST2
        dey
        bne     AS220                           ; D002 D0 F1                    ..
AS230:  asl     FORMAT                           ; D004 0E B4 03                 ...
        bcc     AS240                           ; D007 90 14                    ..
        lda     #$7C                            ; D009 A9 7C                    .|
        cmp     WRAP                             ; D00B C5 D0                    ..
        beq     LD022                           ; D00D F0 13                    ..
        lda     CHAR1-1,x                       ; D00F BD 12 CE                 ...
        jsr     TSTRX
        lda     CHAR2-1,x                       ; D015 BD 18 CE                 ...
        BEQ     AS240
LD01A:  jsr     TSTRX                           ; D01A 20 B4 D0                  ..
AS240:  dex                                     ; D01D CA                       .
        bne     AS210                           ; D01E D0 CD                    ..
        bra     AS300                           ; D020 80 13                    ..
; ----------------------------------------------------------------------------
LD022:  lda     CHAR1-1,x                       ; D022 BD 12 CE                 ...
        jsr     TSTRX                           ; D025 20 B4 D0                  ..
        lda     CHAR2_7C-1,x                    ; D028 BD 1E CE                 ...
        beq     AS240                           ; D02B F0 F0                    ..
        bra     LD01A                           ; D02D 80 EB                    ..
AS250:  jsr     TST2                           ; D02F 20 B1 D0                  ..
        jsr     TST2                           ; D032 20 B1 D0                  ..
AS300:  lda     T1                             ; D035 A5 C9                    ..
        cmp     TMPC                             ; D037 C5 D1                    ..
        beq     AS310                           ; D039 F0 03                    ..
        jmp     TST05                           ; D03B 4C C0 D0                 L..
; ----------------------------------------------------------------------------
AS310:  ldy     LENGTH
        beq     AS500
        lda     T1+1
        cmp     #$9D
        bne     LD06A

        lda     T0
        sbc     T2
        tax
        lda     T0+1
        sbc     T2+1

        bcc     AS320
        bne     AERR
        cpx     #$82
        bcs     AERR
        bcc     AS340
AS320:  tay
        iny
        bne     AERR
        cpx     #$82
        bcc     AERR
AS340:  dex
        dex
        txa
        ldy     LENGTH
        bne     AS420
LD06A:  lda     LA,y
AS420:  jsr     LCC4B
        dey
        bne     LD06A
AS500:  lda     WRAP
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
        jsr     PUT_A_THEN_X_INTO_KEYD_BUFFER
        lda     T2+1
        jsr     MAKHEX_THEN_PUT_A_THEN_X_INTO_KEYD_BUFFER
        lda     T2
        jsr     MAKHEX_THEN_PUT_A_THEN_X_INTO_KEYD_BUFFER
        lda     #' '
        jsr     PUT_KEY_INTO_KEYD_BUFFER
        jmp     MON_MAIN_INPUT
; ----------------------------------------------------------------------------
MAKHEX_THEN_PUT_A_THEN_X_INTO_KEYD_BUFFER:
        jsr     MAKHEX

PUT_A_THEN_X_INTO_KEYD_BUFFER:
        phx     ;Push X onto stack
        jsr     PUT_KEY_INTO_KEYD_BUFFER
        pla     ;Pull it back as A
        jmp     PUT_KEY_INTO_KEYD_BUFFER
; ----------------------------------------------------------------------------
TST2:  jsr     TSTRX
TSTRX:  stx     SXREG
        ldx     TMPC
        cmp     HULP,x
        beq     TST10
        pla
        pla
TST05:  inc     WRAP
        beq     AERR
        jmp     AS110
; ----------------------------------------------------------------------------
AERR:
        jmp     MON_BAD_COMMAND
; ----------------------------------------------------------------------------
TST10:  inx
        stx     TMPC
        ldx     SXREG
        rts
; ----------------------------------------------------------------------------
MON_CMD_WALK:
        lda     #$01
        bcs     LD0D7
        lda     T0
LD0D7:  sta     V1541_FILE_MODE
        jsr     MON_PRINT_HEADER_FOR_REGS
        bra     LD11C_MON_WALK_LD11C
LD0DF:  jsr     MON_PRINT_REGS_WITHOUT_HEADER
        jsr     STOP_FROM_KERN
        beq     LD0F9_JMP_MON_MAIN_INPUT
        dec     V1541_FILE_MODE
        bne     LD11C_MON_WALK_LD11C
        jsr     LB4FB_RESET_KEYD_BUFFER
        lda     #fmode_w_write
        jsr     PUT_KEY_INTO_KEYD_BUFFER
        lda     #' '
        jsr     PUT_KEY_INTO_KEYD_BUFFER
LD0F9_JMP_MON_MAIN_INPUT:
        jmp     MON_MAIN_INPUT
; ----------------------------------------------------------------------------
LD0FC_MON_WALK_OPCODE_TO_HANDLER:
        .addr LD1BA_MON_WALK_OPCODE_20_JSR      ;jump to this address
        .byte $20 ;JSR                          ;  when byte equals this

        .addr LD1D1_MON_WALK_OPCODE_60_RTS
        .byte $60 ;RTS

        .addr LD201_MON_WALK_OPCODE_4C_JMP
        .byte $4c ;JMP

        .addr LD20B_MON_WALK_OPCODE_40_RTI
        .byte $40 ;RTI

        .addr LD1E5_MON_WALK_OPCODE_6C_JMP_IND
        .byte $6c ;JMP ($abcd)

        .addr LD1E8_7C_MON_WALK_OPCODE_7C_JMP_IND_X
        .byte $7c ;JMP ($abcd,X)

LD10E_MON_WALK_CODE_WRITTEN_TO_LINE_INPUT_BUF:
        nop                                     ; D10E EA                       .
        nop                                     ; D10F EA                       .
        sta     MMU_MODE_KERN                   ; D110 8D 00 FA                 ...
        jmp     LD1A3                           ; D113 4C A3 D1                 L..
        sta     MMU_MODE_KERN                   ; D116 8D 00 FA                 ...
        jmp     LD17D                           ; D119 4C 7D D1                 L}.

; ----------------------------------------------------------------------------
LD11C_MON_WALK_LD11C:
        ldx     #$0E
LD11E:  lda     LD10E_MON_WALK_CODE_WRITTEN_TO_LINE_INPUT_BUF,x
        sta     LINE_INPUT_BUF+1,x
        dex
        bpl     LD11E
        jsr     LD216
        sta     LINE_INPUT_BUF
        cmp     #$80
        beq     LD139
        bit     #$0F
        bne     LD143
        bit     #$10
        beq     LD143
LD139:  lda     #$07
        sta     LINE_INPUT_BUF+1
        jsr     LD216
        bra     LD168
LD143:  ldx     #$0F
LD145:  cmp     LD0FC_MON_WALK_OPCODE_TO_HANDLER+2,x
        bne     LD14D
        jmp     (LD0FC_MON_WALK_OPCODE_TO_HANDLER,x)
LD14D:  dex
        dex
        dex
        bpl     LD145
        jsr     DSET
        ldy     LENGTH
        beq     LD168
        jsr     LD216
        sta     LINE_INPUT_BUF+1
        dey
        beq     LD168
        jsr     LD216
        sta     LINE_INPUT_BUF+2
LD168:  ldy     $03BA
        lda     $03B8
        ldx     $03BB
        txs
        ldx     MEM_03B7
        phx
        ldx     $03B9
        plp
        jmp     LINE_INPUT_BUF ;actually code; see LD11E
; ----------------------------------------------------------------------------
LD17D:  php
        pha
        phy
        lda     $03B6
        bne     LD188
        dec     $03B5
LD188:  dec     $03B6
        jsr     LD216
        clc
        tay
        bpl     LD195
        dec     $03B5
LD195:  adc     $03B6
        bcc     LD19D
        inc     $03B5
LD19D:  sta     $03B6
        ply
        pla
        plp
LD1A3:  php
        stx     $03B9
        plx
        stx     MEM_03B7
        tsx
        stx     $03BB
        sta     $03B8
        sty     $03BA
LD1B5:  cli
        cld
        jmp     LD0DF
; ----------------------------------------------------------------------------
LD1BA_MON_WALK_OPCODE_20_JSR:
        jsr     LD216
        tax
        ldy     $03B5
        phy
        ldy     $03B6
        phy
        jsr     LD216
        dec     $03BB
        dec     $03BB
        bra     LD1DD
; ----------------------------------------------------------------------------
LD1D1_MON_WALK_OPCODE_60_RTS:
        plx
        pla
        inx
        bne     LD1D7
        inc     a
LD1D7:  inc     $03BB
        inc     $03BB
LD1DD:  sta     $03B5
        stx     $03B6
        bra     LD1B5
; ----------------------------------------------------------------------------
LD1E5_MON_WALK_OPCODE_6C_JMP_IND:
        ldy     $03B9
        ;Fall through
; ----------------------------------------------------------------------------
LD1E8_7C_MON_WALK_OPCODE_7C_JMP_IND_X:
        ldy     #$00
        jsr     LD216
        pha
        jsr     LD216
        sta     TMPC
        pla
        sta     WRAP
        jsr     LCC6D
        pha
        iny
        jsr     LCC6D
        plx
        bra     LD1DD
; ----------------------------------------------------------------------------
LD201_MON_WALK_OPCODE_4C_JMP:
        jsr     LD216
        pha
        jsr     LD216
        plx
        bra     LD1DD
; ----------------------------------------------------------------------------
LD20B_MON_WALK_OPCODE_40_RTI:
        pla
        sta     MEM_03B7
        plx
        pla
        inc     $03BB
        bra     LD1D7
LD216:  phy
        ldy     #$00
        lda     $03B6
        sta     WRAP
        lda     $03B5
        sta     TMPC
        jsr     LCC6D
        inc     $03B6
        bne     LD22E
        inc     $03B5
LD22E:  ply
        rts
; ----------------------------------------------------------------------------

;
; End of the machine language monitor
;

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
; ----------------------------------------------------------------------------
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
LD330_OUTER_LOOP:
        phx
        phy
        ldy     LD366_FKEY_COLUMNS,x
        ldx     $039C
        lda     #$89
        sec
        jsr     LB6F9_MAYBE_PUT_CHAR_IN_FKEY_BAR_SLOT
        lda     #$65 ;TODO graphics character
        ldy     #$09
        sta     ($BD),y
        ply
LD345_INNER_LOOP:
        jsr     GO_APPL_LOAD_GO_KERN
        beq     LD359
        cmp     #$08 ;todo length of an f-bar menu bar slot label?
        bcs     LD353
        jsr     LD36E_EXITQUITMORE
        bra     LD356
LD353:  jsr     LD3A9_CLC_JMP_LB6F9_MAYBE_PUT_CHAR_IN_FKEY_BAR_SLOT
LD356:  iny
        bne     LD345_INNER_LOOP
LD359:  lda     #$0D ;TODO signals an empty f-key menu bar slot?
        jsr     LD3A9_CLC_JMP_LB6F9_MAYBE_PUT_CHAR_IN_FKEY_BAR_SLOT
        iny
        plx
        inx
        cpx     #$08
        bcc     LD330_OUTER_LOOP
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
        bne     LD375_LOOP ;loop for 4 chars ("EXIT")
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
MEMTOP__:
        rol     a
        inc     a
        ror     a
        bcc     LD3E4
        phx
        lda     #$FF
        sta     MemTopLoByte
        lda     #$F7
        sta     MemTopHiByte
        ldx     $020B
        bne     LD3CE
        cmp     $020A
        bcc     LD3CE
        lda     $020A
        dec     a
        sta     MemTopHiByte
LD3CE:  plx
        cpy     MemTopHiByte
        bcc     LD3DD
        bne     LD3E4
        cpx     MemTopLoByte
        bcc     LD3DD
        bne     LD3E4
LD3DD:  stx     MemTopLoByte
        sty     MemTopHiByte
        clc
LD3E4:  php
        ldy     MemTopHiByte
        stz     $020D
        sty     $020C
        jsr     UPDATE_FREE_PAGES
        ldx     MemTopLoByte
        plp
        rts
; ----------------------------------------------------------------------------
UPDATE_FREE_PAGES:
        cld
        sec
        lda     $020A
        sbc     $020C
        tax
        lda     $020B
        sbc     $020D
        bcs     LD409
        ldx     #$01
LD409:  beq     LD40D
        ldx     #$00
LD40D:  dex
        stx     $BC
        rts
; ----------------------------------------------------------------------------
LD411:  clc
        ldy     #$FF
        jsr     MEMTOP__
        clc
        ldy     #$00
MEMBOT__:
        bcs     LD42F
        cpy     #$10
        bcs     LD429
        ldx     #$00
        ldy     #$10
        jsr     LD429
        sec
        rts
; ----------------------------------------------------------------------------
LD429:  sty     MemBotHiByte
        stx     MemBotLoByte
LD42F:  ldx     MemBotLoByte
        ldy     MemBotHiByte
        clc
        rts
; ----------------------------------------------------------------------------
LD437:  phx
        phy
        cld
        stz     $E5
        asl     a
        sta     $E4
        asl     a
        rol     $E5
        adc     $E4
        pha
        lda     $E5
        adc     #$F7
        ldx     #$03
        jsr     MAP_RAM_PAGE
        pla
        sta     $E4
        ply
        plx
        stx     $DA
        sty     $D9
        lda     #$D9
        sta     SINNER
        sta     $0360
        ldx     #$07
LD461:  lda     #$00
        cpx     #$06
        bcs     LD46B
        txa
        tay
        lda     ($E4),y
LD46B:  ldy     #$07
LD46D:  asl     a
        pha
        jsr     GO_RAM_LOAD_GO_KERN
        ror     a
        jsr     GO_RAM_STORE_GO_KERN
        pla
        dey
        bpl     LD46D
        dex
        bpl     LD461
        jmp     V1541_FIRST_BLOCK

; ----------------------------------------------------------------------------

;$D480-F6FF is filler.  It contains 6502 code but it's actually from the C128
;BASIC at $9480-B6FF.  This is garbage to the CLCD and is not used.  If it is
;zeroed out, the CLCD works normally.  This area is available for new code.
.list off
.include "c128.asm"
.list on

;$F700-F9FF contains part of the CLCD character set.  The CLCD has a
;separate character ROM that is used for the text mode.  It is not yet
;known if this data is actually used (e.g. by a graphics mode).
.list off
.include "charset.asm"
.list on

; ----------------------------------------------------------------------------
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
; The IRQ routine, pointed by the IRQ hardware vector.
IRQ:    pha
        phx
        phy
        sta     MMU_SAVE_MODE
        sta     MMU_MODE_APPL
        tsx

        lda     stack+4,x             ;A = NV-BDIZC
        and     #$10                  ;Test for BRK flag
        bne     LFA28_BRK             ;Branch if BRK flag is set

        lda     #>(RETURN_FROM_IRQ-1)
        pha
        lda     #<(RETURN_FROM_IRQ-1)
        pha
        jmp     (RAMVEC_IRQ)

LFA28_BRK:
        jmp     (RAMVEC_BRK)
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
        jsr     ACIA_IRQ            ;Service ACIA, then come back here for VIA1

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
        jmp     (RAMVEC_TIMER)
; ----------------------------------------------------------------------------
DEFVEC_TIMER:
        sta     MMU_MODE_KERN
        rts
; ----------------------------------------------------------------------------
RETURN_FROM_IRQ:
        ply
        plx
        pla
        sta     MMU_RECALL_MODE
NMI:    rti
; ----------------------------------------------------------------------------
LFA67:  jsr     LFA6D
        jmp     RTS_IN_KERN_MODE
; ----------------------------------------------------------------------------
LFA6D:  phy
        pha
        jmp     RTS_IN_APPL_MODE
; ----------------------------------------------------------------------------
GO_APPL_STORE_GO_KERN:
        sta     MMU_MODE_APPL
        jmp     GO_NOWHERE_STORE_GO_KERN
; ----------------------------------------------------------------------------
LFA78:  jsr     LFA7E
LFA7B_JMP_RTS_IN_KERN_MODE:
        jmp     RTS_IN_KERN_MODE
; ----------------------------------------------------------------------------
LFA7E:
; An interesting example for addresses like $FA80 are write only registers,
; but on read, normal ROM content is read as opcodes, as $FA80 here is inside
; and opcode itself.
        sta     MMU_MODE_APPL
        jmp     (RAMVEC_MEM_0334)
; ----------------------------------------------------------------------------
LFA84:  jsr     LFA8A
LFA87_JMP_RTS_IN_KERN_MODE:
        jmp     RTS_IN_KERN_MODE
; ----------------------------------------------------------------------------
LFA8A:  sta     MMU_MODE_APPL
        jmp     (RAMVEC_MEM_0336)  ;Contains LFA87_JMP_RTS_IN_KERN_MODE by default
; ----------------------------------------------------------------------------
; Default values of "RAM vectors" copied to $314 into the RAM. The "missing"
; vector in the gap seems to be "monitor" entry (according to C128's ROM) but
; points to RTS in CLCD. The the last two vectors are unknown, not exists on
; C128.
VECTSS: .addr   DEFVEC_IRQ
        .addr   DEFVEC_BRK
        .addr   DEFVEC_TIMER
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
        .addr   DEFVEC_UNKNOWN_LFAB4
        .addr   DEFVEC_LOAD
        .addr   DEFVEC_SAVE
        .addr   LFA7B_JMP_RTS_IN_KERN_MODE
        .addr   LFA87_JMP_RTS_IN_KERN_MODE
; ----------------------------------------------------------------------------
DEFVEC_UNKNOWN_LFAB4:
        rts
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
        jsr     LA9E6
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
KR_MATH_DISPATCH:
        sta     MMU_MODE_KERN
        jsr     MATH_DISPATCH
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
;Report an error from the math package: jump through IERROR in APPL mode with
;the BASIC error number in X.
JMP_IERROR:
        sta     MMU_MODE_APPL
        jmp     (IERROR)
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
        bne     MMU_RECALL_MODE
        inc     stack+5,x
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
KR_LB293_SWAP_EDITOR_STATE:
        sta     MMU_MODE_KERN
        jsr     LB293_SWAP_EDITOR_STATE
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
LFBC4_SHOW_OR_HIDE_CURSOR:
        sta     MMU_MODE_KERN
        pha
        bcs     LFBCF_SHOW
        jsr     LB2E4_HIDE_CURSOR
        bra     LFBD2_DONE
LFBCF_SHOW:
        jsr     LB2D6_SHOW_CURSOR
LFBD2_DONE:
        pla
        jmp     RTS_IN_APPL_MODE
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
        sta     MMU_MODE_KERN
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
MEMTOP_:sta     MMU_MODE_KERN
        jsr     MEMTOP__
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
MEMBOT_:sta     MMU_MODE_KERN
        jsr     MEMBOT__
        sta     MMU_MODE_APPL
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
        jmp     RTS_IN_KERN_MODE
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
        jmp     RTS_IN_KERN_MODE
; ----------------------------------------------------------------------------
DEFVEC_CLOSE:
        sta     MMU_MODE_KERN
        jsr     CLOSE__
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
        sta     MMU_MODE_APPL
        jsr     LFFC6_CHKIN
        jmp     RTS_IN_KERN_MODE
; ----------------------------------------------------------------------------
DEFVEC_CHKIN:
        sta     MMU_MODE_KERN
        jsr     CHKIN__
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
        sta     MMU_MODE_APPL
        jsr     LFFC9_CHKOUT
        jmp     RTS_IN_KERN_MODE
; ----------------------------------------------------------------------------
DEFVEC_CHKOUT:
        sta     MMU_MODE_KERN
        jsr     CHKOUT__
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
CLRCH:  sta     MMU_MODE_APPL
        jsr     LFFCC_CLRCH
        jmp     RTS_IN_KERN_MODE
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
        jmp     RTS_IN_KERN_MODE
; ----------------------------------------------------------------------------
DEFVEC_CHRIN:
        sta     MMU_MODE_KERN
        jsr     CHRIN__
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
        sta     MMU_MODE_APPL
        jsr     LFFD2_CHROUT
        jmp     RTS_IN_KERN_MODE
; ----------------------------------------------------------------------------
DEFVEC_CHROUT:
        sta     MMU_MODE_KERN
        jsr     CHROUT__
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
LFD63_LOAD_THEN_GO_KERN:
        jsr     LOAD_
RTS_IN_KERN_MODE:
        sta     MMU_MODE_KERN
        rts
; ----------------------------------------------------------------------------
LOAD_:  stx     $B4
        sty     $B5
        sta     MMU_MODE_APPL
        jmp     (RAMVEC_LOAD)
; ----------------------------------------------------------------------------
DEFVEC_LOAD:
        sta     MMU_MODE_KERN
        jsr     LOAD__
RTS_IN_APPL_MODE:
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
        sta     MMU_MODE_RAM
        rts
; ----------------------------------------------------------------------------
LFD82_SAVE_AND_GO_KERN:
        jsr     SAVE_
        jmp     RTS_IN_KERN_MODE
; ----------------------------------------------------------------------------
SAVE_:  stx     EAL
        sty     EAH
        tax
        lda     $00,x
        sta     STAL
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
SETTIM_:sta     MMU_MODE_KERN
        jsr     LBFD8_SETTIM
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
RDTIM_: sta     MMU_MODE_KERN
        jsr     LBFCE_RDTIM
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
STOP_FROM_KERN:
        sta     MMU_MODE_APPL
        jsr     LFFE1_STOP
        jmp     RTS_IN_KERN_MODE
; ----------------------------------------------------------------------------
DEFVEC_STOP:
        sta     MMU_MODE_KERN
        jsr     LB6E8_STOP
        sta     MMU_MODE_APPL
        rts
; ----------------------------------------------------------------------------
        sta     MMU_MODE_APPL
        jsr     LFFE4_GETIN
        jmp     RTS_IN_KERN_MODE
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
        jmp     RTS_IN_KERN_MODE
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
; Output: X/Y = VIA #1 base address.
; Used registers: X, Y.
IOBASE_:ldx     #<VIA1_PORTB
        ldy     #>VIA1_PORTB
        rts
; ----------------------------------------------------------------------------

UNUSED:
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF

; ----------------------------------------------------------------------------

;
;Start of CLCD KERNAL jump table
;

; ----------------------------------------------------------------------------
        jmp     LFAB5                           ; FF27 4C B5 FA                 L..
; ----------------------------------------------------------------------------
        jmp     LFABF  ;check modifier keys and unknown timer   ; FF2A 4C BF FA                 L..
; ----------------------------------------------------------------------------
        jmp     LFAC9  ;get key blocking                         ; FF2D 4C C9 FA                 L..
; ----------------------------------------------------------------------------
        jmp     LFAD3                           ; FF30 4C D3 FA                 L..
; ----------------------------------------------------------------------------
        jmp     LFADD  ;L8426 monitor calls here to exit too; might go back to menu   ; FF33 4C DD FA                 L..
; ----------------------------------------------------------------------------
        jmp     LFAE7  ;draw f-key bar and wait for k-key or return   ; FF36 4C E7 FA                 L..
; ----------------------------------------------------------------------------
        jmp     LFAF1  ;Pull-up menu above a function key ; FF39 4C F1 FA                 L..
; ----------------------------------------------------------------------------
        jmp     LFAFB  ;Save or restore part of the screen ; FF3C 4C FB FA                 L..
; ----------------------------------------------------------------------------
; Power off with saving the state.
        jmp     LFB05                           ; FF3F 4C 05 FB                 L..
; ----------------------------------------------------------------------------
        jmp     LFB0F  ;Call while waiting for something  ; FF42 4C 0F FB                 L..
; ----------------------------------------------------------------------------
        jmp     LFB19  ;Convert a character to a screen code ; FF45 4C 19 FB                 L..
; ----------------------------------------------------------------------------
        jmp     LFB23                           ; FF48 4C 23 FB                 L#.
; ----------------------------------------------------------------------------
        jmp     LFB2D                           ; FF4B 4C 2D FB                 L-.
; ----------------------------------------------------------------------------
        jmp     LFB37                           ; FF4E 4C 37 FB                 L7.
; ----------------------------------------------------------------------------
        jmp     KR_MATH_DISPATCH  ;Floating point math package (see MATH_DISPATCH)  ; FF51 4C 41 FB                 LA.
; ----------------------------------------------------------------------------
        jmp     PRIMM00   ;print immediate      ; FF54 4C 51 FB                 LQ.
; ----------------------------------------------------------------------------
        jmp     KR_LB758 ;screen and LINE_INPUT_BUF related   ; FF57 4C 92 FB                 L..
; ----------------------------------------------------------------------------
        jmp     KR_LD230_JMP_LD233_PLUS_X ;Function key services  ; FF5A 4C 9C FB                 L..
; ----------------------------------------------------------------------------
        jmp     KR_LB293_SWAP_EDITOR_STATE                           ; FF5D 4C A6 FB                 L..
; ----------------------------------------------------------------------------
        jmp     WaitXticks                      ; FF60 4C B0 FB                 L..
; ----------------------------------------------------------------------------
        jmp     KR_JMP_BELL_RELATED_X                           ; FF63 4C BA FB                 L..
; ----------------------------------------------------------------------------
        jmp     LFBC4_SHOW_OR_HIDE_CURSOR                           ; FF66 4C C4 FB                 L..
; ----------------------------------------------------------------------------
        jmp     KR_LB6F9_MAYBE_PUT_CHAR_IN_FKEY_BAR_SLOT                           ; FF69 4C D6 FB                 L..
; ----------------------------------------------------------------------------
        jmp     KR_ShowChar                        ; FF6C 4C E0 FB                 L..
; ----------------------------------------------------------------------------
        jmp     KR_LCDsetupGetOrSet                           ; FF6F 4C EA FB                 L..
; ----------------------------------------------------------------------------
        jmp     KR_LB684_STA_03F9 ;Keyboard related           ; FF72 4C F4 FB                 L..
; ----------------------------------------------------------------------------
        jmp     KR_LB688_GET_KEY_NONBLOCKING       ; FF75 4C FE FB                 L..
; ----------------------------------------------------------------------------
        jmp     KR_LFC08_JSR_LB4FB_RESET_KEYD_BUFFER                           ; FF78 4C 08 FC                 L..
; ----------------------------------------------------------------------------
        jmp     KR_PUT_KEY_INTO_KEYD_BUFFER        ; FF7B 4C 12 FC                 L..
; ----------------------------------------------------------------------------
;unused kernal jump table entry
        .byte   $FF, $FF, $FF                   ; FF7E FF FF FF
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
MEMTOP: jmp     MEMTOP_                         ; FF99 4C 6E FC                 Ln.
; ----------------------------------------------------------------------------
MEMBOT: jmp     MEMBOT_                         ; FF9C 4C 78 FC                 Lx.
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
; "OPEN". Must call SETLFS_ and SETNAM_ beforehand.
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
; LOAD. Load or verify file. (Must call SETLFS_ and SETNAM_ beforehand.)
; Input: A: 0 = Load, 1-255 = Verify; X/Y = Load address (if secondary
; address = 0).
; Output: Carry: 0 = No errors, 1 = Error; A = KERNAL error code (if Carry =
; 1); X/Y = Address of last byte loaded/verified (if Carry = 0).
; Used registers: A, X, Y.
LOAD:   jmp     LOAD_                           ; FFD5 4C 6A FD                 Lj.
; ----------------------------------------------------------------------------
; SAVE. Save file. (Must call SETLFS_ and SETNAM_ beforehand.)
; Input: A = Address of zero page register holding start address of memory
; area to save; X/Y = End address of memory area plus 1.
; Output: Carry: 0 = No errors, 1 = Error; A = KERNAL error code (if Carry =
; 1).
; Used registers: A, X, Y.
SAVE:   jmp     SAVE_                           ; FFD8 4C 88 FD                 L..
; ----------------------------------------------------------------------------
; SETTIM. Set Time of Day
; Input: A/X/Y = New TOD value.
; Output: –
; Used registers: –
SETTIM: jmp     SETTIM_                          ; FFDB 4C A5 FD                 L..
; ----------------------------------------------------------------------------
; RDTIM. Read Time of Day
; Input: –
; Output: A/X/Y = Current TOD value.
; Used registers: A, X, Y.
RDTIM:  jmp     RDTIM_                            ; FFDE 4C AF FD                 L..
; ----------------------------------------------------------------------------
; STOP. Query Stop key indicator, at memory address $0091; if pressed, call
; CLRCHN and clear keyboard buffer.
; Input: –
; Output: Zero: 0 = Not pressed, 1 = Pressed; Carry: 1 = Pressed.
; Used registers: A, X.
; Vector in RAM ($328) seems to point to $FDC2
LFFE1_STOP:  jmp     (RAMVEC_STOP)                   ; FFE1 6C 28 03                 l(.
; ----------------------------------------------------------------------------
; GETIN. Read byte from default input. (If not keyboard, must call OPEN and
; CHKIN beforehand.)
; Input: –
; Output: A = Byte read.
; Used registers: A, X, Y.
LFFE4_GETIN:  jmp     (RAMVEC_GETIN)                  ; FFE4 6C 2A 03                 l*.
; ----------------------------------------------------------------------------
LFFE7_CLALL:  jmp     (RAMVEC_CLALL)                  ; FFE7 6C 2C 03                 l,.
; ----------------------------------------------------------------------------
; UDTIM. Update Time of Day, at memory address $0390-$0392, and
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
        .byte   $FF, $FF, $FF, $FF              ; FFF6 FF FF FF FF
; ----------------------------------------------------------------------------

NMI_VECTOR:
; The 65xx hardware vectors (NMI, RESET, IRQ).
        .addr   NMI                             ; FFFA 66 FA                    f.
RES_VECTOR:
; This is the RESET vector.
        .addr   RESET                           ; FFFC 07 FA                    ..
IRQ_VECTOR:
        .addr   IRQ                             ; FFFE 0E FA                    ..
