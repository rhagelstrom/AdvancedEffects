#!/bin/bash
prog=$(basename $0)
version="1.0"

# Default Colors

color="white"
outline="black"
shade_color="white"


function help()
{
    echo "$prog Version: $version"
    echo "By: Ryan Hagelstrom"
    echo "Description: Converts svg files to FG icon format"
    echo "Requires: imagemagick"
    echo "Syntax: $prog -i <image.svg>"
    echo
    echo "    -h          Help"
    echo "    -i <image>  SVG image file to convert (required)"
    echo "    -b <color>  Base color"
    echo "    -o <color>  Outline color"
    echo "    -g <color>  Glow color"
    exit
}

function iconify()
{
    unamestr=$(uname)
     if [[ "$unamestr" == 'Linux' ]]; then
        convert="./magick"
    else
        convert="convert"
    fi

    if [ -n "$filename" ] && [[ $filename == *.svg ]]; then
        filename_stripped="${filename%.svg}"
        filename_png="$filename_stripped"
        filename_png+=".png"
        filename_webp="$filename_stripped"
        filename_webp+="-forge.webp"
        filename_webp_sm="$filename_stripped"
        filename_webp_sm+=".webp"

        echo "    Converting $filename $filename_png"

        "$convert" -background none "$filename" "$filename_png"

        # Color the image
        "$convert" "$filename_png" -background none -channel RGB -fuzz 50% -fill "$color" -colorize 100  -alpha on "$filename_png"

        # Resize bigger to fit the halos. Add outline under the edges and slight blur
        "$convert" "$filename_png" -background none -gravity center -extent '125%' -write mpr:input -fill "$outline" -channel RGB -colorize 100 +channel -morphology dilate:4 disk -blur 0x3 mpr:input -composite "$filename_png"

        # Add halow glow under the black with more blur
        "$convert" "$filename_png" -write mpr:input -fill "$shade_color" -channel RGB -colorize 100 +channel -morphology dilate:5 disk -blur 0x10 mpr:input -composite -resize 150x150 -quality 50 -define webp:lossless=true "$filename_webp"

        # Reduce size 30x30 for chat output
        "$convert" "$filename_png" -write mpr:input -fill "$shade_color" -channel RGB -colorize 100 +channel -morphology dilate:5 disk -blur 0x10 mpr:input -composite -resize 30x30 -quality 50 -define webp:lossless=true "$filename_webp_sm"

        rm "$filename_png"
    else
        help
    fi
}
while getopts i:b:o:g: flag
do
    case "${flag}" in
        i) filename=${OPTARG};;
        b) color=${OPTARG};;
        o) outline=${OPTARG};;
        g) shade_color=${OPTARG};;
        *) help ;;
    esac
done

iconify
