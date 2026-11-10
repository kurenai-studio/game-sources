using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;

public class GameBoard : UIBehaviour
{
    [SerializeField] private ManaOrb orbTemplate;
    [SerializeField] private DeadOrb deadOrbTemplate;
    [SerializeField] private int width = 6;
    [SerializeField] private int height = 8;
    RectTransform _rctTrnsfrm;
    Vector2Int mouseDownSquare;
    private int _score = 0;

    public int Score
    {
        get
        {
            return _score;
        }
        private set
        {
            _score = value;
            FindObjectOfType<ScoreDisplay>().SetText(_score.ToString());
        }
    }
    public int NumColors { get; set; }
    public int NumOrbsToKill { get; set; }
    public GridOrb[,] GridOrbs { get; set; }

    public RectTransform rectTransform
    {
        get
        {
            if (_rctTrnsfrm == null)
                _rctTrnsfrm = transform as RectTransform;
            return _rctTrnsfrm;
        }
    }

    public float OrbSize { get { return rectTransform.rect.width / width; } }

    public static GameBoard Instance { get; internal set; }

    // Use this for initialization
    private void Start()
    {
        if (Instance != null) Destroy(Instance);
        Instance = this;
        NumColors = 3;
        NumOrbsToKill = 2;
        Generate(width, height);
    }

    // Update is called once per frame
    void Update()
    {
    }

    public void Generate(int width, int height)
    {
        GridOrbs = new ManaOrb[width, height];

        for (int col = 0; col < width; col++)
        {
            for (int row = 0; row < height; row++)
            {
                CreateManaOrb(col, row);
            }
        }
    }

    private void CreateManaOrb(int col, int row)
    {
        //Create orb
        ManaOrb orb = Instantiate<ManaOrb>(orbTemplate, this.transform);
        orb.SetRandomColor(NumColors);
        orb.Column = col;
        orb.Row = row;
        PlaceOrb(col, row, orb);
        //Add orb event
        orb.OnClicked += OnOrbClick;
        //Add orb to grid
        GridOrbs[col, row] = orb as GridOrb;
    }

    private void PlaceOrb(int col, int row, GridOrb orb)
    {
        //Set orb transform
        RectTransform orbRect = orb.GetComponent<RectTransform>();
        orbRect.sizeDelta = new Vector2(OrbSize, OrbSize);
        orbRect.localPosition = CoordinatesToLocal(col, row);
    }

    private void OnOrbClick(GridOrb orb)
    {
        //find connected orbs
        List<GridOrb> orbs = new List<GridOrb>();
        orbs = GetConnectedOrbs(orb, orbs);

        if (orbs.Count >= 3)
        {
            //Increase score
            Score = Score + 10 * orbs.Count;
            //Set dead orb locations for destroying random orbs
            //Vector2Int[] deadOrbLocations = new Vector2Int[NumOrbsToKill];
            //for (int i = 0; i < NumOrbsToKill; i++)
            //{
            //    GridOrb orbToKill = orbs[Random.Range(0, orbs.Count)];
            //    deadOrbLocations[i] = new Vector2Int(orbToKill.Column, orbToKill.Row);
            //}
            //Destroy remaining connected orbs
            foreach (ManaOrb connectedOrb in orbs)
                Destroy(connectedOrb.gameObject);

            //Add dead orbs for random placements
            //foreach (Vector2Int location in deadOrbLocations)
            //    CreateDeadOrb(location.x, location.y);

            //Kill the clicked orb
            CreateDeadOrb(orb.Column, orb.Row);
            //Fill gaps
            StartCoroutine(DropOrbs());
        }
    }

    private void CreateDeadOrb(int col, int row)
    {
        //Create orb
        ManaOrb orb = Instantiate<ManaOrb>(orbTemplate, this.transform);
        orb.Setdead();
        orb.Column = col;
        orb.Row = row;
        PlaceOrb(col, row, orb);
        //Don't add orb event
        //Add orb to grid
        GridOrbs[col, row] = orb as GridOrb;
    }

