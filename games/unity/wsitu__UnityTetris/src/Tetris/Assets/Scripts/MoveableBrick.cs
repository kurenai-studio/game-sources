using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MoveableBrick : MonoBehaviour
{
    public Grid2D grid;

    public int x;
    public int y;

    public void Move(int newX, int newY)
    {
        grid[newX, newY] = gameObject;
        if (grid[x, y] == gameObject)
        {
            if (x != newX || y != newY)
                grid[x, y] = null;
        }
        x = newX;
        y = newY;
    }

    public void Swap (int newX, int newY)
    {
        if (grid.Has(newX, newY))
        {
            MoveableBrick update = grid[newX, newY].GetComponent<MoveableBrick>();
            update.x = x;
            update.y = y;
        }
        grid.Swap(x, y, newX, newY);
        x = newX;
        y = newY;
    }

    public void Translate(int xAmount, int yAmount)
    {
        Move(x + xAmount, y + yAmount);
    }

    public void MoveDown()
    {
        Translate(0, -1);
    }
}
