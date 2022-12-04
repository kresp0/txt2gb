#!/bin/bash
# Converts text into an image 
# usable on a Game Boy game
# as a background
# License: CC0
# Santiago Crespo - 2022

# Fonts:
# GBStudio-Stars https://github.com/gb-studio-dev/stars-font
# Ac437-CompaqThin-8x8 https://int10h.org/oldschool-pc-fonts/download/
# Mx437-ACM-VGA-8x8 https://int10h.org/oldschool-pc-fonts/download/
# Public-Pixel https://www.ggbot.net/fonts/

set -e

KNOWN_WORKING_FONTS="ACM-VGA (default), CompaqThin, GBStudio-Stars (uppercase only) and Public-Pixel"

TMPDIR="/tmp/ramdisk/txt2gb"

usage() { 
    echo "
Version: txt2gb v0.3
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
    -w char         Line Width in number of char: 1 to 20. It won't cut words. Defaults depending on size: 19, 9, 4

Advanced Font settings:
    -t px           Padding to the Top of each line. Between 1 and 64. Defaults depending on size: 7, 15, 30
    -i px           Interword spacing. Between -5 and 64. Default: 0
    -k px           Kerning: add or remove spacing between each letter. Between -5 and 5. Default: 0
    
Image settings:
    -c px           Maximum height for cutting the images. A multiple of 8 between 8 and 2040 (default)   
    -a px           Image width. A multiple of 8 between 8 and 2040. Default: 160.

GBS Font generation:
    -g            Generate a font.png to use in GBStudio from a font. Required: -f font.
    "
    exit 1
}

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
            if ! echo "$KNOWN_WORKING_FONTS" | grep -q "$FONT"  ; then ## PENDING: use a csv
                echo "🟠 NOTICE: $FONT is an unknown font. Good luck! "
            fi
       ;;
        s) 
            SIZE=${OPTARG}
            if [ "$SIZE" -ne "8" ] && [ "$SIZE" -ne "16" ] && [ "$SIZE" -ne "32" ] ; then 
                echo "🔴 ERROR: Size should be 8, 16 or 32"
                usage
            fi
       ;;
        l) 
            LINESPACING=${OPTARG}
            if [ "$LINESPACING" -ne "0" ] && [ "$LINESPACING" -ne "1" ] ; then 
                echo "🔴 ERROR: Leading should be 0 or 1"
                usage
            fi
       ;;
        p) 
            LEFTPADDING=${OPTARG}
            if [ "$LEFTPADDING" -gt "152" ] || [ "$LEFTPADDING" -lt "0" ]  ; then 
                echo "🔴 ERROR: Padding to the left should be between 0 and 152"
                usage
            fi                              
       ;;
        t) 
            TOPPADDING=${OPTARG}
            if [ "$TOPPADDING" -gt "64" ] || [ "$TOPPADDING" -lt "0" ] ; then 
                echo "🔴 ERROR: Padding to the top should be between 0 and 64"
                usage
            fi                              
       ;;
        w) 
            LINEWIDTH=${OPTARG}
            if [ "$LINEWIDTH" -gt "20" ] || [ "$LINEWIDTH" -lt "1" ] ; then 
                echo "🔴 ERROR: Leading should be between 1 to 20."
                usage
            fi            
       ;;      
        c) 
            MAXHEIGHT=${OPTARG}
            if [ "$MAXHEIGHT" -gt "2040" ] || [ "$MAXHEIGHT" -lt "8" ] ||  [ $(( $MAXHEIGHT % 8 )) -ne 0 ]  ; then 
                echo "🔴 ERROR: Maximum height should be a multiple of 8 between 8 and 2040"
                usage
            fi            
       ;;
        a) 
            IMGWIDTH=${OPTARG}
            if [ "$IMGWIDTH" -gt "2040" ] || [ "$IMGWIDTH" -lt "8" ] ||  [ $(( $IMGWIDTH % 8 )) -ne 0 ]  ; then 
                echo "🔴 ERROR: Image width should be a multiple of 8 between 8 and 2040"
                usage
            fi
            if [ "$IMGWIDTH" -gt "160" ] ; then 
                echo "🟠 NOTICE: Image width ($IMGWIDTH) is wider than the GB screen (160)"
            fi
            if [ "$IMGWIDTH" -lt "160" ] ; then 
                echo "🟠 NOTICE: Image width ($IMGWIDTH) is smaller than the GB screen (160)"
            fi
            
       ;;
        g) 
        GENERATEFONT=1
        echo "🅰️  Generating font.png..."
       ;;
        i) 
            INTERWORD=${OPTARG}
            INTERWORDNODECIMALS=`printf %.0f $INTERWORD`
            if [ "$INTERWORDNODECIMALS" -gt "64" ] || [ "$INTERWORDNODECIMALS" -lt "-5" ] ; then 
                echo "🔴 ERROR: Interword spacing should be between -5 and 64."
                usage
            fi            
       ;;
        k) 
            KERNING=${OPTARG}
            KERNINGNODECIMALS=`printf %.0f $KERNING`
            if [[ "$KERNINGNODECIMALS" -gt 5 ]] || [[ "$KERNINGNODECIMALS" -lt -5 ]] ; then 
                echo "🔴 ERROR: Kerning should be between -5 and 5."
                usage
            fi
       ;;
        h) 
            usage
       ;;
        \?)
            echo "🔴 ERROR: Invalid option."
            usage
            ;;
            
    esac
