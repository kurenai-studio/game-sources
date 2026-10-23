using CookieDungeon.Scripts.Characters;
using CookieDungeon.Scripts.Utils;
using Godot;

namespace CookieDungeon.Scripts.Ui;

public partial class Pause : Control
{
	private static Pause? Instance; // ???? I need this because Show and Hide give an exception when reloading the scene... okay?

	private Button? _resume;
	private Button? _restart;
	private Button? _quit;

	private Label? _maxHp;
	private Label? _maxMp;
	private Label? _atk;
	private Label? _def;
	private Label? _spd;
	private Label? _cr;
	private Label? _cdmg;
	private Label? _exp;
	private Label? _hpR;
	private Label? _mpR;

	public override void _EnterTree()
	{
		Instance = this;
		_resume = GetNode<Button>("%Resume");
		_restart = GetNode<Button>("%Restart");
		_quit = GetNode<Button>("%Quit");
		_maxHp = GetNode<Label>("%MaxHP");
		_maxMp = GetNode<Label>("%MaxMP");
		_atk = GetNode<Label>("%Atk");
		_def = GetNode<Label>("%Def");
		_spd = GetNode<Label>("%Spd");
		_cr = GetNode<Label>("%CR");
		_cdmg = GetNode<Label>("%CDmg");
		_exp = GetNode<Label>("%Exp");
		_hpR = GetNode<Label>("%HPRegen");
		_mpR = GetNode<Label>("%MPRegen");

		_resume.Pressed += OnResume;
		_restart.Pressed += OnRestart;
		_quit.Pressed += OnQuit;
		SignalBus.Paused += OnPause;
	}

	public override void _ExitTree()
	{
		if (_resume is not null)
			_resume.Pressed -= OnResume;
		if (_restart is not null)
			_restart.Pressed -= OnRestart;
		if (_quit is not null)
			_quit.Pressed -= OnQuit;
	}

	private void OnPause(Stats stats)
	{
		_Pause(true);
		if (Instance is null) return;

		if (Instance._maxHp is not null)
			Instance._maxHp.Text = $"Max HP: {stats.MaxHealth}";
		if (Instance._maxMp is not null)
			Instance._maxMp.Text = $"Max MP: {stats.MaxMana}";
		if (Instance._atk is not null)
			Instance._atk.Text = $"Attack: {stats.Attack}";
		if (Instance._def is not null)
			Instance._def.Text = $"Defense: {stats.Defense}";
		if (Instance._spd is not null)
			Instance._spd.Text = $"Speed: {stats.Speed}";
		if (Instance._cr is not null)
			Instance._cr.Text = $"Crit Rate: {stats.CriticalRate}";
		if (Instance._cdmg is not null)
			Instance._cdmg.Text = $"Crit Damage: {stats.CriticalDamage}";
		if (Instance._exp is not null)
			Instance._exp.Text = $"Experience: {stats.Experience}";
		if (Instance._hpR is not null)
			Instance._hpR.Text = $"HP Regen: {stats.HealthRate}/2.5 sec -- Idle: {stats.HealthRate * 2}/2.5 sec";
		if (Instance._mpR is not null)
			Instance._mpR.Text = $"MP Regen: Moving: {stats.ManaRate}/2.5 sec -- Idle: {stats.ManaRate * 2}/2.5 sec";
	}

	private void OnResume()
	{
		_Pause(false);
		SignalBus.BroadcastUnpaused();
	}

	private void _Pause(bool paused)
	{
		Engine.TimeScale = paused ? 0 : 1;
		if (paused)
			Instance?.Show();
		else
			Instance?.Hide();
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
