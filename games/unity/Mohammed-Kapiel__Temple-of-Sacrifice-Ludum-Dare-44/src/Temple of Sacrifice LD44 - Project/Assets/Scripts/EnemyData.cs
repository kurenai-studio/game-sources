using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(fileName = "Enemy", menuName = "Custom/Enemy")]
public class EnemyData : ScriptableObject
{
    public string nameValue = "Barbarian";

    public int damageValue = 1;
    public int healthValue = 1;

    public Sprite image;
    public string flavourDescription = "A vile group of individuals driven by their lust for death, destruction and coin!.";
    public string gameplayDescription = "They focus completely on the first line of our deffences.";
}
