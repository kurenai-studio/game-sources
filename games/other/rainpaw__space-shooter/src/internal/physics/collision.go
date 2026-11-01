package physics

import (
	"github.com/EchoSingh/space-shooter/internal/entities"
)

// CollisionSystem handles collision detection
type CollisionSystem struct {
	entities []entities.Entity
}

// NewCollisionSystem creates a new collision system
func NewCollisionSystem() *CollisionSystem {
	return &CollisionSystem{
		entities: make([]entities.Entity, 0, 100),
	}
}

// AddEntity adds an entity to collision detection
func (cs *CollisionSystem) AddEntity(entity entities.Entity) {
	cs.entities = append(cs.entities, entity)
}

// Clear clears all entities
func (cs *CollisionSystem) Clear() {
	cs.entities = cs.entities[:0]
}

// CheckCollisions checks all collisions
func (cs *CollisionSystem) CheckCollisions() []CollisionPair {
	collisions := make([]CollisionPair, 0)

	for i := 0; i < len(cs.entities); i++ {
		if !cs.entities[i].IsActive() {
			continue
		}

		for j := i + 1; j < len(cs.entities); j++ {
			if !cs.entities[j].IsActive() {
				continue
			}

			if cs.checkCollision(cs.entities[i], cs.entities[j]) {
				collisions = append(collisions, CollisionPair{
					A: cs.entities[i],
					B: cs.entities[j],
				})
			}
		}
	}

	return collisions
}

// checkCollision checks if two entities collide (circle collision)
func (cs *CollisionSystem) checkCollision(a, b entities.Entity) bool {
	// Skip collision between same types in some cases
	if !cs.shouldCollide(a, b) {
		return false
	}

	// Circle-circle collision
	distance := a.GetPosition().DistanceSquared(b.GetPosition())
	radiusSum := a.GetRadius() + b.GetRadius()

	return distance <= radiusSum*radiusSum
}

// shouldCollide determines if two entities should collide
func (cs *CollisionSystem) shouldCollide(a, b entities.Entity) bool {
	typeA := a.GetType()
	typeB := b.GetType()

	// Player bullets don't collide with player
	if typeA == entities.TypePlayer && typeB == entities.TypeBullet {
		return false
	}
	if typeA == entities.TypeBullet && typeB == entities.TypePlayer {
		return false
	}

	// Bullets don't collide with each other
	if typeA == entities.TypeBullet && typeB == entities.TypeBullet {
		return false
	}

	// Particles don't collide
	if typeA == entities.TypeParticle || typeB == entities.TypeParticle {
		return false
	}

	// Enemies don't collide with each other
	if typeA == entities.TypeEnemy && typeB == entities.TypeEnemy {
		return false
	}

	return true
}

// CollisionPair represents a collision between two entities
type CollisionPair struct {
	A entities.Entity
	B entities.Entity
}
