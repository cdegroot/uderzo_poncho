# To be run this way: make -f setup.mk (linux|mac)

ifneq ($(CI), true)
SUDO := sudo
else
YES := -y
endif

.PHONY: linux mac
linux:
	$(SUDO) apt-get install $(YES) premake4 gperf libglfw3-dev libgles2-mesa-dev libglew-dev libfreetype6-dev 

mac:
	brew install premake glew glfw freetype 
