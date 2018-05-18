# Makefile for Linux targets
# Note: assumes Ubuntu. YMMV.

# Note: hack alert. This is a straight copy from the Uderzo makefile.
# TODO clean this up so copy/paste isn't needed anymore. Probably by having Uderzo drop a makefile fragment in priv/
# Anything is better than the current ../uderzo references ;-)

ifeq ($(ERL_EI_INCLUDE_DIR),)
$(error ERL_EI_INCLUDE_DIR not set. Invoke via mix or set it manually)
endif

# Set Erlang-specific compile and linker flags
ERL_CFLAGS ?= -I$(ERL_EI_INCLUDE_DIR)
ERL_LDFLAGS ?= -L$(ERL_EI_LIBDIR)
CLIXIR_DIR = _build/$(MIX_ENV)/lib/clixir/priv
UDERZO_DIR = _build/$(MIX_ENV)/lib/uderzo/priv # This is where we can e.g. pick up a makefile fragment

NANOVG_SRC=../uderzo/c_src/nanovg

HW=$(shell uname -m)
ifeq ($(MIX_TARGET), rpi3)
# We're cross-compiling under Nerves. Play RPi3.
HW=armv7l
# And use - for now - the bundled erlang and nanovg libs.
# TODO cleanup this hack.
LIBNANOVG=../uderzo_demo_nerves/rpi3_deps/lib/libnanovg.a
else
LIBNANOVG=../uderzo/c_src/nanovg/build/libnanovg.a
endif


default: priv compile

# TODO non-debug builds for e.g. prod Mix env?
compile: priv/clixir

priv:
	mkdir priv

C_DEPS := $(wildcard c_src/*.c c_src/*.cx c_src/*.h c_src/*.hx)

# On armv7l, we assume RPi and we want to build for direct framebuffer stuff.
# Otherwise, we assume a regular X build.
# Flags and stuff stolen from /opt/vc/src/hello_pi
ifeq ($(HW), armv7l)
CFLAGS+=-DUDERZO_VC -DSTANDALONE -D__STDC_CONSTANT_MACROS -D__STDC_LIMIT_MACROS -DTARGET_POSIX -D_LINUX -fPIC -DPIC -D_REENTRANT -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64 -U_FORTIFY_SOURCE -Wall -g -DHAVE_LIBOPENMAX=2 -DOMX -DOMX_SKIP64BIT -ftree-vectorize -pipe -DUSE_EXTERNAL_OMX -DHAVE_LIBBCM_HOST -DUSE_EXTERNAL_LIBBCM_HOST -DUSE_VCHIQ_ARM -Wno-psabi
LDFLAGS+=-L/opt/vc/lib/ -lbrcmGLESv2 -lbrcmEGL -lopenmaxil -lbcm_host -lvchostif -lvcos -lvchiq_arm -lpthread -lrt -lm
INCLUDES+=-I/opt/vc/include/ -I/opt/vc/include/interface/vcos/pthreads -I/opt/vc/include/interface/vmcs_host/linux -I/opt/vc/src/hello_pi/libs/ilclient -I/opt/vc/src/hello_pi/libs/vgfont
else
LDFLAGS+=-lglfw -lGL -lGLU -lm -lGLEW
endif

priv/clixir: c_src/uderzo_example.c
	LANG=C $(CC) -g $(CFLAGS) \
    -I$(NANOVG_SRC)/src $(ERL_CFLAGS) -I$(CLIXIR_DIR) \
	  $(INCLUDES) -I../uderzo/c_src \
    -o $@ $< \
    $(LIBNANOVG) -lfreetype -lpng -lz \
    -L$(CLIXIR_DIR) -lclixir \
    $(ERL_LDFLAGS) -lerl_interface -lei \
    $(LDFLAGS)
