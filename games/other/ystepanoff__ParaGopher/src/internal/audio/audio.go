package audio

import (
	"bytes"
	"log"

	"github.com/hajimehoshi/ebiten/v2/audio"
	"github.com/hajimehoshi/ebiten/v2/audio/vorbis"
	"github.com/ystepanoff/paragopher/resources"
)

const sampleRate = 32000

type SoundProfile struct {
	ctx            *audio.Context
	IntroPlayer    *audio.Player
	ShootPlayer    *audio.Player
	HitPlayer      *audio.Player
	GameOverPlayer *audio.Player
}

func getPlayer(ctx *audio.Context, soundBytes []byte) *audio.Player {
	decoded, err := vorbis.DecodeWithSampleRate(
		sampleRate,
		bytes.NewReader(soundBytes),
	)
	if err != nil {
		log.Fatalf("Failed to decode OGG: %v", err)
	}
	player, err := ctx.NewPlayer(decoded)
	if err != nil {
		log.Fatalf("Failed to create player: %v", err)
	}
	return player
}

func NewSoundProfile() *SoundProfile {
	ctx := audio.NewContext(sampleRate)
	return &SoundProfile{
		ctx:            ctx,
		IntroPlayer:    getPlayer(ctx, resources.IntroSoundBytes),
		ShootPlayer:    getPlayer(ctx, resources.ShootSoundBytes),
		HitPlayer:      getPlayer(ctx, resources.HitSoundBytes),
		GameOverPlayer: getPlayer(ctx, resources.GameOverSoundBytes),
	}
}

func Play(player *audio.Player) {
	if err := player.Rewind(); err != nil {
		log.Fatalf("Failed to rewind audio player: %v", err)
	}
	player.Play()
}
