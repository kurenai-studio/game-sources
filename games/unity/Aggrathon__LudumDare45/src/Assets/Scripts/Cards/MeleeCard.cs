using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(menuName="Cards/MeleeCard")]
public class MeleeCard : BaseCard
{
    public int damage;

    public override string GetDescription() {
        return "Deal " + damage + " melee damage";
    }

    public override bool Cast(BoardTarget target, DeckManager manager) {
        if (manager.energy < cost) {
            manager.Alert("Not enough energy!");
            return false;
        }
        if (target == null || target.unit == null) {
            manager.Alert("Invalid target!");
            return false;
        }
        if (target.unit.team == manager) {
            manager.Alert("Target is friendly!");
            return false;
        }
        if ((target.transform.localPosition - target.transform.parent.InverseTransformPoint(manager.transform.position)).sqrMagnitude > 1.8f) {
            manager.Alert("Target is too far away!");
            return false;
        }
        if (damage < 0)
            target.unit.Heal(-damage);
        else
            target.unit.Damage(damage);
        manager.AddAtRandom(this);
        manager.energy -= cost;
        return true;
    }
}
