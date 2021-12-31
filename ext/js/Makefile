TARGET = js
OBJ = $(TARGET).o
OBJS = js-core.o bindgen/rb-js-abi-host.o bindgen/rb-js-abi-guest.o

RM = rm -f
CFLAGS = -O0 -Ibindgen $(RUBY_INCLUDE_FLAGS)

obj: $(OBJ)

$(OBJ): $(OBJS)
	$(LD) js-core.o bindgen/rb-js-abi-host.o bindgen/rb-js-abi-guest.o --relocatable -o $@

bindgen/rb-js-abi-guest.h bindgen/rb-js-abi-guest.c: bindgen/rb-js-abi-guest.wit
	wit-bindgen c --export bindgen/rb-js-abi-guest.wit --out-dir bindgen

bindgen/rb-js-abi-host.h bindgen/rb-js-abi-host.c: bindgen/rb-js-abi-host.wit
	wit-bindgen c --import bindgen/rb-js-abi-host.wit --out-dir bindgen

js.o: bindgen/rb-js-abi-guest.h bindgen/rb-js-abi-host.h

%.o: %.c
	$(CC) -c $(CFLAGS) -o $@ $<
