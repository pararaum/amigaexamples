#ifndef __OUTPUT_FUNCTORS_HH__
#define __OUTPUT_FUNCTORS_HH__

/* Basis class for all output functors.
 *
 * The basis class saves the filename and the output stream and does
 * nothing else.
 */
class OutputBasis {
protected:
  std::string inpfname; //!< input file name
  std::ostream &out; //!< output stream to write results to

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

  /*! \brief write an unsigned word
   *
   * Write an unsigned 16-bit word to the output in binary form.
   *
   * \param us 16-bit word
   */
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
protected:
  bool chip;
public:
  OutputBitplanesC(const std::string &ifn, std::ostream &out_, bool _chip)
    : OutputBitplanes_as_ASCII(ifn, out_), chip(_chip) {
  }
  ~OutputBitplanesC() {
    out << "};\n";
  }
  virtual void output_header(void) {
    out << "unsigned char " << (chip ? "__chip " : "/*__chip*/") << frobnicate_filename() << "[] = {\n";
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
  bool small_palette;
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
      if(!small_palette) {
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
  PaletteWriter(const std::string &ifn, std::ostream &out_, bool small_palette_) : OutputBasis(ifn, out_), small_palette(small_palette_) {
  }

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


#endif
