TARGET = witapi
OBJ_FILES = witapi-core.o bindgen/rb-abi-guest.o
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
	echo -mexec-model=reactor >> $@

$(OBJDIR)/bindgen/rb-abi-guest.h $(OBJDIR)/bindgen/rb-abi-guest.c &: bindgen/rb-abi-guest.wit
	@mkdir -p "$(@D)"
	wit-bindgen c --export bindgen/rb-abi-guest.wit --out-dir $(OBJDIR)/bindgen

$(OBJDIR)/witapi-core.o: $(OBJDIR)/bindgen/rb-abi-guest.h

$(OBJDIR)/bindgen/%.o: $(OBJDIR)/bindgen/%.c
	@mkdir -p "$(@D)"
	$(CC) -c $(CFLAGS) -o $@ $<

$(OBJDIR)/%.o: $(CURDIR)/%.c
	@mkdir -p "$(@D)"
	$(CC) -c $(CFLAGS) -o $@ $<
