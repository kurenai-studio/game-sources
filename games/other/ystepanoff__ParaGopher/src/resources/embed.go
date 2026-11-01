package resources

import _ "embed"

//go:embed audio/intro.ogg
var IntroSoundBytes []byte

//go:embed audio/shoot.ogg
var ShootSoundBytes []byte

//go:embed audio/hit.ogg
var HitSoundBytes []byte

//go:embed audio/gameover.ogg
var GameOverSoundBytes []byte
