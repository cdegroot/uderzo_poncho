// -*- mode: c; -*-

/*
 * This is the Clixir "header" that is put on top of the generated
 * code. It should contain
 * a) includes needed for the generated code;
 * b) a main method
 * c) any other stuff you can think off ;-)
 */
#include "uderzo_support.h"

extern void errorcb(int error, const char *desc);
extern void read_loop();

// These pesky global things, for now.
NVGcontext* vg = NULL;
#ifdef UDERZO_VC
VC_STATE_T state;
#endif

int uderzo_init() {

#ifdef UDERZO_VC
   // Stolen from the hello triangle sample
   int32_t success = 0;
   EGLBoolean result;
   EGLint num_config;

   static EGL_DISPMANX_WINDOW_T nativewindow;

   DISPMANX_UPDATE_HANDLE_T dispman_update;
   VC_RECT_T dst_rect;
   VC_RECT_T src_rect;

   static const EGLint attribute_list[] = {
      EGL_RED_SIZE, 8,
      EGL_GREEN_SIZE, 8,
      EGL_BLUE_SIZE, 8,
      EGL_ALPHA_SIZE, 8,
      EGL_SURFACE_TYPE, EGL_WINDOW_BIT,
      EGL_NONE
   };
   static const EGLint context_attributes[] = {
     EGL_CONTEXT_CLIENT_VERSION, 2,
     EGL_NONE
   };

   EGLConfig config;

   bcm_host_init();
   memset(&state, 0, sizeof(state));

   // get an EGL display connection
   state.display = eglGetDisplay(EGL_DEFAULT_DISPLAY);
   assert(state.display != EGL_NO_DISPLAY);

   // initialize the EGL display connection
   result = eglInitialize(state.display, NULL, NULL);
   assert(EGL_FALSE != result);

   // get an appropriate EGL frame buffer configuration
   result = eglChooseConfig(state.display, attribute_list, &config, 1, &num_config);
   assert(EGL_FALSE != result);

   result = eglBindAPI(EGL_OPENGL_ES_API);
   assert(EGL_FALSE != result);

   state.context = eglCreateContext(state.display, config, EGL_NO_CONTEXT, context_attributes);
   assert(state.context != EGL_NO_CONTEXT);

   // create an EGL window surface
   success = graphics_get_display_size(0 /* LCD */, &state.screen_width, &state.screen_height);
   assert(success >= 0);

   fprintf(stderr, "Raspberry screen size %d by %d\n", state.screen_width, state.screen_height);

   dst_rect.x = 0;
   dst_rect.y = 0;
   dst_rect.width = state.screen_width;
   dst_rect.height = state.screen_height;

   src_rect.x = 0;
   src_rect.y = 0;
   src_rect.width = state.screen_width << 16;
   src_rect.height = state.screen_height << 16;

   state.dispman_display = vc_dispmanx_display_open(0 /* LCD */);
   dispman_update = vc_dispmanx_update_start(0);

   state.dispman_element = vc_dispmanx_element_add (dispman_update, state.dispman_display,
      0/*layer*/, &dst_rect, 0/*src*/,
      &src_rect, DISPMANX_PROTECTION_NONE, 0 /*alpha*/, 0/*clamp*/, 0/*transform*/);

   nativewindow.element = state.dispman_element;
   nativewindow.width = state.screen_width;
   nativewindow.height = state.screen_height;
   vc_dispmanx_update_submit_sync(dispman_update);

   state.surface = eglCreateWindowSurface(state.display, config, &nativewindow, NULL);
   assert(state.surface != EGL_NO_SURFACE);

   // connect the context to the surface
   result = eglMakeCurrent(state.display, state.surface, state.surface, state.context);
   assert(EGL_FALSE != result);

   // Set background color and clear buffers
   glClearColor(0.15f, 0.25f, 0.35f, 1.0f);

   // Enable back face culling. Why?
   //glEnable(GL_CULL_FACE);

   glClear(GL_COLOR_BUFFER_BIT);
   assert(glGetError() == 0);

   // Not in GLES2? TODO check glMatrixMode(GL_MODELVIEW);

   vg = nvgCreateGLES2(NVG_ANTIALIAS | NVG_STENCIL_STROKES | NVG_DEBUG);
   assert(vg != NULL);

   uderzo_vcfbcp_init(); // Ignore errors for now.
#else
    if (!glfwInit()) {
        fprintf(stderr, "Uderzo: Failed to init GLFW.");
        return -1;
    }

    glfwSetErrorCallback(errorcb);
    glfwWindowHint(GLFW_CLIENT_API, GLFW_OPENGL_ES_API);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 2);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 0);

    fprintf(stderr, "Uderzo executable initialized.");
