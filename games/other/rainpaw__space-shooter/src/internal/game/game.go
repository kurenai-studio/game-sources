package game

import (
	"fmt"
	"image/color"
	"math/rand"
	"time"

	"github.com/EchoSingh/space-shooter/internal/engine"
	"github.com/EchoSingh/space-shooter/internal/entities"
	"github.com/EchoSingh/space-shooter/internal/physics"
	"github.com/EchoSingh/space-shooter/internal/ui"
	"github.com/EchoSingh/space-shooter/pkg/vector"
	"github.com/hajimehoshi/ebiten/v2"
	"github.com/hajimehoshi/ebiten/v2/ebitenutil"
)

// Game represents the main game
type Game struct {
	screenWidth  int
	screenHeight int

	// State management
	stateManager *engine.StateManager

	// Game entities
	player    *entities.Player
	enemies   []*entities.Enemy
	bullets   []*entities.Bullet
	particles []*entities.Particle

	// Systems
	collisionSystem *physics.CollisionSystem
	ui              *ui.UI

	// Gameplay
	spawnTimer    float64
	spawnInterval float64
	difficulty    float64
	gameTime      float64

	// Background
	stars []Star
}

// Star represents a background star
type Star struct {
	X, Y  float64
	Speed float64
	Size  float64
	Color color.Color
}

// NewGame creates a new game instance
func NewGame(screenWidth, screenHeight int) (*Game, error) {

	g := &Game{
		screenWidth:     screenWidth,
		screenHeight:    screenHeight,
		stateManager:    engine.NewStateManager(),
		enemies:         make([]*entities.Enemy, 0, 50),
		bullets:         make([]*entities.Bullet, 0, 100),
		particles:       make([]*entities.Particle, 0, 200),
		collisionSystem: physics.NewCollisionSystem(),
		ui:              ui.NewUI(screenWidth, screenHeight),
		spawnInterval:   2.0,
		difficulty:      1.0,
	}

	// Initialize background stars
	g.initStars()

	return g, nil
}

func (g *Game) initStars() {
	g.stars = make([]Star, 100)
	for i := range g.stars {
		g.stars[i] = Star{
			X:     rand.Float64() * float64(g.screenWidth),
			Y:     rand.Float64() * float64(g.screenHeight),
			Speed: 20 + rand.Float64()*50,
			Size:  1 + rand.Float64()*2,
			Color: color.RGBA{R: 200, G: 200, B: 200, A: uint8(100 + rand.Intn(155))},
		}
	}
}

// startGame initializes a new game session
func (g *Game) startGame() {
	g.player = entities.NewPlayer(
		float64(g.screenWidth)/2,
		float64(g.screenHeight)-100,
		float64(g.screenWidth),
		float64(g.screenHeight),
	)

	g.enemies = g.enemies[:0]
	g.bullets = g.bullets[:0]
	g.particles = g.particles[:0]
	g.spawnTimer = 0
	g.difficulty = 1.0
	g.gameTime = 0

	g.stateManager.SetState(engine.StatePlaying)
}

// Update updates the game state
func (g *Game) Update() error {
	dt := 1.0 / 60.0 // Fixed timestep

	// Handle state-specific input
	g.handleInput()

	// Update based on state
	switch g.stateManager.GetState() {
	case engine.StateMenu:
		g.updateMenu(dt)
	case engine.StatePlaying:
		g.updatePlaying(dt)
	case engine.StatePaused:
		// No updates when paused
	case engine.StateGameOver:
		g.updateGameOver(dt)
	}

	return nil
}

func (g *Game) handleInput() {
	// Menu state
	if g.stateManager.IsMenu() {
		if ebiten.IsKeyPressed(ebiten.KeyEnter) {
			g.startGame()
		}
		if ebiten.IsKeyPressed(ebiten.KeyEscape) {
			return
		}
	}

	// Playing state
	if g.stateManager.IsPlaying() {
		if ebiten.IsKeyPressed(ebiten.KeyP) {
			time.Sleep(200 * time.Millisecond) // Simple debounce
			g.stateManager.TogglePause()
		}
		if ebiten.IsKeyPressed(ebiten.KeyEscape) {
			g.stateManager.SetState(engine.StateMenu)
		}
	}

	// Paused state
	if g.stateManager.IsPaused() {
		if ebiten.IsKeyPressed(ebiten.KeyP) {
			time.Sleep(200 * time.Millisecond)
			g.stateManager.TogglePause()
		}
	}

	// Game over state
	if g.stateManager.IsGameOver() {
		if ebiten.IsKeyPressed(ebiten.KeyEnter) {
			g.startGame()
		}
		if ebiten.IsKeyPressed(ebiten.KeyEscape) {
			g.stateManager.SetState(engine.StateMenu)
		}
	}
}

