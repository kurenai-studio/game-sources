using JGM.Gameplay;
using JGM.Gameplay.Base;
using JGM.UI.HealthBar;

namespace JGM.UI.Base
{
    public class PlayerBaseHealthBar : HealthBarBase
    {
        private PlayerBase playerBase;

        private void Awake()
        {
            playerBase = ServiceLocator.Instance.Get<PlayerBase>();
            slider.maxValue = playerBase.MaxHealth;
            slider.value = playerBase.MaxHealth;
        }

        private void OnEnable()
        {
            playerBase.OnHealthChange += OnHealthChange;
        }

        private void OnDisable()
        {
            playerBase.OnHealthChange -= OnHealthChange;
        }
    }
}
