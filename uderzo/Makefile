# Makefile for Linux targets
# Note: assumes Ubuntu. YMMV.

# Note: hack alert. I'm not proud of this stuff. Make it work, make it right, make it fast.

NANOVG_SRC=c_src/nanovg

HW=$(shell uname -m)
ifeq ($(MIX_TARGET), rpi3)
# We're cross-compiling under Nerves. Play RPi3.
HW=armv7l
# And use - for now - the bundled erlang and nanovg libs.
# TODO cleanup this hack.
ERLANG_PATH=../uderzo_demo_nerves/rpi3_deps
LIBNANOVG=../uderzo_demo_nerves/rpi3_deps/lib/libnanovg.a
else
ERLANG_PATH=$(shell erl -eval 'io:format("~s", [lists:concat([code:root_dir(), "/erts-", erlang:system_info(version), "/../usr"])])' -s init stop -noshell)
LIBNANOVG=$(NANOVG_SRC)/build/libnanovg.a
endif


default: priv compile

setup:
	sudo apt-get install premake4 gperf libglfw3-dev libgles2-mesa-dev libglew-dev libfreetype6-dev
	(cd $(NANOVG_SRC); premake4 gmake)

# TODO non-debug builds for e.g. prod Mix env?
compile: $(LIBNANOVG) priv/uderzo

priv:
	mkdir priv

$(LIBNANOVG):
	(cd $(NANOVG_SRC)/build; make nanovg)

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

priv/uderzo: $(C_DEPS) $(LIBNANOVG)
	LANG=C $(CC) -g $(CFLAGS) \
    -I$(NANOVG_SRC)/src -I$(ERLANG_PATH)/include \
	  $(INCLUDES) \
    -o priv/uderzo c_src/*.c \
    $(LIBNANOVG) -lfreetype -lpng -lz \
    -L$(ERLANG_PATH)/lib -lerl_interface -lei \
    $(LDFLAGS)

