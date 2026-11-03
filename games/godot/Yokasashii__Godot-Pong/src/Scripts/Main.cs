using Godot;
using System;

// Author : 
// Version 1.1.1

namespace Com.IsartDigital.Pong;
	
public partial class Main : Node2D
{

	static private Main instance;

	private Main():base() {
		if (instance != null)
		{
			QueueFree();
			GD.Print(nameof(Main) + " Instance already exists, destroying the last added.");
			return;
		}

		instance = this;	
	}

	static public Main GetInstance()
	{
		if (instance == null) instance = (Main)GD.Load<PackedScene>("res://Scenes/Main.tscn").Instantiate();
		return instance;

	}

	public override void _Ready()
	{
		base._Ready();
	}

	public override void _Process(double pDelta)
	{
		base._Process(pDelta);
		float lDelta = (float)pDelta;
	}

	protected override void Dispose(bool pDisposing)
	{
		instance = null;
		base.Dispose(pDisposing);
	}
}