done


if [ -z "$GENERATEFONT" ]  ; then # Rendering a text
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
        echo "🔴 ERROR: $TEXTFILE don't seem to be a txt file"
        exit 1
    fi
else  # Generating a font.png
    if [ -z "$FONT" ] ; then 
        echo "🔴 ERROR: No font to generate specified."
        usage
    fi
    TEXTFILE="extended_ascii.txt"
    IMAGEFILE="$FONT.png"
    LEFTPADDING="0"
    IMGWIDTH="128"
    LINESPACING="0"
    KERNING="0"
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

 if [ -z "$LINEWIDTH" ]  ; then 
    case "$SIZE" in
        8)
            LINEWIDTH="19"
        ;;
        16)
            LINEWIDTH="9"
        ;;
        32)
            LINEWIDTH="4"
        ;;
    esac  
fi

case "$LINESPACING" in
    0)
        cat -s $TEXTFILE | fmt -w $LINEWIDTH | cat -s  > "$TMPDIR/txt"
    ;;
    1)
        cat -s $TEXTFILE | fmt -w $LINEWIDTH | cat -s | perl -pe 's/\n/\n\n/g'  > "$TMPDIR/txt"
    ;;
    *)
        echo "🔴 ERROR: Line spacing should be 0 or 1"
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
        echo "⚠️ WARNING:  Padding to the left is not a multiple of 8: $LEFTPADDING"
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
            echo "⚠️ WARNING: with size $SIZE, padding to the top anything other than 7 or 8 can result in cut or invisible characters. Using: $TOPPADDING"
        fi
    fi
    if [ "$SIZE" -eq "16" ] ; then
        if [ "$TOPPADDING" -ne "15" ] && [ "$TOPPADDING" -ne "16" ] ; then
            echo "⚠️ WARNING: with size $SIZE, padding to the top anything other than 15 or 16 can result in cut or invisible characters. Using: $TOPPADDING"
        fi
    fi
    if [ "$SIZE" -eq "32" ] ; then
        if [ "$TOPPADDING" -gt "32" ] || [ "$TOPPADDING" -lt "30" ] ; then 
            echo "⚠️ WARNING: with size $SIZE, padding to the top less than 30 or more than 32 can result in cut or invisible characters. Using: $TOPPADDING"
        fi
    fi
fi

if [ -z "$INTERWORD" ]  ; then 
    INTERWORD="0"
fi

if [ -z "$KERNING" ]  ; then 
    KERNING="0"
fi

cuttiles() { 
#    echo "Dividing line $LINECOUNT into 8x8 tiles..."
    convert -crop 8x8 $LINECOUNT.png +repage "$TMPDIR/tiles/$LINECOUNT.png"
        TILECOUNT=0
        if ! [ -z "$GENERATEFONT" ]  ; then
            TILES=16
        else
            TILES=20
        fi

        while [ $TILECOUNT -lt "$TILES" ] ;
        do
            convert "$TMPDIR/tiles/$LINECOUNT-$TILECOUNT.png" "$TMPDIR/tiles/$LINECOUNT-$TILECOUNT.rgba"
            md5sum "$TMPDIR/tiles/$LINECOUNT-$TILECOUNT.rgba" >> "$TMPDIR/tilehashlist"
            let TILECOUNT=TILECOUNT+1
        done       
}

