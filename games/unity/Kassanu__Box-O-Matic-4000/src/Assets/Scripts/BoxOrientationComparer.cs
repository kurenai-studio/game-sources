using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BoxOrientationComparer : IComparer<Box> {

    public Player Player { get; set; }

    public BoxOrientationComparer(Player player) {
        Player = player;
    }

    public int Compare(Box x, Box y) {
        return this.ComparePlayerAndBox(x).CompareTo(this.ComparePlayerAndBox(y));
    }

    public float ComparePlayerAndBox(Box box) {
        float lrc = this.LeftOrRight(this.Player.transform.position, box.transform.position);
        if (lrc > 0 && !this.Player.FacingRight || lrc < 0 && this.Player.FacingRight) {
            return -1;
        }
        else {
            return 1;
        }
    }

    /// <summary>  
    ///  This will return whether or not object B is on the left or right of object A
    ///  If the return is positive object B is on the left of object A
    ///  If the return is negative object B is on the right of object A
    /// </summary>  
    public float LeftOrRight(Vector2 A, Vector2 B) {
        return A.x * -B.y + A.y * B.x;
    }
}
