[![CircleCI](https://circleci.com/gh/cdegroot/uderzo_poncho.svg?style=svg)](https://circleci.com/gh/cdegroot/uderzo_poncho)

# Uderzo

Uderzo is a flexible way to add simple OpenGL/NanoVG UIs to Elixir
projects. One clear target is Nerves systems.

Currently, Uderzo is being prototyped. Running a demo on Nerves
works. This repository combines two subprojects in "poncho" style: *
`uderzo/`, the actual library; * `uderzo_demo_nerves/`, a Nerves RPi3
demo (burn it, boot it, and watch graphics animations).  Everything is
rough around the edges, but the end-to-end system is there and making
it nicer is pretty much a downhill run.

## Getting started

There's a bunch of projects in here and some of them need quite a lot
of dependencies installed. Start at this directory's `Makefile` for
a roadmap. The rest of the readme has some background info, this is
a quick list of elixir projects included here:

* `clixir` - a way to safely and easily integrate C code
* `clixir_example` - make C code print hello, world.
* `uderzo` - a 2D vector graphics library for Elixir
* `uderzo_example` - a simple example of an uderzo-based display
* `uderzo_demo_nerves` - use Nerves to make the example run on an RPi3 using VideoCore

## Why?

Today, all your UIs are Web. I think html/javascript/css is not a very
nice environment for developing rich UIs, and I rather stay in Elixir
when I'm developing in Elixir as much as possible. Also, when creating
small systems like a RaspberryPi with a touchscreen hat, I think it's a
bit rich to require a Phoenix server, a Qt browser, and a single page app
just to, say, display the weather. Therefore, I wanted something leaner,
simpler, and basically more fun than another Web UI. Uderzo is the system
that came out, based on NanoVG for 2D graphics. You have a blank canvas
and can paint on it with simple 2D primitives (or mix in full OpenGL ES2
calls), and you can choose what you want to run in Elixir, what in C,
and what in between (more on that later).

## Goals

The prime goal is stability. The GUI is not allowed to crash Erlang
in any circumstances.  Call me paranoid, but I want to run my house
thermostat on this and don't want to come home to frozen pipes because
OpenGL crashed ;-). I also think that this is in line with the Erlang
philosophy: make it as stable as possible.

The second goal is flexibility. I probably want to stick with Elixir
for my UI as much as possible, but if it's not fast enough, I want to
be able to move to C. Or something in beween.

The third goal is to have an API that feels like a native Elixir API
and stay as faithful to the BEAM/Erlang/Elixir design philosophy as
possible. One of the design philosophies is system independence - I want
to be able to design a GUI on a full development system, burn it to a Pi,
and have it run the same.

## Design

Uderzo runs a `GraphicsServer` supervisor, which starts a Port to the
`uderzo` executable. The executable contains all the graphics code,
and thus can do the silly stuff that makes C programs crash without
affecting the Erlang VM.

Communication is through the stdin/stdout connection - commands are sent
out as Erlang tuples, responses are received in the same fashion. All
responses go to a pid specified in the corresponding command, and
everything is meant to be asynchronous - again, this is closest to how
things are supposed to work on the BEAM.

Essentially, that's it. You have a C executable that initializes OpenGL
and NanoVG, then reads a command (using the `ei` library), executes it,
and optionally sends a response back.

## Clixir

However, that smells like typing a lot of repetitive code. Therefore, the
"glue" code is written in an Elixir subset/dialect that's dubbed Clixir. It's
the magic sauce that makes extending and adapting Uderzo fun. A (graphics) function
in Clixir is specified with `defgfx` (the name will likely change, as Clixir is
applicable as a generic safe FFI mechanism). You can find examples in the uderzo
README. A Clixir function will expand into an Elixir function definition with the right
arguments that calls out to the GraphicsServer and a C function that has the body of
the function in equivalent C code wrapped in the code to demarshall arguments and
marshall any responses. Function dispatch is through a `gperf` generated hashtable
and therefore extremely fast.

Given that all the boring/hard code is generated, it becomes easy to move graphics
code between Elixir, Clixir, and C so you can pick and choose.

Clixir documentation for the latest published version of the library starts
[here](https://hexdocs.pm/clixir/clixir.html).

## Docs

Docs for the latest version of the library can be
found [here](https://hexdocs.pm/uderzo/api-reference.html).

## Nerves Demo

`cd uderzo_demo_nerves; mix do deps.get, run`

should pop up the NanoVG demo. If you burn the Nerves firmware, it should pop up a
(currently worse looking) demo on a Pi3. Note that currently, only Linux and Mac
OS X have been tested but it should work on Windows with little adaptation.

## Desktop Demo

`cd uderzo_example; mix run -e Uderzo.Demo.run --no-halt`

This should pop up a window showing fake temperature readings.

## Installation

Ensure you are running a supported Elixir version. Uderzo has been tested with
Elixir 1.6.5 and Erlang 20.2. Install them by first installing
[asdf](https://github.com/asdf-vm/asdf). Then run `asdf install`

### Arch Linux

Assuming you're running X11 then installing the following packages should work:

    sudo pacman -S gperf glfw-x11 glew

## License

To stay compatible with Nerves, this work is licensed under the Apache License. Details
can be found in the file LICENSE in this repository.

NanoVG is included in this repository and is under a MIT/BSD style license. Included in
NanoVG are some utility routines from the STB collection that have been placed into the
public domain.

## TODO

See https://github.com/cdegroot/uderzo_poncho/projects/1

## Contributing

Submit a pull request, an issue, or hit me up on Slack.

