using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

public class BoxDistanceComparer : IComparer<Box> {

    public Player Player { get; set; }

    public BoxDistanceComparer(Player player) {
        Player = player;
    }

    public int Compare(Box x, Box y) {
        return Vector2.Distance(Player.transform.position, x.transform.position).CompareTo(Vector2.Distance(Player.transform.position, y.transform.position));
    }
}