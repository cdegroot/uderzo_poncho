/*
 * Common includes for all Uderzo files.
 */

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
