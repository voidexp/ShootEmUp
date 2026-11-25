Shoot 'Em Up!
=============
The most boring space shooter for the Nintendo Entertainment System.

# Prerequisites

To build the game, the following software is required:

- The CC65 toolchain (`cc65`, `ld65`)
- Python 3.10+
- Make

The build scripts and tests are written in Python and depend on a few packages.

It is a good practice to install and run them from an isolated virtual
environment. Run these commands in the project's root directory:

    $ python -m venv .venv
    $ . venv/bin/activate          # Unix-es
    $ . venv/Scripts/activate.bat  # Windows CMD
    $ . venv/Scripts/activate.ps1  # Windows PowerShell
    $ pip install -r requirements.txt

# Building the ROM
Once your build environment is set up, just run:

    $ make

If everything goes ok, the `game.nes` ROM file will be created in the project's
root.

You can run it in your favourite NES emulator, enjoy!
