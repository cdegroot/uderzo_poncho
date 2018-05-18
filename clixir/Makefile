# Makefile for Linux targets

# This makefile does two things, which is not nice but I didn't want to split
# Clixir up further:
# 1. It builds the library, priv/libclixir.a
# 2. It builds the example executable, priv/clixir
# The bits for step 2 are what needs to be replicated for projects just
# using Clixir.

ifeq ($(ERL_EI_INCLUDE_DIR),)
$(error ERL_EI_INCLUDE_DIR not set. Invoke via mix or set it manually)
endif

# Set Erlang-specific compile and linker flags
ERL_CFLAGS ?= -I$(ERL_EI_INCLUDE_DIR)
ERL_LDFLAGS?= -L$(ERL_EI_LIBDIR) -lerl_interface -lei

default: priv compile

compile: priv/libclixir.a priv/clixir

priv:
	mkdir priv

priv/libclixir.a: c_src/clixir_support.c c_src/clixir_support.h
	LANG=C $(CC) -c $(CFLAGS) \
    -Ic_src $(ERL_CFLAGS) \
    -o /tmp/clixir_support.o $<
	ar rcs $@ /tmp/clixir_support.o

priv/clixir: c_src/clixir.c priv/libclixir.a
	LANG=C $(CC) $(CFLAGS) \
	  -Ic_src $(ERL_CFLAGS) \
    $< -o $@ -Lpriv -lclixir $(ERL_LDFLAGS)
