# Makefile for Linux targets
# Note: assumes Ubuntu. YMMV.

# Dogfood our configuration makefile fragment.
include c_src/uderzo.mk

LIBNANOVG=priv/libnanovg$(MIX_TARGET).a

ifeq ($(MIX_TARGET), rpi3)
RPI3_LIBFREETYPE = priv/libfreetyperpi3.a
RPI3_LIBPNG      = priv/libpngrpi3.a
endif

ifeq ($(MIX_ENV), test)
DEBUG=true
endif
ifeq ($(MIX_ENV), dev)
DEBUG=true
endif

ifeq ($(DEBUG), true)
CFLAGS+=-g -DDEBUG
else
CFLAGS=+-O2 -DNDEBUG
endif

default: priv $(RPI3_LIBFREETYPE) $(RPI3_LIBPNG) compile
	cp c_src/*.h priv
	cp c_src/uderzo.mk priv

# TODO non-debug builds for e.g. prod Mix env?
compile: $(LIBNANOVG) priv/clixir

priv:
	mkdir priv

$(LIBNANOVG): 
	cd c_src; \
	  LANG=C $(CC) $(CFLAGS) -MMD -MP \
    -DFONS_USE_FREETYPE -D_CRT_SECURE_NO_WARNINGS \
	  -I/usr/include/freetype2 \
    -o /tmp/nanovg.o -c nanovg.c
	ar -rcs $(LIBNANOVG) /tmp/nanovg.o

C_DEPS := $(wildcard c_src/*.c c_src/*.cx c_src/*.h c_src/*.hx)

ifeq ($(MIX_TARGET), rpi3)
FTLIBS = $(RPI3_LIBFREETYPE) $(RPI3_LIBPNG)
else
FTLIBS = -lfreetype -lpng
endif


priv/clixir: $(C_DEPS) $(LIBNANOVG)
	LANG=C $(CC) $(CFLAGS) \
		 -Ic_src $(ERL_CFLAGS) -I$(CLIXIR_DIR) $(INCLUDES) \
		 -o priv/clixir c_src/uderzo.c \
		 $(LIBNANOVG) $(FTLIBS) -lz \
		 -L$(CLIXIR_DIR) -lclixir$(MIX_TARGET) \
		 $(ERL_LDFLAGS) -lerl_interface -lei \
		 $(LDFLAGS)

# Not superclean, but for now we'll stick with it - install
# libfreetype and libpng for the RPI3 target
priv/libfreetyperpi3.a: rpi3_deps/lib/libfreetype.a
	cp $< $@
priv/libpngrpi3.a: rpi3_deps/lib/libpng.a
	cp $< $@

