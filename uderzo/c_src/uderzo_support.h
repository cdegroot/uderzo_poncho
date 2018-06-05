/*
 * Common includes for all Uderzo files.
 */
#ifndef UDERZO_SUPPORT_H
#define UDERZO_SUPPORT_H

// OpenGL ES 2 should support the widest array of devices.
// When UDERZO_VC is set, we target RaspberryPi's VideoCore.
#ifdef UDERZO_VC
#  include <bcm_host.h>
#  include <GLES2/gl2.h>
#  include <GLES2/gl2ext.h>
#  include <EGL/egl.h>
#  include <EGL/eglext.h>
#else
#  define GLFW_INCLUDE_ES2
#  define GLFW_INCLUDE_GLEXT
#  include <GLFW/glfw3.h>
#endif

#include <nanovg.h>
#define NANOVG_GLES2_IMPLEMENTATION
#include <nanovg_gl.h>
#include <nanovg_gl_utils.h>

#include "clixir_support.h"

// Our main function has a global context for NVG
extern NVGcontext *vg;

#ifdef UDERZO_VC
typedef struct
{
  // Global state for VideoCore code.
  // TODO: remove unused stuff.
   uint32_t screen_width;
   uint32_t screen_height;
// OpenGL|ES objects
   DISPMANX_DISPLAY_HANDLE_T dispman_display;
   DISPMANX_ELEMENT_HANDLE_T dispman_element;
   EGLDisplay display;
   EGLSurface surface;
   EGLContext context;

   GLuint verbose;
   GLuint vshader;
   GLuint fshader;
   GLuint mshader;
   GLuint program;
   GLuint program2;
   GLuint tex_fb;
   GLuint tex;
   GLuint buf;
} VC_STATE_T;

extern VC_STATE_T state;
#endif


#endif // UDERZO_SUPPORT_H
