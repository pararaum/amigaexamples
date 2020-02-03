#include <cstdio>
#include <cassert>
#include <iostream>
#include <vector>
#include <algorithm>
#include <iterator>
#include <boost/format.hpp>
#include <SDL2/SDL.h>
#include <SDL2/SDL_image.h>
#include "cli_parser.h"
#include "output_functors.hh"

typedef std::vector<std::vector<bool>> BitplaneVector;

enum Return_Values_for_CLI {
  CLIRET_parsing_failed = 1,
  CLIRET_not_enough_files = 2,
  CLIRET_exception = 64
};
gengetopt_args_info args;

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


void handle_file(const char *fname) {
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
	  headerwriter = new HeaderWriterBin(fname, std::cout);
	} else if(outformat == "asm") {
	  headerwriter = new HeaderWriterASM(fname, std::cout);
	} else if(outformat == "c") {
	  headerwriter = new HeaderWriterC(fname, std::cout);
	} else {
	  throw std::invalid_argument("header, unknown format: " + outformat);
	}
	(*headerwriter)(surf->w, surf->h, args.bitplane_number_arg);
	delete headerwriter;
      }
      if(args.palette_flag) {
	PaletteWriter *palettewriter = NULL;
	if((outformat == "bin") || (outformat == "raw")) {
	  palettewriter = new PaletteWriterBin(fname, std::cout, args.small_palette_flag);
	} else if(outformat == "asm") {
	  palettewriter = new PaletteWriterASM(fname, std::cout, args.small_palette_flag);
	} else if(outformat == "c") {
	  palettewriter = new PaletteWriterC(fname, std::cout, args.small_palette_flag);
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
	  obfunctor = new OutputBitplanes(fname, std::cout);
	} else if(outformat == "c") {
	  obfunctor = new OutputBitplanesC(fname, std::cout, args.bitplane_chip_flag);
	} else if(outformat == "asm") {
	  obfunctor = new OutputBitplanesASM(fname, std::cout);
	} else {
	  throw std::invalid_argument("unknown format: " + outformat);
	}
	(*obfunctor)(args.interleave_flag, surf->w, surf->h, raws);
	delete obfunctor;
      }
    }
  }
  SDL_FreeSurface(surf);
}

int main(int argc, char **argv) {
  if(cmdline_parser(argc, argv, &args) != 0) {
    return CLIRET_parsing_failed;
  } else if(args.inputs_num == 0) {
    cmdline_parser_print_help();
    return CLIRET_not_enough_files;
  }
  try {
    if(SDL_Init(0) != 0) {
      SDL_Log("Intitialisation failed: %s", SDL_GetError());
      throw std::runtime_error(SDL_GetError());
    }
    handle_file(args.inputs[0]);
    atexit(SDL_Quit);
  }
  catch(const std::exception &excp) {
    std::cerr << "Error: " << excp.what() << std::endl;
    return CLIRET_exception;
  }
  return 0;
}
 
