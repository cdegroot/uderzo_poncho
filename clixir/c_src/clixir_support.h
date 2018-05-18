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

/** Write response bytes. Used in generated code */
extern void write_response_bytes(const char *data, unsigned short len);

/** Does a hexdump of data on stderr. Note that everything needs to be compiled
    with CLIXIR_PROTOCOL_DUMP defined */
extern void dump_hex(const char prefix, const void* data, size_t size);

#endif
