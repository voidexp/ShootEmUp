src := $(shell find . -type f -name "*.asm")

all: $(patsubst %.asm,%.o,$(src)) rom.o

rom.asm: ../game.yaml rom.asm.in
	$(GENROM) ../game.yaml $@

%.o : %.asm
	$(AS) -I. $< -o $@

clean:
	@find . -type f -name "*.o" -exec rm -fv {} +
	@rm -fv rom.asm
