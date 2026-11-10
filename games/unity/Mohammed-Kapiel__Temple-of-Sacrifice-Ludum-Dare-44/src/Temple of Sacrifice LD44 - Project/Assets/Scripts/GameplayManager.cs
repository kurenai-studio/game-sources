using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.SceneManagement;

//Refrences:
//https://answers.unity.com/questions/677070/sorting-a-list-linq.html
public class GameplayManager : MonoBehaviour
{
    public GameObject cardPrefab;

    public GameObject cardDeck;
    public GameObject playerField;
    public GameObject enemyField;

    public GameObject[] enemies;
    public CardData[] cardTypes;

    //[HideInInspector]
    public GameObject currentCard;

    //[HideInInspector]
    public GameObject currentUnit;

    public GameObject deffendText;

    //Game Logic
    public int hp = 100;
    [HideInInspector]
    public int maxHp;

    public int currentRound = 0;

    //UI
    public TextMeshProUGUI roundText;
    public Image healthBackground;

    public GameObject losePanel;

    public void Start()
    {
        maxHp = hp;
    }

    public void DecrementHealth(int amount)
    {
        hp -= amount;

        if (hp <= 0)
        {
            //DEATH!
            LoseGame();
        }

        healthBackground.type = Image.Type.Filled;
        healthBackground.fillMethod = Image.FillMethod.Vertical;
        healthBackground.fillAmount = (float)hp / maxHp;
    }

    public void IncrementHealth(int amount)
    {
        hp += amount;

        healthBackground.type = Image.Type.Filled;
        healthBackground.fillMethod = Image.FillMethod.Vertical;
        healthBackground.fillAmount = (float)hp / maxHp;
    }

    public void LoseGame()
    {
        losePanel.SetActive(true);
        losePanel.transform.GetChild(0).GetComponent<TextMeshProUGUI>().text = currentRound + "";
        Destroy(this);
        //Todo:
        //Panel 1st child is the score value text.
        //Panel  has buttons to load scene.
        //Create exit button.
    }

    public void NextRound()
    {
        currentRound++;
        roundText.text = currentRound + "";

        ProcessPlayer();
        ProcessEnemy();

        DrawCard();
    }

    public void ProcessEnemy()
    {
        EnemiesAttack();
        SpawnEnemies();
    }

    public void SpawnEnemies()
    {
        int basePowerMultiplier = currentRound / 4;
        basePowerMultiplier++;

        int positionInfo = (currentRound - 1) % 4;

        print("basePowerMultiplier: " + basePowerMultiplier);
        print("extraPowerMultiplier: " + positionInfo);

        Enemy tmpEnemy = enemies[positionInfo].GetComponent<Enemy>();
        tmpEnemy.ScaleUpToDifficulty(positionInfo == 3 ? basePowerMultiplier - 1 : basePowerMultiplier);
        tmpEnemy.Spawn();
    }

    public void EnemiesAttack()
    {
        Enemy[] tmpEnemies = enemyField.transform.GetComponentsInChildren<Enemy>();
        List<Card> tmpCardsDefending = new List<Card>();
        List<Card> tmpCards = new List<Card>();

        foreach (Transform unit in playerField.transform)
        {
            Card tmpCard = unit.GetComponent<Card>();

            if (tmpCard.numberOfUnits > 0)
            {
                if (tmpCard.isDeffended)
                {
                    tmpCardsDefending.Add(tmpCard);
                }

                tmpCards.Add(tmpCard);
            }
        }

        for (int i = 0; i < 4; i++)
        {
            if (tmpEnemies[i].healthValue > 0)
            {
                //Enemy Allowed to attack!
                switch (i)
                {
                    case 0:
                        //Barbarian Logic!
                        if (tmpCardsDefending.Count > 0)
                        {
                            tmpCardsDefending[0].TakeDamage(tmpEnemies[i].damageValue);
                        }
                        else
                        {
                            DecrementHealth(tmpEnemies[i].damageValue);
                        }
                        break;
                    case 1:
                        //Heathen Disciple Logic!
                        int discipleDamageTmp = tmpEnemies[i].damageValue;
                        int deffenderCounter = 0;

                        if (tmpCardsDefending.Count > 0)
                        {
                            foreach (var defender in tmpCardsDefending)
                            {
                                if (discipleDamageTmp >= defender.healthValue)
                                {
                                    int tmpHealth = defender.healthValue;
                                    defender.TakeDamage(discipleDamageTmp);

                                    discipleDamageTmp -= tmpHealth;

                                    deffenderCounter++;
                                }
                                else
                                {
                                    break;
                                }
                            }
                            Debug.Log("Defenders hit = " + deffenderCounter + " damge to hp = " + discipleDamageTmp);
                            if (discipleDamageTmp > 0 && deffenderCounter >= tmpCardsDefending.Count)
                            {
                                DecrementHealth(discipleDamageTmp);
                            }

                        }
                        else
                        {
                            DecrementHealth(tmpEnemies[i].damageValue);
                        }
                        break;
                    case 2:
                        //Barbarian Archer Logic!
                        if (tmpCards.Count > 0)
                        {
                            tmpCards.Sort(delegate (Card x, Card y) { return y.numberOfUnits.CompareTo(x.numberOfUnits); });
                            tmpCards[0].TakeDamage(tmpEnemies[i].damageValue);
                        }
                        break;
                    case 3:
                        //Heathen Catapult Logic!
                        DecrementHealth(tmpEnemies[i].damageValue);
                        break;
                    default:
                        break;
                }
            }

        }
    }

