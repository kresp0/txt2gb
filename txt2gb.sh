#!/bin/bash
# Converts text into an image 
# usable on a GB Studio game
# as a background
# License: CC0
# Santiago Crespo - 2022

# Count unique tiles: https://gb-studio-tile-count.glitch.me/

# Fonts:
# GBStudio-Stars https://github.com/gb-studio-dev/stars-font
# Ac437-CompaqThin-8x8 https://int10h.org/oldschool-pc-fonts/download/
# Mx437-ACM-VGA-8x8 https://int10h.org/oldschool-pc-fonts/download/
# Public-Pixel https://www.ggbot.net/fonts/

set -e

KNOWN_WORKING_FONTS="ACM-VGA (default), CompaqThin, GBStudio-Stars (uppercase only) and Public-Pixel"

usage() { 
    echo "
Version: txt2gb v0.2
Author: Santiago Crespo    
License: CC0   

Usage: 
$0 [OPTIONS ...] input.txt
$0 [OPTIONS ...] -g -f font

Text settings: 
    -f font         Font name to render text. Known working fonts are: $KNOWN_WORKING_FONTS
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
    "
    exit 1
}

TMPDIR="/tmp/txt2gb"

# Defaults
FONT="ACM-VGA"
SIZE="8"
LINESPACING="1"
MAXHEIGHT="2040"

while getopts f:s:l:p:t:w:c:hgi:k:a: flag
do
    case "${flag}" in
        f) 
            FONT=${OPTARG}
            if ! echo "$KNOWN_WORKING_FONTS" | grep -q "$FONT"  ; then
                echo "NOTICE: $FONT is an unknown font. Good luck! "
            fi
       ;;
        s) 
            SIZE=${OPTARG}
            if [ "$SIZE" -ne "8" ] && [ "$SIZE" -ne "16" ] && [ "$SIZE" -ne "32" ] ; then 
                echo "ERROR: Size should be 8, 16 or 32"
                usage
            fi
       ;;
        l) 
            LINESPACING=${OPTARG}
            if [ "$LINESPACING" -ne "0" ] && [ "$LINESPACING" -ne "1" ] ; then 
                echo "ERROR: Leading should be 0 or 1"
                usage
            fi
       ;;
        p) 
            LEFTPADDING=${OPTARG}
            if [ "$LEFTPADDING" -gt "152" ] || [ "$LEFTPADDING" -lt "0" ]  ; then 
                echo "ERROR: Padding to the left should be between 0 and 152"
                usage
            fi                              
       ;;
        t) 
            TOPPADDING=${OPTARG}
            if [ "$TOPPADDING" -gt "64" ] || [ "$TOPPADDING" -lt "0" ] ; then 
                echo "ERROR: Padding to the top should be between 0 and 64"
                usage
            fi                              
       ;;
        w) 
            LEADING=${OPTARG}
            if [ "$LEADING" -gt "20" ] || [ "$LEADING" -lt "1" ] ; then 
                echo "ERROR: Leading should be between 1 to 20."
                usage
            fi            
       ;;      
        c) 
            MAXHEIGHT=${OPTARG}
            if [ "$MAXHEIGHT" -gt "2040" ] || [ "$MAXHEIGHT" -lt "8" ] ||  [ $(( $MAXHEIGHT % 8 )) -ne 0 ]  ; then 
                echo "ERROR: Maximum height should be a multiple of 8 between 8 and 2040"
                usage
            fi            
       ;;
        a) 
            IMGWIDTH=${OPTARG}
            if [ "$IMGWIDTH" -gt "2040" ] || [ "$IMGWIDTH" -lt "8" ] ||  [ $(( $IMGWIDTH % 8 )) -ne 0 ]  ; then 
                echo "ERROR: Image width should be a multiple of 8 between 8 and 2040"
                usage
            fi
            if [ "$IMGWIDTH" -gt "160" ] ; then 
                echo "NOTICE: Image width ($IMGWIDTH) is wider than the GB screen (160)"
            fi
            if [ "$IMGWIDTH" -lt "160" ] ; then 
                echo "NOTICE: Image width ($IMGWIDTH) is smaller than the GB screen (160)"
            fi
            
       ;;
        g) 
        GENERATEFONT=1
        echo "Generating font.png..."
       ;;
        i) 
            INTERWORD=${OPTARG}
            INTERWORDNODECIMALS=`printf %.0f $INTERWORD`
            if [ "$INTERWORDNODECIMALS" -gt "64" ] || [ "$INTERWORDNODECIMALS" -lt "-5" ] ; then 
                echo "ERROR: Interword spacing should be between -5 and 64."
                usage
            fi            
       ;;
        k) 
            KERNING=${OPTARG}
            KERNINGNODECIMALS=`printf %.0f $KERNING`
            if [[ "$KERNINGNODECIMALS" -gt 5 ]] || [[ "$KERNINGNODECIMALS" -lt -5 ]] ; then 
                echo "ERROR: Kerning should be between -5 and 5."
                usage
            fi
       ;;
        h) 
            usage
       ;;
        \?)
            echo "ERROR: Invalid option."
            usage
            ;;
            
    esac
done


