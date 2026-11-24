src := $(shell find . -name "*.bmp")

all: $(patsubst %.bmp,%.chr,$(src))

%.chr: %.bmp
	$(BMP2CHR) $< $@

clean:
	@rm -f *.chr
