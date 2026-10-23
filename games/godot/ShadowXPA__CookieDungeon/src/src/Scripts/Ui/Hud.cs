using CookieDungeon.Scripts.Utils;
using Godot;

namespace CookieDungeon.Scripts.Ui;

public partial class Hud : Control
{
	private Label? _level;
	private Label? _health;
	private Label? _mana;
	private ProgressBar? _hpBar;
	private ProgressBar? _mpBar;
	private ProgressBar? _dashCooldown;

	public override void _Ready()
	{
		_level = GetNode<Label>("%Level");
		_health = GetNode<Label>("%Health");
		_hpBar = GetNode<ProgressBar>("%HPBar");
		_mana = GetNode<Label>("%Mana");
		_mpBar = GetNode<ProgressBar>("%MPBar");
		_dashCooldown = GetNode<ProgressBar>("%DashCooldown");

		SignalBus.LevelUpdated += UpdateLevel;
		SignalBus.HealthUpdated += UpdateHealth;
		SignalBus.ManaUpdated += UpdateMana;
		SignalBus.DashCooldownUpdated += UpdateDashCooldown;
	}

	public override void _ExitTree()
	{
		SignalBus.LevelUpdated -= UpdateLevel;
		SignalBus.HealthUpdated -= UpdateHealth;
		SignalBus.ManaUpdated -= UpdateMana;
		SignalBus.DashCooldownUpdated -= UpdateDashCooldown;
	}

	private void UpdateLevel(int level)
	{
		if (_level is null) return;
		_level.Text = $"Lv.: {level}";
	}

	private void UpdateHealth(int health, int maxHealth)
	{
		if (_health is null || _hpBar is null) return;
		_health.Text = $"{health}/{maxHealth}";
		_hpBar.Value = health;
		_hpBar.MaxValue = maxHealth;
	}

	private void UpdateMana(int mana, int maxMana)
	{
		if (_mana is null || _mpBar is null) return;
		_mana.Text = $"{mana}/{maxMana}";
		_mpBar.Value = mana;
		_mpBar.MaxValue = maxMana;
	}

	private void UpdateDashCooldown(float cooldown, float maxCooldown)
	{
		if (_dashCooldown is null) return;
		_dashCooldown.Value = cooldown;
		_dashCooldown.MaxValue = maxCooldown;
	}
}
