using System.Linq;
using UnityEngine;

namespace AnatomyJam.Character
{
    public class PartyManager : MonoBehaviour
    {
        public static PartyManager S;

        [SerializeField]
        public UIDisplay[] _displays;

        private CharacterBehavior[] _team;

        private void Awake()
        {
            S = this;
            _team = _displays.Select(x => new CharacterBehavior(x, x.Info)).ToArray();
        }

        public bool IsPartyAlive => _team.Any(x => x.IsAlive);

        public CharacterBehavior GetRandomCharacter()
        {
            var stillAlive = _team.Where(x => x.IsAlive).ToArray();
            return stillAlive[Random.Range(0, stillAlive.Length)];
        }

        public void Revive()
        {
            foreach (var character in _team)
            {
                character.Revive();
            }
        }

        public void ReadyForFight()
        {
            foreach (var character in _team)
            {
                character.ReadyForFight();
            }
        }

        public void SetRunningState(bool value)
        {
            foreach (var character in _team)
            {
                character.ToggleWalkAnimation(value);
            }
        }

        public void UpdateTimers(CharacterBehavior target, float deltaTime)
        {
            foreach (var character in _team)
            {
                if (!character.IsAlive)
                {
                    // KOed characters can't fight
                    continue;
                }

                character.PassTime(deltaTime, 1.5f);
                if (character.CanAttack)
                {
                    character.Attack(character.TargetType == SO.TargetType.Enemy ? target : GetRandomCharacter());
                }
            }
        }

        public void Rearm()
        {
            foreach (var character in _team)
            {
                character.UpdateEquipement();
            }
        }

        public void GiveItem(float level, SO.CharacterClass hero_ID)
        {
            _team.FirstOrDefault(x => x.Class == hero_ID).NextEquipement += level;
        }
    }
}
