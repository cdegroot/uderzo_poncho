# Makefile for Linux targets
# Note: assumes Ubuntu. YMMV.

# Note: hack alert. I'm not proud of this stuff. Make it work, make it right, make it fast.

ifeq ($(ERL_EI_INCLUDE_DIR),)
$(error ERL_EI_INCLUDE_DIR not set. Invoke via mix or set it manually)
endif

# Set Erlang-specific compile and linker flags
ERL_CFLAGS ?= -I$(ERL_EI_INCLUDE_DIR)

default: priv compile

compile: priv/libclixir.a

priv:
	mkdir priv

priv/libclixir.a: c_src/clixir_support.c c_src/clixir_support.h
	LANG=C $(CC) -c $(CFLAGS) \
    -Ic_src $(ERL_CFLAGS) \
    -o /tmp/clixir_support.o $<
	ar rcs $@ /tmp/clixir_support.o
