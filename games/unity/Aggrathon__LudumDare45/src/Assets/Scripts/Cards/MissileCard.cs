using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(menuName="Cards/MissileCard")]
public class MissileCard : BaseCard
{
    public int damage;

    public override string GetDescription() {
        if (damage < 0)
            return "Heal a summoned creature";
        return "Deal " + damage + " damage";
    }

    public override bool Cast(BoardTarget target, DeckManager manager) {
        if (manager.energy < cost) {
            manager.Alert("Not enough energy!");
            return false;
        }
        if (target == null || target.unit == null) {
            manager.Alert("Invalid target!");
            return false;
        } else {
            if (damage > 0 && target.unit.team == manager) {
                manager.Alert("Target is friendly!");
                return false;
            }
            if (damage < 0 && target.unit.team != manager) {
                manager.Alert("Target is not friendly!");
                return false;
            }
            if (damage < 0)
                target.unit.Heal(-damage);
            else
                target.unit.Damage(damage);
            manager.Discard(this);
            manager.energy -= cost;
            return true;
        }
    }
}
