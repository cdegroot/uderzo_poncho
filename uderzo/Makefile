# Makefile for Linux targets
# Note: assumes Ubuntu. YMMV.

# Dogfood our configuration makefile fragment.
include c_src/uderzo.mk

NANOVG_SRC=deps/nanovg

ifeq ($(MIX_TARGET), rpi3)
# TODO cleanup this hack, if must be by including this binary somewhere.
LIBNANOVG=../uderzo_demo_nerves/rpi3_deps/lib/libnanovg.a
else
LIBNANOVG=$(NANOVG_SRC)/build/libnanovg.a
endif

default: priv compile
	cp $(LIBNANOVG) priv
	cp c_src/uderzo_support.h $(NANOVG_SRC)/src/*.h priv
	cp c_src/uderzo.mk priv

premake:
	(cd $(NANOVG_SRC); premake4 gmake)


# TODO non-debug builds for e.g. prod Mix env?
compile: $(LIBNANOVG) priv/clixir

priv:
	mkdir priv

$(LIBNANOVG): premake
	(cd $(NANOVG_SRC)/build; make nanovg)

C_DEPS := $(wildcard c_src/*.c c_src/*.cx c_src/*.h c_src/*.hx)

priv/clixir: $(C_DEPS) $(LIBNANOVG)
	LANG=C $(CC) -g $(CFLAGS) \
		 -I$(NANOVG_SRC)/src $(ERL_CFLAGS) -I$(CLIXIR_DIR) $(INCLUDES) \
		 -o priv/clixir c_src/uderzo.c \
		 $(LIBNANOVG) -lfreetype -lpng -lz \
		 -L$(CLIXIR_DIR) -lclixir \
		 $(ERL_LDFLAGS) -lerl_interface -lei \
		 $(LDFLAGS)