#endif
}

void errorcb(int error, const char *desc) {
    // TODO proper callback on stdout as well.
    fprintf(stderr, "GLFW error %d: %s\n", error, desc);
    // For now, just crash.
    assert(0);
}

#ifdef UDERZO_VC

// Code originally from https://github.com/tasanakorn/rpi-fbcp
// Note that faster/more complex variants exist (Adafruit has one
// that checks the minim rectangle to be copied), but for standard
// embedded displays low framerates shouldn't be bad. Feel free to
// disagree and send patches ;-)

// One-time initialization of the copying process. This opens files, sets
// up one-time variables, and basically readies us for the tight-loop (once
// per frame) stuff. Returns 0 on success, -1 on error.
int uderzo_vcfbcp_init() {
    struct fb_fix_screeninfo finfo;
    uint32_t image_prt;

    state.vcfbcp_fbfd = open("/dev/fb1", O_RDWR);
    if (state.vcfbcp_fbfd == -1) {
        fprintf(stderr, "Unable to open secondary display\n");
        return -1;
    }
    if (ioctl(state.vcfbcp_fbfd, FBIOGET_FSCREENINFO, &finfo)) {
        fprintf(stderr, "Unable to get secondary display information\n");
        return -1;
    }
    if (ioctl(state.vcfbcp_fbfd, FBIOGET_VSCREENINFO, &state.vcfbcp_vinfo)) {
        fprintf(stderr, "Unable to get secondary display information\n");
        return -1;
    }

    fprintf(stderr, "SPI Display screen size is %d by %d, bpp=%d\n", state.vcfbcp_vinfo.xres, state.vcfbcp_vinfo.yres, state.vcfbcp_vinfo.bits_per_pixel);

    state.vcfbcp_screen_resource = vc_dispmanx_resource_create(VC_IMAGE_RGB565, state.vcfbcp_vinfo.xres, state.vcfbcp_vinfo.yres, &image_prt);
    if (!state.vcfbcp_screen_resource) {
        fprintf(stderr, "Unable to create screen buffer\n");
        close(state.vcfbcp_fbfd);
        return -1;
    }

    state.vcfbcp_fbp = (char*) mmap(0, finfo.smem_len, PROT_READ | PROT_WRITE, MAP_SHARED,
                                    state.vcfbcp_fbfd, 0);
    if (state.vcfbcp_fbp <= 0) {
        fprintf(stderr, "Unable to create mamory mapping\n");
        close(state.vcfbcp_fbfd);
        vc_dispmanx_resource_delete(state.vcfbcp_screen_resource);
        return -1;
    }

    vc_dispmanx_rect_set(&state.vcfbcp_rect, 0, 0, state.vcfbcp_vinfo.xres, state.vcfbcp_vinfo.yres);

    state.vcfbcp_initialized = VCFBCP_INITIALIZED; // zee magic cookie
    return 0;
}

// Copies current frame to secondary display. Returns -1 on trouble.
int uderzo_vcfbcp_copy() {
    if (state.vcfbcp_initialized != VCFBCP_INITIALIZED) {
        fprintf(stderr, "VideoCore framebuffer copy not initialized, did you call uderzo_vcfbcp_init?\n");
        return -1;
    }

    vc_dispmanx_snapshot(state.dispman_display, state.vcfbcp_screen_resource, 0);
    vc_dispmanx_resource_read_data(state.vcfbcp_screen_resource, &state.vcfbcp_rect, state.vcfbcp_fbp,
                                   state.vcfbcp_vinfo.xres * state.vcfbcp_vinfo.bits_per_pixel / 8);
    return 0;
}

#endif // UDERZO_VC specific code

// End of manually maintained header. Generated code follows below.
