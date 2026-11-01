using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class BoardController : MonoBehaviour
{
    /* TODO */
    // Create grid from ANY dimensions
    // WIN CONDITION
    // LOSE CONDITION
    // MARK CELLS
    // CREATE BOARD
    // First click = never loses
    // Main Menu
    // Credits Screen
    // Music
    // Navigate grid with touch buttons
    // Mouse Support
    // Score System
    // Time
    // Leaderboards
    // Ads
    // Video ads
    // Custom boards (crosses, hearts, diamonds, ...)
    // Cosmetic Packs
    // Paid version
    // Time Attack
    // Minigame (quick boards to solve in seconds)
    // Animated Tutorial
    // New game mode?
    // Amnesia mode (game forgets plays older than 10 moves)
    
    public Color OneBombIsNearColor;
    public Color TwoBombsAreNearColor;
    public Color ThreeBombsAreNearColor;

    [Space] public GameObject Cell;
    private int bombCount = 8;
    private Vector2 dimensions = Vector2.one;

    private GridLayoutGroup grid;

    #region Unity

    private void Awake()
    {
        grid = GetComponent<GridLayoutGroup>();
    }
    #endregion
    
    public void Init(Vector2 dim, int bombs)
    {
        bombCount = bombs;
        dimensions = dim;
        
        
        
        
    }
}
