# Overview

Uderzo is a way of writing 2D user interfaces with minimum fuzz and
maximum fun. It is based on [Clixir](https://hex.pm/packages/clixir)
for the interfacing with C.

The basis for Uderzo is OpenGL (as the Embedded 2.0 profile) and
[NanoVG](https://github.com/memononen/nanovg) for the HTML5 Canvas
like vector graphics. It currently supports the following platforms:

* Linux and MacOS, where GLFW will be used to open a window;
* RaspberryPi 3, which compiles against Broadcom's VideoCore library.

The latter is the "interesting" target, as it will allow you to
build a [Nerves](https://nerves-project.org/) application which
can write to either HDMI or a "HAT" style LCD/TFT display without
needing extra stuff like Xorg or even Qt Embedded. However, nothing
precludes you from writing games for Linux or MacOS for it.

## Status

Currently, Uderzo is "platform-complete" in that the example app in
its repository runs on the three target platforms. However, the
library of functions is still pretty rudimentary. The expectation
is that developing actual applications on top of it will drive
a basic set of 2D functions that are directly accessible from Elixir.

## Example code

The Uderzo repository, setup as a "poncho" style project, contains
a simple example application that consists of three files:

* [c_src/thermostat.cx](https://github.com/cdegroot/uderzo_poncho/blob/master/uderzo_example/c_src/thermostat.hx). This is the Clixir header file that will be included on top of the
generated C code. In this case, it just includes the Uderzo support header.

* [lib/thermostat.ex](https://github.com/cdegroot/uderzo_poncho/blob/master/uderzo_example/lib/thermostat.ex). This is a regular Elixir file which uses Clixir to define C functions
that draw stuff, mixed with Elixir functions to combine these C functions
to higher-level primitives. As they sit in the same source file, switching
functions from Elixir to C is trivial and transparent.

* [lib/demo.ex](https://github.com/cdegroot/uderzo_poncho/blob/master/uderzo_example/lib/demo.ex). This is the top level driver - it initializes Uderzo and the thermostat demo, and then goes into
a render loop that does the rendering and then instructs Uderzo to end the frame. This code
is basically the boilerplate that every Uderzo application needs.

At the moment, there is really not much more to it; input currently is not handled but
very easy to slap on.
