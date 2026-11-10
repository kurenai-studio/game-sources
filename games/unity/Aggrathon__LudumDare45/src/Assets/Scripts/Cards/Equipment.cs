using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(menuName="Equipment")]
public class Equipment : ScriptableObject
{
    public Sprite sprite;
    public string description;
    public int rarity;
    public Type type;

    public Effect[] effects;

    public enum When { Combat, Turn, General }
    public enum Type { Head, Chest, Hand }

    [System.Serializable]
    public struct Effect
    {
        public When when;
        public int energy;
        public int cards;
        public int upgrades;
        public int health;
        public BaseCard card;
    }

    public void OnEquip(PlayerManager player) {
        foreach (var eff in effects)
        {
            if (eff.when == When.General) {
                player.upgrades.numUpgrades += eff.upgrades;
                player.maxHealth += eff.health;
                player.Heal(eff.health);
            }
        }
    }

    public void OnDequip(PlayerManager player) {
        foreach (var eff in effects)
        {
            if (eff.when == When.General) {
                player.upgrades.numUpgrades -= eff.upgrades;
                player.maxHealth -= eff.health;
                player.Heal(0, false);
            }
        }
    }
    
    public void OnCombat(PlayerManager player) {
        foreach (var eff in effects)
        {
            if (eff.when == When.Combat) {
                player.Heal(eff.health, false);
                for (int i = 0; i < eff.cards; i++)
                    player.deck.DrawToHand();
                player.deck.energy += eff.energy;
                if (eff.card != null)
                    player.deck.AddAtRandom(eff.card);
            }
        }
    }
    
    public void OnTurn(PlayerManager player) {
        foreach (var eff in effects)
        {
            if (eff.when == When.Turn) {
                player.Heal(eff.health, false);
                for (int i = 0; i < eff.cards; i++)
                    player.deck.DrawToHand();
                player.deck.energy += eff.energy;
            }
        }
    }
}
