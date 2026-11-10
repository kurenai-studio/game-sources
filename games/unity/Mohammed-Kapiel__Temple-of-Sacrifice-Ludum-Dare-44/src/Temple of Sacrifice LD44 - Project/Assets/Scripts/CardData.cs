using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(fileName = "Card", menuName = "Custom/Card")]
public class CardData : ScriptableObject
{
    public string nameValue = "Hoplite";
    public int costValue = 5;

    public int damageValue = 2;
    public int healthValue = 2;

    public int moneyValue = 2;

    public Sprite image;
    public string description = "A holy warrior who fights with shield and spear!";
}
