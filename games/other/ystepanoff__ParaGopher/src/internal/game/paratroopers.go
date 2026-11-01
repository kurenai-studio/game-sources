package game

import (
	"math"
	"time"

	"github.com/hajimehoshi/ebiten/v2"
	"github.com/ystepanoff/paragopher/internal/audio"
	"github.com/ystepanoff/paragopher/internal/config"
	"github.com/ystepanoff/paragopher/internal/utils"
)

type Paratrooper struct {
	x, y        float32
	parachute   bool
	landed      bool
	walking     bool
	falling     bool
	fellAt      time.Time
	over, under *Paratrooper
}

func (g *Game) drawParatrooper(screen *ebiten.Image, p *Paratrooper) {
	image := g.paratrooperImage
	if p.landed || !p.parachute {
		if p.landed && p.falling {
			image = g.paratrooperFellImage
		} else {
			image = g.paratrooperLandedImage
		}
	}
	op := &ebiten.DrawImageOptions{}
	dx := float64(image.Bounds().Dx())
	dy := float64(image.Bounds().Dy())
	op.GeoM.Translate(float64(p.x)-dx/2.0, float64(p.y)-dy/2.0)
	screen.DrawImage(image, op)
}

func (g *Game) drawParatroopers(screen *ebiten.Image) {
	for _, p := range g.paratroopers {
		if p.landed && p.falling {
			g.drawParatrooper(screen, p)
		}
	}
	for _, p := range g.paratroopers {
		if !p.landed || !p.falling {
			g.drawParatrooper(screen, p)
		}
	}
}

func (g *Game) spawnParatrooper(x, y float32) {
	g.paratroopers = append(g.paratroopers, &Paratrooper{
		x:         x,
		y:         y,
		parachute: true,
	})
}

func (g *Game) updateParatroopers() {
	updated := make([]*Paratrooper, 0, len(g.paratroopers))
	for _, p := range g.paratroopers {
		if !p.landed {
			p.y += config.ParatrooperFallSpeed
			if p.falling {
				p.y += config.ParatrooperFallSpeed
			}
			dy := float32(g.paratrooperLandedImage.Bounds().Dy()) / 2.0
			if p.y >= config.GroundY-dy {
				p.y = config.GroundY - dy
				p.landed = true
				p.walking = true
				p.parachute = false
				p.fellAt = time.Now()
			}
		} else {
			if p.falling && p.landed {
				if time.Since(p.fellAt).Seconds() > 3 {
					continue
				}
			} else {
				g.walk(p)
			}
		}
		updated = append(updated, p)
	}
	g.paratroopers = updated
}

func (g *Game) walk(p *Paratrooper) {
	if g.showGameOverDialog {
		return
	}
	vx := float32(config.ParatrooperWalkSpeed)
	baseX := (config.ScreenWidth - config.BaseWidth) / 2
	if p.x > float32(config.ScreenWidth)/2.0 {
		vx = -vx
	}
	newX := p.x + vx
	if utils.Overlap1D(
		newX-config.ParatrooperWidth/2.0,
		config.ParatrooperWidth,
		baseX,
		config.BaseWidth,
	) {
		if p.y >= config.ScreenHeight-config.BaseHeight {
			p.walking = false
			return
		} else {
			pinkBaseX := (float32(config.ScreenWidth) - config.BaseWidth/3.0) / 2.0
			pinkBaseW := config.BaseWidth / 3
			if utils.Overlap1D(p.x-config.ParatrooperWidth/2.0, config.ParatrooperWidth, pinkBaseX, pinkBaseW) {
				audio.Play(g.soundProfile.GameOverPlayer)
				g.showGameOverDialog = true
			}
		}
	}
	for _, q := range g.paratroopers {
		if (math.Abs(float64(q.x-p.x)) < 1e-6 &&
			math.Abs(float64(q.y-p.y)) < 1e-6) ||
			!q.landed ||
			q.walking {
			continue
		}
		if utils.Overlap1D(
			newX-config.ParatrooperWidth/2.0,
			config.ParatrooperWidth,
			q.x-config.ParatrooperWidth/2.0,
			config.ParatrooperWidth,
		) && math.Abs(float64(p.y-q.y)) < 1e-6 {
			if q.over == nil {
				p.x = q.x
				p.y = q.y - config.ParatrooperHeight
				q.over = p
				if p.under != nil {
					p.under.over = nil
				}
				p.under = q
			} else {
				p.walking = false
			}
			return
		}
	}
	p.x = newX
}
