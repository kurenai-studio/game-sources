using CookieDungeon.Scripts.Characters.Enemy;
using CookieDungeon.Scripts.Characters.Player;
using CookieDungeon.Scripts.Utils;
using Godot;
using Godot.Collections;

namespace CookieDungeon.Scripts.Objects;

public partial class Door : StaticBody2D
{
	[Export]
	public Marker2D? Target { get; private set; }
	[Export]
	public string DefaultLabel { get; private set; } = string.Empty;
	[Export]
	public State InitialState { get; private set; }
	[Export]
	public Node? EnemyContainer { get; private set; }

	private AnimatedSprite2D? _sprite;
	private Marker2D? _marker;
	private Area2D? _interaction;
	private Label? _doorLabel;
	private State _state;

	public override void _Ready()
	{
		_sprite = GetNode<AnimatedSprite2D>("%Sprite");
		_marker = GetNode<Marker2D>("%Marker");
		_interaction = GetNode<Area2D>("%Interaction");
		_doorLabel = GetNode<Label>("%DoorLabel");

		_doorLabel.Text = DefaultLabel;
		SetState(InitialState);

		_interaction.BodyEntered += OnPlayerEnter;
		_interaction.BodyExited += OnPlayerExit;
		SignalBus.MonsterKilled += MonsterKilled;
	}

	public override void _ExitTree()
	{
		if (_interaction is not null)
		{
			_interaction.BodyEntered -= OnPlayerEnter;
			_interaction.BodyExited -= OnPlayerExit;
		}

		SignalBus.MonsterKilled -= MonsterKilled;
	}

	public void SetState(State state)
	{
		_state = state;

		if (state == State.Locked)
		{
			_sprite?.Play("locked");
		}
		else
		{
			_sprite?.Play("unlocked");
		}
	}

	private void OnPlayerEnter(Node2D body)
	{
		if (_doorLabel is null || body is not Player player) return;

		if (_state == State.Locked)
		{
			_doorLabel.Text = "Locked";
		}
		else
		{
			player.SetTeleportTarget(Target);
			_doorLabel.Text = "Press F to enter";
			_sprite?.Play("open");
		}
	}

	private void OnPlayerExit(Node2D body)
	{
		if (_doorLabel is null || body is not Player player) return;

		player.SetTeleportTarget(null);
		_doorLabel.Text = DefaultLabel;

		if (_state != State.Unlocked) return;
		_sprite?.Play("unlocked");
	}

	private void MonsterKilled(int experience)
	{
		if (EnemyContainer is null) return;

		foreach (var enemy in EnemyContainer.GetChildren().Cast<Enemy>())
		{
			if (!enemy.IsDead) return;
		}

		SetState(State.Unlocked);
	}

	public enum State
	{
		Locked,
		Unlocked
	}
}
