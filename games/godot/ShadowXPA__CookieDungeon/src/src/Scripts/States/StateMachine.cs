using System.Collections.Immutable;
using CookieDungeon.Scripts.Movement;
using CookieDungeon.Scripts.Utils;
using Godot;

namespace CookieDungeon.Scripts.States;

[GlobalClass]
public partial class StateMachine : Node
{
    [Export]
    public State? InitialState { get; set; }
    public State? CurrentState { get; private set; }

    public ImmutableDictionary<string, State> States { get => _states.ToImmutableDictionary(); }
    private readonly Dictionary<string, State> _states = [];

    public Action<string, string>? StateChanged;

    public void Initialize(CharacterBody2D? subject = null)
    {
        var states = GetChildren();
        foreach (var state in states)
        {
            if (state is State s)
            {
                _states.Add(s.Name.ToString().ToLower(), s);
                s.Subject = subject;
            }
        }

        if (InitialState is not null)
            ChangeState(InitialState.Name);
    }

    public void ProcessInput(InputEvent @event)
    {
        var newState = CurrentState?.ProcessInput(@event);

        if (newState is not null)
            ChangeState(newState);
    }

    public void ProcessPhysics(double delta)
    {
        var newState = CurrentState?.ProcessPhysics(delta);

        if (newState is not null)
            ChangeState(newState);
    }

    public void ProcessFrame(double delta)
    {
        var newState = CurrentState?.ProcessFrame(delta);

        if (newState is not null)
            ChangeState(newState);
    }

    public void ChangeState(string state)
    {
        state = state.ToLower();
        var currentState = CurrentState?.Name.ToString().ToLower();

        var oldState = CurrentState;
        var hasState = _states.TryGetValue(state, out var newState);

        if (!hasState)
        {
            return;
        }

        CurrentState?.Exit();
        CurrentState = newState;
        CurrentState?.Enter();

        StateChanged?.Invoke(oldState?.Name ?? string.Empty, newState?.Name ?? string.Empty);
    }
}
