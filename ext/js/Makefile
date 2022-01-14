TARGET = js
OBJ_FILES = js-core.o bindgen/rb-js-abi-host.o
OBJDIR ?= $(CURDIR)
OBJS = $(patsubst %.o,$(OBJDIR)/%.o, $(OBJ_FILES))

RM = rm -f
CFLAGS = -O0 -I$(OBJDIR)/bindgen -I$(OBJDIR) $(RUBY_INCLUDE_FLAGS)

.PHONY: obj
obj: $(OBJS) $(OBJDIR)/link.filelist

.PHONY: clean
clean:
	rm -f $(OBJS) $(OBJDIR)/link.filelist $(OBJDIR)/bindgen/*.h $(OBJDIR)/bindgen/*.o $(OBJDIR)/bindgen/*.c

$(OBJDIR)/link.filelist:
	echo $(foreach obj,$(OBJS),$(abspath $(obj))) > $@

$(OBJDIR)/bindgen/rb-js-abi-host.h $(OBJDIR)/bindgen/rb-js-abi-host.c &: bindgen/rb-js-abi-host.wit
	@mkdir -p "$(@D)"
	wit-bindgen c --import bindgen/rb-js-abi-host.wit --out-dir $(OBJDIR)/bindgen

$(OBJDIR)/js-core.o: $(OBJDIR)/bindgen/rb-js-abi-host.h

$(OBJDIR)/bindgen/%.o: $(OBJDIR)/bindgen/%.c
	@mkdir -p "$(@D)"
	$(CC) -c $(CFLAGS) -o $@ $<

$(OBJDIR)/%.o: $(CURDIR)/%.c
	@mkdir -p "$(@D)"
	$(CC) -c $(CFLAGS) -o $@ $<
