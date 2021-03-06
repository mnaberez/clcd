# Commodore LCD Partial Disassembly

This is an incomplete disassembly of the KERNAL ROM of [Bil Herd](http://c128.com/)'s Commodore LCD prototype.  See the [Commodore LCD page](http://mikenaberezny.com/2008/10/04/commodore-lcd-firmware/) for the original binaries, schematics, and specifications.

## Hardware

### Main Clock

The Commodore LCD runs at 1 MHz based on this evidence:

- A [photo](https://flickr.com/photos/mnaberez/31314601462) of Bil Herd's prototype shows a 4.0 MHz crystal above the G65SC102.  The [schematic](http://mikenaberezny.com/2008/10/04/commodore-lcd-firmware/) shows it connected to pins 35 (XTLI) and 37 (XTLO).  The [GTE 65SC102 datasheet](http://archive.6502.org/datasheets/cmd_g65scxxx_mpu_family.pdf) says, "the 65SC10X Series is supplied with an internal clock generator operating at four times the Φ2 frequency."  The [Rockwell R65C102 datasheet](http://archive.6502.org/datasheets/rockwell_r65c00_microprocessors.pdf) agrees, saying, "The R65C102 internal clocks may be generated by a TTL level single phase input, an RC time base input, (÷ 4) using the XTLO and XTLI input pins.  See Figure 7 for an example of a crystal time base circuit."  Figure 7 reiterates, "R65C102 crystal frequency is divided by 4, i.e. Φ2 (OUT) = F/4."

- The IRQ handler that updates the TOD clock (at $FA3C and $BF4F) expects to be called at 60 Hz, which has a period of 16666 microseconds.  The IRQ is fired by Timer 1, which is configured (at $877E) to fire after 16666 edges of Φ2.  Since 1 MHz has a period of 1 microsecond, Φ2 must be 1 MHz.

### Serial Bus (IEC)

The IEC routines are extremely similar to those in the C64 KERNAL.

The IEC signals are connected to VIA1 ($F800):

| Pin | IEC Signal | Polarity | Source |
|-----|-----|----------|--------|
|VIA1 PB7 |DAT_IN  |inverted from C64   | DEBPIA $BE3E |
|VIA1 PB6 |CLK_IN  |inverted from C64   | DEBPIA $BE3E |
|VIA1 PB5 |DAT_OUT |same as C64| DATAHI $BE2C, DATALO $BE35 |
|VIA1 PB4 |CLK_OUT |same as C64| CLKHI $BE1A, CLKLO $BE23 |
|VIA1 PB3 |ATN_OUT |same as C64| SCATN $BD4C, LIST5 $BCB8 |

VIA1 Timer 2 is used in one-shot mode for IEC bus timing.  It is not used for interrupts but is polled by the IEC bus routines (EOIACP at $BDB3, ISRCLK at $BD11, ISR04 at $BD2C, and ACP00 at BDBB).

### Centronics Port

The KERNAL supports a Centronics printer on device number 30 (see `NOPEN` at $BB1C).  This device is output only (see `CHROUT/BSOUT` at $B994).  Attempting to read from it will give `?NOT INPUT FILE ERROR` (see `GETIN` at $B958).

The Centronics signals are connected to VIA2 ($F880):

| Pin | Centronics Signal | Source |
|-----|-----|--------|
|VIA2 PA0-7|Data 0-7 out|$C3B6|
|VIA2 PB6|/BUSY in|$C396|
|VIA2 PB5|Possibly STROBE out|$C3B9|
|VIA2 CA2|Possibly STROBE out|$C3C1|

Before writing the data byte, the LCD will wait for /BUSY to go high.  If it does not go high within a timeout,
or if STOP is pressed, the LCD will abort.  If /BUSY goes high, the byte is placed on the data lines and
STROBE is pulsed.  Above, there are two candidates for STROBE.  Both of these lines are pulsed immediately after putting the byte on PORTA.

### Beeper / CB2 Sound

The KERNAL screen device (`3`) will sound the beeper when control code 7 is written (see routine at $C65C and the calls to it).  The beeper is driven by CB2 of VIA2 (see $C64B).

### DTMF Dial Tone Generator

The LCD has a separate DTMF tone generator circuit that is used to dial the phone number for the internal modem.  

### Jiffy Clock / TOD Clock

VIA1 ($F800) Timer 1 is used in free-running mode to provide a 60 Hz interrupt ($877E).  The KERNAL maintains the clock, blinks the cursor, and scans the keyboard in the interrupt handler ($877E) like other CBM machines.

## Firmware

### Alarm

The KERNAL updates the TOD clock on a 60 Hz interrupt like other CBM machines.  An alarm has also been added (see UDTIM at $BF93).  The alarm counts down hours, minutes, and seconds independently of the TOD clock.  The alarm beeps 3 times in the final seconds of the countdown.

This program sounds the alarm in 1 hour, 30 minutes, and 15 seconds:

```text
0 poke917,1:poke916,30:poke915,15
1 printpeek(917),peek(916),peek(915):goto1
```

### Devices

The KERNAL supports the following devices:

| Device Number | Description |
|--------------|--------------|
|0 |Keyboard |
|1 |Virtual 1541 (RAM Disk) |
|2 |RS-232 Port (6551 ACIA) |
|3 |Screen (LCD) |
|4-29 |IEC Serial Bus |
|30 |Centronics Port |
|31 |Real Time Clock |

There are 3 devices not found on other Commodore computers:

 - Virtual 1541.  This is the RAM disk.  The cassette routines have been completely removed and device number 1 has been repurposed for the Virtual 1541.  Device 1 is the default device number so `LOAD` with no device number will load from the Virtual 1541.

 - Centronics port.  This is an output-only device that sends data to the dedicated Centronics port on the side of the machine.  The secondary address (channel number) selects various character translation modes.  Translation is supported by the RS-232 (6551 ACIA) device, a feature that the Plus/4 does not have.

 - Real Time Clock.  This device can set or read the LCD's built-in OKI M58321 RTC chip ([photo](https://flickr.com/photos/mnaberez/31314604052/in/album-72157673583276503/)).  It can also synchronize the RTC time with the software TOD clock.

### Editor

The editor supports these control codes:

| Code | CHR$ | Function | Source |
|------|------|----------|--------|
| $07 | CHR$(7) | Bell | $AC96 |
| $09 | CHR$(9) | Tab | $AC99 |
| $0A | CHR$(10) | Linefeed | $AC9C |
| $0D | CHR$(13) | Carriage Return | $AC9F |
| $0E | CHR$(14) | Lowercase Mode | $ACA2 |
| $11 | CHR$(17) | Cursor Down | $ACA5 |
| $12 | CHR$(18) | Reverse On | $ACA8 |
| $13 | CHR$(19) | Home | $ACAB |
| $14 | CHR$(14) | Delete | $ACAE |
| $18 | CHR$(24) | Set or Clear Tab | $ACAE |
| $19 | CHR$(25) | CTRL-Y Lock (Disables Shift-Commodore) | $ACB4 |
| $1A | CHR$(26) | CTRL-Z Unlock (Enables Shift-Commodore) | $ACB7 |
| $1D | CHR$(29) | Cursor Right | $ACBA |
| $8D | CHR$(141) | Shift-Return | $ACBD |
| $8E | CHR$(142) | Uppercase Mode | $ACC0 |
| $91 | CHR$(145) | Cursor Up | $ACC3 |
| $92 | CHR$(146) | Reverse Off | $ACC6 |
| $93 | CHR$(147) |Clear Screen | $ACC9 |
| $94 | CHR$(148) |Insert | $ACC9 |
| $9D | CHR$(157) |Cursor Left | $ACCF |

It also supports nearly all of the ESC codes in the C128:

| ESC Code | Function | Source |
|--------------|----------|--------|
|ESC-A | Enable auto-insert mode | $B0D5 |
|ESC-B | Set bottom right of screen window at current position | $B0D8 |
|ESC-C | Disable auto-insert mode | $B0DB |
|ESC-D | Delete the current line | $B0DE |
|ESC-E | Set cursor to nonflashing mode | $B0E1 |
|ESC-F | Set cursor to flashing mode | $B0E4 |
|ESC-I | Insert line | $B0E7 |
|ESC-J | Move to start of current line | $B0EA |
|ESC-K | Move to end of current line | $B0ED |
|ESC-L | Enable scrolling | $B0F0 |
|ESC-M | Disable scrolling | $B0F4 |
|ESC-O | Cancel insert, quote, reverse modes | $B0F7 |
|ESC-P | Erase to start of current line | $B0FA |
|ESC-Q | Erase to end of current line | $B0FD |
|ESC-T | Set top left of screen window at cursor position | $B0FF |
|ESC-V | Scroll up | $B103 |
|ESC-W | Scroll down | $B106 |
|ESC-Y | Set default tab stops (8 spaces) | $B108 |
|ESC-Z | Clear all tab stops | $B10B |

### Monitor

The monitor is entered with the `MONITOR` command in BASIC.  The following commands are supported:

| Command | Function | Source |
|--------------|----------|--------|
| X | Exit | $C88C |
| M | Memory | $C88D |
| R | Registers | $C88E |
| G | Go | $C88F |
| T | Transfer|  $C890 |
| C | Compare | $C891 |
| D | Disassemble|  $C892 |
| A | Assemble | $C893 |
| . | Alias for Assemble|  $C894 |
| H | Hunt | $C895  |
| F | Fill | $C896  |
| > | Modify Memory | $C897 |
| ; | Modify Registers | $C898 |
| W | Walk | $C899 |
| L | Load | $C89A |
| S | Save | $C89B |
| V | Verify | $C89C |

The commands use the same syntax as the TED-series and C128 monitors (see the [C128 Programmer's Reference Guide](https://web.archive.org/web/20200211184434/https://commodore.bombjack.org/commodore/commodore/C128_Programmers_Reference_Guide.pdf), page 186).  The "A" (Assemble) and "D" (Disassemble) commands have been extended to handle the 65C02 opcodes.

A new command, "W" (Walk), has been added.  It single steps from the current PC.  This command is not found in the TED-series or C128 monitors.

The monitor commands have been extended to support the MMU.  The MMU mode is shown in the `MODE` column of the status display:

```text
   PC  SR AC XR YR SP MODE OPCODE   MNEMONIC
; 0000 00 00 00 00 FF  02  00       BRK
```

The `MODE` may be one of three values: 0 (`MMU_MODE_RAM`), 1 (`MMU_MODE_APPL`), or 2 (`MMU_MODE_KERN`).  The mode can be changed by cursoring up and editing the `;` line.  Any value other than 0, 1, or 2 will leave the mode unchanged.  After changing the mode, any monitor command will operate in that mode.

### Virtual 1541

Virtual 1541 is not a complete CBM DOS implementation.  The command channel only seems to support:

- `I` Initialize ($8C6F)
- `R` Rename ($980E)
- `S` Scratch ($97D6)
- `V` Validate ($9842)

Strangely, format (`N`) is missing and validate (`V`) seems to format.  This can be observed in BASIC by saving a file to the Virtual 1541 and then validating with `COLLECT U1`.  

## License

The KERNAL disassembly started with a [disassembly](https://web.archive.org/web/20170419205827/http://commodore-lcd.lgb.hu/sk/) published by Gábor Lénárt.  The [first commit](https://github.com/mnaberez/clcd/commit/1ed4364725671934c2e71e171b92fc4db92292dc) in this repository was that disassembly.  It first was changed from a webpage to a source file that could be reassembled to the original `kizapr-u102.bin`.  Over time, many more comments and symbols were added.

No rights are claimed on the original Commodore LCD ROMs or the initial KERNAL disassembly work done by Gábor Lénárt.  All other work in this repository is made available under the [3-Clause BSD License](./LICENSE.txt).

## Contact

[Mike Naberezny](https://github.com/mnaberez)
