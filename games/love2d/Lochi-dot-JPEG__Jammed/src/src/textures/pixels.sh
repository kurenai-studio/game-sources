#/bin/zsh

get_pixel(){
    magick $3 -format "%[fx:u.p{$1,$2}.a]\n"  info:
}

print_grid(){
		OUT=""
		for y in {1..20}; do
				ROW="{"
				for x in {1..20}; do
						ROW="$ROW$(get_pixel $(( $((x * 16)) - 1 )) $(( $((y * 16)) - 1 )) $1),"
				done
				ROW="$ROW},"
				OUT="$OUT
$ROW"
		done
		echo $OUT > "$item.pattern"
}

for item in fg*.png; do
		print_grid $item
done
