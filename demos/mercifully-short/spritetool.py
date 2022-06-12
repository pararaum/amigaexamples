#! /usr/bin/env python3

import argparse
import PIL.Image

BORDERCOLOUR = 240

def find_border(img, x, y):
    try:
        right = img.getpixel((x + 1, y)) == BORDERCOLOUR
        down = img.getpixel((x, y + 1)) == BORDERCOLOUR
        diag = img.getpixel((x + 1, y + 1)) != BORDERCOLOUR
        if right and down and diag:
            # Top left border found.
            height = 2
            while img.getpixel((x, y + height)) == BORDERCOLOUR:
                height += 1
            width = 2
            while img.getpixel((x + width, y)) == BORDERCOLOUR:
                width += 1
            return (x + 1, y + 1, x + width - 1, y + height - 1)
    except IndexError:
        pass

def find_borders(img):
    borders = []
    for pxidx in (i for i, c in enumerate(img.tobytes()) if c == BORDERCOLOUR):
        y = pxidx // img.width
        x = pxidx % img.width
        #print(x, y, pxidx, find_border(img, x, y))
        border = find_border(img, x, y)
        if border:
            borders.append(border)
            img.crop(border).save("croppedsprite.%d.%d.png" % (border[0], border[1]))
    return borders

def main():
    parser = argparse.ArgumentParser(description='Amiga Sprite Tool.')
    parser.add_argument("spritesheet", help="name of the spritesheet file")
    args = parser.parse_args()
    img = PIL.Image.open(args.spritesheet)
    print(find_borders(img))

if __name__ == "__main__":
    main()