countuniquetiles() { 
    UNIQUETILES=`cat "$TMPDIR/tilehashlist" | awk '{print $1}' | sort -u | wc -l`
    if [ "$UNIQUETILES" -gt "256" ] ; then
        echo "🔴 ERROR: More than 256 unique tiles! This image cannot be used in GBS :("
    fi
    if [ "$UNIQUETILES" -gt "192" ] &&  [ "$UNIQUETILES" -lt "256" ]  ; then
        echo "⚠️ WARNING: More than 192 unique tiles. Only usable for LOGO scenes. Try setting a maximum height for cutting the images lower than $MAXHEIGHT with -c"
    fi
    echo "Unique tiles: $UNIQUETILES"
}

rendertext() { 
    cd $TMPDIR
    rm -f "$TMPDIR/tilehashlist"
    LINECOUNT="0"
    echo "✍️  Writing lines..."
    while IFS= read -r line
    do
        echo $line
        let LINECOUNT=LINECOUNT+1
        echo "$line" | convert -size $IMGWIDTH"x"$SIZE -interword-spacing $INTERWORD -kerning $KERNING -append +antialias xc:"#e0f8cf" -font $FONT -pointsize $SIZE -fill "#071821" -annotate +$LEFTPADDING+$TOPPADDING "@-" $LINECOUNT.png
        cuttiles        
    done < "$TMPDIR/txt"

    echo "📝 Concatenating lines..."
    IMAGES=`ls -1 "$TMPDIR"/*.png | sort -V | perl -pe 's/\n/ /g'`
    montage -mode concatenate -tile 1x $IMAGES image.png

    if [ -z "$GENERATEFONT" ]  ; then 
        IMGHEIGHT=`file image.png | awk -F ' x ' '{print $2}' | awk -F ',' '{print $1}'`
        REMAININGHEIGHT=$IMGHEIGHT
        if [ "$IMGHEIGHT" -gt "$MAXHEIGHT" ] ; then
            echo "The image height ($IMGHEIGHT) is larger than $MAXHEIGHT. Cuting the image..."
            CUTS=$((IMGHEIGHT / MAXHEIGHT))
            mkdir cuts
            cd cuts
            IMAGECOUNT="0"
            let CUTS=CUTS+1
            while [ $CUTS -gt "0" ] ;
            do
                OFFSET=$((IMAGECOUNT * MAXHEIGHT))
                if [ "$REMAININGHEIGHT" -lt "$MAXHEIGHT" ] ; then
                    convert ../image.png -crop "$IMGWIDTH"x"$REMAININGHEIGHT"+0+"$OFFSET" +repage "$IMAGENAME-$IMAGECOUNT.png"
                    countuniquetiles
                    echo "🖼️ 🖼️ 🖼️  Several images generated:"
                    cp *png "$INITIALDIR/"
                    ls -1 "$INITIALDIR/$IMAGENAME"-*png
                    exit 0
                else
                    convert ../image.png -crop 160x"$MAXHEIGHT"+0+"$OFFSET" +repage "$IMAGENAME-$IMAGECOUNT.png"
                    let REMAININGHEIGHT=REMAININGHEIGHT-MAXHEIGHT
                    let IMAGECOUNT=IMAGECOUNT+1
                fi
                let CUTS=CUTS-1     
            done
        fi
    fi
}

renderfont() { 
    cp "$INITIALDIR/extended_ascii.txt"  "$TMPDIR/txt"
    rm -f  "$TMPDIR/"*png
    rendertext
    cp "$TMPDIR/image.png" "$INITIALDIR/$IMAGEFILE"
    convert "$TMPDIR/image.png" -interpolate Integer -filter point -resize "200%" "$INITIALDIR/2x_$IMAGEFILE"
    echo "Font: $FONT
Top padding: $TOPPADDING
Interword: $INTERWORD
Kerning: $KERNING
txt2img.sh -f $FONT -t$TOPPADDING -i$INTERWORD -k$KERNING file.txt " > "$INITIALDIR/$FONT.txt"
    rm -f  "$TMPDIR/"*png
    IMGWIDTH="160"
    echo ""  > "$TMPDIR/txt"
    echo ' The quick brown fox jumps over the lazy dog' | fmt -w 20 | perl -pe 's/\n /\n\n /g' | perl -pe 's/\n/\n\n/g'   >> "$TMPDIR/txt"
    echo "" >> "$TMPDIR/txt"
    echo ' The quick brown fox jumps over the lazy dog
    
 !@#$%^\& ABCDEFGHIJKL
 MNOPQRSTUVWXYZ
 
' $FONT' ' | fmt -w 20 | perl -pe 's/\n /\n\n /g'  >> "$TMPDIR/txt"    
    rendertext
    convert "$TMPDIR/image.png" -interpolate Integer -filter point -resize "200%" "$INITIALDIR/Sample_$IMAGEFILE"
    echo "🥳 $IMAGEFILE and Sample_$IMAGEFILE generated!"
    echo "If you want to generate background images:"
    echo "txt2gb.sh -f $FONT -t$TOPPADDING -i$INTERWORD -k$KERNING file.txt"
}