    public void ProcessPlayer()
    {
        foreach (RectTransform child in playerField.transform)
        {
            Card tmpCard = child.GetComponentInChildren<Card>();

            if(!tmpCard.isAttacked && !tmpCard.isDeffended)
            {
                //Pray
                IncrementHealth(tmpCard.moneyValue);
            }

            tmpCard.NewRound();
            child.GetComponent<Button>().interactable = true;
        }
    }

    public void DrawCard()
    {
        GameObject tmp = Instantiate(cardPrefab, cardDeck.transform);
        Card tmpCard = tmp.transform.GetComponentInChildren<Card>();

        //Give Higher priority to cards later in the deck.
        int weightTotal = 0;
        int wiegthModifier = cardTypes.Length;
        for(int i = 0; i < cardTypes.Length; i++)
        {
            weightTotal += i + 1;
        }

        int result = 0, total = 0;
        int randVal = Random.Range(1, weightTotal + 1);
        for (result = 0; result < cardTypes.Length; result++)
        {
            total += result + 1;
            //Debug.Log("total " + total + " card index " + result + " Wiegths " + weightTotal + " Rand va " + randVal);
            if (total >= randVal) break;
        }

        tmpCard.cardData = cardTypes[result];
        tmpCard.gameplayManager = this;
        tmpCard.Spawn(true);
    }

    public void AssignUnit(GameObject playerUnit)
    {
        if (currentCard != null)
        {
            //Cicking on a unit after picking a card.
            Card tmpCard = currentCard.transform.GetComponentInChildren<Card>();
            Card unitCard = playerUnit.GetComponent<Card>();

            DecrementHealth(tmpCard.cardData.costValue);

            if (unitCard.cardData == null)
            {
                //Fresh Spawn!
                unitCard.cardData = tmpCard.cardData;
                unitCard.Spawn(false);
            }
            else
            {
                if (unitCard.cardData.nameValue == tmpCard.cardData.nameValue)
                {
                    //Improve unit
                    unitCard.Spawn(false);
                }
                else
                {
                    //Replace unit
                    unitCard.Die();
                    unitCard.cardData = tmpCard.cardData;
                    unitCard.Spawn(false);
                }
            }


            Destroy(currentCard.transform.parent.gameObject);
            currentCard = null;
        }
        else
        {
            //Cicking on a unit without picking a card.


        }

        //Clicking on a unit.
        if (playerUnit.GetComponent<Card>().cardData == null)
        {
            return;
        }

        currentUnit = playerUnit;
        deffendText.SetActive(true);
    }

    public void AttackUnit(GameObject enemyUnit)
    {
        if (currentUnit != null)
        {
            //Click on enemy unit after clicking on player unit
            Enemy enemyCard = enemyUnit.GetComponent<Enemy>();
            Card unitCard = currentUnit.GetComponentInChildren<Card>();

            if (!unitCard.isAttacked && !unitCard.isDeffended && enemyCard.healthValue > 0)
            {
                int returnDamage = enemyCard.healthValue;
                enemyCard.TakeDamage(unitCard.damageValue);
                unitCard.isAttacked = true;

                if (unitCard.cardData.nameValue == "Hoplite")
                {
                    unitCard.TakeDamage(returnDamage);
                }
                
                currentUnit.GetComponent<Button>().interactable = false;
            }
        }
    }

    public void DeffendUnit()
    {
        if (currentUnit != null)
        {
            deffendText.SetActive(false);
            Card unitCard = currentUnit.GetComponentInChildren<Card>();

            if (!unitCard.isAttacked && !unitCard.isDeffended)
            {
                unitCard.isDeffended = true;
                currentUnit.GetComponent<Button>().interactable = false;
            }
        }
    }

    public void AssignCard(GameObject card)
    {
        currentCard = card;
    }

    public void DeselectUnit()
    {
        currentUnit = null;
        deffendText.SetActive(false);
    }

    public void DeselectCard()
    {
        currentCard = null;
    }
}
