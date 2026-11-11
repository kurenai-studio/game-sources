#! /bin/sh

for file in *.svg
do
	filename=`echo "${file}" | sed s/.svg//`
	/Applications/Inkscape.app/Contents/MacOS/inkscape -h 360 --export-png="../assets/${filename}.png" "${file}"
done
