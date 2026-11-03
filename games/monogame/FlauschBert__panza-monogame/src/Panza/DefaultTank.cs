using Microsoft.Xna.Framework;
using System.Collections.Generic;
using System;

namespace org.flauschhaus.Panza {

public class DefaultTank {

// Default values of Tank derived from Player index
private static List<DefaultTank> _tanks;

public enum Side { Left = 0, Right };
public enum Height { Top = 0, Bottom };

public string TankFileName { get; set; }
public string GunFileName { get; set; }
public Vector2 Direction { get; set; }
public Vector2 GunDirection { get; set; }
public Tuple<Side,Height> PositionInfo { get; set; }

private DefaultTank () {}

static DefaultTank ()
{
  _tanks = new List<DefaultTank>();
  _tanks.Add(new DefaultTank() {
    TankFileName="tank01",
    GunFileName="gun01",
    Direction=new Vector2(0,1),
    GunDirection=new Vector2(0,1),
    PositionInfo=new Tuple<Side,Height>(Side.Left,Height.Top)
  });
  _tanks.Add(new DefaultTank() {
    TankFileName="tank02",
    GunFileName="gun02",
    Direction=new Vector2(0,-1),
    GunDirection=new Vector2(0,-1),
    PositionInfo=new Tuple<Side,Height>(Side.Right,Height.Bottom)
  });
}

static public DefaultTank GetTank (int index)
{
  return _tanks[index];
}

static public Vector2 GetPosition (Tuple<Side,Height> info, Vector2 windowSize)
{
  var side = (int)info.Item1;
  var height = (int)info.Item2;
  var halfSize = windowSize / 2;
  var quarterSize = windowSize / 4;
  return new Vector2 (
    side * halfSize.X + quarterSize.X,
    height * halfSize.Y + quarterSize.Y
  );
}

} // DefaultTank

} // ns
