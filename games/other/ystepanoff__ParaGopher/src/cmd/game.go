package main

import (
	"log"
	"os"

	"github.com/hajimehoshi/ebiten/v2"
	"github.com/ystepanoff/paragopher/internal/config"
	"github.com/ystepanoff/paragopher/internal/game"
)

func main() {
	ebiten.SetWindowSize(config.ScreenWidth, config.ScreenHeight)
	ebiten.SetWindowTitle("ParaGopher")
	ebiten.SetTPS(120)

	g := game.NewGame()
	if err := ebiten.RunGame(g); err != nil {
		if err == config.ErrQuit {
			os.Exit(0)
		}
		log.Fatal(err)
	}
}
