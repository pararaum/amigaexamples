#include <cstdio>
#include <cassert>
#include <iostream>
#include <vector>
#include <algorithm>
#include <iterator>
#include <fstream>
#include <sstream>
#include <boost/format.hpp>
#include <SDL2/SDL.h>
#include <SDL2/SDL_image.h>
#include "cli_parser.h"
#include "output_functors.hh"

typedef std::vector<std::vector<bool>> BitplaneVector;

enum Return_Values_for_CLI {
  CLIRET_parsing_failed = 1,
  CLIRET_not_enough_files = 2,
  CLIRET_io_error = 3,
  CLIRET_exception = 64
};
gengetopt_args_info args;


/*! convert chunky to planar
 *
 * \param width number of bytes in a row
 * \param height height of picture aka number of rows
 * \param pixels pointer to pixels in chunky format
 * \return eight bitplanes (vectors of bits)
 */
BitplaneVector convert_c2p(int width, int height, unsigned char *pixels) {
  int row, column;
  unsigned int val;
  int bit;
  BitplaneVector result(8);
  
  for(row = 0; row < height; ++row) {
    for(column = 0; column < width; ++column) {
      val = pixels[column + width * row];
      for(bit = 0; bit < 8; ++bit) {
	if(val & (1 << bit)) {
	  result[bit].push_back(true);
	} else {
	  result[bit].push_back(false);
	}
      }
    }
  }
  return result;
}


/* \brief Convert bitplane to raw binary
 *
 * Convert bitplane data (a vector of booleans) to raw binary
 * octets. This function is very simple and will just take eight
 * boolean values and convert them into a octet. A vector of octets is
 * returned.
 *
 * @param bitplane bitplane vector
 * @return vector of octets
 */
std::vector<unsigned char> bitplane2bin(const std::vector<bool> &bitplane) {
  std::vector<unsigned char> raw;
  unsigned char bin;

  if((bitplane.size() & 0x7) != 0) {
    throw std::invalid_argument("bitplane size is not divisible by eight");
  }
  for(unsigned long i = 0; i < bitplane.size(); i += 8) {
    bin = 0;
    if(bitplane[i + 0]) bin |= 0x80;
    if(bitplane[i + 1]) bin |= 0x40;
    if(bitplane[i + 2]) bin |= 0x20;
    if(bitplane[i + 3]) bin |= 0x10;
    if(bitplane[i + 4]) bin |= 0x08;
    if(bitplane[i + 5]) bin |= 0x04;
    if(bitplane[i + 6]) bin |= 0x02;
    if(bitplane[i + 7]) bin |= 0x01;
    raw.push_back(bin);
  }
  return raw;
}


std::vector<std::vector<unsigned char>> bitplanes2bins(const BitplaneVector &bitplanes) {
  std::vector<std::vector<unsigned char>> bins(bitplanes.size());

  std::transform(bitplanes.begin(), bitplanes.end(), bins.begin(), bitplane2bin);
  return bins;
}


