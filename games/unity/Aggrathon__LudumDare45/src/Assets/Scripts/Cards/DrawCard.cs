using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(menuName="Cards/DrawCard")]
public class DrawCard : BaseCard
{
    public int num;
    public bool discard;

    public override string GetDescription() {
        if (discard) {
            return "Discard your hand and redraw it";
        } else {
            return "Draw "+num+" Cards";
        }
    }

    public override bool Cast(BoardTarget target, DeckManager manager) {
        if (manager.energy < cost) {
            manager.Alert("Not enough energy!");
            return false;
        }
        if (discard) {
            var hand = manager.handTransform.GetComponentsInChildren<CardUI>();
            num = hand.Length;
            foreach (var c in hand)
            {
                manager.Discard(c.card);
                Destroy(c.gameObject);
            }
        } else {
            manager.Discard(this);
        }
        for (int i = 0; i < num; i++)
        {
            manager.DrawToHand();
        }
        manager.energy -= cost;
        return true;
    }
}
