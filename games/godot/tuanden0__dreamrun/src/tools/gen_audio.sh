#!/usr/bin/env bash
# Generates every sound of the game with ffmpeg (no recordings, no downloads, nothing third-party):
#   wind, drone, drips, rumble  looping ambient layers
#   step_1..4, land             one-shots
#   birds, room                 the bedroom of the wake-up scene
# Output: game/assets/audio/*.ogg (mono, 44.1 kHz, Vorbis). Loops are built with whole numbers of cycles so they
# join without a click; noise layers get a 0.3 s fade at both ends. Peaks are normalised to -6 dB (loops) / -3 dB.
# Run it again to regenerate; swapping a file for a real recording needs no code change, only the same name.
set -eu
OUT="$(cd "$(dirname "$0")/.." && pwd)/game/assets/audio"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$OUT"
FF=(ffmpeg -hide_banner -loglevel error -y)
SR=44100

# peak-normalise $1 (wav) to $2 dB and encode to $3 (ogg)
finish() {
	local in="$1" target="$2" out="$3" peak
	peak=$(ffmpeg -hide_banner -i "$in" -af volumedetect -f null - 2>&1 | sed -n 's/.*max_volume: \(-\?[0-9.]*\) dB.*/\1/p' | tail -1)
	local gain
	gain=$(awk -v t="$target" -v p="$peak" 'BEGIN { printf "%.2f", t - p }')
	"${FF[@]}" -i "$in" -af "volume=${gain}dB" -ac 1 -ar $SR -c:a libvorbis -q:a 4 "$out"
	echo "$(basename "$out"): peak ${peak} dB -> ${target} dB"
}

# --- wind: a slow swell of low pink noise with a thin whistle on top (24 s loop)
"${FF[@]}" \
	-f lavfi -i "anoisesrc=color=pink:duration=24:amplitude=0.6:sample_rate=$SR:seed=3" \
	-f lavfi -i "anoisesrc=color=white:duration=24:amplitude=0.25:sample_rate=$SR:seed=4" \
	-filter_complex "[0]highpass=f=60,lowpass=f=900,tremolo=f=0.11:d=0.55[a];[1]bandpass=f=700:width_type=h:w=400,tremolo=f=0.1:d=0.8[b];[a][b]amix=inputs=2:weights=1 0.5:normalize=0,afade=t=in:d=0.3,afade=t=out:st=23.7:d=0.3" \
	"$TMP/wind.wav"
finish "$TMP/wind.wav" -6 "$OUT/wind.ogg"

# --- drone: three low sines a little apart plus dark noise, whole cycles in 20 s (loop)
"${FF[@]}" \
	-f lavfi -i "sine=f=49:duration=20:sample_rate=$SR" \
	-f lavfi -i "sine=f=73.5:duration=20:sample_rate=$SR" \
	-f lavfi -i "sine=f=98:duration=20:sample_rate=$SR" \
	-f lavfi -i "anoisesrc=color=brown:duration=20:amplitude=0.5:sample_rate=$SR:seed=5" \
	-filter_complex "[3]lowpass=f=180,afade=t=in:d=0.3,afade=t=out:st=19.7:d=0.3[n];[0][1][2][n]amix=inputs=4:weights=1 0.6 0.35 0.5:normalize=0,tremolo=f=0.1:d=0.4" \
	"$TMP/drone.wav"
finish "$TMP/drone.wav" -6 "$OUT/drone.ogg"

# --- drips: five falling-pitch pings, spread over 20 s, with a little echo (loop)
inputs=()
chain=""
labels=""
i=0
for spec in "0.4 1.00 0.9" "3.1 0.85 0.6" "6.8 1.15 0.8" "9.9 0.95 0.5" "13.7 1.05 0.7" "16.9 0.8 0.6"; do
	set -- $spec
	inputs+=(-f lavfi -i "aevalsrc='$3*sin(2*PI*($1*0+$2*(1600*t-1800*t*t)))*exp(-t*30)':d=0.32:s=$SR")
	ms=$(awk -v s="$1" 'BEGIN { printf "%d", s * 1000 }')
	chain+="[$i]adelay=${ms}|${ms}[d$i];"
	labels+="[d$i]"
	i=$((i + 1))
done
"${FF[@]}" "${inputs[@]}" -filter_complex "${chain}${labels}amix=inputs=$i:normalize=0,apad=whole_dur=20,atrim=0:20,aecho=0.8:0.6:140|290:0.35|0.2" "$TMP/drips.wav"
finish "$TMP/drips.wav" -6 "$OUT/drips.ogg"