renderrandom() {
    rendertext
    UNIQUETILESRANDOMASCII=`cat "$TMPDIR/tilehashlist" | awk '{print $1}' | sort -u | wc -l`
    echo "Unique tiles in font.png with default interword: $UNIQUETILESMAX"
    echo "Unique tiles with random ASCII: $UNIQUETILESRANDOMASCII. Top padding=$TOPPADDING, kerning=$KERNING, interword=$INTERWORD"
}

    
if [ -z "$GENERATEFONT" ]  ; then 
    rendertext
    countuniquetiles
    echo "🖼️  Image generated:"
    cp image.png "$INITIALDIR/$IMAGEFILE"
    ls -1 "$INITIALDIR/$IMAGEFILE"
else # Try to generate font.png

# AUTOMATIC TOP PADDING
    echo "7️⃣  Testing with top padding of 7"...
    TOPPADDING=7
    rendertext
    BLACKPX7=`convert "$TMPDIR/image.png" -define histogram:unique-colors=true -format %c histogram:info:- | grep 071821 | awk -F ':' '{print $1}' | perl -pe 's/ //g'`
    cp "$TMPDIR/image.png" "/tmp/image7.png" 
    echo "8️⃣  Testing with top padding of 8"...
    TOPPADDING=8
    rm -f "$TMPDIR"/*png
    rendertext
    BLACKPX8=`convert "$TMPDIR/image.png" -define histogram:unique-colors=true -format %c histogram:info:- | grep 071821 | awk -F ':' '{print $1}' | perl -pe 's/ //g'`
    cp "$TMPDIR/image.png" "/tmp/image8.png" 
    if [ "$BLACKPX8" -gt "$BLACKPX7" ] ; then
        echo "✨8️⃣  With a top padding of 8 there are more black px ($BLACKPX8) than with 7 ($BLACKPX7)"    
        TOPPADDING=8
    else
        echo "✨7️⃣  With a top padding of 7 there are the same or more black px ($BLACKPX7) than with 8 ($BLACKPX8)"
        TOPPADDING=7
    fi

# AUTOMATIC KERNING
    echo "🅱️  Determining kerning..."
     rendertext
    UNIQUETILESMAX=`cat "$TMPDIR/tilehashlist" | awk '{print $1}' | sort -u | wc -l`
    rm "$TMPDIR/txt"
    echo "🎲 Generating lines of common ASCII in random positions"
    echo '!@#$%^\&
a b c d e f g h i j k l m n o p q r s t u v w x y z
ABCDEFGHIJKLMNOPQRSTUVWXYZ' > common_ascii.txt

    for LONGCOUNTER in {1..6}; do
        cat common_ascii.txt | fold -w1 | shuf | tr -d '\n' | fold -w 20  >> "$TMPDIR/rnd"
    done
    cp "$TMPDIR/rnd" "$TMPDIR/txt"

    for KERNINGTRIES in {0..5}; do
        KERNING=$KERNINGTRIES
        cp "$INITIALDIR/extended_ascii.txt"  "$TMPDIR/txt"       
        rendertext
        UNIQUETILESMAX=`cat "$TMPDIR/tilehashlist" | awk '{print $1}' | sort -u | wc -l`
        cp "$TMPDIR/rnd" "$TMPDIR/txt"
        renderrandom
         if (( UNIQUETILESRANDOMASCII < UNIQUETILESMAX  )); then
            echo "✅ Found a good kerning: $KERNING"
            renderfont
            exit 0 
        fi    
    done
    
if (( KERNINGTRIES == "5"  )); then
    echo "🔴😔 ERROR: Cannot find a way to use $FONT on 8x8 tiles. Tried with kerning 0-5 but no luck."
    echo "$FONT" >> "$INITIALDIR/00failed-fonts.txt"
    exit 1
fi


echo ########### PENDING INTERWORD


renderfont     
fi
exit 0
