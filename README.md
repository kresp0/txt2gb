# txt2gb
A script to generate background images with text for GB Studio

## Features
* 3 different fonts supported: ACM-VGA, CompaqThin and GBStudio-Stars
* 3 different font sizes: 8, 16 and 32 px
* Optional line spacing
* Customizable maximum heigh for the images
* Automatically splits lines too long
* Automatically splits images too long

## Usage
Usage: ./txt2gb.sh [options ...] input.txt
Options: 
    -f font         Font: GBStudio-Stars (uppercase only), ACM-VGA(default) and CompaqThin
    -s px           Font size: 8 (default, 19 char/line), 16 (9 char/line) and 32 (4 char/line)
    -l lines        Line spacing: 0 or 1 (default)
    -h px           Maximum height for cutting the images. A multiple of 8 between 8 and 2040 (default)
