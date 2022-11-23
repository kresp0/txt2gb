#!/bin/bash
# Converts text into an image 
# usable on a GB Studio game
# as a background
# License: CC0
# Santiago Crespo - 2022

# Fonts:
# GBStudio-Stars https://github.com/gb-studio-dev/stars-font
# Ac437-CompaqThin-8x8 https://int10h.org/oldschool-pc-fonts/download/
# Mx437-ACM-VGA-8x8 https://int10h.org/oldschool-pc-fonts/download/

set -e

TMPDIR="/tmp/txt2gb"

TEXTFILE="${BASH_ARGV[0]}"
IMAGENAME=`echo $TEXTFILE | awk -F '.txt' '{print $1}'`
IMAGEFILE="$IMAGENAME.png"

if [ -z "$TEXTFILE" ] || [ -z "$IMAGEFILE" ]; then
    echo "Version: txt2gb v0.1
Author: Santiago Crespo    
License: CC0   

Usage: $0 [options ...] input.txt
Options: 
    -f font         Font: GBStudio-Stars (uppercase only), ACM-VGA(default) and CompaqThin
    -s px           Font size: 8 (default, 19 char/line), 16 (9 char/line) and 32 (4 char/line)
    -l lines        Line spacing: 0 or 1 (default)
    -h px           Maximum height for cutting the images. A multiple of 8 between 8 and 2040 (default)
    "
    exit 1
fi

FONT="ACM-VGA"
SIZE="8"
LINESPACING="1"
MAXHEIGHT="2040"

while getopts f:s:l:h: flag
do
    case "${flag}" in
        f) 
            FONT=${OPTARG}
            if ! [ "$FONT" = "ACM-VGA" ] && ! [ "$FONT" = "CompaqThin" ] &&  ! [ "$FONT" = "GBStudio-Stars" ] ; then
                echo "Error: font should be GBStudio-Stars, ACM-VGA or CompaqThin"
                exit 1
            fi
       ;;
        s) 
            SIZE=${OPTARG}
            if [ "$SIZE" -ne "8" ] && [ "$SIZE" -ne "16" ] && [ "$SIZE" -ne "32" ] ; then 
                echo "Error: Size should be 8, 16 or 32"
                exit 1
            fi
       ;;
        l) 
            LINESPACING=${OPTARG}
            if [ "$LINESPACING" -ne "0" ] && [ "$LINESPACING" -ne "1" ]; then 
                echo "Error: Line spacing should be 0 or 1"
                exit 1
            fi
       ;;
        h) 
            MAXHEIGHT=${OPTARG}
            if [ "$MAXHEIGHT" -gt "2040" ] || [ "$MAXHEIGHT" -lt "8" ] ||  [ $(( $MAXHEIGHT % 8 )) -ne 0 ]  ; then 
                echo "Error: Maximum height should be a multiple of 8 between 8 and 2040"
                exit 1
            fi            
       ;;
    esac
done

FILETYPE=`file $TEXTFILE`
if ! [[ "$FILETYPE" == *"text"* ]] || ! [[ "$TEXTFILE" == *"txt"* ]]; then
    echo "Error: $TEXTFILE don't seem to be a txt file"
    exit 1
fi

INITIALDIR="`pwd`"
rm -rf $TMPDIR
mkdir $TMPDIR

case "$FONT" in
    GBStudio-Stars)
        FONT="GBStudio-Stars"
    ;;
    ACM-VGA)
        FONT="Mx437-ACM-VGA-8x8"
    ;;
    CompaqThin)
        FONT="Ac437-CompaqThin-8x8"
    ;;
esac

case "$SIZE" in
    8)
        LINEWIDHT="19"
    ;;
    16)
        LINEWIDHT="9"
    ;;
    32)
        LINEWIDHT="4"
    ;;
esac  


case "$LINESPACING" in
    0)
        cat -s $TEXTFILE | fmt -w $LINEWIDHT | cat -s  > $TMPDIR/txt
    ;;
    1)
        cat -s $TEXTFILE | fmt -w $LINEWIDHT | cat -s | perl -pe 's/\n/\n\n/g'  > $TMPDIR/txt    
    ;;
    *)
        echo "Error: Line spacing should be 0 or 1"
        exit 1
    ;;
esac

if [ "$FONT" == "GBStudio-Stars" ] ; then # Workaround for this uppercase-only font
    tr [:lower:] [:upper:] < $TMPDIR/txt > $TMPDIR/TXT
    mv $TMPDIR/TXT $TMPDIR/txt
fi

cd $TMPDIR

COUNT="0"

echo "Generating lines..."
while IFS= read -r line
do
    let COUNT=COUNT+1

case "$SIZE" in
    8)
        echo "$line" | convert -size 160x$SIZE -append +antialias xc:"#e0f8cf" -font $FONT -pointsize $SIZE -fill "#071821" -annotate +8+7 "@-" $COUNT.png
    ;;
    16)
        if [ "$FONT" == "Ac437-CompaqThin-8x8" ] ; then # Workaround for this font at 16px
            echo "$line" | convert -size 160x$SIZE -append +antialias xc:"#e0f8cf" -font $FONT -pointsize $SIZE -fill "#071821" -annotate +10+15 "@-" $COUNT.png
        else
            echo "$line" | convert -size 160x$SIZE -append +antialias xc:"#e0f8cf" -font $FONT -pointsize $SIZE -fill "#071821" -annotate +8+15 "@-" $COUNT.png                    
        fi
    ;;
    32)
        echo "$line" | convert -size 160x$SIZE -append +antialias xc:"#e0f8cf" -font $FONT -pointsize $SIZE -fill "#071821" -annotate +8+30 "@-" $COUNT.png
    ;;
esac  

done < txt

echo "Concatenating lines..."
IMAGES=`ls -1 *.png | sort -V | perl -pe 's/\n/ /g'`
montage -mode concatenate -tile 1x $IMAGES image.png

IMGHEIGHT=`file image.png | awk -F ' x ' '{print $2}' | awk -F ',' '{print $1}'`
REMAININGHEIGHT=$IMGHEIGHT
if [ "$IMGHEIGHT" -gt "$MAXHEIGHT" ] ; then
    echo "Cuting the image..."
    CUTS=$((IMGHEIGHT / MAXHEIGHT))
    mkdir cuts
    cd cuts
    COUNT="0"
    let CUTS=CUTS+1
    while [ $CUTS -gt "0" ] ;
    do
        OFFSET=$((COUNT * MAXHEIGHT))
        if [ "$REMAININGHEIGHT" -lt "$MAXHEIGHT" ] ; then
            convert ../image.png -crop 160x$REMAININGHEIGHT+0+$OFFSET +repage $IMAGENAME-$COUNT.png && echo ok y bb
            echo "Several images generated:"
            cp *png "$INITIALDIR/"
            ls -1 "$INITIALDIR/$IMAGENAME"-*png
            exit 0
        else
            convert ../image.png -crop 160x$MAXHEIGHT+0+$OFFSET +repage $IMAGENAME-$COUNT.png
            let REMAININGHEIGHT=REMAININGHEIGHT-MAXHEIGHT
            let COUNT=COUNT+1
        fi
        let CUTS=CUTS-1     
    done
fi

echo "Image generated:"
cp image.png "$INITIALDIR/$IMAGEFILE"
ls -1 "$INITIALDIR/$IMAGEFILE"

exit 0