SDL_Surface *handle_file(std::ostream &outstr, const char *fname) {
  SDL_Surface *surf = IMG_Load(fname);

  if(!surf) {
    throw std::runtime_error(IMG_GetError());
  }
  const std::string outformat(args.output_format_arg);
  // http://wiki.libsdl.org/SDL_PixelFormat
  SDL_PixelFormat *format = surf->format;
  SDL_Palette *palette = format->palette;
  if(format->BitsPerPixel != 8) {
    std::cerr << "Not 8 BPP!\n";
  } else if(palette == NULL) {
    std::cerr << "No palette!\n";
  } else {
    BitplaneVector bplvec(convert_c2p(surf->w, surf->h, static_cast<unsigned char*>(surf->pixels)));
    if(args.bitplane_number_arg < 8) {
      bplvec.resize(args.bitplane_number_arg);
    }
    if(!(args.header_flag || args.palette_flag || args.bitplanes_flag)) {
      std::cerr << "File: " << fname << '\n'
		<< "\tFormat: " << format->format << '\n'
		<< "\tBitPerPixel: " << (int)format->BitsPerPixel << '\n'
		<< "\tncolors: " << palette->ncolors << '\n'
	;
      for(int i = 0; i < palette->ncolors; ++i) {
	SDL_Color &cref(palette->colors[i]);
	std::cerr << boost::format("\t\t$%02X%02X%02X\n") % (int)cref.r % (int)cref.g % (int)cref.b;
      }
    } else {
      if(args.header_flag) {
	HeaderWriter *headerwriter = NULL;
	if((outformat == "bin") || (outformat == "raw")) {
	  headerwriter = new HeaderWriterBin(fname, outstr);
	} else if(outformat == "asm") {
	  headerwriter = new HeaderWriterASM(fname, outstr);
	} else if(outformat == "c") {
	  headerwriter = new HeaderWriterC(fname, outstr);
	} else {
	  throw std::invalid_argument("header, unknown format: " + outformat);
	}
	(*headerwriter)(surf->w, surf->h, args.bitplane_number_arg);
	delete headerwriter;
      }
      if(args.palette_flag) {
	PaletteWriter *palettewriter = NULL;
	if((outformat == "bin") || (outformat == "raw")) {
	  palettewriter = new PaletteWriterBin(fname, outstr, args.small_palette_flag);
	} else if(outformat == "asm") {
	  palettewriter = new PaletteWriterASM(fname, outstr, args.small_palette_flag);
	} else if(outformat == "c") {
	  palettewriter = new PaletteWriterC(fname, outstr, args.small_palette_flag);
	} else {
	  throw std::invalid_argument("palette, unknown format: " + outformat);
	}
	(*palettewriter)(palette, args.bitplane_number_arg);
	delete palettewriter;
      }
      if(args.bitplanes_flag) {
	OutputBitplanes *obfunctor;
	std::vector<std::vector<unsigned char>> raws(bitplanes2bins(bplvec));
	if((outformat == "bin") || (outformat == "raw")) {
	  obfunctor = new OutputBitplanes(fname, outstr);
	} else if(outformat == "c") {
	  obfunctor = new OutputBitplanesC(fname, outstr, args.bitplane_chip_flag);
	} else if(outformat == "asm") {
	  obfunctor = new OutputBitplanesASM(fname, outstr);
	} else {
	  throw std::invalid_argument("unknown format: " + outformat);
	}
	(*obfunctor)(args.interleave_flag, surf->w, surf->h, raws);
	delete obfunctor;
      }
    }
  }
  return surf;
}


/** Create an 8-bit grayscale surface from a bitplane (vector of bools).
 *  true  → white (255)
 *  false → black (0)
 */
SDL_Surface *bitplane_to_surface(int width, int height,
                                 const std::vector<bool> &bitplane)
{
  if (static_cast<int>(bitplane.size()) != width * height) {
    throw std::invalid_argument("bitplane size does not match width*height");
  }

  SDL_Surface *s = SDL_CreateRGBSurfaceWithFormat(0, width, height, 8,
                                                  SDL_PIXELFORMAT_INDEX8);
  if (!s) throw std::runtime_error(SDL_GetError());

  // Simple black/white palette
  SDL_Color colors[2] = {
    {0, 0, 0, 255},       // 0 = black
    {255, 255, 255, 255}  // 1 = white
  };
  SDL_SetPaletteColors(s->format->palette, colors, 0, 2);

  Uint8 *pixels = static_cast<Uint8*>(s->pixels);
  for (int i = 0; i < width * height; ++i) {
    pixels[i] = bitplane[i] ? 1 : 0;
  }
  return s;
}


/** Display original image + eight bitplanes arranged counterclockwise
 *  around it.  Bitplane 0 is immediately to the right of the original.
 *  ESC or closing the window ends the display.
 */