func (g *Game) updateMenu(dt float64) {
	g.updateStars(dt)
}

func (g *Game) updatePlaying(dt float64) {
	g.gameTime += dt

	// Update stars
	g.updateStars(dt)

	// Check game over first
	if g.player != nil && g.player.Health != nil && g.player.Health.IsDead() {
		g.stateManager.SetState(engine.StateGameOver)
		return
	}

	// Update player
	if g.player != nil {
		if err := g.player.Update(dt); err != nil {
			// Log error but continue game
			_ = err
		}
	}

	// Handle player firing
	if g.player.IsFiring() {
		g.spawnPlayerBullet()
		g.player.FireWeapon()
	}

	// Update enemies
	g.updateEnemies(dt)

	// Update bullets
	g.updateBullets(dt)

	// Update particles
	g.updateParticles(dt)

	// Spawn enemies
	g.updateSpawning(dt)

	// Check collisions
	g.checkCollisions()

	// Increase difficulty over time
	g.difficulty = 1.0 + g.gameTime/30.0
	g.spawnInterval = 2.0 / g.difficulty
}

func (g *Game) updateGameOver(dt float64) {
	g.updateStars(dt)
	g.updateParticles(dt)
}

func (g *Game) updateStars(dt float64) {
	for i := range g.stars {
		g.stars[i].Y += g.stars[i].Speed * dt
		if g.stars[i].Y > float64(g.screenHeight) {
			g.stars[i].Y = 0
			g.stars[i].X = rand.Float64() * float64(g.screenWidth)
		}
	}
}

func (g *Game) updateEnemies(dt float64) {
	for i := len(g.enemies) - 1; i >= 0; i-- {
		enemy := g.enemies[i]
		if !enemy.IsActive() {
			g.enemies = append(g.enemies[:i], g.enemies[i+1:]...)
			continue
		}
		_ = enemy.Update(dt)
	}
}

func (g *Game) updateBullets(dt float64) {
	for i := len(g.bullets) - 1; i >= 0; i-- {
		bullet := g.bullets[i]
		if !bullet.IsActive() {
			g.bullets = append(g.bullets[:i], g.bullets[i+1:]...)
			continue
		}
		_ = bullet.Update(dt)
	}
}

func (g *Game) updateParticles(dt float64) {
	for i := len(g.particles) - 1; i >= 0; i-- {
		particle := g.particles[i]
		if !particle.IsActive() {
			g.particles = append(g.particles[:i], g.particles[i+1:]...)
			continue
		}
		_ = particle.Update(dt)
	}
}

func (g *Game) updateSpawning(dt float64) {
	g.spawnTimer += dt
	if g.spawnTimer >= g.spawnInterval {
		g.spawnTimer = 0
		g.spawnEnemy()
	}
}

func (g *Game) spawnEnemy() {
	enemy := entities.SpawnRandom(float64(g.screenWidth), float64(g.screenHeight))
	g.enemies = append(g.enemies, enemy)
}

func (g *Game) spawnPlayerBullet() {
	pos := g.player.GetPosition()
	velocity := vector.New(0, -entities.PlayerBulletSpeed)

	bullet := entities.NewBullet(
		pos.X, pos.Y-20,
		velocity,
		entities.PlayerBulletDamage,
		entities.OwnerPlayer,
		float64(g.screenWidth),
		float64(g.screenHeight),
	)

	g.bullets = append(g.bullets, bullet)

	// Add trail particle
	trail := entities.CreateTrail(pos.X, pos.Y, velocity)
	g.particles = append(g.particles, trail)
}

