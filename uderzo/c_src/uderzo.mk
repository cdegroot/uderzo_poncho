# Makefile fragment to configure an uderzo library or client build.

# Set Erlang-specific compile and linker flags passed from Mix
ifeq ($(ERL_EI_INCLUDE_DIR),)
$(error ERL_EI_INCLUDE_DIR not set. Invoke via mix or set it manually)
endif
ERL_CFLAGS ?= -I$(ERL_EI_INCLUDE_DIR)
ERL_LDFLAGS ?= -L$(ERL_EI_LIBDIR)

# An explicit objective of Uderzo is to support the RaspberryPi with VideoCore
# (i.e. "no Xorg"). For now, we always assume that whether you compile under
# Nerves with a MIX_TARGET or on a RPi3 directly, you want that mode. Note
# that this will assume you develop/test on an RPi3, which I think it the
# only RaspberryPi suitable for development purposes. You can, however, override
# MIX_TARGET.
ifeq ($(shell uname -m), armv7l)
MIX_TARGET ?= rpi3
endif

ifdef MIX_TARGET
# We're cross-compiling under Nerves. Play Raspberry Pi.
CFLAGS+=-DUDERZO_VC -DSTANDALONE -D__STDC_CONSTANT_MACROS -D__STDC_LIMIT_MACROS -DTARGET_POSIX -D_LINUX -fPIC -DPIC -D_REENTRANT -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64 -U_FORTIFY_SOURCE -Wall -DHAVE_LIBOPENMAX=2 -DOMX -DOMX_SKIP64BIT -ftree-vectorize -pipe -DUSE_EXTERNAL_OMX -DHAVE_LIBBCM_HOST -DUSE_EXTERNAL_LIBBCM_HOST -DUSE_VCHIQ_ARM -Wno-psabi
LDFLAGS+=-L/opt/vc/lib/ -lbrcmGLESv2 -lbrcmEGL -lopenmaxil -lbcm_host -lvchostif -lvcos -lvchiq_arm -lpthread -lrt -lm
INCLUDES+=-I/opt/vc/include/ -I/opt/vc/include/interface/vcos/pthreads -I/opt/vc/include/interface/vmcs_host/linux -I/opt/vc/src/hello_pi/libs/ilclient -I/opt/vc/src/hello_pi/libs/vgfont
else
# Native build using GLFW and similar goodies
ifeq ($(shell uname -s),Linux)
LDFLAGS+=-lglfw -lGL -lGLU -lm -lGLEW
endif
ifeq ($(shell uname -s),Darwin)
LDFLAGS+=-framework OpenGL -lglfw -lglew -framework Carbon -framework GLUT
endif
endif

# For the benefit of clients:
UDERZO_CFLAGS = -I$(UDERZO_DIR) $(ERL_CFLAGS) -I$(CLIXIR_DIR) $(INCLUDES)
UDERZO_LDFLAGS = -L$(UDERZO_DIR) -lnanovg$(MIX_TARGET) -lfreetype$(MIX_TARGET) -lpng$(MIX_TARGET) -lz -L$(CLIXIR_DIR) -lclixir$(MIX_TARGET) $(ERL_LDFLAGS) -lerl_interface -lei $(LDFLAGS)