    private IEnumerator DropOrbs()
    {
        yield return new WaitForSeconds(0.1f);
        //Go row by row
        for (int row = 0; row < height; row++)
        {
            bool fillInRow = false;
            for (int col = 0; col < width; col++)
            {
                if (GridOrbs[col, row] == null)
                {
                    fillInRow = true;
                    //Find next droppable orb above
                    int y = row + 1;
                    while (GridOrbs[col, row] == null)
                    {
                        if (y == height)//Top of the board reached
                        {
                            //Generate new orb
                            CreateManaOrb(col, row);
                        }
                        else if (GridOrbs[col, y] != null //Non-empty
                            && GridOrbs[col, y].OrbTypeID != -1) //Not dead
                        {
                            MoveOrb(col, y, col, row);
                        }
                        else
                        {
                            //No orb found: increment
                            y++;
                        }
                    }
                }
            }
            if (fillInRow)
            {
                //Wait before moving on to find the next row to fill
                yield return new WaitForSeconds(0.1f);
            }
        }
    }

    private void MoveOrb(int oldCol, int oldRow, int newCol, int newRow)
    {
        //Orb found, drop it in here
        GridOrb orb = GridOrbs[oldCol, oldRow];
        GridOrbs[newCol, newRow] = orb;
        orb.Column = newCol;
        orb.Row = newRow;
        PlaceOrb(newCol, newRow, orb);
        //Empty previous slot
        GridOrbs[oldCol, oldRow] = null;
    }

    private List<GridOrb> GetConnectedOrbs(GridOrb orb, List<GridOrb> orbs)
    {
        orbs.Add(orb);
        //Check above
        if (orb.Row + 1 < height)
        {
            GridOrb upOrb = GridOrbs[orb.Column, orb.Row + 1];
            if (upOrb!= null && !orbs.Contains(upOrb) && upOrb.OrbTypeID == orb.OrbTypeID)
            {
                //If the orb matches and is not already in the list
                //Add it and all of it's connected orbs
                orbs = GetConnectedOrbs(upOrb, orbs);
            }
        }
        //Check Right
        if (orb.Column + 1 < width)
        {
            GridOrb rightOrb = GridOrbs[orb.Column + 1, orb.Row];
            if (rightOrb != null && !orbs.Contains(rightOrb) && rightOrb.OrbTypeID == orb.OrbTypeID)
            {
                //If the orb matches and is not already in the list
                //Add it and all of it's connected orbs
                orbs = GetConnectedOrbs(rightOrb, orbs);
            }
        }
        //Check Below
        if (orb.Row > 0)
        {
            GridOrb downOrb = GridOrbs[orb.Column, orb.Row - 1];
            if (downOrb != null && !orbs.Contains(downOrb) && downOrb.OrbTypeID == orb.OrbTypeID)
            {
                //If the orb matches and is not already in the list
                //Add it and all of it's connected orbs
                orbs = GetConnectedOrbs(downOrb, orbs);
            }
        }
        //Check Left
        if (orb.Column > 0)
        {
            GridOrb leftOrb = GridOrbs[orb.Column - 1, orb.Row];
            if (leftOrb != null && !orbs.Contains(leftOrb) && leftOrb.OrbTypeID == orb.OrbTypeID)
            {
                //If the orb matches and is not already in the list
                //Add it and all of it's connected orbs
                orbs = GetConnectedOrbs(leftOrb, orbs);
            }
        }
        return orbs;
    }

    private Vector2 CoordinatesToLocal(int col, int row)
    {
        return new Vector2((col * OrbSize) - (rectTransform.rect.width / 2), row * OrbSize);
    }

    public void ResetGrid()
    {
        Score = 0;
        //Empty Grid
        foreach(ManaOrb orb in GridOrbs)
        {
            Destroy(orb.gameObject);
        }
        //Fill grid
        Generate(width, height);
    }

    public void HighlightSelected(ManaOrb source)
    {
        List<GridOrb> selOrbs = new List<GridOrb>();
        selOrbs = GetConnectedOrbs(source, selOrbs);

        if (selOrbs.Count < 3) return;

        foreach (ManaOrb morb in selOrbs)
        {
            morb.SetPointerHighlight(true);
        }
    }

    public void LowlightSelected(ManaOrb source)
    {
        List<GridOrb> selOrbs = new List<GridOrb>();
        selOrbs = GetConnectedOrbs(source, selOrbs);

        foreach (ManaOrb morb in selOrbs)
        {
            morb.SetPointerHighlight(false);
        }
    }
}
