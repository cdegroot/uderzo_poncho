# Makefile for Linux targets

UDERZO_DIR = $(CURDIR)/_build/$(MIX_ENV)/lib/uderzo/priv
include $(UDERZO_DIR)/uderzo.mk

default: priv priv/clixir

priv:
	mkdir priv

priv/clixir: c_src/uderzo_example.c
	LANG=C $(CC) -g $(CFLAGS) $(UDERZO_CFLAGS) \
	  -o $@ $< \
	  $(UDERZO_LDFLAGS)
