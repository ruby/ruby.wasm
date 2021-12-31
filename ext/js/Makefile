TARGET = js
OBJ = $(TARGET).o

RM = rm -f
CFLAGS = -O0 $(RUBY_INCLUDE_FLAGS)

obj: $(OBJ)

%.o: %.c
	$(CC) -c $(CFLAGS) -o $@ $<
