using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(menuName="Cards/MissileAreaCard")]
public class MissileAreaCard : BaseCard
{
    public int damage = 1;
    public float radius = 1.5f;

    public override string GetDescription() {
        return string.Format("Deal {0} damage in an area with radius {1:0.0}", damage, radius);
    }

    public override bool Cast(BoardTarget target, DeckManager manager) {
        if (manager.energy < cost) {
            manager.Alert("Not enough energy!");
            return false;
        }
        foreach (var b in target.board.targets)
        {
            if (b.unit != null && (b.transform.localPosition - target.transform.localPosition).sqrMagnitude < radius*radius) {
                if (damage < 0)
                    b.unit.Heal(-damage);
                else
                    b.unit.Damage(damage);
            }
        }
        manager.Discard(this);
        manager.energy -= cost;
        return true;
    }
}
