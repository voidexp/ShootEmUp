Shoot 'Em Up!
=============
A shooter game for Nintendo Entertainment System.

# Python virtualenv
The build scripts are written in Python and depend on few packages.
Create and setup a virtual environment for the project:

    python -m venv .venv
    .venv/bin/activate          # Unix-es
    .venv/Scripts/activate.bat  # Windows CMD
    .venv/Scripts/activate.ps1  # Windows PowerShell

    pip install -r requirements.txt

# Building the ROM
Ensure to have the virtualenv activated and that the CC65 toolchain is in your
PATH, then just run:

    python build.py

You can explicitly set the path to the assembler and linker executables with
`-a` and `-l` options respectively:

    python build.py -a D:\Software\cc65\bin\ca65.exe -l D:\Software\cc65\bin\ld65.exe

For more options, check:

    python build.py --help

If everything goes ok, the ROM file will be created in `build/game.nes`.
