using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MazeGenerator
{

    int[,] maze;
    int num_sets;
    Stack<(int, int)> stack;

    public enum CellShape
    {
        WallEnd,
        WallStraight,
        WallTurn,
        WallT,
        WallCross,
        WallAlone,
        Space,
        SpaceEnd,
        SpaceStraight,
        SpaceCorner,
        SpaceU,
        SpaceEnclosed
    }

    public MazeGenerator(int width, int height)
    {
        maze = new int[width, height];
        stack = new Stack<(int, int)>();
        num_sets = 1;
    }

    public void OpenSpace(int x, int y)
    {
        FloodFill((x, y), num_sets);
        num_sets++;
    }

    public void OpenSpace(int x1, int x2, int y1, int y2)
    {
        for (int x = x1; x <= x2; x++)
        {
            for (int y = y1; y <= y2; y++)
            {
                stack.Push((x, y));
            }
        }
        FloodFill(stack.Pop(), num_sets);
        num_sets++;
    }

    public void OpenSpace(RectInt r)
    {
        OpenSpace(
            Mathf.Max(r.x - r.width / 2, 0),
            Mathf.Min(r.x + r.width / 2, maze.GetLength(0) - 1),
            Mathf.Max(r.y - r.height / 2, 0),
            Mathf.Min(r.y + r.height / 2, maze.GetLength(1) - 1)
        );
    }

    public void ForceWall(int x, int y)
    {
        maze[x, y] = -1;
    }

    public void ForceWall(RectInt r)
    {
        int minX = Mathf.Max(r.x - r.width / 2, 0);
        int maxX = Mathf.Min(r.x + r.width / 2, maze.GetLength(0) - 1);
        int minY = Mathf.Max(r.y - r.height / 2, 0);
        int maxY = Mathf.Min(r.y + r.height / 2, maze.GetLength(1) - 1);
        for (int x = minX; x <= maxX; x++)
        {
            for (int y = minY; y <= maxY; y++)
            {
                ForceWall(x, y);
            }
        }
    }

    public void Generate()
    {
        // This is a slow and naive implementation of Kruskals algorithm
        // TODO: Replace the FloodFill with a Union-Set structure
        List<(int, int)> unvisited = new List<(int, int)>(maze.Length / 4);
        for (int x = 0; x < maze.GetLength(0); x++)
        {
            for (int y = 0; y < maze.GetLength(1); y++)
            {
                if ((x % 2 == 0) && (y % 2 == 0) && maze[x, y] == 0)
                    OpenSpace(x, y);
                else if (((x % 2 == 0) || (y % 2 == 0)) && maze[x, y] == 0)
                    unvisited.Add((x, y));
            }
        }
        unvisited.Shuffle();
        foreach ((int x, int y) in unvisited)
        {
            KruskalCarve(x, y);
        }
    }

    public (CellShape, float) GetCell(int x, int y)
    {
        int walls = 0;
        if (GetLeft(x, y).Item3 <= 0)
            walls += 1;
        if (GetRight(x, y).Item3 <= 0)
            walls += 2;
        if (GetUp(x, y).Item3 <= 0)
            walls += 4;
        if (GetDown(x, y).Item3 <= 0)
            walls += 8;
        if (maze[x, y] <= 0)
        {
            return walls switch
            {
                0b0001 => (CellShape.WallEnd, 0f),
                0b0010 => (CellShape.WallEnd, 180f),
                0b0100 => (CellShape.WallEnd, -90f),
                0b1000 => (CellShape.WallEnd, 90f),
                0b0101 => (CellShape.WallTurn, 0f),
                0b0110 => (CellShape.WallTurn, -90f),
                0b1010 => (CellShape.WallTurn, 180f),
                0b1001 => (CellShape.WallTurn, 90f),
                0b0011 => (CellShape.WallStraight, 0f),
                0b1100 => (CellShape.WallStraight, 90f),
                0b1110 => (CellShape.WallT, 0f),
                0b1011 => (CellShape.WallT, -90f),
                0b1101 => (CellShape.WallT, 180f),
                0b0111 => (CellShape.WallT, 90f),
                0b1111 => (CellShape.WallCross, 0f),
                _ => (CellShape.WallAlone, 0f),
            };
        }
        else
        {
            return walls switch
            {
                0b0001 => (CellShape.SpaceEnd, 0f),
                0b0010 => (CellShape.SpaceEnd, 180f),
                0b0100 => (CellShape.SpaceEnd, -90f),
                0b1000 => (CellShape.SpaceEnd, 90f),
                0b0101 => (CellShape.SpaceCorner, 0f),
                0b0110 => (CellShape.SpaceCorner, -90f),
                0b1010 => (CellShape.SpaceCorner, 180f),
                0b1001 => (CellShape.SpaceCorner, 90f),
                0b0011 => (CellShape.SpaceStraight, 0f),
                0b1100 => (CellShape.SpaceStraight, 90f),
                0b1110 => (CellShape.SpaceU, 0f),
                0b1011 => (CellShape.SpaceU, -90f),
                0b1101 => (CellShape.SpaceU, 180f),
                0b0111 => (CellShape.SpaceU, 90f),
                0b1111 => (CellShape.SpaceEnclosed, 0f),
                _ => (CellShape.Space, 0f),
            };
        }
    }

    public IEnumerable<(int, int, CellShape, float)> GetCells()
    {
        for (int x = 0; x < maze.GetLength(0); x++)
        {
            for (int y = 0; y < maze.GetLength(1); y++)
            {
                (CellShape cell, float rot) = GetCell(x, y);
                yield return (x, y, cell, rot);
            }
        }
    }

    void KruskalCarve(int x, int y)
    {
        if (maze[x, y] > 0)
        {
            return;
        }
        int left = GetLeft(x, y).Item3;
        int right = GetRight(x, y).Item3;
        int up = GetUp(x, y).Item3;
        int down = GetDown(x, y).Item3;
        if (left > 0)
        {
            if (left == right)
                return;
            if (left == up)
                return;
            if (left == down)
                return;
        }
        if (right > 0)
        {
            if (right == up)
                return;
            if (right == down)
                return;
        }
        if (up > 0 & up == down)
            return;
        FloodFill((x, y), num_sets);
        num_sets++;
    }


    void FloodFill((int, int) pos, int set)
    {
        stack.Push(pos);
        while (stack.Count > 0)
        {
            (int x, int y) = stack.Pop();
            maze[x, y] = set;
            foreach ((int x2, int y2, int m) in GetNeighbours(x, y))
            {
                if (m <= 0 | m == set)
                    continue;
                if (m < set)
                {
                    set = m;
                    stack.Push((x, y));
                    break;
                }
                else
                {
                    stack.Push((x2, y2));
                }
            }
        }
    }



    (int, int, int) GetLeft(int x, int y)
    {
        if (x == 0)
            return (0, y, -1);
        return (x - 1, y, maze[x - 1, y]);
    }
    (int, int, int) GetRight(int x, int y)
    {
        if (maze.GetLength(0) == x + 1)
            return (x, y, -1);
        return (x + 1, y, maze[x + 1, y]);
    }
    (int, int, int) GetUp(int x, int y)
    {
        if (y == 0)
            return (x, 0, -1);
        return (x, y - 1, maze[x, y - 1]);
    }
    (int, int, int) GetDown(int x, int y)
    {
        if (maze.GetLength(1) == y + 1)
            return (x, y, -1);
        return (x, y + 1, maze[x, y + 1]);
    }
    IEnumerable<(int, int, int)> GetNeighbours(int x, int y)
    {
        yield return GetLeft(x, y);
        yield return GetRight(x, y);
        yield return GetUp(x, y);
        yield return GetDown(x, y);
    }
}
