# Makefile for Linux targets

# See mix.exs for environment expectations
ifeq ($(ERL_EI_INCLUDE_DIR),)
$(error ERL_EI_INCLUDE_DIR not set. Invoke via mix or set it manually)
endif

# Set Erlang-specific compile and linker flags
ERL_CFLAGS ?= -I$(ERL_EI_INCLUDE_DIR)
ERL_LDFLAGS?= -L$(ERL_EI_LIBDIR) -lerl_interface -lei

default: priv compile priv/clixir_support.h

compile: priv/libclixir.a

priv:
	mkdir priv

priv/libclixir.a: c_src/clixir_support.c c_src/clixir_support.h
	LANG=C $(CC) -c $(CFLAGS) \
    -Ic_src $(ERL_CFLAGS) \
    -o /tmp/clixir_support.o $<
	ar rcs $@ /tmp/clixir_support.o

priv/clixir_support.h: c_src/clixir_support.h
	cp $< $@
