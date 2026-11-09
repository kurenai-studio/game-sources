using UnityEngine;
using UnityEngine.UI;

public class UIManager : GenericUnitySingleton<UIManager>
{
    [SerializeField]
    private Text whoseTurnText;
    [SerializeField]
    private Text movesLeftText;
    [SerializeField]
    private Text battlesWon;
    [SerializeField]
    private Text battlesLost;

    public void SetWhoseTurnText(EGameState whoseTurn)
    {
        switch (whoseTurn)
        {
            case EGameState.PlayerTurn:
                this.whoseTurnText.text = "Your Turn";
                break;
            case EGameState.AITurn:
                this.whoseTurnText.text = "AI Turn";
                break;
            default:
                this.whoseTurnText.text = "";
                break;
        }
    }

    public void SetMovesLeftText(int movesLeftCount)
    {
        this.movesLeftText.text = "Moves Left: " + movesLeftCount;
    }

    public void SetBattlesWonText(int battlesWonCount)
    {
        this.battlesWon.text = "Battles Won: " + battlesWonCount;
    }

    public void SetBattlesLostText(int battlesLostCount)
    {
        this.battlesLost.text = "Battles Lost: " + battlesLostCount;
    }
}
