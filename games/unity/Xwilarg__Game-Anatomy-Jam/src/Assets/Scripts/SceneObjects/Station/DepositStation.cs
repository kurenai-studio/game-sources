using AnatomyJam.Character;
using AnatomyJam.Material;
using AnatomyJam.Player;
using AnatomyJam.SceneObjects;
using AnatomyJam.SceneObjects.Station;
using AnatomyJam.SO;
using UnityEngine;

namespace Assets.Scripts.SceneObjects.Station
{
    public class DepositStation : AStation
    {
        [SerializeField]
        private CharacterClass _target;

        public override void Deposit(PlayerController pc, SceneObject obj)
        {
            PartyManager.S.GiveItem(obj.GetComponent<Armor>().Value, _target);
        }
    }
}
