using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;

public class Enemy : MonoBehaviour, ISelectHandler
{
    public EnemyData enemyData;
    public GameplayManager gameplayManager;

    public int damageValue;
    public int healthValue;

    public TextMeshProUGUI nameText;
    public TextMeshProUGUI damageText;
    public TextMeshProUGUI healthText;

    public Image portrait;
    public TextMeshProUGUI flavourDescriptionText;
    public TextMeshProUGUI gameplayDescriptionText;


    public void ScaleUpToDifficulty(int level)
    {
        damageValue += enemyData.damageValue * level;
        healthValue += enemyData.healthValue * level;
    }

    public void Spawn()
    {
        nameText.text = enemyData.nameValue;
        portrait.sprite = enemyData.image;

        flavourDescriptionText.text = enemyData.flavourDescription;
        gameplayDescriptionText.text = enemyData.gameplayDescription;

        damageText.text = damageValue + "";
        healthText.text = healthValue + "";

        
    }

    public void TakeDamage(int damage)
    {
        //Health represents the number of enemies, thus damage is reduced only if an enemy is killed.
        healthValue -= damage;
        damageValue = (int)Mathf.Ceil((float)healthValue / (float)enemyData.healthValue) * enemyData.damageValue;

        damageText.text = damageValue + "";
        healthText.text = healthValue + "";

        if(healthValue <= 0)
        {
            Die();
        }

    }

    public void Die()
    {
        damageValue = 0;
        healthValue = 0;

        nameText.text = "";
        damageText.text = "";
        healthText.text = "";
        flavourDescriptionText.text = "";
        gameplayDescriptionText.text = "";
        GetComponent<Image>().sprite = null;
    }

    public void OnSelect(BaseEventData eventData)
    {
        gameplayManager.AttackUnit(this.gameObject);

    }
}
