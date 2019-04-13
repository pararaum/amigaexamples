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


/* Basis class for all output functors.
 *
 * The basis class saves the filename and the output stream and does
 * nothing else.
 */
class OutputBasis {
protected:
  std::string inpfname; //!< input file name
  std::ostream &out;

  /*\brief Make filename compatible with programming languages
   *
   *In the filename only alphanumeric characters are left, all other
   *characters are replaced by an underscore. If the string begins
   *with a number it is prepended with an underscore, too.
   *
   *@return frobnicated filename string
   */
  std::string frobnicate_filename(void) {
    std::string fname(inpfname);
    
    for(auto &x : fname) { if(!isalnum(x)) x = '_'; }
    if(isdigit(fname[0])) fname = '_' + fname;
    return fname;
  }
public:
  /*Constructor
   *
   *The stored filename has the path component removed.
   */
  OutputBasis(const std::string &ifn, std::ostream &out_)
    : inpfname(ifn), out(out_) {
    if(inpfname.rfind('/') != std::string::npos) {
      inpfname = inpfname.substr(inpfname.rfind('/') + 1);
    }
  }
  virtual ~OutputBasis() {}

  void write_uword(unsigned short us) {
    out << static_cast<unsigned char>(us >> 8)
	<< static_cast<unsigned char>(us & 0x00FF);
  }
};


/*!\brief Class for writing the bitplane data.
 *
 * This class defines a framework for writing the bitplane
 * data. Overwrite the functions to get a different output format.
 */
class OutputBitplanes : public OutputBasis {
public:
  OutputBitplanes(const std::string &ifn, std::ostream &out_) : OutputBasis(ifn, out_) {}

  virtual void output_header(void) {
  }
  virtual void output_footer(void) {
  }
  virtual void operator()(bool ilvd, unsigned int width, unsigned int height, const std::vector<std::vector<unsigned char>> &rbpls) {
    output_header();
    output_raw_bitplanes(ilvd, width / 8, height, rbpls);
    output_footer();
  }
  virtual void output_row_header(void) {}
  virtual void output_char_separator(void) {}
  virtual void output_row_separator(void) {}
  virtual void outc(unsigned char ch) {
    out << ch;
  }
  /*! \brief Output bitplanes in binary form.
   *
   * This function will output the given bitplanes in raw binary form.
   *
   * @param ilvd write bitplans interleaved?
   * @param byplin bytes per line
   * @param height number of lines
   * @param rbpls raw bitplanes to be written
   */
  virtual void output_raw_bitplanes(bool ilvd, unsigned int byplin, unsigned int height, const std::vector<std::vector<unsigned char>> &rbpls) {
    if(ilvd) {
      assert(rbpls[0].size() == byplin * height);
      for(unsigned int row = 0; row < height; ++row) {
	for(unsigned int plane = 0; plane < rbpls.size(); ++plane) {
	  output_row_header();
	  outc(rbpls[plane].at(0 + byplin * row));
	  for(unsigned int col = 1; col < byplin; ++col) {
	    output_char_separator();
	    outc(rbpls[plane].at(col + byplin * row));
	  }
	  output_row_separator();
	}
      }
      // std::vector<std::vector<unsigned char>::const_iterator> iters(rbpls.size());
      // std::transform(rbpls.begin(), rbpls.end(), iters.begin(),
      // 	     [](const std::vector<unsigned char> &x) { return x.begin(); }
      // 	     );
      // for(unsigned line = 0; line < rbpls[0].size() / byplin; ++line) {
      //   for(unsigned bplno = 0; bplno < rbpls.size(); ++bplno) {
      // 	for(auto &raw : iters) {
      // 	  std::copy(raw, raw + byplin, std::ostream_iterator<unsigned char>(out));
      // 	  raw += byplin;
      // 	}
      //   }
      // }
    } else {
      // for(auto &raw : rbpls) {
      // 	std::copy(raw.begin(), raw.end(), std::ostream_iterator<unsigned char>(out));
      // }
      for(unsigned int plane = 0; plane < rbpls.size(); ++plane) {
	for(unsigned int row = 0; row < height; ++row) {
	  output_row_header();
	  outc(rbpls[plane].at(0 + byplin * row));
	  for(unsigned int col = 1; col < byplin; ++col) {
	    output_char_separator();
	    outc(rbpls[plane].at(col + byplin * row));
	  }
	  output_row_separator();
	}
      }
    }
  }
};


class OutputBitplanes_as_ASCII : public OutputBitplanes {
public:
  using OutputBitplanes::OutputBitplanes;
};