func (g *Game) checkCollisions() {
	// Clear collision system
	g.collisionSystem.Clear()

	// Add all collidable entities
	g.collisionSystem.AddEntity(g.player)
	for _, enemy := range g.enemies {
		if enemy.IsActive() {
			g.collisionSystem.AddEntity(enemy)
		}
	}
	for _, bullet := range g.bullets {
		if bullet.IsActive() {
			g.collisionSystem.AddEntity(bullet)
		}
	}

	// Check collisions
	collisions := g.collisionSystem.CheckCollisions()

	// Handle collisions
	for _, collision := range collisions {
		g.handleCollision(collision.A, collision.B)
	}
}

func (g *Game) handleCollision(a, b entities.Entity) {
	// Safety check
	if a == nil || b == nil {
		return
	}

	// Bullet vs Enemy
	if a.GetType() == entities.TypeBullet && b.GetType() == entities.TypeEnemy {
		bullet := a.(*entities.Bullet)
		enemy := b.(*entities.Enemy)

		if bullet.GetOwner() == entities.OwnerPlayer {
			enemy.TakeDamage(bullet.GetDamage())
			bullet.SetActive(false)

			if !enemy.IsActive() && g.player != nil {
				g.player.AddScore(enemy.ScoreValue)
				g.spawnExplosion(enemy.GetPosition())
			}
		}
	} else if a.GetType() == entities.TypeEnemy && b.GetType() == entities.TypeBullet {
		g.handleCollision(b, a)
		return
	}

	// Player vs Enemy
	if a.GetType() == entities.TypePlayer && b.GetType() == entities.TypeEnemy {
		player := a.(*entities.Player)
		enemy := b.(*entities.Enemy)

		if player != nil && player.Health != nil {
			player.Health.Damage(20)
		}
		enemy.SetActive(false)
		g.spawnExplosion(enemy.GetPosition())
	} else if a.GetType() == entities.TypeEnemy && b.GetType() == entities.TypePlayer {
		g.handleCollision(b, a)
		return
	}
}

func (g *Game) spawnExplosion(pos vector.Vector2) {
	explosion := entities.CreateExplosion(pos.X, pos.Y, 20)
	g.particles = append(g.particles, explosion...)
}

// Draw draws the game
func (g *Game) Draw(screen *ebiten.Image) {
	// Clear screen
	screen.Fill(color.RGBA{R: 10, G: 10, B: 20, A: 255})

	// Draw stars
	g.drawStars(screen)

	// Draw based on state
	switch g.stateManager.GetState() {
	case engine.StateMenu:
		g.ui.DrawMenu(screen)
	case engine.StatePlaying:
		g.drawGame(screen)
	case engine.StatePaused:
		g.drawGame(screen)
		g.ui.DrawPauseMenu(screen)
	case engine.StateGameOver:
		g.drawGame(screen)
		g.ui.DrawGameOver(screen, g.player.GetScore())
	}
}

func (g *Game) drawStars(screen *ebiten.Image) {
	for _, star := range g.stars {
		img := ebiten.NewImage(int(star.Size), int(star.Size))
		img.Fill(star.Color)
		op := &ebiten.DrawImageOptions{}
		op.GeoM.Translate(star.X, star.Y)
		screen.DrawImage(img, op)
	}
}

func (g *Game) drawGame(screen *ebiten.Image) {
	// Draw particles (behind)
	for _, particle := range g.particles {
		if particle.IsActive() {
			particle.Draw(screen)
		}
	}

	// Draw bullets
	for _, bullet := range g.bullets {
		if bullet.IsActive() {
			bullet.Draw(screen)
		}
	}

	// Draw enemies
	for _, enemy := range g.enemies {
		if enemy.IsActive() {
			enemy.Draw(screen)
		}
	}

	// Draw player
	if g.player != nil && g.player.IsActive() {
		g.player.Draw(screen)
	}

	// Draw HUD
	if g.player != nil {
		g.ui.DrawHUD(screen, g.player.GetScore(), g.player.Health.Current)
	}

	// Draw debug info
	g.drawDebug(screen)
}

func (g *Game) drawDebug(screen *ebiten.Image) {
	debug := fmt.Sprintf("Enemies: %d | Bullets: %d | Particles: %d",
		len(g.enemies), len(g.bullets), len(g.particles))
	ebitenutil.DebugPrint(screen, debug)
}

// Layout returns the game's screen size
func (g *Game) Layout(outsideWidth, outsideHeight int) (int, int) {
	return g.screenWidth, g.screenHeight
}
