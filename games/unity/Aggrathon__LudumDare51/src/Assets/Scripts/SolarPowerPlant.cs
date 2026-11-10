using UnityEngine;
using UnityEngine.UI;
using TMPro;

public class SolarPowerPlant : APowerPlant
{
    [SerializeField] float energyMax = 0.2f;
    GameState state;

    [Header("UI")]
    [SerializeField] Image powerMeter;
    [SerializeField] Image costMeter;

    float Sun
    {
        get
        {
            float sun = Mathf.Max(Mathf.Cos(state.DayFrac * Mathf.PI * 2f - Mathf.PI) + 0.25f, 0f);
            if (state.CurrentEvent != null)
            {
                sun *= 1 - 0.5f * state.CurrentEvent.rain;
            }
            return sun;
        }
    }

    void Start()
    {
        state = GameState.Instance;
        state.AddPowerPlant(this);
        costMeter.fillAmount = GetCost() / maxCost;
    }

    void Update()
    {
        powerMeter.fillAmount = GetPower() / maxPower;
    }

    public override float GetPower()
    {
        return Sun * energyMax;
    }

    public override float GetCost()
    {
        return 0.03f;
    }
}