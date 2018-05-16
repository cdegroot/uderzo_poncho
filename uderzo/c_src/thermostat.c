#line 1 "c_src/thermostat.hx"// -*- mode; c; -*-

#include "uderzo_support.h"


// END OF HEADER


#line 1 "Elixir.Uderzo.Thermostat"// Generated code for draw_text do not edit!
static void _dispatch_draw_text(const char *buf, unsigned short len, int *index) {
    double sz;
    char t[BUF_SIZE];
    long t_len;
    long tl;
    double x;
    double y;
    assert(ei_decode_binary(buf, index, t, &t_len) == 0);
    t[t_len] = '\0';
    assert(ei_decode_long(buf, index, &tl) == 0);
    assert(ei_decode_double(buf, index, &sz) == 0);
    assert(ei_decode_double(buf, index, &x) == 0);
    assert(ei_decode_double(buf, index, &y) == 0);
    nvgFontSize(vg, sz);
    nvgFontFace(vg, "sans");
    nvgTextAlign(vg, NVG_ALIGN_LEFT | NVG_ALIGN_TOP);
    nvgFillColor(vg, nvgRGBA(255, 255, 255, 255));
    nvgText(vg, x, y, t, t + tl);
}

// Generated code for show_flame do not edit!
static void _dispatch_show_flame(const char *buf, unsigned short len, int *index) {
    double h;
    double w;
    assert(ei_decode_double(buf, index, &w) == 0);
    assert(ei_decode_double(buf, index, &h) == 0);
    fprintf(stderr, "Here is where we draw a flame..;");
}

// Generated code for create_font do not edit!
static void _dispatch_create_font(const char *buf, unsigned short len, int *index) {
    char file_name[BUF_SIZE];
    long file_name_len;
    char name[BUF_SIZE];
    long name_len;
    int retval;
    assert(ei_decode_binary(buf, index, name, &name_len) == 0);
    name[name_len] = '\0';
    assert(ei_decode_binary(buf, index, file_name, &file_name_len) == 0);
    file_name[file_name_len] = '\0';
    assert(nvgCreateFont(vg, name, file_name) >= 0);
}

/* ANSI-C code produced by gperf version 3.1 */
/* Command-line: /usr/bin/gperf -t /tmp/clixir-temp-nonode@nohost--576460752303421247.gperf  */
/* Computed positions: -k'' */

#line 1 "/tmp/clixir-temp-nonode@nohost--576460752303421247.gperf"
struct dispatch_entry {
  char *name;
  void (*dispatch_func)(const char *buf, unsigned short len, int *index);
};

#define TOTAL_KEYWORDS 3
#define MIN_WORD_LENGTH 9
#define MAX_WORD_LENGTH 11
#define MIN_HASH_VALUE 9
#define MAX_HASH_VALUE 11
/* maximum key range = 3, duplicates = 0 */

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
  return len;
}

struct dispatch_entry *
in_word_set (register const char *str, register size_t len)
{
  static struct dispatch_entry wordlist[] =
    {
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
#line 6 "/tmp/clixir-temp-nonode@nohost--576460752303421247.gperf"
      {"draw_text", _dispatch_draw_text},
#line 7 "/tmp/clixir-temp-nonode@nohost--576460752303421247.gperf"
      {"show_flame", _dispatch_show_flame},
#line 8 "/tmp/clixir-temp-nonode@nohost--576460752303421247.gperf"
      {"create_font", _dispatch_create_font}
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

