# To be run this way: make -f setup.mk (linux|mac)

.PHONY: linux mac
linux:
	sudo apt-get install premake4 gperf libglfw3-dev libgles2-mesa-dev libglew-dev libfreetype6-dev 

mac:
	brew install premake glew glfw freetype 
