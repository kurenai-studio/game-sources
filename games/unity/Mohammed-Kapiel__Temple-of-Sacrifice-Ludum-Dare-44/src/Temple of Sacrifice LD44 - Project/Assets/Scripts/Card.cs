using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;

public class Card : MonoBehaviour, ISelectHandler, IDeselectHandler
{
    public CardData cardData;
    public GameplayManager gameplayManager;

    public bool isCard;

    public bool isAttacked;
    public bool isDeffended;

    public int damageValue = 0;
    public int healthValue = 0;
    public int moneyValue = 0;

    public int numberOfUnits = 0;

    public TextMeshProUGUI nameText;
    public TextMeshProUGUI costText;
    public TextMeshProUGUI damageText;
    public TextMeshProUGUI healthText;
    public TextMeshProUGUI prayerText;

    //public TextMeshProUGUI numberOfUnitsText;
    public TextMeshProUGUI descriptionText;
    public Image portrait;

    public void Spawn(bool isCard)
    {
        this.isCard = isCard;
        isAttacked = false;
        isAttacked = false;

        if (!isCard)
        {
            damageValue += cardData.damageValue;
            healthValue += cardData.healthValue;
            moneyValue += cardData.moneyValue;
            numberOfUnits++;
        }

        ReDrawUI();
    }

    public void NewRound()
    {
        isAttacked = false;
        isDeffended = false;
    }

    public void TakeDamage(int damage)
    {
        if(damage < cardData.healthValue)
        {
            //No units lost
            Debug.Log(damage);
        }
        else
        {
            if(cardData.healthValue == 0)
            {
                //Priests
                Die();
                return;
            }
            numberOfUnits -= Mathf.FloorToInt(damage/ cardData.healthValue);
            Debug.Log(numberOfUnits + " " + damage);
            damageValue = numberOfUnits * cardData.damageValue;
            healthValue = numberOfUnits * cardData.healthValue;
            moneyValue = numberOfUnits * cardData.moneyValue;

            damageText.text = damageValue + "";
            healthText.text = healthValue + "";
            costText.text = moneyValue + "";
            //numberOfUnitsText.text = numberOfUnits + "";

            if (numberOfUnits <= 0)
            {
                Die();
            }
        }
    }

    public void Die()
    {
        cardData = null;

        damageValue = 0;
        healthValue = 0;
        numberOfUnits = 0;
        moneyValue = 0;

        nameText.text = "";
        damageText.text = "";
        healthText.text = "";
        costText.text = "";
        //numberOfUnitsText.text = "";

        GetComponent<Image>().sprite = null;
    }

    public void ReDrawUI()
    {
        nameText.text = cardData.nameValue;
        costText.text = cardData.costValue + "";
        portrait.sprite = cardData.image;
        descriptionText.text = cardData.description;

        
        //numberOfUnitsText.text = numberOfUnits + "";

        if (isCard)
        {
            damageText.text = cardData.damageValue + "";
            healthText.text = cardData.healthValue + "";
            costText.text = cardData.costValue + "";
            prayerText.text = cardData.moneyValue + "";
        }
        else
        {
            damageText.text = damageValue + "";
            healthText.text = healthValue + "";
            costText.text = moneyValue + "";
        }
        
    }

    public void OnSelect(BaseEventData eventData)
    {
        if (isCard)
        {
            gameplayManager.AssignCard(this.gameObject);
        }
        else
        {
            gameplayManager.AssignUnit(this.gameObject);
        }
        
    }

    public void OnDeselect(BaseEventData eventData)
    {
        if (cardData == null)
        {
            return;
        }

        if (isCard)
        {
            Invoke("DeselectCard", 0.1f);
            
        }
        else
        {
            Invoke("DeselectUnit", 0.1f);
        }
    }

    public void DeselectCard()
    {
        gameplayManager.DeselectCard();
    }

    public void DeselectUnit()
    {
        gameplayManager.DeselectUnit();
    }
}
