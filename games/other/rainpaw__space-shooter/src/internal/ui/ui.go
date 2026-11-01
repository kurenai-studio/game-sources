package ui

import (
	"fmt"
	"image/color"

	"github.com/hajimehoshi/ebiten/v2"
	"github.com/hajimehoshi/ebiten/v2/ebitenutil"
)

// UI handles all UI rendering
type UI struct {
	screenWidth  int
	screenHeight int
}

// NewUI creates a new UI manager
func NewUI(screenWidth, screenHeight int) *UI {
	return &UI{
		screenWidth:  screenWidth,
		screenHeight: screenHeight,
	}
}

// DrawHUD draws the game HUD
func (u *UI) DrawHUD(screen *ebiten.Image, score, health int) {
	// Score
	scoreText := fmt.Sprintf("SCORE: %d", score)
	ebitenutil.DebugPrintAt(screen, scoreText, 10, 10)

	// Health
	healthText := fmt.Sprintf("HEALTH: %d", health)
	ebitenutil.DebugPrintAt(screen, healthText, 10, 25)

	// FPS
	fpsText := fmt.Sprintf("FPS: %.0f", ebiten.ActualFPS())
	ebitenutil.DebugPrintAt(screen, fpsText, u.screenWidth-100, 10)
}

// DrawMenu draws the main menu
func (u *UI) DrawMenu(screen *ebiten.Image) {
	centerX := u.screenWidth / 2
	centerY := u.screenHeight / 2

	// Title
	ebitenutil.DebugPrintAt(screen, "SPACE SHOOTER", centerX-70, centerY-80)

	// Instructions
	ebitenutil.DebugPrintAt(screen, "WASD or Arrow Keys to Move", centerX-100, centerY-20)
	ebitenutil.DebugPrintAt(screen, "SPACE to Fire", centerX-60, centerY)
	ebitenutil.DebugPrintAt(screen, "P to Pause", centerX-50, centerY+20)
	ebitenutil.DebugPrintAt(screen, "Press ENTER to Start", centerX-80, centerY+60)
	ebitenutil.DebugPrintAt(screen, "Press ESC to Quit", centerX-70, centerY+80)
}

// DrawPauseMenu draws the pause menu
func (u *UI) DrawPauseMenu(screen *ebiten.Image) {
	centerX := u.screenWidth / 2
	centerY := u.screenHeight / 2

	// Semi-transparent overlay
	overlay := ebiten.NewImage(u.screenWidth, u.screenHeight)
	overlay.Fill(color.RGBA{R: 0, G: 0, B: 0, A: 128})
	screen.DrawImage(overlay, nil)

	// Pause text and instruction
	ebitenutil.DebugPrintAt(screen, "PAUSED", centerX-30, centerY-20)
	ebitenutil.DebugPrintAt(screen, "Press P to Resume", centerX-70, centerY+20)
}

// DrawGameOver draws the game over screen
func (u *UI) DrawGameOver(screen *ebiten.Image, score int) {
	centerX := u.screenWidth / 2
	centerY := u.screenHeight / 2

	// Semi-transparent overlay
	overlay := ebiten.NewImage(u.screenWidth, u.screenHeight)
	overlay.Fill(color.RGBA{R: 0, G: 0, B: 0, A: 128})
	screen.DrawImage(overlay, nil)

	// Game Over text and score
	ebitenutil.DebugPrintAt(screen, "GAME OVER", centerX-45, centerY-40)
	scoreText := fmt.Sprintf("Final Score: %d", score)
	ebitenutil.DebugPrintAt(screen, scoreText, centerX-60, centerY)
	ebitenutil.DebugPrintAt(screen, "Press ENTER to Restart", centerX-90, centerY+40)
	ebitenutil.DebugPrintAt(screen, "Press ESC for Menu", centerX-75, centerY+60)
}
