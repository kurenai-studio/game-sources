package entities

import (
	"image/color"

	"github.com/EchoSingh/space-shooter/pkg/vector"
	"github.com/hajimehoshi/ebiten/v2"
)

const (
	PlayerSpeed        = 300.0
	PlayerFireRate     = 0.15
	PlayerMaxHealth    = 100
	PlayerRadius       = 20.0
	PlayerBulletSpeed  = 500.0
	PlayerBulletDamage = 10
)

// Player represents the player's spaceship
type Player struct {
	BaseEntity
	Health *Health
	Weapon *Weapon
	Visual *Visual
	Score  int

	// Input state
	moveUp    bool
	moveDown  bool
	moveLeft  bool
	moveRight bool
	firing    bool

	// Screen bounds
	screenWidth  float64
	screenHeight float64
}

// NewPlayer creates a new player
func NewPlayer(x, y, screenWidth, screenHeight float64) *Player {
	return &Player{
		BaseEntity: BaseEntity{
			Position: vector.New(x, y),
			Velocity: vector.Zero(),
			Active:   true,
			Type:     TypePlayer,
			Radius:   PlayerRadius,
		},
		Health: NewHealth(PlayerMaxHealth),
		Weapon: &Weapon{
			Damage:         PlayerBulletDamage,
			FireRate:       PlayerFireRate,
			BulletSpeed:    PlayerBulletSpeed,
			ProjectileType: ProjectileNormal,
		},
		Visual: &Visual{
			Color:  color.RGBA{R: 100, G: 200, B: 255, A: 255},
			Width:  45,
			Height: 55,
		},
		screenWidth:  screenWidth,
		screenHeight: screenHeight,
	}
}

// Update updates the player
func (p *Player) Update(dt float64) error {
	// Update weapon
	p.Weapon.Update(dt)

	// Handle input
	p.handleInput()

	// Calculate movement
	direction := vector.Zero()
	if p.moveUp {
		direction.Y -= 1
	}
	if p.moveDown {
		direction.Y += 1
	}
	if p.moveLeft {
		direction.X -= 1
	}
	if p.moveRight {
		direction.X += 1
	}

	// Normalize diagonal movement
	if direction.X != 0 || direction.Y != 0 {
		direction = direction.Normalize()
	}

	// Apply velocity
	p.Velocity = direction.Mul(PlayerSpeed)
	p.Position = p.Position.Add(p.Velocity.Mul(dt))

	// Clamp to screen bounds
	p.Position = p.Position.Clamp(
		vector.New(PlayerRadius, PlayerRadius),
		vector.New(p.screenWidth-PlayerRadius, p.screenHeight-PlayerRadius),
	)

	return nil
}

func (p *Player) handleInput() {
	p.moveUp = ebiten.IsKeyPressed(ebiten.KeyW) || ebiten.IsKeyPressed(ebiten.KeyArrowUp)
	p.moveDown = ebiten.IsKeyPressed(ebiten.KeyS) || ebiten.IsKeyPressed(ebiten.KeyArrowDown)
	p.moveLeft = ebiten.IsKeyPressed(ebiten.KeyA) || ebiten.IsKeyPressed(ebiten.KeyArrowLeft)
	p.moveRight = ebiten.IsKeyPressed(ebiten.KeyD) || ebiten.IsKeyPressed(ebiten.KeyArrowRight)
	p.firing = ebiten.IsKeyPressed(ebiten.KeySpace)
}

// Draw draws the player
func (p *Player) Draw(screen *ebiten.Image) {
	// Draw player ship as a simple circle for now
	x, y := float32(p.Position.X), float32(p.Position.Y)
	w := float32(p.Visual.Width / 2)

	// Draw simple representation
	img := ebiten.NewImage(int(w*2), int(w*2))
	img.Fill(p.Visual.Color)
	op := &ebiten.DrawImageOptions{}
	op.GeoM.Translate(float64(x-w), float64(y-w))
	screen.DrawImage(img, op)

	// Draw health bar
	p.drawHealthBar(screen)
}

func (p *Player) drawHealthBar(screen *ebiten.Image) {
	barWidth := 60.0
	barHeight := 5.0
	x := p.Position.X - barWidth/2
	y := p.Position.Y + p.Visual.Height/2 + 10

	// Background
	bgImg := ebiten.NewImage(int(barWidth), int(barHeight))
	bgImg.Fill(color.RGBA{R: 50, G: 50, B: 50, A: 255})
	bgOp := &ebiten.DrawImageOptions{}
	bgOp.GeoM.Translate(x, y)
	screen.DrawImage(bgImg, bgOp)

	// Health
	healthWidth := barWidth * p.Health.GetPercentage()

	// Only draw health bar if there's health remaining
	if healthWidth > 0 {
		healthColor := color.RGBA{R: 100, G: 255, B: 100, A: 255}
		if p.Health.GetPercentage() < 0.3 {
			healthColor = color.RGBA{R: 255, G: 100, B: 100, A: 255}
		} else if p.Health.GetPercentage() < 0.6 {
			healthColor = color.RGBA{R: 255, G: 255, B: 100, A: 255}
		}
		healthImg := ebiten.NewImage(int(healthWidth), int(barHeight))
		healthImg.Fill(healthColor)
		healthOp := &ebiten.DrawImageOptions{}
		healthOp.GeoM.Translate(x, y)
		screen.DrawImage(healthImg, healthOp)
	}
}

// IsFiring returns whether the player is firing
func (p *Player) IsFiring() bool {
	return p.firing && p.Weapon.CanFire()
}

// FireWeapon fires the weapon
func (p *Player) FireWeapon() {
	p.Weapon.Fire()
}

// OnCollision handles collision
func (p *Player) OnCollision(other Entity) {
	switch other.GetType() {
	case TypeEnemy:
		p.Health.Damage(10)
	case TypePowerUp:
		// Handle power-up
	}
}

// AddScore adds to the player's score
func (p *Player) AddScore(points int) {
	p.Score += points
}

// GetScore returns the current score
func (p *Player) GetScore() int {
	return p.Score
}
