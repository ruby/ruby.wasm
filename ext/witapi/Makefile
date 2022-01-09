TARGET = witapi
OBJS = witapi-core.o bindgen/rb-abi-guest.o

RM = rm -f
CFLAGS = -O0 -Ibindgen $(RUBY_INCLUDE_FLAGS)

.PHONY: obj
obj: $(OBJS)

.PHONY: clean
clean:
	rm -f $(OBJS) link.filelist bindgen/*.h bindgen/*.o bindgen/*.c

link.filelist:
	echo $(foreach obj,$(OBJS),$(abspath $(obj))) > $@
	echo -mexec-model=reactor >> $@

bindgen/rb-abi-guest.h bindgen/rb-abi-guest.c: bindgen/rb-abi-guest.wit
	wit-bindgen c --export bindgen/rb-abi-guest.wit --out-dir bindgen

witapi-core.o: bindgen/rb-abi-guest.h

%.o: %.c
	$(CC) -c $(CFLAGS) -o $@ $<
