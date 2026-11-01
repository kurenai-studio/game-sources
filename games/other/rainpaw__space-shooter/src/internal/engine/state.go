package engine

// GameState represents the current state of the game
type GameState int

const (
	StateMenu GameState = iota
	StatePlaying
	StatePaused
	StateGameOver
)

// StateManager manages game states
type StateManager struct {
	currentState  GameState
	previousState GameState
}

// NewStateManager creates a new state manager
func NewStateManager() *StateManager {
	return &StateManager{
		currentState:  StateMenu,
		previousState: StateMenu,
	}
}

// GetState returns the current state
func (sm *StateManager) GetState() GameState {
	return sm.currentState
}

// SetState sets the current state
func (sm *StateManager) SetState(state GameState) {
	sm.previousState = sm.currentState
	sm.currentState = state
}

// GetPreviousState returns the previous state
func (sm *StateManager) GetPreviousState() GameState {
	return sm.previousState
}

// IsPlaying returns true if the game is in playing state
func (sm *StateManager) IsPlaying() bool {
	return sm.currentState == StatePlaying
}

// IsPaused returns true if the game is paused
func (sm *StateManager) IsPaused() bool {
	return sm.currentState == StatePaused
}

// IsGameOver returns true if game is over
func (sm *StateManager) IsGameOver() bool {
	return sm.currentState == StateGameOver
}

// IsMenu returns true if in menu
func (sm *StateManager) IsMenu() bool {
	return sm.currentState == StateMenu
}

// TogglePause toggles between playing and paused
func (sm *StateManager) TogglePause() {
	if sm.currentState == StatePlaying {
		sm.SetState(StatePaused)
	} else if sm.currentState == StatePaused {
		sm.SetState(StatePlaying)
	}
}
