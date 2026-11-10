using AnatomyJam.SO;
using AnatomyJam.Util;
using UnityEngine;

namespace AnatomyJam.Character
{
    [System.Serializable]
    public class CharacterBehavior
    {
        private int _maxHealth, _maxMana;
        private int _currentHealth, _currentMana;

        private UIDisplay _display;
        public SO.CharacterInfo _info;

        public float _timeBeforeAttack;

        public float NextEquipement
        {
            set; get;
        } = 0;

        public float _currentEquipement = 1f;

        public int _armor;
        public Range<int> _attack;

        public CharacterBehavior(UIDisplay display, SO.CharacterInfo info)
        {
            _display = display;
            _info = info;

            _maxHealth = info.BaseHealth;
            _maxMana = info.BaseMana;
            _currentHealth = _maxHealth;
            _currentMana = _maxMana;
            _armor = _info.BaseArmor;
            _attack = _info.BaseAttack;
            display.Init(info);

            if (info.EnemySprite != null)
            {
                _display.UpdateSprite(info.EnemySprite);
            }
        }

        public void Revive()
        {
            _currentHealth = _maxHealth;
            _currentMana = _maxMana;
            _armor = Mathf.RoundToInt(_info.BaseArmor * _currentEquipement);
            _attack = new Range<int>()
            {
                Min = Mathf.RoundToInt(_info.BaseAttack.Min * _currentEquipement),
                Max = Mathf.RoundToInt(_info.BaseAttack.Max * _currentEquipement)
            };
            _display.Init(_info);
            _display.Toggle(true);
        }

        public bool IsAlive => _currentHealth > 0;
        public bool CanAttack => _timeBeforeAttack <= 0f;
        public TargetType TargetType => _info.TargetType;
        public CharacterClass Class => _info.Class;

        public void ToggleWalkAnimation(bool state)
        {
            _display.ToggleWalkAnimation(state);
        }

        /// <summary>
        /// Lower health given the damage given in parameter
        /// If damage is negative, will heal the character instead
        /// </summary>
        public void TakeDamage(int value)
        {
            // Substract armor
            if (value > 0)
            {
                value = Mathf.Clamp(value - _armor, 0, value);
            }
            _currentHealth = Mathf.Clamp(_currentHealth - value, 0, _maxHealth);
            _display.UpdateHealth((float)_currentHealth / _maxHealth);
        }

        /// <summary>
        /// Attack the target given in parameter
        /// </summary>
        public void Attack(CharacterBehavior target)
        {
            var damage = Mathf.RoundToInt(Random.Range(_attack.Min, _attack.Max));
            target.TakeDamage(damage);
            _display.TriggerAttackAnimation();
            ResetTimerAttack();
        }

        /// <summary>
        /// Called when a fight start, reset the state
        /// </summary>
        public void ReadyForFight()
        {
            ResetTimerAttack();
        }

        /// <summary>
        /// Called every frame, reduce the attack timer
        /// </summary>
        public void PassTime(float deltaTime, float timeMult = 1f)
        {
            _timeBeforeAttack -= deltaTime * timeMult;
        }

        /// <summary>
        /// Called once an attack was done, reset the timer for the next attack
        /// </summary>
        private void ResetTimerAttack()
        {
            _timeBeforeAttack = Random.Range(_info.AttackSpeed.Min, _info.AttackSpeed.Max);
        }

        public void UpdateEquipement()
        {
            _currentEquipement += NextEquipement;
            NextEquipement = 0;
        }

        public override string ToString() => $"{_info.Name} ({_info.Class}): {_currentHealth} / {_maxHealth} HP";
    }
}
