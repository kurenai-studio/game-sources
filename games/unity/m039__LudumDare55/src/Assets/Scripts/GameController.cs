using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEngine.SceneManagement;

namespace LD55
{
    public class GameController : MonoBehaviour
    {
        static public GameController Instance;

        List<Altar> _altars;

        List<Enemy> _enemies;

        bool _isFinished = false;

        float _timer = 0f;

        void Awake()
        {
            Instance = this;
        }

        void Start()
        {
            Init();
        }

        void Init()
        {
            var altars = FindObjectsOfType<Altar>(true);
            if (altars != null)
            {
                _altars = new List<Altar>(altars);
            } else
            {
                _altars = new();
            }

            var enemies = FindObjectsOfType<Enemy>(true);
            if (enemies != null)
            {
                _enemies = new List<Enemy>(enemies);
            } else
            {
                _enemies = new();
            }
        }

        void Update()
        {
            ProcessUpdate();
        }

        void ProcessUpdate()
        {
            if (_isFinished)
                return;

            _timer += Time.unscaledDeltaTime;
            if (_timer < 1)
                return;

            _timer = 0f;

            for (int i = _altars.Count - 1; i >= 0; i--)
            {
                if (_altars[i].IsActivated)
                {
                    _altars.RemoveAt(i);
                }
            }

            for (int i = _enemies.Count - 1; i >= 0; i--)
            {
                if (_enemies[i] == null)
                {
                    _enemies.RemoveAt(i);
                }
            }

            if (_altars.Count <= 0 &&
                _enemies.All(e => !e.gameObject.activeSelf)) {
                _isFinished = true;
                StartCoroutine(EndGame());
            }
        }

        public void RestartLevel()
        {
            Time.timeScale = 1f;
            SceneManager.LoadScene(SceneManager.GetActiveScene().buildIndex);
        }

        public void NextLevel()
        {
            Time.timeScale = 1f;
            SceneManager.LoadScene(SceneManager.GetActiveScene().buildIndex + 1);
        }

        public void LoseGame()
        {
            Time.timeScale = 0f;
            MainUI.Instance.ShowLoseScreen();
        }

        IEnumerator EndGame()
        {
            yield return new WaitForSecondsRealtime(2);

            MainUI.Instance.ShowWinScreen();
        }
    }
}
