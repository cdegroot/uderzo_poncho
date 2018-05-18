# Makefile fragment to configure an uderzo library or client build.

# Set Erlang-specific compile and linker flags passed from Mix
ifeq ($(ERL_EI_INCLUDE_DIR),)
$(error ERL_EI_INCLUDE_DIR not set. Invoke via mix or set it manually)
endif
ERL_CFLAGS ?= -I$(ERL_EI_INCLUDE_DIR)
ERL_LDFLAGS ?= -L$(ERL_EI_LIBDIR)
CLIXIR_DIR = _build/$(MIX_ENV)/lib/clixir/priv

# An explicit objective of Uderzo is to support the RaspberryPi with VideoCore
# (i.e. "no Xorg").
ifeq ($(MIX_TARGET), rpi3)
# We're cross-compiling under Nerves. Play RPi3.
CFLAGS+=-DUDERZO_VC -DSTANDALONE -D__STDC_CONSTANT_MACROS -D__STDC_LIMIT_MACROS -DTARGET_POSIX -D_LINUX -fPIC -DPIC -D_REENTRANT -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64 -U_FORTIFY_SOURCE -Wall -g -DHAVE_LIBOPENMAX=2 -DOMX -DOMX_SKIP64BIT -ftree-vectorize -pipe -DUSE_EXTERNAL_OMX -DHAVE_LIBBCM_HOST -DUSE_EXTERNAL_LIBBCM_HOST -DUSE_VCHIQ_ARM -Wno-psabi
LDFLAGS+=-L/opt/vc/lib/ -lbrcmGLESv2 -lbrcmEGL -lopenmaxil -lbcm_host -lvchostif -lvcos -lvchiq_arm -lpthread -lrt -lm
INCLUDES+=-I/opt/vc/include/ -I/opt/vc/include/interface/vcos/pthreads -I/opt/vc/include/interface/vmcs_host/linux -I/opt/vc/src/hello_pi/libs/ilclient -I/opt/vc/src/hello_pi/libs/vgfont
else
# Native build using GLFW and similar goodies
LDFLAGS+=-lglfw -lGL -lGLU -lm -lGLEW
endif

# For the benefit of clients:
UDERZO_CFLAGS = -I$(UDERZO_DIR) $(ERL_CFLAGS) -I$(CLIXIR_DIR) $(INCLUDES)
UDERZO_LDFLAGS = -L$(UDERZO_DIR) -lnanovg -lfreetype -lpng -lz -L$(CLIXIR_DIR) -lclixir $(ERL_LDFLAGS) -lerl_interface -lei $(LDFLAGS)
