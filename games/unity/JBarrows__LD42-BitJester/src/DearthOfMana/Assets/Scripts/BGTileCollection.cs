using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BGTileCollection : MonoBehaviour {

    [SerializeField]
    private RectTransform tileTemplate;

    /// <summary>
    /// Gets or sets number of tiles along the horizontal and vertical axes
    /// </summary>
    public Vector2 TileCountVector { get; private set; }

    /// <summary>
    /// Gets the total number of tiles in the grid
    /// </summary>
    public int TileCountScalar { get { return (int)TileCountVector.x * (int)TileCountVector.y; } }

    public float AnchorWidth
    {
        get
        {
            RectTransform t = this.GetComponent<RectTransform>();
            return t.anchorMax.x - t.anchorMin.x;
        }
    }

    public float TileWidth
    {
        get
        {
            //The extra 0.5 is for hex offset
            return AnchorWidth / (TileCountVector.x + 0.5f);
        }
    }

    // Use this for initialization
    void Start () {
        
	}

    private void Generate(int width, int height)
    {
        TileCountVector = new Vector2(width, height);
        for (int y = 0; y < height; y++)
        {
            float offset = y % 2 == 0 ? 0f : TileWidth / 2;
            for (int x = 0; x < width; x++)
            {
                RectTransform tile = Instantiate<RectTransform>(tileTemplate, transform);
                tile.anchoredPosition = new Vector2((x * TileWidth) + offset, y * TileWidth);
            }
        }
    }

    // Update is called once per frame
    void Update () {
		
	}
}
