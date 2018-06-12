# Makefile for Linux targets
# Note: assumes Ubuntu. YMMV.

# Dogfood our configuration makefile fragment.
include c_src/uderzo.mk

LIBNANOVG=priv/libnanovg$(MIX_TARGET).a

ifdef MIX_TARGET
TARGET_LIBFREETYPE = priv/libfreetype$(MIX_TARGET).a
TARGET_LIBPNG      = priv/libpng$(MIX_TARGET).a
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
CFLAGS+=-O2 -DNDEBUG
endif

ifeq ($(shell uname -s),Darwin)
INCLUDES += -I/usr/local/include/freetype2
endif

default: priv $(TARGET_LIBFREETYPE) $(TARGET_LIBPNG) compile
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
	  -I/usr/include/freetype2 $(INCLUDES) \
    -o /tmp/nanovg.o -c nanovg.c
	ar -rcs $(LIBNANOVG) /tmp/nanovg.o

C_DEPS := $(wildcard c_src/*.c c_src/*.cx c_src/*.h c_src/*.hx)

ifdef MIX_TARGET
FTLIBS = $(TARGET_LIBFREETYPE) $(TARGET_LIBPNG)
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
# libfreetype and libpng for the specified target
priv/libfreetype$(MIX_TARGET).a: rpi_deps/lib/libfreetype.a
	cp $< $@
priv/libpng$(MIX_TARGET).a: rpi_deps/lib/libpng.a
	cp $< $@
