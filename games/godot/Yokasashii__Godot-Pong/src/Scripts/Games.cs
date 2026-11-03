using Com.Vincent_Guerrini.PlayBoard.GameObject;
using Godot;
using System.Xml.Linq;

// Author : Vincent Guerrini / Yoka

namespace Com.Vincent_Guerrini.PlayBoard.Games;
	
public partial class Games : Node2D
{
	protected bool onGame;
    protected Player player = new Player();
    protected RandomNumberGenerator rand = new RandomNumberGenerator();
    protected Vector2 screenSize;
    protected int scorePlayer = 0;

    public override void _Ready()
	{
		StartRound();
    }

	public override void _Process(double pDelta)
	{
		float lDelta = (float)pDelta;

        if (onGame)
        {
            CheckRound();
        }
    }

	protected virtual void StartRound()
	{
		onGame = true;
	}

    protected virtual void CheckRound()
    {
        if (!onGame) StartRound();
    }
}

