package vector

import "math"

// Vector2 represents a 2D vector
type Vector2 struct {
	X, Y float64
}

// New creates a new Vector2
func New(x, y float64) Vector2 {
	return Vector2{X: x, Y: y}
}

// Zero returns a zero vector
func Zero() Vector2 {
	return Vector2{X: 0, Y: 0}
}

// Add adds two vectors
func (v Vector2) Add(other Vector2) Vector2 {
	return Vector2{
		X: v.X + other.X,
		Y: v.Y + other.Y,
	}
}

// Sub subtracts other from v
func (v Vector2) Sub(other Vector2) Vector2 {
	return Vector2{
		X: v.X - other.X,
		Y: v.Y - other.Y,
	}
}

// Mul multiplies vector by scalar
func (v Vector2) Mul(scalar float64) Vector2 {
	return Vector2{
		X: v.X * scalar,
		Y: v.Y * scalar,
	}
}

// Div divides vector by scalar
func (v Vector2) Div(scalar float64) Vector2 {
	if scalar == 0 {
		return v
	}
	return Vector2{
		X: v.X / scalar,
		Y: v.Y / scalar,
	}
}

// Length returns the length (magnitude) of the vector
func (v Vector2) Length() float64 {
	return math.Sqrt(v.X*v.X + v.Y*v.Y)
}

// LengthSquared returns the squared length (more efficient)
func (v Vector2) LengthSquared() float64 {
	return v.X*v.X + v.Y*v.Y
}

// Normalize returns a unit vector in the same direction
func (v Vector2) Normalize() Vector2 {
	length := v.Length()
	if length == 0 {
		return Zero()
	}
	return v.Div(length)
}

// Distance returns the distance between two vectors
func (v Vector2) Distance(other Vector2) float64 {
	return v.Sub(other).Length()
}

// DistanceSquared returns the squared distance (more efficient)
func (v Vector2) DistanceSquared(other Vector2) float64 {
	return v.Sub(other).LengthSquared()
}

// Dot returns the dot product
func (v Vector2) Dot(other Vector2) float64 {
	return v.X*other.X + v.Y*other.Y
}

// Angle returns the angle in radians
func (v Vector2) Angle() float64 {
	return math.Atan2(v.Y, v.X)
}

// Rotate rotates the vector by angle in radians
func (v Vector2) Rotate(angle float64) Vector2 {
	cos := math.Cos(angle)
	sin := math.Sin(angle)
	return Vector2{
		X: v.X*cos - v.Y*sin,
		Y: v.X*sin + v.Y*cos,
	}
}

// Lerp performs linear interpolation between two vectors
func (v Vector2) Lerp(other Vector2, t float64) Vector2 {
	return Vector2{
		X: v.X + (other.X-v.X)*t,
		Y: v.Y + (other.Y-v.Y)*t,
	}
}

// Clamp clamps the vector components between min and max
func (v Vector2) Clamp(min, max Vector2) Vector2 {
	return Vector2{
		X: clampFloat(v.X, min.X, max.X),
		Y: clampFloat(v.Y, min.Y, max.Y),
	}
}

func clampFloat(value, min, max float64) float64 {
	if value < min {
		return min
	}
	if value > max {
		return max
	}
	return value
}
