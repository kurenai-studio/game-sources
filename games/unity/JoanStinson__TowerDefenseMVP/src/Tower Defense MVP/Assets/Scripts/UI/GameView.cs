using JGM.Gameplay;
using JGM.Gameplay.Base;
using JGM.Gameplay.Waves;
using UnityEngine;
using UnityEngine.UI;

namespace JGM.UI
{
    public class GameView : MonoBehaviour
    {
        [Header("Game Controller")]
        [SerializeField] private GameController gameController;

        [Header("Panels")]
        [SerializeField] private GameObject topPanel;
        [SerializeField] private GameObject bottomPanel;
        [SerializeField] private GameObject popupLose;
        [SerializeField] private GameObject popupWin;

        [Header("Buttons")]
        [SerializeField] private Button[] restartButtons;

        private void Awake()
        {
            var serviceLocator = ServiceLocator.Instance;
            var playerBase = serviceLocator.Get<PlayerBase>();
            var wavesController = serviceLocator.Get<WavesController>();

            gameController.OnGameStart += OnGameStart;
            playerBase.OnHealthDepleted += OnGameOver;
            wavesController.OnAllWavesComplete += OnGameWin;

            foreach (var button in restartButtons)
            {
                button.onClick.AddListener(OnGameRestart);
            }
        }

        private void OnGameStart()
        {
            topPanel.SetActive(true);
            bottomPanel.SetActive(true);
            popupLose.SetActive(false);
            popupWin.SetActive(false);
        }

        private void OnGameOver()
        {
            popupLose.SetActive(true);
            Time.timeScale = 0;
        }

        private void OnGameWin()
        {
            popupWin.SetActive(true);
            Time.timeScale = 0;
        }

        private void OnGameRestart()
        {
            gameController.RestartGame();
            Time.timeScale = 1;
        }
    }
}