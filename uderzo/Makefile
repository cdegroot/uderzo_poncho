# Makefile for Linux targets
# Note: assumes Ubuntu. YMMV.

# Dogfood our configuration makefile fragment.
include c_src/uderzo.mk

LIBNANOVG=priv/libnanovg$(MIX_TARGET).a

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

# Work-around for nerves not setting $(AR) during cross-compile
# https://github.com/nerves-project/nerves/issues/297
ifneq ($(CROSSCOMPILE),)
AR = $(CROSSCOMPILE)-ar
endif

default: priv compile
	cp c_src/*.h priv
	cp c_src/uderzo.mk priv

# TODO non-debug builds for e.g. prod Mix env?
compile: $(LIBNANOVG) priv/clixir

priv:
	mkdir priv

$(LIBNANOVG):
	cd c_src; \
	  LANG=C $(CC) $(CFLAGS) -MMD -MP \
    -D_CRT_SECURE_NO_WARNINGS \
	  $(INCLUDES) \
    -o /tmp/nanovg.o -c nanovg.c
	$(AR) rcs $(LIBNANOVG) /tmp/nanovg.o

C_DEPS := $(wildcard c_src/*.c c_src/*.cx c_src/*.h c_src/*.hx)

priv/clixir: $(C_DEPS) $(LIBNANOVG)
	LANG=C $(CC) $(CFLAGS) \
		 -Ic_src $(ERL_CFLAGS) -I$(CLIXIR_DIR) $(INCLUDES) \
		 -o priv/clixir c_src/uderzo.c \
		 $(LIBNANOVG) \
		 -L$(CLIXIR_DIR) -lclixir$(MIX_TARGET) \
		 $(ERL_LDFLAGS) -lerl_interface -lei \
		 $(LDFLAGS)
