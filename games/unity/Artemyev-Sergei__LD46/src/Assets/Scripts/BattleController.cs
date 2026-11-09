using System.Collections.Generic;
using System.Linq;
using UnityEngine;

public class BattleController : MonoBehaviour, IEventSquadDefeatedListener, IEventSquadCapturedFlagListener
{
    public EventBattleFinished EventBattleFinished = new EventBattleFinished();

    private List<Squad> playerSquads;
    private List<Squad> aiSquads;

    private ITurnTaker playerController;
    private ITurnTaker aiController;

    private AttackDirectionArrow attackDirectionArrow;

    private int battlesWonCount = 0;
    private int battlesLostCount = 0;

    private void Awake()
    {
        this.attackDirectionArrow = GetComponentInChildren<AttackDirectionArrow>(true);
    }

    public void StartBattle()
    {
        this.playerSquads = new List<Squad>();
        this.aiSquads = new List<Squad>();

        List<Squad> allSquads = FindObjectsOfType<Squad>().ToList();
        foreach (Squad squad in allSquads)
        {
            if (squad.gameObject.tag == "AI")
            {
                squad.SetBannerColor(Color.cyan);
                this.aiSquads.Add(squad);
            }

            if (squad.gameObject.tag == "Player")
            {
                this.playerSquads.Add(squad);

                if (squad.GetSquadType() == ESquadType.King)
                {
                    squad.GetComponent<SquadCollisions>().EventSquadCapturedFlag.AddListener(this);
                }
            }

            squad.EventSquadDefeated.AddListener(this);
        }

        this.playerController = new PlayerController(this.attackDirectionArrow);
        this.aiController = new AIController(this.aiSquads);
    }

    public void OnSquadDefeated(Squad squad)
    {
        squad.EventSquadDefeated.RemoveListener(this);

        if (squad.gameObject.tag == "Player")
        {
            this.playerSquads.Remove(squad);

            if (squad.GetSquadType() == ESquadType.King || this.playerSquads.Count <= 0)
            {
                LoseBattle();
            }
        }

        if (squad.gameObject.tag == "AI")
        {
            this.aiSquads.Remove(squad);

            if (this.aiSquads.Count <= 0)
            {
                WinBattle();
            }
        }
    }

    public void OnSquadCapturedFlag(Squad squad)
    {
        WinBattle();
        squad.GetComponent<SquadCollisions>().EventSquadCapturedFlag.RemoveListener(this);
    }

    private void WinBattle()
    {
        this.battlesWonCount++;
        EventBattleFinished.Dispatch(true);
        UIManager.Instance.SetBattlesWonText(this.battlesWonCount);
    }

    private void LoseBattle()
    {
        this.battlesLostCount++;
        EventBattleFinished.Dispatch(false);
        UIManager.Instance.SetBattlesLostText(this.battlesLostCount);
    }

    public EGameState ProcessTurn(EGameState whoseTurn)
    {
        EGameState whoseNextTurn = whoseTurn;
        switch (whoseTurn)
        {
            case EGameState.PlayerTurn:
                this.playerController.TakeTurn();
                if (this.playerController.IsTurnFinished())
                {
                    whoseNextTurn = EGameState.AITurn;
                }
                break;
            case EGameState.AITurn:
                this.aiController.TakeTurn();
                if (this.aiController.IsTurnFinished())
                {
                    whoseNextTurn = EGameState.PlayerTurn;
                }
                break;
            default:
                break;
        }
        return whoseNextTurn;
    }
}
