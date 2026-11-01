package pool

import "sync"

// Pool is a generic object pool
type Pool[T any] struct {
	pool    sync.Pool
	factory func() T
	reset   func(*T)
}

// NewPool creates a new object pool
func NewPool[T any](factory func() T, reset func(*T)) *Pool[T] {
	p := &Pool[T]{
		factory: factory,
		reset:   reset,
	}
	p.pool.New = func() interface{} {
		return factory()
	}
	return p
}

// Get retrieves an object from the pool
func (p *Pool[T]) Get() T {
	return p.pool.Get().(T)
}

// Put returns an object to the pool
func (p *Pool[T]) Put(obj T) {
	if p.reset != nil {
		p.reset(&obj)
	}
	p.pool.Put(obj)
}
