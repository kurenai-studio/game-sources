using System;
using System.Collections.Generic;
using TMPro;
using UnityEngine;
using UnityEngine.SceneManagement;

public class InventoryManager : MonoBehaviour
{
    [SerializeField]
    private TMP_Text _inventoryLabel;

    [SerializeField]
    private TMP_Text _playerHealth;

    [SerializeField]
    private GameObject _gameOverPopup;

    [SerializeField]
    private TMP_Text _gameOverText;

    private readonly string _inventoryTemplate = "Cards\nFire: {0}\nIce: {1}";
    private readonly Dictionary<CardType, int> _inventory = new()
    {
        { CardType.Fire, 0 },
        { CardType.Ice, 0 }
    };

    private void Awake()
    {
        UpdateUI();
    }

    private void OnEnable()
    {
        MessageQueue.Instance.AddListener<CardPickedUpMessage>(OnCardPickedUp);
        MessageQueue.Instance.AddListener<GameOverMessage>(OnGameOver);
        MessageQueue.Instance.AddListener<HealthUpdateMessage>(OnHealthUpdated);
    }

    private void OnDisable()
    {
        MessageQueue.Instance.RemoveListener<CardPickedUpMessage>(OnCardPickedUp);
        MessageQueue.Instance.RemoveListener<GameOverMessage>(OnGameOver);
        MessageQueue.Instance.RemoveListener<HealthUpdateMessage>(OnHealthUpdated);
    }

    private void OnCardPickedUp(CardPickedUpMessage message)
    {
        Debug.Log($"CardPickedUpMessage: {message.Quantity}x {message.Type}");

        _inventory[message.Type] += message.Quantity;

        UpdateUI();
    }

    private void OnGameOver(GameOverMessage message)
    {
        _gameOverPopup.SetActive(true);
        _gameOverText.text = string.Format(_gameOverText.text, 
            _inventory[CardType.Fire] + _inventory[CardType.Ice]);
        Time.timeScale = 0;
    }

    private void OnHealthUpdated(HealthUpdateMessage message)
    {
        _playerHealth.text = $"HP :{message.Amount}";
    }

    private void UpdateUI()
    {
        _inventoryLabel.text = string.Format(_inventoryTemplate, 
            _inventory[CardType.Fire], _inventory[CardType.Ice]);
    }

    public void PlayAgainButton()
    {
        Time.timeScale = 1;
        SceneManager.LoadScene(0);
    }
}
