// DESCRIPTION: Verilator: Verilog example module
//
// This file ONLY is placed under the Creative Commons Public Domain, for
// any use, without warranty, 2017 by Wilson Snyder.
// SPDX-License-Identifier: CC0-1.0
//======================================================================

#include <verilated.h>
#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <iomanip>
#include <filesystem>
#include "verilated_fst_c.h"

#include "Vnes_tb.h"

vluint64_t ppu_cycle = 0;
double sc_time_stamp() {
    return ppu_cycle;  // Note does conversion to real, to match SystemC
}

class FrameRecorder
{
    int skip_frames;
    int max_frames;
    int w,h;
    bool active_frame;
    std::ofstream f;
    unsigned char pal_r[64] = {0x66,0x00,0x14,0x3b,0x5c,0x6e,0x6c,0x56,0x33,0x0b,0x00,0x00,0x00,0x00,0x00,0x00,0xad,0x15,0x42,0x75,0xa0,0xb7,0xb5,0x99,0x6b,0x38,0x0c,0x00,0x00,0x00,0x00,0x00,0xff,0x64,0x92,0xc6,0xf3,0xfe,0xfe,0xea,0xbc,0x88,0x5c,0x45,0x48,0x4f,0x00,0x00,0xff,0xc0,0xd3,0xe8,0xfb,0xfe,0xfe,0xf7,0xe4,0xcf,0xbd,0xb3,0xb5,0xb8,0x00,0x00};
    unsigned char pal_g[64] = {0x66,0x2a,0x12,0x00,0x00,0x00,0x06,0x1d,0x35,0x48,0x52,0x4f,0x40,0x00,0x00,0x00,0xad,0x5f,0x40,0x27,0x1a,0x1e,0x31,0x4e,0x6d,0x87,0x93,0x8f,0x7c,0x00,0x00,0x00,0xfe,0xb0,0x90,0x76,0x6a,0x6e,0x81,0x9e,0xbe,0xd8,0xe4,0xe0,0xcd,0x4f,0x00,0x00,0xfe,0xdf,0xd2,0xc8,0xc2,0xc4,0xcc,0xd8,0xe5,0xef,0xf4,0xf3,0xeb,0xb8,0x00,0x00};
    unsigned char pal_b[64] = {0x66,0x88,0xa7,0xa4,0x7e,0x40,0x00,0x00,0x00,0x00,0x00,0x08,0x4d,0x00,0x00,0x00,0xad,0xd9,0xff,0xfe,0xcc,0x7b,0x20,0x00,0x00,0x00,0x00,0x32,0x8d,0x00,0x00,0x00,0xff,0xff,0xff,0xff,0xff,0xcc,0x70,0x22,0x00,0x00,0x30,0x82,0xde,0x4f,0x00,0x00,0xff,0xff,0xff,0xff,0xff,0xea,0xc5,0xa5,0x94,0x96,0xab,0xcc,0xf2,0xb8,0x00,0x00};

public:
    int frame_num;
    FrameRecorder(int max_frames, int skip_frames, int w, int h);
    ~FrameRecorder() { if(f.is_open()) f.close(); };
    bool process(int vblank, int pixel_en, int pixel);
};

FrameRecorder::FrameRecorder(int max_frames=0, int skip_frames=0, int w=256, int h=240)
    : frame_num(0), max_frames(max_frames), skip_frames(skip_frames), w(w), h(h), active_frame(false)
{

}

