AS := ca65
LD := ld65
PY := $(PWD)/.venv/bin/python
PYTEST := $(PWD)/.venv/bin/pytest
BMP2CHR := $(PY) $(PWD)/tools/bmp2chr.py
LVL2BIN := $(PY) $(PWD)/tools/lvl2bin.py
GENROM := $(PY) $(PWD)/tools/genrom.py

export AS
export LD
export PY
export BMP2CHR
export LVL2BIN
export GENROM

.PHONY: objs clean tilesets levels rom

all: game.nes

objs:
	$(MAKE) -C src

tilesets:
	$(MAKE) -C data/tilesets

levels:
	$(MAKE) -C data/levels

game.nes: tilesets levels objs rom.cfg
	$(LD) -C rom.cfg -o $@ $(shell find src -type f -name "*.o")

clean:
	$(MAKE) -C data/levels clean
	$(MAKE) -C data/tilesets clean
	$(MAKE) -C src clean
	@rm -fv game.nes

test:
	$(PYTEST)
