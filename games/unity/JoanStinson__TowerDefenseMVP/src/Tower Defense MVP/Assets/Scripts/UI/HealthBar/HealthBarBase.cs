using UnityEngine;
using UnityEngine.UI;

namespace JGM.UI.HealthBar
{
    public abstract class HealthBarBase : MonoBehaviour
    {
        [SerializeField]
        protected Slider slider;

        protected void OnHealthChange(int health)
        {
            slider.value = health;
        }
    }
}
