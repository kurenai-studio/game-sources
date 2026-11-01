extends RefCounted
## Measurements on the click's sample data for the audio tests. Not a test
## file itself: the runner only loads files named test_*.gd.
##
## Levels are fractions of full scale, where 1.0 is 0 dBFS.

const FULL_SCALE: float = 32768.0


## Every sample of a 16 bit mono stream as a fraction of full scale.
static func samples(stream: AudioStreamWAV) -> PackedFloat64Array:
	var data: PackedByteArray = stream.data
	var count: int = data.size() >> 1
	var out: PackedFloat64Array = PackedFloat64Array()
	out.resize(count)
	for n: int in count:
		out[n] = data.decode_s16(n * 2) / FULL_SCALE
	return out


static func peak(wave: PackedFloat64Array) -> float:
	var loudest: float = 0.0
	for value: float in wave:
		loudest = maxf(loudest, absf(value))
	return loudest


static func peak_index(wave: PackedFloat64Array) -> int:
	var best: int = 0
	for n: int in wave.size():
		if absf(wave[n]) > absf(wave[best]):
			best = n
	return best


static func mean(wave: PackedFloat64Array) -> float:
	var total: float = 0.0
	for value: float in wave:
		total += value
	return total / maxf(1.0, float(wave.size()))


## The loudest sample from index first up to, but not including, index last.
static func peak_between(wave: PackedFloat64Array, first: int, last: int) -> float:
	var loudest: float = 0.0
	for n: int in range(maxi(first, 0), mini(last, wave.size())):
		loudest = maxf(loudest, absf(wave[n]))
	return loudest


## The first index where the level reaches fraction of the peak.
static func first_reaching(wave: PackedFloat64Array, fraction: float) -> int:
	var target: float = peak(wave) * fraction
	for n: int in wave.size():
		if absf(wave[n]) >= target:
			return n
	return -1


## The index after which the level stays below fraction of the peak.
static func last_above(wave: PackedFloat64Array, fraction: float) -> int:
	var target: float = peak(wave) * fraction
	for n: int in range(wave.size() - 1, -1, -1):
		if absf(wave[n]) >= target:
			return n
	return -1


## Copies of wave starting at each offset (in samples) added together, the way
## the mixer sums clicks that overlap.
static func mix(wave: PackedFloat64Array, offsets: PackedInt64Array) -> PackedFloat64Array:
	var length: int = 0
	for offset: int in offsets:
		length = maxi(length, offset + wave.size())
	var out: PackedFloat64Array = PackedFloat64Array()
	out.resize(length)
	for offset: int in offsets:
		for n: int in wave.size():
			out[offset + n] += wave[n]
	return out


static func to_dbfs(level: float) -> float:
	return linear_to_db(level)
