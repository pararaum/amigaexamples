
How to transform font images
============================


Divide
------

See:

 * http://www.imagemagick.org/Usage/crop/
 * http://www.imagemagick.org/Usage/crop/#crop_tile

Subdivide into eight times eight tiles: `convert 37148_sim1_font11_long_\(no_shadow\)_blue_-final.png +gravity -crop 8x8 tiles_%02x.png`.
Subdivide if number of tiles is known: `convert 37147_terminal_fonts_03.xpm -crop 80x1@ +repage +adjoin chars_%02x.png`.

Montage
-------

 * http://www.imagemagick.org/Usage/montage/

Montage all image into a large one without space and try to guess the final size: `montage tiles_* -geometry +0+0 /tmp/all.png`.
Use the tile operator to specify the tiling, here a single column: `montage tile.* -tile 1x -geometry +0+0 full.xpm`.
And a single row: `montage tile.* -tile x1 -geometry +0+0 full.xpm`.

Traps
-----

The XBM file format stores the first pixel in the LSB! This will
effectively mirror each character if copied vanilla into the graphics
hardware.
