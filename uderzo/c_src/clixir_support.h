/*
 * Declarations for Clixir support functions and other common stuff.
 */
#ifndef __INCLUDED_CLIXIR_SUPPORT_H
#define __INCLUDED_CLIXIR_SUPPORT_H

#include <assert.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <stdlib.h>
#include <sys/uio.h>

#include <erl_interface.h> // or ei.h? No clue so far.

// we try to fit most of our shit in here until proven wrong. A 64k
// buffer size has the advantage that we can allocate it on modern
// stacks, which speeds things up and saves us from memory leaks.
#define BUF_SIZE 65536

// Send back a single OK atom
#define SEND_ERLANG_OK     write_single_atom("ok")
// Send back an error tuple
#define SEND_ERLANG_ERR(x) write_response_tuple2("error", x)

// The main read loop for clixir. Will read from stdin and
// dispatch commands to the generated code.
extern void clixir_read_loop();

// Utility functions to send data back to the BEAM VM.
extern void write_single_atom(const char *atom);
extern void write_response_tuple2(const char *atom, const char *message);
extern void write_response_bytes(const char *data, unsigned short len);
extern void dump_hex(const void* data, size_t size);

#endif
