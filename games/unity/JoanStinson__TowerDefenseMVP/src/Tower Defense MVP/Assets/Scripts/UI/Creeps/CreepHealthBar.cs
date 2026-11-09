using JGM.Gameplay.Creeps;
using JGM.UI.HealthBar;
using UnityEngine;

namespace JGM.UI.Creeps
{
    public class CreepHealthBar : HealthBarBase
    {
        [SerializeField]
        private Creep creep;

        private void Start()
        {
            slider.maxValue = creep.MaxHealth;
            slider.value = creep.MaxHealth;
            creep.OnTakeDamage += OnHealthChange;
        }

        private void OnDestroy()
        {
            creep.OnTakeDamage -= OnHealthChange;
        }
    }
}
