using Com.Vincent_Guerrini.PlayBoard.GameObject;
using Com.Vincent_Guerrini.PlayBoard.GameObject.Pong;
using Godot;
using Godot.Collections;
using System;
using System.Xml.Linq;
using static Godot.OpenXRInterface;

namespace Com.Vincent_Guerrini.PlayBoard.Games;

public partial class Pong : Games
{
    [Export] private PackedScene scenePlayer;
    [Export] private PackedScene sceneBall;
    [Export] private Label score;
    [Export] private Timer gameTimer;
    [Export] private Texture2D skinPlayer;

    private Array<Com.Vincent_Guerrini.PlayBoard.GameObject.GameObject> elements = [];
    private Player player2 = new Player();
    private PongBall ball = new PongBall();
    private int scorePlayer2 = 0;


    public override void _Ready()
    {
        screenSize = GetWindow().Size;
        elements = [
            player = (Player)scenePlayer.Instantiate(),
            player2 = (Player)scenePlayer.Instantiate(),
            ball = (PongBall)sceneBall.Instantiate()];
        player.runderer.Texture = skinPlayer;
        int lCount = elements.Count;
        for (int i = 0; i <= lCount - 1; i++) { AddChild(elements[i]); }
        gameTimer.Timeout += SpeedUpBall;
        base._Ready();
    }

    public override void _Process(double pDelta)
    {
        base._Process(pDelta);
    }

    protected override void StartRound()
    {
        player.Position = new Vector2(50, screenSize.Y / 2);
        player2.Position = new Vector2(screenSize.X - 50, screenSize.Y / 2);

        player.KeyUp = Key.Z;
        player.KeyDown = Key.S;

        ball.Position = new Vector2(screenSize.X / 2, screenSize.Y / 2);
        ball.Scale = new Vector2(rand.Randf() > 0.5 ? 1 : -1, rand.Randf() > 0.5 ? 1 : -1);
        ball.speed = 200;
        score.Text = scorePlayer + " : " + scorePlayer2;
        gameTimer.Start(5);
        base.StartRound();
    }

    protected override void CheckRound()
    {
        if (ball.Position.X > screenSize.X) { scorePlayer++; onGame = false; }
        if (ball.Position.X < 0) { scorePlayer2++; onGame = false; }
        base.CheckRound();
    }

    private void SpeedUpBall()
    {
        ball.speed += 50;
    }


}