# --- rumble: something huge breathing, 8 s loop
"${FF[@]}" \
	-f lavfi -i "anoisesrc=color=brown:duration=8:amplitude=0.7:sample_rate=$SR:seed=6" \
	-f lavfi -i "sine=f=41:duration=8:sample_rate=$SR" \
	-f lavfi -i "sine=f=30.5:duration=8:sample_rate=$SR" \
	-filter_complex "[0]lowpass=f=110,afade=t=in:d=0.3,afade=t=out:st=7.7:d=0.3[n];[n][1][2]amix=inputs=3:weights=1 0.8 0.6:normalize=0,tremolo=f=1.25:d=0.5" \
	"$TMP/rumble.wav"
finish "$TMP/rumble.wav" -6 "$OUT/rumble.ogg"

# --- footsteps: a dull thud on leaves and earth, four variants
n=1
for lp in 650 800 720 900; do
	"${FF[@]}" \
		-f lavfi -i "anoisesrc=color=brown:duration=0.16:amplitude=0.9:sample_rate=$SR:seed=$((10 + n))" \
		-f lavfi -i "anoisesrc=color=white:duration=0.05:amplitude=0.12:sample_rate=$SR:seed=$((20 + n))" \
		-filter_complex "[0]highpass=f=90,lowpass=f=$lp,afade=t=in:d=0.004,afade=t=out:st=0.015:d=0.14[a];[1]bandpass=f=3000:width_type=h:w=2000,afade=t=out:d=0.05[b];[a][b]amix=inputs=2:normalize=0,apad=whole_dur=0.16,atrim=0:0.16" \
		"$TMP/step_$n.wav"
	finish "$TMP/step_$n.wav" -3 "$OUT/step_$n.ogg"
	n=$((n + 1))
done

# --- landing: heavier thud with a low body
"${FF[@]}" \
	-f lavfi -i "anoisesrc=color=brown:duration=0.35:amplitude=0.9:sample_rate=$SR:seed=30" \
	-f lavfi -i "aevalsrc='sin(2*PI*62*t)*exp(-t*14)':d=0.35:s=$SR" \
	-filter_complex "[0]lowpass=f=350,afade=t=in:d=0.004,afade=t=out:st=0.03:d=0.32[a];[a][1]amix=inputs=2:weights=1 1.2:normalize=0" \
	"$TMP/land.wav"
finish "$TMP/land.wav" -3 "$OUT/land.ogg"

# --- birds: short rising chirps, in twos and threes, over a soft room tone (24 s loop)
inputs=()
chain=""
labels=""
i=0
for spec in "1.2 2800" "1.38 2950" "4.6 3600" "4.76 3750" "4.92 3600" "8.9 3100" "9.1 3300" "12.4 4000" "12.55 4200" "15.8 3000" "16.0 3150" "16.2 3300" "19.7 3800" "19.85 3950" "22.3 2900"; do
	set -- $spec
	inputs+=(-f lavfi -i "aevalsrc='0.7*sin(2*PI*($2*t+9000*t*t))*exp(-pow((t-0.06)/0.035,2))':d=0.14:s=$SR")
	ms=$(awk -v s="$1" 'BEGIN { printf "%d", s * 1000 }')
	chain+="[$i]adelay=${ms}|${ms}[d$i];"
	labels+="[d$i]"
	i=$((i + 1))
done
"${FF[@]}" "${inputs[@]}" -f lavfi -i "anoisesrc=color=pink:duration=24:amplitude=0.05:sample_rate=$SR:seed=40" \
	-filter_complex "${chain}${labels}amix=inputs=$i:normalize=0,apad=whole_dur=24,atrim=0:24[b];[$i]lowpass=f=500,afade=t=in:d=0.3,afade=t=out:st=23.7:d=0.3[t];[b][t]amix=inputs=2:normalize=0,aecho=0.8:0.5:90:0.25" \
	"$TMP/birds.wav"
finish "$TMP/birds.wav" -6 "$OUT/birds.ogg"

# --- room: a warm, slow chord (C major, whole cycles in 20 s) for the bedroom and the credits
"${FF[@]}" \
	-f lavfi -i "sine=f=262:duration=20:sample_rate=$SR" \
	-f lavfi -i "sine=f=330:duration=20:sample_rate=$SR" \
	-f lavfi -i "sine=f=392:duration=20:sample_rate=$SR" \
	-filter_complex "[0][1][2]amix=inputs=3:weights=1 0.7 0.5:normalize=0,tremolo=f=0.2:d=0.3,lowpass=f=1200" \
	"$TMP/room.wav"
finish "$TMP/room.wav" -6 "$OUT/room.ogg"
