package entities

import (
	"image/color"

	"github.com/EchoSingh/space-shooter/pkg/vector"
)

// EntityType represents the type of entity
type EntityType int

const (
	TypePlayer EntityType = iota
	TypeEnemy
	TypeBullet
	TypePowerUp
	TypeParticle
)

// Entity is the base interface for all game entities
type Entity interface {
	Update(dt float64) error
	GetPosition() vector.Vector2
	GetVelocity() vector.Vector2
	IsActive() bool
	SetActive(bool)
	GetType() EntityType
	GetRadius() float64
}

// BaseEntity provides common entity functionality
type BaseEntity struct {
	Position vector.Vector2
	Velocity vector.Vector2
	Active   bool
	Type     EntityType
	Radius   float64
}

func (e *BaseEntity) GetPosition() vector.Vector2 {
	return e.Position
}

func (e *BaseEntity) GetVelocity() vector.Vector2 {
	return e.Velocity
}

func (e *BaseEntity) IsActive() bool {
	return e.Active
}

func (e *BaseEntity) SetActive(active bool) {
	e.Active = active
}

func (e *BaseEntity) GetType() EntityType {
	return e.Type
}

func (e *BaseEntity) GetRadius() float64 {
	return e.Radius
}

// Drawable is an interface for entities that can be drawn
type Drawable interface {
	Entity
	Draw(screen interface{})
}

// Collidable is an interface for entities that can collide
type Collidable interface {
	Entity
	OnCollision(other Entity)
}

// Health component for entities with health
type Health struct {
	Current int
	Maximum int
}

func NewHealth(max int) *Health {
	return &Health{
		Current: max,
		Maximum: max,
	}
}

func (h *Health) Damage(amount int) {
	h.Current -= amount
	if h.Current < 0 {
		h.Current = 0
	}
}

func (h *Health) Heal(amount int) {
	h.Current += amount
	if h.Current > h.Maximum {
		h.Current = h.Maximum
	}
}

func (h *Health) IsDead() bool {
	return h.Current <= 0
}

func (h *Health) GetPercentage() float64 {
	if h.Maximum == 0 {
		return 0
	}
	return float64(h.Current) / float64(h.Maximum)
}

// Visual component for rendering
type Visual struct {
	Color  color.Color
	Width  float64
	Height float64
	Angle  float64
}

// Weapon component
type Weapon struct {
	Damage         int
	FireRate       float64
	BulletSpeed    float64
	LastFireTime   float64
	CurrentTime    float64
	ProjectileType ProjectileType
}

type ProjectileType int

const (
	ProjectileNormal ProjectileType = iota
	ProjectileLaser
	ProjectileMissile
	ProjectileSpread
)

func (w *Weapon) CanFire() bool {
	return w.CurrentTime-w.LastFireTime >= w.FireRate
}

func (w *Weapon) Fire() {
	w.LastFireTime = w.CurrentTime
}

func (w *Weapon) Update(dt float64) {
	w.CurrentTime += dt
}
