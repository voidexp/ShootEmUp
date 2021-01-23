Shoot 'Em Up!
=============
A shooter game for Nintendo Entertainment System.

# Building the ROM
Ensure you have a Python 3.6+ interpreter installed and the CC65 toolchain in
your PATH, then just run:

    python build.py

You can explicitly set the path to the assembler and linker executables with
`-a` and `-l` options respectively:

    python build.py -a D:\Software\cc65\bin\ca65.exe -l D:\Software\cc65\bin\ld65.exe

For more options, check:

    python build.py --help

If everything goes ok, the ROM file will be created in `build/game.nes`.
