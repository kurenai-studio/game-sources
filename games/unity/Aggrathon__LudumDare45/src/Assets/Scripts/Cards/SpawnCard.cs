using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(menuName="Cards/SpawnCard")]
public class SpawnCard : BaseCard
{
    public Unit unit;

    public override string GetDescription() {
        return "Summon a " + unit.unitName;
    }

    public override bool Cast(BoardTarget target, DeckManager manager) {
        if (manager.energy < cost) {
            manager.Alert("Not enough energy!");
            return false;
        }
        if (target == null) {
            manager.Alert("Must target the board!");
            return false;
        }
        if (target.unit != null) {
            manager.Alert("Space is already occupied!");
            return false;
        } else {
            if (this.target == Target.Spawn && !Utils.Vector3InBox(manager.transform.position, manager.spawnPositionLimit, target.transform.position)) {
                manager.Alert("Can only be spawned on the homerow!");
                return false;
            }
            manager.energy -= cost;
            Instantiate(unit, target.transform.position, Quaternion.identity).Setup(manager, target);
            return true;
        }
    }
}