class OutputBitplanesASM : public OutputBitplanes_as_ASCII {
public:
  OutputBitplanesASM(const std::string &ifn, std::ostream &out_)
    : OutputBitplanes_as_ASCII(ifn, out_) {
  }
  virtual void output_header(void) {
    out << frobnicate_filename() << ":\n";
  }
  virtual void output_row_header(void) {
    out << "\tDC.B\t";
  }
  virtual void output_row_separator(void) {
    out << '\n';
  }
  virtual void output_char_separator(void) {
    out << ", ";
  }
  virtual void outc(unsigned char ch) {
    char buf[9];

    sprintf(buf, "$%02x", (unsigned int)ch);
    out << buf;
  }
};


class OutputBitplanesC : public OutputBitplanes_as_ASCII {
public:
  OutputBitplanesC(const std::string &ifn, std::ostream &out_)
    : OutputBitplanes_as_ASCII(ifn, out_) {
  }
  ~OutputBitplanesC() {
    out << "};\n";
  }
  virtual void output_header(void) {
    out << "unsigned char " << (args.bitplane_chip_flag ? "__chip " : "/*__chip*/") << frobnicate_filename() << "[] = {\n";
  }
  virtual void output_row_header(void) {
    out << '\t';
  }
  virtual void output_row_separator(void) {
    out << ",\n";
  }
  virtual void output_char_separator(void) {
    out << ", ";
  }
  virtual void outc(unsigned char ch) {
    char buf[9];

    sprintf(buf, "0x%02x", (unsigned int)ch);
    out << buf;
  }
};


/*! \brief Image Header Writer Class
 *
 * This class will write the image header in the appropriate format.
 */
class HeaderWriter : public OutputBasis {
public:
  using OutputBasis::OutputBasis;

  /*! \brief Write the header
   *
   *The palette is written to the output but the number of bitplanes
   *will specify the maximum number of colours written (2^bitpl).
   *
   *@param palette pointer to an SDL_Palette
   *@param bitpl number of bitplanes
   */
  virtual void operator()(unsigned short __attribute__((unused))width, unsigned short __attribute__((unused)) height, unsigned short __attribute__((unused)) no_bitplanes) = 0;
};


/*!\brief Write binary header
 *
 * This writes a very simple binary header of 16 bytes, consisting of:
 *
 *  - Width (UWORD)
 *  - Height (UWORD)
 *  - Bitplanes (UWORD)
 *
 * Remaining words are set to zero.
 */
class HeaderWriterBin : public HeaderWriter {
public:
  using HeaderWriter::HeaderWriter;

  virtual void operator()(unsigned short width, unsigned short height, unsigned short no_bitplanes) {
    int i;

    write_uword(width);
    write_uword(height);
    write_uword(no_bitplanes);
    write_uword(0);
    for(i = 0; i < 4; ++i) {
      write_uword(0);
    }
#if 0
    out << "P4\n";
    out << "# bitplanes=" << no_bitplanes << '\n';
    out << width << ' ';
    out << height * no_bitplanes;
    out << std::endl;
#endif
  }
};


class HeaderWriterASM : public HeaderWriter {
public:
  using HeaderWriter::HeaderWriter;

  virtual void operator()(unsigned short width, unsigned short height, unsigned short no_bitplanes) {
    std::string fname(frobnicate_filename());

    out << "\t; Filename '" << inpfname << "'\n";
    out << fname + "_width\tEQU\t" << width << std::endl;
    out << fname + "_height\tEQU\t" << height << std::endl;
    out << fname + "_bitplanes\tEQU\t" << no_bitplanes << std::endl;
    out << "\tXDEF\t" << fname << std::endl;
    out << "\tXDEF\t" << fname + "_width\n";
    out << "\tXDEF\t" << fname + "_height\n";
    out << "\tXDEF\t" << fname + "_bitplanes\n";
  }
};


class HeaderWriterC : public HeaderWriter {
public:
  using HeaderWriter::HeaderWriter;

  virtual void operator()(unsigned short width, unsigned short height, unsigned short no_bitplanes) {
    std::string fname(frobnicate_filename());

    out << "\t/* Filename '" << inpfname << "' */\n";
    out << "#define " << fname + "_width\t" << width << "\n";
    out << "#define " << fname + "_height\t" << height << "\n";
    out << "#define " << fname + "_bitplanes\t" << no_bitplanes << "\n";
  }
};


