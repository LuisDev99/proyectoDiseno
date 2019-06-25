#include <iostream>
#include <string>
#include <memory>
#include <chrono>
#include <verilated.h>          // Defines common routines
#include "VGADefines.h"
#include "VGADisplay.h"
#include "VVGA800x600.h"
#include "VVGA800x600_VGA800x600.h"

int main(int argc, char** argv)
{
    Verilated::commandArgs(argc, argv);   // Remember args

    std::unique_ptr<VVGA800x600> uut = std::make_unique<VVGA800x600>();

    //VGA stuff
    int last_clock = 0, last_vsync, counter = 0;

    std::unique_ptr<VGADisplay> vga = std::make_unique<VGADisplay>(*uut, VGA_WIDTH, VGA_HEIGHT);

    if (!vga->initDisplay()) {
        std::cerr << "Failed to init VGA display" << std::endl;
        return 1;
    }

    uut->reset = 0;
    uut->clk = 0;
    //uut->nextIMG = 1;
    uut->eval();

    uut->reset = 1;
    uut->eval();

    uut->reset = 0;
    uut->eval();
    
    last_vsync = uut->vsync;
    last_clock = uut->clk;
    std::cout << "VSync: " << static_cast<int>(uut->vsync) << '\n';

    int pulse_count = 0;
    int counter1 = 0;
    
    auto start = std::chrono::high_resolution_clock::now();

    while (!Verilated::gotFinish()) {
        uut->eval();
    
        //VGA clock positive edge
        if (uut->clk == 1) {
            vga->clockPulse(uut->red, uut->green, uut->blue);
            // if(counter1 == 10){
            //     uut->nextIMG = 1;
            //     counter1 = 0;
            // } else {
            //     counter1++;
            //     uut->nextIMG = 0;
            // }
        }

        //Check for vsync pulse
        if (last_vsync != uut->vsync) {
            if ((last_vsync == 1) && (uut->vsync == 0)) {
                //Negative pulse
                auto finish = std::chrono::high_resolution_clock::now();
                std::chrono::duration<double> elapsed = finish - start;
                std::cout << "Elapsed Time: " << elapsed.count() << "s" << '\n';
                start = finish;
                
                vga->paint();
            }

            last_vsync = uut->vsync;
        }

        uut->clk = !uut->clk;

        //  if (vga->isWindowClosed()) {
        //     break;
        // }
    }

    uut->final(); // Done simulating

    return 0;
}
