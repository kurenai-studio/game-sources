package physics

import (
	"testing"

	"github.com/EchoSingh/space-shooter/internal/entities"
	"github.com/EchoSingh/space-shooter/pkg/vector"
)

func TestNewCollisionSystem(t *testing.T) {
	cs := NewCollisionSystem()

	if cs == nil {
		t.Fatal("NewCollisionSystem returned nil")
	}
}

func TestAddEntity(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping test in short mode (CI environment)")
	}
	cs := NewCollisionSystem()
	player := entities.NewPlayer(100, 100, 800, 600)

	cs.AddEntity(player)

	if len(cs.entities) != 1 {
		t.Errorf("Expected 1 entity, got %d", len(cs.entities))
	}
}

func TestClear(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping test in short mode (CI environment)")
	}
	cs := NewCollisionSystem()
	player := entities.NewPlayer(100, 100, 800, 600)

	cs.AddEntity(player)
	cs.Clear()

	if len(cs.entities) != 0 {
		t.Errorf("Expected 0 entities after clear, got %d", len(cs.entities))
	}
}

func TestCollisionDetection(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping test in short mode (CI environment)")
	}
	cs := NewCollisionSystem()

	// Create two entities that should collide
	player := entities.NewPlayer(100, 100, 800, 600)
	enemy := entities.NewEnemy(entities.EnemyBasic, 105, 105, 800, 600)

	cs.AddEntity(player)
	cs.AddEntity(enemy)

	collisions := cs.CheckCollisions()

	if len(collisions) == 0 {
		t.Error("Expected collision between player and enemy")
	}
}

func TestNoCollisionWhenFarApart(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping test in short mode (CI environment)")
	}
	cs := NewCollisionSystem()

	player := entities.NewPlayer(100, 100, 800, 600)
	enemy := entities.NewEnemy(entities.EnemyBasic, 500, 500, 800, 600)

	cs.AddEntity(player)
	cs.AddEntity(enemy)

	collisions := cs.CheckCollisions()

	if len(collisions) > 0 {
		t.Error("No collision expected when entities are far apart")
	}
}

func TestBulletPlayerNoCollision(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping test in short mode (CI environment)")
	}
	cs := NewCollisionSystem()

	player := entities.NewPlayer(100, 100, 800, 600)
	bullet := entities.NewBullet(100, 100, vector.Zero(), 10, entities.OwnerPlayer, 800, 600)

	cs.AddEntity(player)
	cs.AddEntity(bullet)

	collisions := cs.CheckCollisions()

	if len(collisions) > 0 {
		t.Error("Player bullets should not collide with player")
	}
}

func TestInactiveEntityNoCollision(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping test in short mode (CI environment)")
	}
	cs := NewCollisionSystem()

	player := entities.NewPlayer(100, 100, 800, 600)
	enemy := entities.NewEnemy(entities.EnemyBasic, 105, 105, 800, 600)
	enemy.SetActive(false)

	cs.AddEntity(player)
	cs.AddEntity(enemy)

	collisions := cs.CheckCollisions()

	if len(collisions) > 0 {
		t.Error("Inactive entities should not collide")
	}
}

func BenchmarkCollisionDetection(b *testing.B) {
	if testing.Short() {
		b.Skip("Skipping benchmark in short mode (CI environment)")
	}
	cs := NewCollisionSystem()

	// Add many entities
	for i := 0; i < 50; i++ {
		enemy := entities.NewEnemy(entities.EnemyBasic, float64(i*10), float64(i*10), 800, 600)
		cs.AddEntity(enemy)
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		cs.CheckCollisions()
	}
}
