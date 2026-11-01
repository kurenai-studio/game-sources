package vector

import (
	"math"
	"testing"
)

func TestVector2Add(t *testing.T) {
	v1 := New(3, 4)
	v2 := New(1, 2)
	result := v1.Add(v2)

	if result.X != 4 || result.Y != 6 {
		t.Errorf("Add failed: expected (4, 6), got (%f, %f)", result.X, result.Y)
	}
}

func TestVector2Sub(t *testing.T) {
	v1 := New(5, 7)
	v2 := New(2, 3)
	result := v1.Sub(v2)

	if result.X != 3 || result.Y != 4 {
		t.Errorf("Sub failed: expected (3, 4), got (%f, %f)", result.X, result.Y)
	}
}

func TestVector2Mul(t *testing.T) {
	v := New(2, 3)
	result := v.Mul(3)

	if result.X != 6 || result.Y != 9 {
		t.Errorf("Mul failed: expected (6, 9), got (%f, %f)", result.X, result.Y)
	}
}

func TestVector2Length(t *testing.T) {
	v := New(3, 4)
	length := v.Length()
	expected := 5.0

	if math.Abs(length-expected) > 0.0001 {
		t.Errorf("Length failed: expected %f, got %f", expected, length)
	}
}

func TestVector2Normalize(t *testing.T) {
	v := New(3, 4)
	result := v.Normalize()
	length := result.Length()

	if math.Abs(length-1.0) > 0.0001 {
		t.Errorf("Normalize failed: length should be 1.0, got %f", length)
	}
}

func TestVector2Distance(t *testing.T) {
	v1 := New(0, 0)
	v2 := New(3, 4)
	distance := v1.Distance(v2)
	expected := 5.0

	if math.Abs(distance-expected) > 0.0001 {
		t.Errorf("Distance failed: expected %f, got %f", expected, distance)
	}
}

func TestVector2Dot(t *testing.T) {
	v1 := New(2, 3)
	v2 := New(4, 5)
	dot := v1.Dot(v2)
	expected := 23.0 // 2*4 + 3*5

	if math.Abs(dot-expected) > 0.0001 {
		t.Errorf("Dot failed: expected %f, got %f", expected, dot)
	}
}

func TestVector2Rotate(t *testing.T) {
	v := New(1, 0)
	result := v.Rotate(math.Pi / 2) // 90 degrees

	// Should be approximately (0, 1)
	if math.Abs(result.X) > 0.0001 || math.Abs(result.Y-1.0) > 0.0001 {
		t.Errorf("Rotate failed: expected (0, 1), got (%f, %f)", result.X, result.Y)
	}
}

func TestVector2Lerp(t *testing.T) {
	v1 := New(0, 0)
	v2 := New(10, 10)
	result := v1.Lerp(v2, 0.5)

	if result.X != 5 || result.Y != 5 {
		t.Errorf("Lerp failed: expected (5, 5), got (%f, %f)", result.X, result.Y)
	}
}

func BenchmarkVector2Add(b *testing.B) {
	v1 := New(3, 4)
	v2 := New(1, 2)

	for i := 0; i < b.N; i++ {
		_ = v1.Add(v2)
	}
}

func BenchmarkVector2Length(b *testing.B) {
	v := New(3, 4)

	for i := 0; i < b.N; i++ {
		_ = v.Length()
	}
}

func BenchmarkVector2Normalize(b *testing.B) {
	v := New(3, 4)

	for i := 0; i < b.N; i++ {
		_ = v.Normalize()
	}
}
