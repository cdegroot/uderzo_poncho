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
#  include <linux/fb.h>
#  include <sys/mman.h>
#  include <sys/types.h>
#  include <sys/stat.h>
#  include <sys/ioctl.h>
#  include <fcntl.h>
#else
#  define GLFW_INCLUDE_GLEXT
#  include <GLFW/glfw3.h>
#endif

#include <nanovg.h>
#ifdef UDERZO_VC
#  define NANOVG_GLES2_IMPLEMENTATION
#else
#  define NANOVG_GL2_IMPLEMENTATION
#endif
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

    // State for the framebuffer copier. Note that this is only
    // valid after you called uderzo_vcfbcp_init!
    DISPMANX_RESOURCE_HANDLE_T vcfbcp_screen_resource;
    struct fb_var_screeninfo vcfbcp_vinfo;
    VC_RECT_T vcfbcp_rect;
    int vcfbcp_fbfd;
    char *vcfbcp_fbp;

    int vcfbcp_initialized;
} VC_STATE_T;

#define VCFBCP_INITIALIZED 0xccca5eee

extern VC_STATE_T state;

// Initialize the frame buffer copier. Call once
extern int uderzo_vcfbcp_init();
// Copy the framebuffer to fb1. Call when a frame has been rendered.
extern int uderzo_vcfbcp_copy();
#endif

#endif // UDERZO_SUPPORT_H
