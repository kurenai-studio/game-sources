package entities

import (
	"image/color"
	"math/rand"

	"github.com/EchoSingh/space-shooter/pkg/vector"
	"github.com/hajimehoshi/ebiten/v2"
)

// Particle represents a visual effect particle
type Particle struct {
	BaseEntity
	Visual   *Visual
	LifeTime float64
	MaxLife  float64
	Fade     bool
}

// NewParticle creates a new particle
func NewParticle(x, y float64, velocity vector.Vector2, color color.Color, size, life float64) *Particle {
	return &Particle{
		BaseEntity: BaseEntity{
			Position: vector.New(x, y),
			Velocity: velocity,
			Active:   true,
			Type:     TypeParticle,
			Radius:   size / 2,
		},
		Visual: &Visual{
			Color:  color,
			Width:  size,
			Height: size,
		},
		MaxLife: life,
		Fade:    true,
	}
}

// Update updates the particle
func (p *Particle) Update(dt float64) error {
	p.LifeTime += dt

	// Update position
	p.Position = p.Position.Add(p.Velocity.Mul(dt))

	// Apply drag
	p.Velocity = p.Velocity.Mul(0.98)

	// Deactivate if expired
	if p.LifeTime >= p.MaxLife {
		p.Active = false
	}

	return nil
}

// Draw draws the particle
func (p *Particle) Draw(screen *ebiten.Image) {
	alpha := 1.0
	if p.Fade {
		alpha = 1.0 - (p.LifeTime / p.MaxLife)
	}

	// Get the original color
	r, g, b, _ := p.Visual.Color.RGBA()
	particleColor := color.RGBA{
		R: uint8(r >> 8),
		G: uint8(g >> 8),
		B: uint8(b >> 8),
		A: uint8(alpha * 255),
	}

	x, y := p.Position.X, p.Position.Y
	size := p.Visual.Width

	img := ebiten.NewImage(int(size), int(size))
	img.Fill(particleColor)
	op := &ebiten.DrawImageOptions{}
	op.GeoM.Translate(x-size/2, y-size/2)
	screen.DrawImage(img, op)
}

// CreateExplosion creates explosion particles
func CreateExplosion(x, y float64, count int) []*Particle {
	particles := make([]*Particle, count)
	colors := []color.Color{
		color.RGBA{R: 255, G: 200, B: 0, A: 255},
		color.RGBA{R: 255, G: 150, B: 0, A: 255},
		color.RGBA{R: 255, G: 100, B: 0, A: 255},
		color.RGBA{R: 200, G: 50, B: 0, A: 255},
	}

	for i := 0; i < count; i++ {
		speed := 50 + rand.Float64()*150
		velocity := vector.New(
			speed*float64(rand.Float64()-0.5)*2,
			speed*float64(rand.Float64()-0.5)*2,
		)

		particleColor := colors[rand.Intn(len(colors))]
		size := 2 + rand.Float64()*4
		life := 0.3 + rand.Float64()*0.7

		particles[i] = NewParticle(x, y, velocity, particleColor, size, life)
	}

	return particles
}

// CreateTrail creates trail particles
func CreateTrail(x, y float64, velocity vector.Vector2) *Particle {
	trailColor := color.RGBA{R: 100, G: 200, B: 255, A: 200}
	size := 2.0 + rand.Float64()*2
	life := 0.2 + rand.Float64()*0.3

	// Trail moves opposite to entity
	trailVelocity := velocity.Mul(-0.3)

	return NewParticle(x, y, trailVelocity, trailColor, size, life)
}
