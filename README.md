Shoot 'Em Up!
=============
A shooter game for Nintendo Entertainment System.

# Building the ROM

    ca65.exe src\main.asm
    ld65.exe -C rom.cfg -o game.nes src\main.o
