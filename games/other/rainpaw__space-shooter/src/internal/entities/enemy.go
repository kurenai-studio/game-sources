package entities

import (
	"image/color"
	"math"
	"math/rand"

	"github.com/EchoSingh/space-shooter/pkg/vector"
	"github.com/hajimehoshi/ebiten/v2"
)

// EnemyType represents different enemy types
type EnemyType int

const (
	EnemyBasic EnemyType = iota
	EnemyFast
	EnemyTank
	EnemyShooter
)

// Enemy represents an enemy ship
type Enemy struct {
	BaseEntity
	Health      *Health
	Visual      *Visual
	EnemyType   EnemyType
	Speed       float64
	ScoreValue  int
	MovePattern MovePattern
	Time        float64

	screenWidth  float64
	screenHeight float64
}

// MovePattern defines enemy movement behavior
type MovePattern int

const (
	PatternStraight MovePattern = iota
	PatternSine
	PatternZigZag
	PatternSeek
)

// NewEnemy creates a new enemy
func NewEnemy(enemyType EnemyType, x, y, screenWidth, screenHeight float64) *Enemy {
	enemy := &Enemy{
		BaseEntity: BaseEntity{
			Position: vector.New(x, y),
			Velocity: vector.Zero(),
			Active:   true,
			Type:     TypeEnemy,
		},
		EnemyType:    enemyType,
		screenWidth:  screenWidth,
		screenHeight: screenHeight,
	}

	// Configure based on type
	switch enemyType {
	case EnemyBasic:
		enemy.Health = NewHealth(20)
		enemy.Speed = 100
		enemy.Radius = 12
		enemy.ScoreValue = 10
		enemy.MovePattern = PatternStraight
		enemy.Visual = &Visual{
			Color:  color.RGBA{R: 255, G: 100, B: 100, A: 255},
			Width:  24,
			Height: 24,
		}
	case EnemyFast:
		enemy.Health = NewHealth(10)
		enemy.Speed = 200
		enemy.Radius = 10
		enemy.ScoreValue = 15
		enemy.MovePattern = PatternZigZag
		enemy.Visual = &Visual{
			Color:  color.RGBA{R: 255, G: 150, B: 50, A: 255},
			Width:  20,
			Height: 20,
		}
	case EnemyTank:
		enemy.Health = NewHealth(50)
		enemy.Speed = 50
		enemy.Radius = 20
		enemy.ScoreValue = 25
		enemy.MovePattern = PatternStraight
		enemy.Visual = &Visual{
			Color:  color.RGBA{R: 150, G: 50, B: 50, A: 255},
			Width:  40,
			Height: 40,
		}
	case EnemyShooter:
		enemy.Health = NewHealth(30)
		enemy.Speed = 80
		enemy.Radius = 15
		enemy.ScoreValue = 20
		enemy.MovePattern = PatternSine
		enemy.Visual = &Visual{
			Color:  color.RGBA{R: 200, G: 50, B: 200, A: 255},
			Width:  30,
			Height: 30,
		}
	}

	return enemy
}

// Update updates the enemy
func (e *Enemy) Update(dt float64) error {
	e.Time += dt

	// Update movement based on pattern
	switch e.MovePattern {
	case PatternStraight:
		e.Velocity = vector.New(0, e.Speed)
	case PatternSine:
		e.Velocity = vector.New(
			math.Sin(e.Time*2)*100,
			e.Speed,
		)
	case PatternZigZag:
		zigzag := math.Floor(e.Time*2) / 2
		direction := 1.0
		if int(zigzag)%2 == 0 {
			direction = -1.0
		}
		e.Velocity = vector.New(direction*150, e.Speed)
	case PatternSeek:
		// This would seek the player (needs player reference)
		e.Velocity = vector.New(0, e.Speed)
	}

	// Update position
	e.Position = e.Position.Add(e.Velocity.Mul(dt))

	// Deactivate if off screen
	if e.Position.Y > e.screenHeight+50 {
		e.Active = false
	}
	if e.Position.X < -50 || e.Position.X > e.screenWidth+50 {
		e.Active = false
	}

	return nil
}

// Draw draws the enemy
func (e *Enemy) Draw(screen *ebiten.Image) {
	x, y := float32(e.Position.X), float32(e.Position.Y)
	w := float32(e.Visual.Width / 2)

	// Draw enemy as simple square
	img := ebiten.NewImage(int(w*2), int(w*2))
	img.Fill(e.Visual.Color)
	op := &ebiten.DrawImageOptions{}
	op.GeoM.Translate(float64(x-w), float64(y-w))
	screen.DrawImage(img, op)
}

// OnCollision handles collision
func (e *Enemy) OnCollision(other Entity) {
	switch other.GetType() {
	case TypeBullet:
		// Damage is handled by the collision system
	case TypePlayer:
		e.Active = false
	}
}

// TakeDamage damages the enemy
func (e *Enemy) TakeDamage(amount int) {
	e.Health.Damage(amount)
	if e.Health.IsDead() {
		e.Active = false
	}
}

// SpawnRandom spawns a random enemy
func SpawnRandom(screenWidth, screenHeight float64) *Enemy {
	enemyTypes := []EnemyType{EnemyBasic, EnemyFast, EnemyTank, EnemyShooter}
	enemyType := enemyTypes[rand.Intn(len(enemyTypes))]

	x := rand.Float64() * screenWidth
	y := -30.0

	return NewEnemy(enemyType, x, y, screenWidth, screenHeight)
}
