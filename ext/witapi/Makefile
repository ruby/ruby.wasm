TARGET = witapi
OBJS = witapi-core.o bindgen/rb-js-abi-guest.o

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

bindgen/rb-js-abi-guest.h bindgen/rb-js-abi-guest.c: bindgen/rb-js-abi-guest.wit
	wit-bindgen c --export bindgen/rb-js-abi-guest.wit --out-dir bindgen

witapi-core.o: bindgen/rb-js-abi-guest.h

%.o: %.c
	$(CC) -c $(CFLAGS) -o $@ $<
