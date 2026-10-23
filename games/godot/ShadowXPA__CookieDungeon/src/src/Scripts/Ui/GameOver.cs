using CookieDungeon.Scripts.Utils;
using Godot;

namespace CookieDungeon.Scripts.Ui;

public partial class GameOver : Control
{
	private static GameOver? Instance;

	private Button? _restart;
	private Button? _quit;

	public override void _EnterTree()
	{
		Instance = this;
		_restart = GetNode<Button>("%Restart");
		_quit = GetNode<Button>("%Quit");

		_restart.Pressed += OnRestart;
		_quit.Pressed += OnQuit;
		SignalBus.PlayerDied += OnPlayerDied;
	}

	public override void _ExitTree()
	{
		if (_restart is not null)
			_restart.Pressed -= OnRestart;
		if (_quit is not null)
			_quit.Pressed -= OnQuit;
		SignalBus.PlayerDied -= OnPlayerDied;
	}

	private void _Pause(bool paused)
	{
		Engine.TimeScale = paused ? 0.25 : 1;
		if (paused)
			Instance?.Show();
		else
			Instance?.Hide();
	}

	private void OnPlayerDied()
	{
		_Pause(true);
	}

	private void OnRestart()
	{
		_Pause(false);
		GetTree().ReloadCurrentScene();
	}

	private void OnQuit()
	{
		GetTree().Quit();
	}
}
