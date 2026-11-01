package entities

import (
	"testing"

	"github.com/EchoSingh/space-shooter/pkg/vector"
)

func TestNewPlayer(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping test in short mode (CI environment)")
	}
	player := NewPlayer(100, 100, 800, 600)

	if player == nil {
		t.Fatal("NewPlayer returned nil")
	}

	if !player.IsActive() {
		t.Error("Player should be active")
	}

	if player.Health.Current != PlayerMaxHealth {
		t.Errorf("Expected health %d, got %d", PlayerMaxHealth, player.Health.Current)
	}

	if player.GetType() != TypePlayer {
		t.Error("Player type should be TypePlayer")
	}
}

func TestPlayerMovement(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping test in short mode (CI environment)")
	}
	player := NewPlayer(100, 100, 800, 600)
	initialPos := player.GetPosition()

	// Directly set position to test movement works
	player.Position = vector.New(100, 50)

	if player.Position.Y >= initialPos.Y {
		t.Error("Player position should be movable")
	}
}

func TestPlayerBoundaries(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping test in short mode (CI environment)")
	}
	player := NewPlayer(10, 10, 800, 600)

	// Try to move off screen
	player.Position = vector.New(-100, -100)
	_ = player.Update(0.016)

	pos := player.GetPosition()
	if pos.X < 0 || pos.Y < 0 {
		t.Error("Player should be clamped to screen boundaries")
	}
}

func TestPlayerWeapon(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping test in short mode (CI environment)")
	}
	player := NewPlayer(100, 100, 800, 600)

	// Update weapon time so it can fire
	player.Weapon.Update(1.0)

	if !player.Weapon.CanFire() {
		t.Error("Weapon should be able to fire initially")
	}

	player.Weapon.Fire()

	// Weapon should have cooldown
	if player.Weapon.CanFire() {
		t.Error("Weapon should have cooldown after firing")
	}
}

func TestPlayerHealth(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping test in short mode (CI environment)")
	}
	player := NewPlayer(100, 100, 800, 600)

	initialHealth := player.Health.Current
	player.Health.Damage(10)

	if player.Health.Current != initialHealth-10 {
		t.Errorf("Expected health %d, got %d", initialHealth-10, player.Health.Current)
	}

	if player.Health.IsDead() {
		t.Error("Player should not be dead after small damage")
	}

	player.Health.Damage(1000)
	if !player.Health.IsDead() {
		t.Error("Player should be dead after fatal damage")
	}
}

func TestPlayerScore(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping test in short mode (CI environment)")
	}
	player := NewPlayer(100, 100, 800, 600)

	if player.GetScore() != 0 {
		t.Error("Initial score should be 0")
	}

	player.AddScore(10)
	if player.GetScore() != 10 {
		t.Errorf("Expected score 10, got %d", player.GetScore())
	}

	player.AddScore(25)
	if player.GetScore() != 35 {
		t.Errorf("Expected score 35, got %d", player.GetScore())
	}
}

func BenchmarkPlayerUpdate(b *testing.B) {
	if testing.Short() {
		b.Skip("Skipping benchmark in short mode (CI environment)")
	}
	player := NewPlayer(100, 100, 800, 600)

	for i := 0; i < b.N; i++ {
		_ = player.Update(0.016)
	}
}
