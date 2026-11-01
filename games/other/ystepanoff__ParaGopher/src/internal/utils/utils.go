package utils

func Overlap1D(x1, w1, x2, w2 float32) bool {
	if x1+w1 <= x2 || x2+w2 <= x1 {
		return false
	}
	return true
}

func Overlap2D(x1, y1, w1, h1 float32, x2, y2, w2, h2 float32) bool {
	if !Overlap1D(x1, w1, x2, w2) || !Overlap1D(y1, h1, y2, h2) {
		return false
	}
	return true
}
