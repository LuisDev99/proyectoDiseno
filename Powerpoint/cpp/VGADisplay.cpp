#include <iostream>
#include "VGADisplay.h"

VGADisplay::~VGADisplay() {
    if (window != nullptr) {
        SDL_DestroyRenderer(renderer);
        SDL_DestroyWindow(window);

        SDL_Quit();
    }
}

bool VGADisplay::initDisplay() {
    SDL_Init(SDL_INIT_VIDEO);

    window = SDL_CreateWindow(
        "VGA Screen",
        SDL_WINDOWPOS_UNDEFINED,
        SDL_WINDOWPOS_UNDEFINED,
        width,
        height,
        SDL_WINDOW_OPENGL
    );

    if (window == nullptr) {
        std::cerr << "Could not create window: " << SDL_GetError() << '\n';
        return false;
    }

    renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);
    if (renderer == nullptr) {
        std::cerr << "Could not create renderer : " << SDL_GetError() << '\n';
        SDL_DestroyWindow(window);
        SDL_Quit();
        return false;
    }

    return true;
}

void VGADisplay::clockPulse(uint8_t red, uint8_t green, uint8_t blue) {
    unsigned x = vgam.VGA800x600->hcount;
    unsigned y = vgam.VGA800x600->vcount;

    if ((x < width) && (y < height)) {
        Color c;
        c.red = red << 5;
        c.green = green << 5;
        c.blue = blue << 6;

        frameBuff[y*width + x] = c;
    }
}

void VGADisplay::paint() {
    for (unsigned y = 0; y < height; y++) {
        for (unsigned x = 0; x < width; x++) {
            Color color = frameBuff[y * width + x];

            SDL_SetRenderDrawColor(renderer, color.red, color.green, color.blue, 255);
            SDL_RenderDrawPoint(renderer, x, y);
        }
    }
    SDL_RenderPresent(renderer);
}

bool VGADisplay::isWindowClosed() {
    SDL_Event e;
    if (SDL_PollEvent(&e)) {
        if (e.type == SDL_QUIT) {
            return true;
        }
    }

    return false;
}

void VGADisplay::saveScreenshot(const char *filename) {
        SDL_Surface *pScreenShot;

        pScreenShot = SDL_CreateRGBSurface(0, width, height, 32, 0x00ff0000, 0x0000ff00, 0x000000ff, 0xff000000);
        if(pScreenShot) {
            SDL_RenderReadPixels(renderer,
                                nullptr,
                                SDL_PIXELFORMAT_ARGB8888,
                                pScreenShot->pixels,
                                pScreenShot->pitch);

            SDL_SaveBMP(pScreenShot, filename);
            SDL_FreeSurface(pScreenShot);
        } else {
            std::cerr << "Couldn't create screenshot surface. SDL_GetError() - " << SDL_GetError() << "\n";
        }
}