if [ -z "$GENERATEFONT" ]  ; then # Generating text
    TEXTFILE="${BASH_ARGV[0]}"
    IMAGENAME=`echo $TEXTFILE | awk -F '.txt' '{print $1}'`
    IMAGEFILE="$IMAGENAME.png"
    if [ -z "$IMGWIDTH" ]  ; then
        IMGWIDTH="160"
    fi
    if [ -z "$TEXTFILE" ] || [ -z "$IMAGEFILE" ]; then
            usage
    fi
    FILETYPE=`file $TEXTFILE`
    if ! [[ "$FILETYPE" == *"text"* ]] || ! [[ "$TEXTFILE" == *"txt"* ]]; then
        echo "ERROR: $TEXTFILE don't seem to be a txt file"
        exit 1
    fi
else  # Generating font.png
    if [ -z "$FONT" ] ; then 
        echo "ERROR: No font to generate specified."
        usage
    fi
    TEXTFILE="extended_ascii.txt"
    IMAGEFILE="$FONT.png"
    LINESPACING="0"
    LEFTPADDING="0"
    IMGWIDTH="128"

fi


INITIALDIR="`pwd`"
rm -rf $TMPDIR
mkdir -p $TMPDIR/tiles

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

 if [ -z "$LEADING" ]  ; then 
    case "$SIZE" in
        8)
            LEADING="19"
        ;;
        16)
            LEADING="9"
        ;;
        32)
            LEADING="4"
        ;;
    esac  
fi

case "$LINESPACING" in
    0)
        cat -s $TEXTFILE | fmt -w $LEADING | cat -s  > $TMPDIR/txt
    ;;
    1)
        cat -s $TEXTFILE | fmt -w $LEADING | cat -s | perl -pe 's/\n/\n\n/g'  > $TMPDIR/txt    
    ;;
    *)
        echo "ERROR: Line spacing should be 0 or 1"
        exit 1
    ;;
esac

if [ "$FONT" == "GBStudio-Stars" ] ; then # Workaround for this uppercase-only font
    tr [:lower:] [:upper:] < $TMPDIR/txt > $TMPDIR/TXT
    mv $TMPDIR/TXT $TMPDIR/txt
fi


if [ -z "$LEFTPADDING" ]  ; then 
    LEFTPADDING="8"
    if [ "$SIZE" -eq "16" ] &&  [ "$FONT" == "Ac437-CompaqThin-8x8" ] ; then # Workaround for this font at 16px
        LEFTPADDING="10"
    fi
else
    if  [ $(( $LEFTPADDING % 8 )) -ne 0 ] ; then
        echo "WARNING:  Padding to the left is not a multiple of 8: $LEFTPADDING"
    fi
fi


if [ -z "$TOPPADDING" ]  ; then 
    case "$SIZE" in
        8)
            TOPPADDING="7"
        ;;
        16)
            TOPPADDING="15"
        ;;
        32)
            TOPPADDING="30"
        ;;    
    esac
else
    if [ "$SIZE" -eq "8" ] ; then
        if [ "$TOPPADDING" -ne "7" ] && [ "$TOPPADDING" -ne "8" ] ; then
            echo "WARNING: with size $SIZE, padding to the top anything other than 7 or 8 can result in cut or invisible characters. Using: $TOPPADDING"
        fi
    fi
    if [ "$SIZE" -eq "16" ] ; then
        if [ "$TOPPADDING" -ne "15" ] && [ "$TOPPADDING" -ne "16" ] ; then
            echo "WARNING: with size $SIZE, padding to the top anything other than 15 or 16 can result in cut or invisible characters. Using: $TOPPADDING"
        fi
    fi
    if [ "$SIZE" -eq "32" ] ; then
        if [ "$TOPPADDING" -gt "32" ] || [ "$TOPPADDING" -lt "30" ] ; then 
            echo "WARNING: with size $SIZE, padding to the top less than 30 or more than 32 can result in cut or invisible characters. Using: $TOPPADDING"
        fi
    fi
fi

if [ -z "$INTERWORD" ]  ; then 
    INTERWORD="0"
fi

if [ -z "$KERNING" ]  ; then 
    KERNING="0"
fi


cd $TMPDIR

COUNT="0"

echo "Generating lines..."
while IFS= read -r line
do
    let COUNT=COUNT+1
    echo "$line" | convert -size $IMGWIDTH"x"$SIZE -interword-spacing $INTERWORD -kerning $KERNING -append +antialias xc:"#e0f8cf" -font $FONT -pointsize $SIZE -fill "#071821" -annotate +$LEFTPADDING+$TOPPADDING "@-" $COUNT.png



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
            convert ../image.png -crop "$IMGWIDTH"x"$REMAININGHEIGHT"+0+"$OFFSET" +repage "$IMAGENAME-$COUNT.png"
            echo "Several images generated:"
            cp *png "$INITIALDIR/"
            ls -1 "$INITIALDIR/$IMAGENAME"-*png
            exit 0
        else
            convert ../image.png -crop 160x"$MAXHEIGHT"+0+"$OFFSET" +repage "$IMAGENAME-$COUNT.png"
            let REMAININGHEIGHT=REMAININGHEIGHT-MAXHEIGHT
            let COUNT=COUNT+1
        fi
        let CUTS=CUTS-1     
    done
fi


##### PENDING: function to check the limit of 192 tiles or 256 tiles (if no dialogue is needed)

echo "Image generated:"
cp image.png "$INITIALDIR/$IMAGEFILE"
ls -1 "$INITIALDIR/$IMAGEFILE"

exit 0
