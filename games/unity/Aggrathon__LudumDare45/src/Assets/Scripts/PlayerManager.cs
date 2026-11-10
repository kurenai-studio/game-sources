using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(DeckManager))]
public class PlayerManager : MonoBehaviour, IPlayerManager
{
    
    DeckManager deckManager;
    public DeckManager deck { get => deckManager; }

    [SerializeField] GameObject endTurnButton;
    [SerializeField] TMPro.TextMeshProUGUI healthText;
    [SerializeField] GameObject gameOverScreen;
    [SerializeField] internal Upgrades upgrades;
    [SerializeField] Vector3 vulnerableZone = new Vector3(3, 1, 1);

    GameManager gameManager;

    internal Equipment headItem;
    internal Equipment chestItem;
    internal Equipment handItem;

    private void Awake() {
        endTurnButton?.SetActive(false);
        deckManager = GetComponent<DeckManager>();
        maxHealth = health;
        healthText.text = string.Format("{0}<color=black><size=20>\n{1}</size></color>", health, maxHealth);
    }

    [SerializeField] protected int energyGain = 1;
    [SerializeField] protected int cardGain = 2;
    [SerializeField] protected int health = 10;
    internal int maxHealth;

    public void StartCombat(GameManager manager) {
        gameManager = manager;
        deckManager.PrepareBattle(manager.groundTargets);
        deckManager.Shuffle();
        endTurnButton?.SetActive(false);
        handItem?.OnCombat(this);
        headItem?.OnCombat(this);
        chestItem?.OnCombat(this);
    }

    public void StartTurn() {
        if (health <= 0) {
            gameManager.Loose(this);
            return;
        }
        deckManager.energy += energyGain;
        for (int i = 0; i < cardGain; i++)
            deckManager.DrawToHand();
        deckManager.interactable = true;
        endTurnButton?.SetActive(true);
        for (int i = 0; i < deckManager.units.Count; i++)
        {
            deckManager.units[i].hasMoved = false;
        }
        handItem?.OnTurn(this);
        headItem?.OnTurn(this);
        chestItem?.OnTurn(this);
    }

    public void EndTurn() {
        deckManager.interactable = false;
        endTurnButton?.SetActive(false);
        gameManager.NextTurn();
    }

    public void EndCombat(bool won) {
        deckManager.interactable = false;
        endTurnButton?.SetActive(false);
        if (won) {
            deckManager.PrepareBattle(gameManager.groundTargets);
            upgrades.Show();
        } else {
            gameOverScreen.SetActive(true);
        }
    }

    public void Upgraded() {
        gameManager.NextCombat();
    }

    public void Damage(int amount) {
        health -= amount;
        healthText.text = string.Format("{0}<color=black><size=20>\n{1}</size></color>", health, maxHealth);
        if (health <= 0)
            gameManager?.Loose(this);
    }

    public void Heal(int amount, bool over = false) {
        health += amount;
        if (health > maxHealth) {
            if (over)
                maxHealth += (health - maxHealth)/2;
            health = maxHealth;
        }
        healthText.text = string.Format("{0}<color=black><size=20>\n{1}</size></color>", health, maxHealth);
    }

    public Vector3 GetPosition()
    {
        return transform.position;
    }
    
    private void OnDrawGizmosSelected() {
        Gizmos.color = Color.red;
        Gizmos.DrawWireCube(transform.position, vulnerableZone * 2);
    }
}
