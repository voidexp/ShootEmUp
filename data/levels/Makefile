all: demo/level.bin

demo/level.bin: demo/level.yaml demo/*.bmp
	$(LVL2BIN) demo/level.yaml demo/level.bin

clean:
	@rm -fv demo/level.bin
