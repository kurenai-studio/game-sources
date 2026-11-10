using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class UIController : MonoBehaviour {

    [SerializeField]
    Slider m_healthSlider;

    [SerializeField]
    Text m_scoreText;

    [SerializeField]
    GameObject m_gameplayUI;

    [SerializeField]
    GameObject m_gameOverUI;

    [SerializeField]
    Text m_endGameScore;

    [SerializeField]
    Text m_insultThePlayerText;

    GameController m_game;

	void Start ()
    {
        OnRestartGame();

        m_game = FindObjectOfType<GameController>();
        m_healthSlider.maxValue = (float)Constants.PLAYER_TOTAL_HEALTH;
	}
	
	void FixedUpdate()
    {
        m_healthSlider.value = (float)m_game.Player.CurrentHealth;
        m_scoreText.text = "Score: " + m_game.Score.ToString("N0");

        //Nice. Insult the player. Good idea
        if(m_game.Score == 0)
        {
            m_insultThePlayerText.gameObject.SetActive(true);
            m_insultThePlayerText.text = "You suck!";
        }
        else
        {
            m_insultThePlayerText.gameObject.SetActive(false);
        }
    }

    /// <summary>
    /// Enables gameplay UI
    /// </summary>
    public void OnRestartGame()
    {
        m_gameplayUI.SetActive(true);
        m_gameOverUI.SetActive(false);
    }

    /// <summary>
    /// Player has died, show end game screen
    /// </summary>
    public void OnGameEnded()
    {
        Debug.Log("Game Over");

        m_gameplayUI.SetActive(false);
        m_gameOverUI.SetActive(true);

        m_endGameScore.text = m_game.Score.ToString("N0");
    }
}
