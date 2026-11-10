using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(menuName="Cards/SlowMissileCard")]
public class SlowMissileCard : BaseCard
{
    public int damage;

    public override string GetDescription() {
        return "Deal " + damage + " damage and slow down their movement";
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
            if (target.unit.team == manager) {
                manager.Alert("Target is friendly!");
                return false;
            }
            target.unit.moveDist = Mathf.Max(1.1f, target.unit.moveDist * 0.6f);
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
