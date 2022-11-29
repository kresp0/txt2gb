# txt2gb
A script to generate background images with text and text.png fonts for GB Studio

## Features
* Support for any compatible TTF font (unicode looking good at 8x8)
* Accepts text of any lenght
* Generate a font.png file for its use in GBS
* 3 different font sizes: 8, 16 and 32 px
* Optional line spacing
* Options to adjust left and top padding, interword spacing and kerning.
* Customizable maximum height for the images
* Automatically splits lines that are too long
* Automatically splits images that are too long

## Usage

Usage: ./txt2gb.sh [options ...] input.txt

Options: 

Usage: 

./txt2gb (0.2).sh [OPTIONS ...] input.txt

./txt2gb (0.2).sh [OPTIONS ...] -g -f font

Text settings: 

    -f font         Font name to render text. Known working fonts are: ACM-VGA (default), CompaqThin, GBStudio-Stars (uppercase only) and Public-Pixel
    
    -s px           Font Size: 8 (default, 19 char/line), 16 (9 char/line) and 32 (4 char/line)
    
    -l lines        Leading (line spacing): 0 or 1 (default)
    
    -p px           Padding to the left. Between 0 and 152. Usually a multiple of 8. Default: 8
    

Advanced text settings:

    -w char     Line Width in number of char: 1 to 20. It won't cut words. Defaults depending on size: 19, 9, 4
    
    -t px           Padding to the Top of each line. Between 1 and 64. Defaults depending on size: 7, 15, 30
    
    -i px           Interword spacing. Between -5 and 64. Default: 0
    
    -k px           Kerning:  add or remove spacing between each letter. Between -5 and 5. Default: 0
    
    
Image settings:

    -c px           Maximum height for cutting the images. A multiple of 8 between 8 and 2040 (default)   
    
    -a px           Image width. A multiple of 8 between 8 and 2040. Default: 160.
    

GBS Font generation:

    -g font         Generate a font.png to use in GBStudio from a font. A font name is required.
    


## Fonts for GB Studio
The [ACM-VGA and CompaqThin fonts for GB Studio](https://github.com/kresp0/compaqthin-and-acm-vga-fonts) are also available, so you can use it for the dialogs and elsewhere.

## Sample text 8px

### ACM-VGA
![ACM-VGA](/samples/ACM-VGA-s8-l1.png)
![ACM-VGA](/samples/ACM-VGA-s8-l0.png)

### CompaqThin
![CompaqThin](/samples/CompaqThin-s8-l1.png)
![CompaqThin](/samples/CompaqThin-s8-l0.png)

### GBStudio-Stars
![GBStudio-Stars](/samples/GBStudio-Stars-s8-l1.png)
![GBStudio-Stars](/samples/GBStudio-Stars-s8-l0.png)


## Sample text 16px

### ACM-VGA
![ACM-VGA](/samples/ACM-VGA-s16-l1.png)
![ACM-VGA](/samples/ACM-VGA-s16-l0.png)

### CompaqThin
![CompaqThin](/samples/CompaqThin-s16-l1.png)
![CompaqThin](/samples/CompaqThin-s16-l0.png)

### GBStudio-Stars
![GBStudio-Stars](/samples/GBStudio-Stars-s16-l1.png)
![GBStudio-Stars](/samples/GBStudio-Stars-s16-l0.png)


## Sample text 32px

### ACM-VGA
![ACM-VGA](/samples/ACM-VGA-s32-l0.png)

### CompaqThin
![CompaqThin](/samples/CompaqThin-s32-l0.png)

### GBStudio-Stars
![GBStudio-Stars](/samples/GBStudio-Stars-s32-l0.png)

