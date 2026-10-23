#!/bin/bash

magick icon.svg -resize 144x144! icon144x144.png
magick icon.svg -resize 180x180! icon180x180.png
magick icon.svg -resize 512x512! icon512x512.png
magick -background none splash.svg splash.png
