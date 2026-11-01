package main

import (
	"log"

	"github.com/EchoSingh/space-shooter/internal/game"
	"github.com/hajimehoshi/ebiten/v2"
)

const (
	screenWidth  = 800
	screenHeight = 600
	gameTitle    = "Space Shooter"
)

func main() {
	// Initialize the game
	g, err := game.NewGame(screenWidth, screenHeight)
	if err != nil {
		log.Fatalf("Failed to initialize game: %v", err)
	}

	// Set window properties
	ebiten.SetWindowSize(screenWidth, screenHeight)
	ebiten.SetWindowTitle(gameTitle)
	ebiten.SetWindowResizingMode(ebiten.WindowResizingModeEnabled)

	// Run the game
	if err := ebiten.RunGame(g); err != nil {
		log.Fatalf("Game error: %v", err)
	}
}