bool FrameRecorder::process(int vblank, int pixel_en, int pixel)
{
    if (active_frame)
    {
        if (pixel_en)
        {
            // record a pixel
            f.write((char*) &pal_r[pixel], 1);
            f.write((char*) &pal_g[pixel], 1);
            f.write((char*) &pal_b[pixel], 1);
        }

        if (vblank)
        {
            // frame is over
            std::cout << "done" << std::endl;
            f.close();
            active_frame = false;
            try
            {
                std::filesystem::copy( "logs/frame.tmp", "logs/frame.ppm", std::filesystem::copy_options::overwrite_existing);
            }
            catch (std::filesystem::filesystem_error )
            {
                // std::cout << "logs/frame.tmp doesnt exist?" << std::endl;
            }

            if(max_frames > 0 && frame_num >= max_frames) return false;
        }
    }
    else if (!vblank)
    {
        // new frame
        frame_num++;
        active_frame = true;

        if (frame_num <= skip_frames)
        {
            std::cout << "Skipping frame " << frame_num << " ...";
        }
        else
        {
            // std::ostringstream fname;
            // fname << "logs/frame" << std::setfill('0') << std::setw(4) << frame_num-skip_frames << ".ppm";
            // fname << "logs/frame.tmp";
            // std::cout << "Recording frame " << frame_num << " of " << max_frames << " at " << fname.str() << " ... ";
            std::cout << "Recording frame " << frame_num << " of " << max_frames << " ... ";
            f.open("logs/frame.tmp", std::ios::binary);
            if(!f.is_open()) 
            {
                std::cout << "Failed to open file " << "logs/frame.tmp" << "  Aborting" << std::endl;
                return false;
            }
            f << "P6" << std::endl << w << " " << h << std::endl << 255 << std::endl;
        }            

    }
    return true;
}


int main(int argc, char** argv) {

    if (0 && argc && argv) {}

    int max_frames=0;
    int max_cycles=0;
    int skip_frames=32;
    for (int i=0; i<argc; i++)
    {
        if(strcmp(argv[i], "--max_frames") == 0)
        {
            max_frames = std::stoi(argv[++i]);
            std::cout << "Stopping after recording " << max_frames << " frames" << std::endl;
        }
        if(strcmp(argv[i], "--skip_frames") == 0)
        {
            skip_frames = std::stoi(argv[++i]);
            std::cout << "Skipping first " << skip_frames << " frames" << std::endl;
        }
        else if(strcmp(argv[i], "--max_cycles") == 0)
        {
            max_cycles = std::stoi(argv[++i]);
            std::cout << "Stopping after " << max_cycles << " ppu cycles" << std::endl;
        }
    }


    Verilated::debug(0);
    Verilated::randReset(2);
    Verilated::commandArgs(argc, argv);
    Verilated::mkdir("logs");

    Vnes_tb* top = new Vnes_tb;  // Or use a const unique_ptr, or the VL_UNIQUE_PTR wrapper

    Verilated::traceEverOn(true);
    VerilatedFstC* tfp = new VerilatedFstC;
    top->trace (tfp, 99);

    FrameRecorder framerec(max_frames, 0); //skip_frames);
    
    top->clk = 0;
    bool dumping = false;
    bool stillgoing = true;
    while (!Verilated::gotFinish() && stillgoing) {
        ++ppu_cycle;
        top->clk = !top->clk;
        top->rst = (ppu_cycle < 10) ? 1 : 0;
        // if (ppu_cycle < 5) {
        //     // Zero coverage if still early in reset, otherwise toggles there may
        //     // falsely indicate a signal is covered
        //     VerilatedCov::zero();
        // }
        top->eval();

        if(framerec.frame_num >= skip_frames)
        {
            if(!dumping) {
                dumping = true;
                tfp->open("logs/nes_tb.fst");
            }
            tfp->dump(Verilated::time());
        }

        if(top->clk && top->pixel_clk)
        {
            stillgoing = stillgoing && framerec.process(top->vblank, top->pixel_en, top->pixel);
            stillgoing = stillgoing && (max_cycles==0 || ppu_cycle<=max_cycles);
        }
    }

    top->final();
    tfp->close();

    //  Coverage analysis (since test passed)
#if VM_COVERAGE
    Verilated::mkdir("logs");
    VerilatedCov::write("logs/coverage.dat");
#endif

    delete top;
    top = NULL;
    exit(0);
}
