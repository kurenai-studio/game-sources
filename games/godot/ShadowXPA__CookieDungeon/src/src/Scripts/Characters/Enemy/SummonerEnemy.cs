using CookieDungeon.Scripts.States;
using Godot;
using Godot.Collections;

namespace CookieDungeon.Scripts.Characters.Enemy;

public partial class SummonerEnemy : RangedEnemy
{
    [Export]
    public Array<PackedScene>? Enemies { get; private set; }
    [Export]
    public Array<Marker2D>? EnemySpawners { get; private set; }
    [Export]
    public Node? EnemyContainer { get; private set; }
    [Export]
    public int MaxSpawns { get; private set; } = 10;

    private double _summonTimer;

    public override void _Ready()
    {
        base._Ready();
        RandomizeSummonTimer();
    }

    public override void _Process(double delta)
    {
        base._Process(delta);

        _summonTimer -= delta;

        if (_summonTimer <= 0 && !IsDead)
        {
            StateMachine?.CallDeferred(StateMachine.MethodName.ChangeState, "Summon");
            RandomizeSummonTimer();
        }
    }

    private void RandomizeSummonTimer()
    {
        _summonTimer = GD.RandRange(10, 30);
    }

    public void SummonEnemy()
    {
        if (Enemies is null ||
            EnemySpawners is null ||
            Enemies.Count == 0 ||
            EnemyContainer is null ||
            EnemyContainer.GetChildCount() >= MaxSpawns) return;

        foreach (var spawner in EnemySpawners)
        {
            var index = GD.RandRange(0, Enemies.Count - 1);
            var enemy = Enemies[index].Instantiate<Enemy>();
            enemy.Level = Level / 2;
            EnemyContainer.AddChild(enemy);
            enemy.GlobalPosition = spawner.GlobalPosition;
        }
    }
}
