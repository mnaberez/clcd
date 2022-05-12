# Commodore LCD Partial Disassembly

This is an incomplete disassembly of the KERNAL ROM of [Bil Herd](http://c128.com/)'s Commodore LCD prototype.  See the [Commodore LCD ROMs](http://mikenaberezny.com/2008/10/04/commodore-lcd-firmware/) page for the original binaries.

This disassembly is based on a [disassembly published](https://web.archive.org/web/20170419205827/http://commodore-lcd.lgb.hu/sk/) by Gábor Lénárt.  It been changed from a webpage to a source file that can be assembled with [ca65](https://www.cc65.org/doc/ca65.html).  The reassembled binary is bit-identical to the original `kizapr-u102.bin` file.

The primary motivation for this version of the disassembly was to better understand the IEC implementation of the LCD.  Therefore, most of the changes from the original are in the IEC routines.  The routines are extremely similar to those in the C64 KERNAL.

## License

No rights are claimed on the original Commodore LCD ROMs or the initial disassembly work done by Gábor Lénárt.  All other work in this repository is made available under the [3-Clause BSD License](./LICENSE.txt).

## Contact

[Mike Naberezny](https://github.com/mnaberez)