void display_bitplanes(SDL_Surface *orig, const BitplaneVector &bpls)
{
  if (bpls.size() != 8) {
    throw std::invalid_argument("exactly eight bitplanes expected");
  }

  const int w = orig->w;
  const int h = orig->h;
  const int W = 3 * w;          // total window size
  const int H = 3 * h;

  // Create the eight bitplane surfaces
  SDL_Surface *bpsurf[8];
  for (int i = 0; i < 8; ++i) {
    bpsurf[i] = bitplane_to_surface(w, h, bpls[i]);
  }

  // Big surface that holds the 3×3 arrangement
  SDL_Surface *canvas = SDL_CreateRGBSurfaceWithFormat(
      0, W, H, 32, SDL_PIXELFORMAT_RGBA32);
  if (!canvas) throw std::runtime_error(SDL_GetError());

  // Fill background (dark grey)
  SDL_FillRect(canvas, nullptr, SDL_MapRGB(canvas->format, 40, 40, 40));

  // Layout positions (row-major in the 3×3 grid)
  //
  //   0 1 2
  //   3 4 5
  //   6 7 8
  //
  // Center (4) = original image
  // Bitplane 0 → right of center (pos 5)
  // then counterclockwise:
  //   1 → top-right (2)
  //   2 → top       (1)
  //   3 → top-left  (0)
  //   4 → left      (3)
  //   5 → bot-left  (6)
  //   6 → bottom    (7)
  //   7 → bot-right (8)

  const int pos_x[9] = {0, w, 2*w, 0, w, 2*w, 0, w, 2*w};
  const int pos_y[9] = {0, 0, 0,   h, h, h,   2*h, 2*h, 2*h};

  // Blit original into the centre
  SDL_Rect dst = { pos_x[4], pos_y[4], w, h };
  SDL_BlitSurface(orig, nullptr, canvas, &dst);

  // Counter-clockwise mapping: bitplane index → grid position
  const int bp_to_pos[8] = { 5, 2, 1, 0, 3, 6, 7, 8 };

  for (int i = 0; i < 8; ++i) {
    dst.x = pos_x[bp_to_pos[i]];
    dst.y = pos_y[bp_to_pos[i]];
    SDL_BlitSurface(bpsurf[i], nullptr, canvas, &dst);
  }

  // ---- SDL window / event loop ----
  if (SDL_InitSubSystem(SDL_INIT_VIDEO) != 0) {
    throw std::runtime_error(SDL_GetError());
  }

  SDL_Window *win = SDL_CreateWindow(
      "Original + Bitplanes (ESC to quit)",
      SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
      W, H, SDL_WINDOW_SHOWN);
  if (!win) throw std::runtime_error(SDL_GetError());

  SDL_Surface *winsurf = SDL_GetWindowSurface(win);
  SDL_BlitSurface(canvas, nullptr, winsurf, nullptr);
  SDL_UpdateWindowSurface(win);

  SDL_Event e;
  while (SDL_WaitEvent(&e)) {
    if (e.type == SDL_QUIT ||
	(e.type == SDL_KEYDOWN && e.key.keysym.sym == SDLK_ESCAPE) ||
	(e.type == SDL_KEYDOWN && e.key.keysym.sym == SDLK_q) ) {
      break;
    }
  }

  // Cleanup
  SDL_DestroyWindow(win);
  SDL_FreeSurface(canvas);
  for (int i = 0; i < 8; ++i) SDL_FreeSurface(bpsurf[i]);
  SDL_QuitSubSystem(SDL_INIT_VIDEO);
}


int main(int argc, char **argv) {
  if(cmdline_parser(argc, argv, &args) != 0) {
    return CLIRET_parsing_failed;
  } else if(args.inputs_num == 0) {
    cmdline_parser_print_help();
    return CLIRET_not_enough_files;
  }
  try {
    std::stringstream out; // Here we store the output temporarily.
    if(SDL_Init(0) != 0) {
      SDL_Log("Intitialisation failed: %s", SDL_GetError());
      throw std::runtime_error(SDL_GetError());
    }
    atexit(SDL_Quit);
    SDL_Surface *surf = handle_file(out, args.inputs[0]);
    out << std::flush;
    if(args.output_given) {
      std::ofstream ofile(args.output_arg);
      if(!ofile) {
	std::cerr << "Error opening file: " << args.output_arg << std::endl;
	return CLIRET_io_error;
      }
      ofile << out.rdbuf();
    } else {
      std::cout << out.rdbuf();
    }
    if (args.display_flag) {
      // We have to reload as handle_file() culls unused bitplanes,
      // therefore it is made sure that always all 8 planes are
      // available for the display.
      BitplaneVector full = convert_c2p(surf->w, surf->h,
                                        static_cast<unsigned char*>(surf->pixels));
      display_bitplanes(surf, full);
    }
    if(surf) {
      SDL_FreeSurface(surf);
    }
  }
  catch(const std::exception &excp) {
    std::cerr << "Error: " << excp.what() << std::endl;
    return CLIRET_exception;
  }
  return 0;
}
 
