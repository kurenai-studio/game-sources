using UnityEngine;

public class GameManager : GenericUnitySingleton<GameManager>, IEventBattleFinishedListener
{
    public SceneLoader SceneLoader;
    public BattleController BattleController;

    private EGameState gameState = EGameState.Loading;

    private void OnEnable()
    {
        SceneLoader.GameLevelLoaded += OnGameLevelLoaded;
        this.BattleController.EventBattleFinished.AddListener(this);
    }

    private void Start()
    {
        SceneLoader.LoadNextBattle();
    }

    private void OnGameLevelLoaded()
    {
        this.BattleController.StartBattle();
        this.gameState = EGameState.PlayerTurn;
    }

    public void OnBattleFinished(bool isPlayerWin)
    {
        if (isPlayerWin)
        {
            this.gameState = EGameState.BattleWon;
        }
        else
        {
            this.gameState = EGameState.BattleLost;
        }
    }

    private void OnDisable()
    {
        SceneLoader.GameLevelLoaded -= OnGameLevelLoaded;
        this.BattleController.EventBattleFinished.RemoveListener(this);
    }

    private void Update()
    {
        if (this.gameState == EGameState.Loading)
        {
            return;
        }

        if (this.gameState == EGameState.BattleLost || (this.gameState == EGameState.PlayerTurn && Input.GetButtonDown("Restart"))) // Escape button
        {
            this.gameState = EGameState.Loading;
            SceneLoader.RestartBattle();
            return;
        }

        if (this.gameState == EGameState.BattleWon)
        {
            this.gameState = EGameState.Loading;
            SceneLoader.LoadNextBattle();
            return;
        }

        this.gameState = this.BattleController.ProcessTurn(this.gameState);
        UIManager.Instance.SetWhoseTurnText(this.gameState);
    }
}
