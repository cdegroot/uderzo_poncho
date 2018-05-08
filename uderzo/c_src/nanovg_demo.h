#ifndef DEMO_H
#define DEMO_H

#include "nanovg.h"

struct DemoData {
	int fontNormal, fontBold, fontIcons, fontEmoji;
	int images[12];
};
typedef struct DemoData DemoData;

int loadDemoData(NVGcontext* vg, DemoData* data);
void freeDemoData(NVGcontext* vg, DemoData* data);
void renderDemo(NVGcontext* vg, float mx, float my, float width, float height, float t, int blowup, DemoData* data);

void saveScreenShot(int w, int h, int premult, const char* name);

void drawWindow(NVGcontext* vg, const char* title, float x, float y, float w, float h);
void drawSearchBox(NVGcontext* vg, const char* text, float x, float y, float w, float h);
void drawDropDown(NVGcontext* vg, const char* text, float x, float y, float w, float h);
void drawLabel(NVGcontext* vg, const char* text, float x, float y, float w, float h);
void drawEditBoxBase(NVGcontext* vg, float x, float y, float w, float h);
void drawEditBox(NVGcontext* vg, const char* text, float x, float y, float w, float h);
void drawEditBoxNum(NVGcontext* vg, const char* text, const char* units, float x, float y, float w, float h);
void drawCheckBox(NVGcontext* vg, const char* text, float x, float y, float w, float h);
void drawButton(NVGcontext* vg, int preicon, const char* text, float x, float y, float w, float h, NVGcolor col);
void drawSlider(NVGcontext* vg, float pos, float x, float y, float w, float h);
void drawEyes(NVGcontext* vg, float x, float y, float w, float h, float mx, float my, float t);
void drawGraph(NVGcontext* vg, float x, float y, float w, float h, float t);
void drawSpinner(NVGcontext* vg, float cx, float cy, float r, float t);
void drawThumbnails(NVGcontext* vg, float x, float y, float w, float h, const int* images, int nimages, float t);
void drawColorwheel(NVGcontext* vg, float x, float y, float w, float h, float t);
void drawLines(NVGcontext* vg, float x, float y, float w, float h, float t);
void drawParagraph(NVGcontext* vg, float x, float y, float width, float height, float mx, float my);
void drawWidths(NVGcontext* vg, float x, float y, float width);
void drawCaps(NVGcontext* vg, float x, float y, float width);
void drawScissor(NVGcontext* vg, float x, float y, float t);

#endif // DEMO_H
