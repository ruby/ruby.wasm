TARGET = js
OBJS = js-core.o bindgen/rb-js-abi-host.o

RM = rm -f
CFLAGS = -O0 -Ibindgen $(RUBY_INCLUDE_FLAGS)

.PHONY: obj
obj: $(OBJS)

.PHONY: clean
clean:
	rm -f $(OBJS) link.filelist bindgen/*.h bindgen/*.o bindgen/*.c

link.filelist:
	echo $(foreach obj,$(OBJS),$(abspath $(obj))) > $@

bindgen/rb-js-abi-host.h bindgen/rb-js-abi-host.c: bindgen/rb-js-abi-host.wit
	wit-bindgen c --import bindgen/rb-js-abi-host.wit --out-dir bindgen

js-core.o: bindgen/rb-js-abi-host.h bindgen/rb-js-abi-host.h

%.o: %.c
	$(CC) -c $(CFLAGS) -o $@ $<
