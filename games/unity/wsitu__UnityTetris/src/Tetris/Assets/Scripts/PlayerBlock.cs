using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PlayerBlock : MonoBehaviour
{

    public Color blockColor;
    public GameObject[] topRow = new GameObject[4];
    public GameObject[] bottomRow = new GameObject[4];

    public Level level;
    public Grid2D levelGrid;
    public Grid2D moveGrid;

    private List<GameObject> bricks = new List<GameObject>();
    private List<GameObject> guides = new List<GameObject>();
    private Grid2D guideGrid;
    private float moveCooldown = 0.15f;
    private bool canDown;
    private bool canLeft;
    private bool canRight;
    private int _x;
    private int _y;
    private int _length = 0;

    public int x
    {
        get => _x;
        set
        {
            int diff = value - _x;
            foreach (GameObject brick in bricks)
                brick.GetComponent<MoveableBrick>().Translate(diff, 0);
            _x = value;
        }
    }

    public int y
    {
        get => _y;
        set
        {
            int diff = value - y;
            foreach (GameObject brick in bricks)
                brick.GetComponent<MoveableBrick>().Translate(0, diff);
            _y = value;
        }
    }

    public int length
    {
        get => _length;
    }

    public bool CanMove(int toX, int toY)
    {
        int xDiff = toX - x;
        int yDiff = toY - y;
        foreach (GameObject brick in bricks)
        {
            MoveableBrick info = brick.GetComponent<MoveableBrick>();
            if (!moveGrid.IsValid(info.x + xDiff, info.y + yDiff))
                return false;
            if (levelGrid.Has(info.x + xDiff, info.y + yDiff))
                return false;
        }

        return true;
    }

    public void PlaceDown()
    {
        foreach (GameObject brick in bricks)
        {
            foreach (GameObject g in guides) Destroy(g);
            MoveableBrick info = brick.GetComponent<MoveableBrick>();
            levelGrid[info.x, info.y] = brick;
            Destroy(gameObject);
        }
        level.ClearLines();
    }

    public void Rotate()
    {
        void RotateBorderClockWise(int xStart, int yStart, int borderLength)
        {
            int toEdge = borderLength - 1;
            for (int i = 0; i < toEdge; i++)
            {
                Swap(xStart + i, yStart, xStart, yStart + toEdge - i);
                Swap(xStart + i, yStart, xStart + toEdge - i, yStart + toEdge);
                Swap(xStart + i, yStart, xStart + toEdge, yStart + i);
            }
        }
        for(int layer = 0; layer < (int) length/2; layer++)
            RotateBorderClockWise(x + layer, y + layer, length - layer * 2);
    }

    public void SafeRotate()
    {
        if (x < 0)
            x = 0;
        else if (x + length > moveGrid.XLength)
            x = moveGrid.XLength - length;
        if (y < 0)
            y = 0;
        else if (y + length > moveGrid.YLength)
            y = moveGrid.YLength - length;
        Rotate();
        for (int i = 0; i < (int)length/2; i++)
        {
            if(CanMove(x, y + i))
            {
                y = y + i;
                return;
            }
        }
        // Rotate back to original 
        for (int i = 0; i < 3; i++)
            Rotate();
    }

    public void Spawn(int xPosition = 0, int yPosition = 0)
    {
        moveGrid = new Grid2D(levelGrid.XLength, levelGrid.YLength);
        guideGrid = new Grid2D(levelGrid.XLength, levelGrid.YLength);
        GameObject[][] layout = new GameObject[2][];
        layout[1] = topRow;
        layout[0] = bottomRow;
        for (int y = 0; y < layout.GetLength(0); y++)
        {
            for (int x = 0; x < layout[y].Length; x++)
            {
                if (layout[y][x] == null) continue;
                GameObject brick = Instantiate(layout[y][x]);
                bricks.Add(brick);
                brick.GetComponent<Renderer>().material.color = blockColor;
                moveGrid[x, y] = brick;
                MoveableBrick setup = brick.GetComponent<MoveableBrick>();
                setup.grid = moveGrid;
                setup.x = x;
                setup.y = y;
                if (_length < x + 1) _length = x + 1;
                if (_length < y + 1) _length = y + 1;

                GameObject guideBrick = Instantiate(layout[y][x]);
                guides.Add(guideBrick);
                Color darkGray = new Color(0.1f, 0.1f, 0.1f, 1f);
                guideBrick.GetComponent<Renderer>().material.color = darkGray;
                guideGrid[x, y] = guideBrick;
                setup = guideBrick.GetComponent<MoveableBrick>();
                setup.grid = guideGrid;
                setup.x = x;
                setup.y = y;
            }
        }
        _x = 0;
        _y = 0 + (layout.GetLength(0) - length); //position layout at top
        x = xPosition;
        y = yPosition;
    }

    public void Swap(int firstX, int firstY, int secondX, int secondY)
    {
        GameObject temp = moveGrid[firstX, firstY];
        if(temp == null)
        {
            temp = moveGrid[secondX, secondY];
            if (temp != null)
                temp.GetComponent<MoveableBrick>().Swap(firstX, firstY);
        }
        else
            temp.GetComponent<MoveableBrick>().Swap(secondX, secondY);
    }

    IEnumerator DownCooldown()
    {
        canDown = false;
        yield return new WaitForSeconds(moveCooldown);
        canDown = true;
    }
    IEnumerator LeftCooldown()
    {
        canLeft = false;
        yield return new WaitForSeconds(moveCooldown);
        canLeft = true;
    }
    IEnumerator RightCooldown()
    {
        canRight = false;
        yield return new WaitForSeconds(moveCooldown);
        canRight = true;
    }

    void Start()
    {
    }

    void Update()
    {
        int bottomDiff;
        for (bottomDiff = 0; bottomDiff < moveGrid.YLength; bottomDiff++)
            if (!CanMove(x, y - (bottomDiff + 1))) break;
        for (int i = 0; i < bricks.Count; i++)
        {
            MoveableBrick original = bricks[i].GetComponent<MoveableBrick>();
            MoveableBrick guide = guides[i].GetComponent<MoveableBrick>();

            if (bottomDiff >= length)
                guide.Move(original.x, original.y - bottomDiff);
            else
            {
                Vector3 hide = new Vector3(0, -guideGrid.YLength, 0);
                guide.gameObject.transform.position = hide;
            }
        }
        if (Input.GetKeyDown(KeyCode.Space))
        {
            y -= bottomDiff;
            PlaceDown();
        }
        if (Input.GetButtonDown("Vertical") && Input.GetAxis("Vertical") > 0)
        {
            SafeRotate();
        }
        if (Input.GetAxis("Vertical") < 0)
        {
            if (Input.GetButtonDown("Vertical"))
                canDown = true;
            if (canDown && Input.GetButton("Vertical"))
            {
                if (CanMove(x, y - 1))
                {
                    y--;
                    StartCoroutine("DownCooldown");
                }

            }
        }
        if (Input.GetAxis("Horizontal") > 0)
        {
            if (Input.GetButtonDown("Horizontal"))
                canRight = true;
            if (canRight && Input.GetButton("Horizontal"))
            {
                if (CanMove(x + 1, y))
                {
                    x++;
                    StartCoroutine("RightCooldown");
                }

            }
        }
        if (Input.GetAxis("Horizontal") < 0)
        {
            if (Input.GetButtonDown("Horizontal"))
                canLeft = true;
            if (canLeft && Input.GetButton("Horizontal"))
            {
                if (CanMove(x - 1, y))
                {
                    x--;
                    StartCoroutine("LeftCooldown");
                }

            }
        }
    }
}
