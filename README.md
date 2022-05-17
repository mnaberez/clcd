# Commodore LCD Partial Disassembly

This is an incomplete disassembly of the KERNAL ROM of [Bil Herd](http://c128.com/)'s Commodore LCD prototype.  See the [Commodore LCD ROMs](http://mikenaberezny.com/2008/10/04/commodore-lcd-firmware/) page for the original binaries.

This disassembly is based on the [disassembly](https://web.archive.org/web/20170419205827/http://commodore-lcd.lgb.hu/sk/) of the KERNAL ROM found in Bil Herd's LCD prototype published by Gábor Lénárt.  It been changed from a webpage to a source file that can be assembled with [ca65](https://www.cc65.org/doc/ca65.html).  The reassembled binary is bit-identical to the original `kizapr-u102.bin` file.  Some symbols have been renamed to more conventional CBM names, e.g. `LFSDevNum` to `FA`, with the goal of making the disassembly easier to read for those familiar with the other KERNALs.  Some hardcoded addresses were replaced with symbols, e.g. `LAT`.  Additional routines have been disassembled.

## Hardware

### Main Clock

The Commodore LCD probably runs at 1 MHz based on two things:

1. A [photo](https://flickr.com/photos/mnaberez/31314601462) of Bil Herd's prototype shows a 4.0 MHz crystal above the G65SC102.  It is likely that it is connected to pins 35 (XTLI) and 37 (XTLO).  The [GTE 65SC102 datasheet](http://archive.6502.org/datasheets/cmd_g65scxxx_mpu_family.pdf) says, "the 65SC10X Series is supplied with an internal clock generator operating at four times the Φ2 frequency."  The [Rockwell R65C102 datasheet](http://archive.6502.org/datasheets/rockwell_r65c00_microprocessors.pdf) agrees, saying, "The R65C102 internal clocks may be generated by a TTL level single phase input, an RC time base input, (÷ 4) using the XTLO and XTLI input pins.  See Figure 7 for an example of a crystal time base circuit."  Figure 7 reiterates, "R65C102 crystal frequency is divided by 4, i.e. Φ2 (OUT) = F/4."

2. The IEC routine `W1MS` in this KERNAL (at $BE4A) is a busy loop that waits 1 ms.  It is identical to the `W1MS` routine in the C64, a computer which runs at ~1 MHz.  If the LCD ran at a speed other than 1 MHz, `W1MS` would need to be different.

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

## Firmware

### Screen Editor

The screen editor supports nearly all of the ESC codes in the C128:

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

### Alarm

The KERNAL updates the TOD clock on a 60 Hz interrupt like other CBM machines.  An alarm has also been added (see UDTIM at $BF93).  The alarm counts down hours, minutes, and seconds independently of the TOD clock.  The alarm beeps 3 times in the final seconds of the countdown.

This program sounds the alarm in 1 hour, 30 minutes, and 15 seconds:

```text
0 poke917,1:poke916,30:poke915,15
1 printpeek(917),peek(916),peek(915):goto1
```

## License

No rights are claimed on the original Commodore LCD ROMs or the initial disassembly work done by Gábor Lénárt.  All other work in this repository is made available under the [3-Clause BSD License](./LICENSE.txt).

## Contact

[Mike Naberezny](https://github.com/mnaberez)
