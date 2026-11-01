package entities

import (
	"image/color"

	"github.com/EchoSingh/space-shooter/pkg/vector"
	"github.com/hajimehoshi/ebiten/v2"
)

// BulletOwner represents who fired the bullet
type BulletOwner int

const (
	OwnerPlayer BulletOwner = iota
	OwnerEnemy
)

// Bullet represents a projectile
type Bullet struct {
	BaseEntity
	Visual   *Visual
	Damage   int
	Owner    BulletOwner
	LifeTime float64
	MaxLife  float64

	screenWidth  float64
	screenHeight float64
}

// NewBullet creates a new bullet
func NewBullet(x, y float64, velocity vector.Vector2, damage int, owner BulletOwner, screenWidth, screenHeight float64) *Bullet {
	bulletColor := color.RGBA{R: 100, G: 200, B: 255, A: 255}
	if owner == OwnerEnemy {
		bulletColor = color.RGBA{R: 255, G: 100, B: 100, A: 255}
	}

	return &Bullet{
		BaseEntity: BaseEntity{
			Position: vector.New(x, y),
			Velocity: velocity,
			Active:   true,
			Type:     TypeBullet,
			Radius:   3,
		},
		Visual: &Visual{
			Color:  bulletColor,
			Width:  6,
			Height: 12,
		},
		Damage:       damage,
		Owner:        owner,
		MaxLife:      3.0,
		screenWidth:  screenWidth,
		screenHeight: screenHeight,
	}
}

// Update updates the bullet
func (b *Bullet) Update(dt float64) error {
	b.LifeTime += dt

	// Update position
	b.Position = b.Position.Add(b.Velocity.Mul(dt))

	// Deactivate if off screen or too old
	if b.LifeTime > b.MaxLife {
		b.Active = false
	}
	if b.Position.Y < -20 || b.Position.Y > b.screenHeight+20 {
		b.Active = false
	}
	if b.Position.X < -20 || b.Position.X > b.screenWidth+20 {
		b.Active = false
	}

	return nil
}

// Draw draws the bullet
func (b *Bullet) Draw(screen *ebiten.Image) {
	x, y := b.Position.X, b.Position.Y
	w, h := b.Visual.Width/2, b.Visual.Height/2

	img := ebiten.NewImage(int(b.Visual.Width), int(b.Visual.Height))
	img.Fill(b.Visual.Color)
	op := &ebiten.DrawImageOptions{}
	op.GeoM.Translate(x-w, y-h)
	screen.DrawImage(img, op)
}

// OnCollision handles collision
func (b *Bullet) OnCollision(other Entity) {
	b.Active = false
}

// GetDamage returns the bullet's damage
func (b *Bullet) GetDamage() int {
	return b.Damage
}

// GetOwner returns who fired the bullet
func (b *Bullet) GetOwner() BulletOwner {
	return b.Owner
}
