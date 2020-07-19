# Makefile for Linux targets

ifeq ($(ERL_EI_INCLUDE_DIR),)
$(error ERL_EI_INCLUDE_DIR not set. Invoke via mix or set it manually)
endif

# Set Erlang-specific compile and linker flags
ERL_CFLAGS ?= -I$(ERL_EI_INCLUDE_DIR)
ERL_LDFLAGS?= -L$(ERL_EI_LIBDIR) -lei

# TODO A bit of a hack, I'm probably missing something here...
CLIXIR_DIR = _build/$(MIX_ENV)/lib/clixir/priv

default: priv compile

compile: priv/clixir

priv:
	mkdir priv

priv/clixir: c_src/clixir_example.c
	LANG=C $(CC) $(CFLAGS) \
	  -I$(CLIXIR_DIR) $(ERL_CFLAGS) \
    $< -o $@ -L$(CLIXIR_DIR) -lclixir $(ERL_LDFLAGS)