class PaletteWriter : public OutputBasis {
protected:
  /*Calculate number of colours for palette
   *
   *The number of colours is 2^bitpl at most. If there are not enough
   *colors in the palette this is considered an error.
   *
   *@param palette pointer to an SDL_Palette
   *@param bitpl number of bitplanes
   *@return number of colours to use
   */
  int num_colors(const SDL_Palette *palette, int bitpl) const {
    assert(palette->ncolors > 0);
    assert(bitpl > 0);
    // How many colours do we need?
    bitpl = 1 << bitpl;
    if(bitpl > palette->ncolors) {
      if(!args.small_palette_flag) {
	throw std::invalid_argument("not enough colours for bitplanes");
      } else {
	bitpl = palette->ncolors;
      }
    }
    return bitpl;
  }
  /*Get the i-th colour from the palette
   *
   *The value is in the Amiga format as $0RGB, an 16-bit word.
   *
   *@param palette pointer to a SDL_Palette
   *@param i get the i-th colour
   *@return colour value as 16-bit word
   */
  unsigned short amiga_colour(const SDL_Palette *palette, int i) {
    unsigned short r, g, b, col;

    /* We only have four bit per colour value. */
    r = palette->colors[i].r >> 4;
    g = palette->colors[i].g >> 4;
    b = palette->colors[i].b >> 4;
    col = r << 8;
    col |= g << 4;
    col |= b;
    return col;
  }
public:
  using OutputBasis::OutputBasis;

  /*Write the palette
   *
   *The palette is written to the output but the number of bitplanes
   *will specify the maximum number of colours written (2^bitpl).
   *
   *@param palette pointer to an SDL_Palette
   *@param bitpl number of bitplanes
   */
  virtual void operator()(const SDL_Palette *palette, int bitpl) = 0;
};



/*Write the palette in binary format.
 *
 *The palette is written in the Amiga format, as $0RGB.
 */
class PaletteWriterBin : public PaletteWriter {
public:
  using PaletteWriter::PaletteWriter;

  virtual void operator()(const SDL_Palette *palette, int bitpl) {
    for(int i = 0; i < num_colors(palette, bitpl); ++i) {
      unsigned short col = amiga_colour(palette, i);

      write_uword(col);
    }
  }
};


/*Write the palette in ASM format.
 *
 *The palette is written in the Amiga format, as $0RGB.
 */
class PaletteWriterASM : public PaletteWriter {
public:
  using PaletteWriter::PaletteWriter;

  virtual void operator()(const SDL_Palette *palette, int bitpl) {
    out << frobnicate_filename() << "_palette:\n";
    for(int i = 0; i < num_colors(palette, bitpl); ++i) {
      unsigned short col = amiga_colour(palette, i);

      out << boost::format("\tDC.W\t$%04x\n") % col;
    }
  }
};


/*Write the palette in C format.
 *
 *The palette is written in the Amiga format, as $0RGB.
 */
class PaletteWriterC : public PaletteWriter {
public:
  using PaletteWriter::PaletteWriter;

  virtual void operator()(const SDL_Palette *palette, int bitpl) {
    out << "unsigned short " << frobnicate_filename() << "_palette[] = {\n";
    for(int i = 0; i < num_colors(palette, bitpl); ++i) {
      unsigned short col = amiga_colour(palette, i);

      out << boost::format("\t0x%04x,\n") % col;
    }
    out << "};\n";
  }
};


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
      if(outformat == "bin") {
	palettewriter = new PaletteWriterBin(fname, std::cout);
      } else if(outformat == "asm") {
	palettewriter = new PaletteWriterASM(fname, std::cout);
      } else if(outformat == "c") {
	palettewriter = new PaletteWriterC(fname, std::cout);
      } else {
	throw std::invalid_argument("palette, unknown format: " + outformat);
      }
      (*palettewriter)(palette, args.bitplane_number_arg);
      delete palettewriter;
    }
    if(args.bitplanes_flag) {
      OutputBitplanes *obfunctor;
      std::vector<std::vector<unsigned char>> raws(bitplanes2bins(bplvec));
      if(outformat == "bin") {
	obfunctor = new OutputBitplanes(fname, std::cout);
      } else if(outformat == "c") {
	obfunctor = new OutputBitplanesC(fname, std::cout);
      } else if(outformat == "asm") {
	obfunctor = new OutputBitplanesASM(fname, std::cout);
      } else {
	throw std::invalid_argument("unknown format: " + outformat);
      }
      (*obfunctor)(args.interleave_flag, surf->w, surf->h, raws);
      delete obfunctor;
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
    if(SDL_Init(SDL_INIT_VIDEO) != 0) {
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
 
