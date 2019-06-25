#ifndef _VGA_DISPLAY_H

#define _VGA_DISPLAY_H

#include <vector>
#include <cstdint>
#include <SDL.h>
#include "VVGA800x600.h"
#include "VVGA800x600_VGA800x600.h"

class VGADisplay {
public:
  VGADisplay(VVGA800x600& vgam, int width, int height):
    width(width), height(height), vgam(vgam),
    window(nullptr), renderer(nullptr),
    frameBuff(width * height) {}

  ~VGADisplay();

  bool initDisplay();
  void clockPulse(uint8_t red, uint8_t green, uint8_t blue);
  void paint();
  void saveScreenshot(const char *filename);
  bool isWindowClosed();

  void getResolution(int &width, int &height) {
      width = this->width;
      height = this->height;
  }

private:
    struct Color {
        uint8_t red;
        uint8_t green;
        uint8_t blue;
    };

private:
    SDL_Window *window;
    SDL_Renderer *renderer;
    int width, height; 	// Screen resolution
    std::vector<Color> frameBuff;
    VVGA800x600& vgam;
};

#endif
