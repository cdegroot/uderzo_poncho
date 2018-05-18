#include <clixir_support.h>
#line 1 "/home/cees/mine/uderzo_poncho/clixir/_build/dev/clixir/Elixir.Clixir.Example.ExampleModule.hx"
/* This is an example C header file that will be included as is in the generated source */
#include <stdio.h>

// END OF HEADER


#line 1 "Elixir.Clixir.Example.ExampleModule"// Generated code for hello from Elixir.Clixir.Example.ExampleModule

static void _dispatch_Elixir_Clixir_Example_ExampleModule_hello(const char *buf, unsigned short len, int *index) {
    char message[BUF_SIZE];
    long message_len;
    assert(ei_decode_binary(buf, index, message, &message_len) == 0);
    message[message_len] = '\0';
    printf("Hello, %s!\n", message);
}


/* ANSI-C code produced by gperf version 3.1 */
/* Command-line: /usr/bin/gperf -t /tmp/clixir-temp-nonode@nohost--576460752303423385.gperf  */
/* Computed positions: -k'' */

#line 1 "/tmp/clixir-temp-nonode@nohost--576460752303423385.gperf"
struct dispatch_entry {
  char *name;
  void (*dispatch_func)(const char *buf, unsigned short len, int *index);
};

#define TOTAL_KEYWORDS 1
#define MIN_WORD_LENGTH 41
#define MAX_WORD_LENGTH 41
#define MIN_HASH_VALUE 0
#define MAX_HASH_VALUE 0
/* maximum key range = 1, duplicates = 0 */

#ifdef __GNUC__
__inline
#else
#ifdef __cplusplus
inline
#endif
#endif
/*ARGSUSED*/
static unsigned int
hash (register const char *str, register size_t len)
{
  return 0;
}

struct dispatch_entry *
in_word_set (register const char *str, register size_t len)
{
  static struct dispatch_entry wordlist[] =
    {
#line 6 "/tmp/clixir-temp-nonode@nohost--576460752303423385.gperf"
      {"Elixir_Clixir_Example_ExampleModule_hello", _dispatch_Elixir_Clixir_Example_ExampleModule_hello}
    };

  if (len <= MAX_WORD_LENGTH && len >= MIN_WORD_LENGTH)
    {
      register unsigned int key = hash (str, len);

      if (key <= MAX_HASH_VALUE)
        {
          register const char *s = wordlist[key].name;

          if (*str == *s && !strcmp (str + 1, s + 1))
            return &wordlist[key];
        }
    }
  return 0;
}

void _dispatch_command(const char *buf, unsigned short len, int *index) {
    char atom[MAXATOMLEN];
    struct dispatch_entry *dpe;
    assert(ei_decode_atom(buf, index, atom) == 0);

    dpe = in_word_set(atom, strlen(atom));
    if (dpe != NULL) {
         (dpe->dispatch_func)(buf, len, index);
    } else {
        fprintf(stderr, "Dispatch function not found for [%s]\
", atom);
    }
}

