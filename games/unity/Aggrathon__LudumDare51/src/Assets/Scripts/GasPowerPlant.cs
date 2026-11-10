using UnityEngine;
using UnityEngine.UI;
using TMPro;

public class GasPowerPlant : APowerPlant
{
    [SerializeField] float baseCost = 0.3f;
    GameState state;

    [Header("UI")]
    [SerializeField] Slider valve;
    [SerializeField] Image powerMeter;
    [SerializeField] Image costMeter;

    float Cost { get { return baseCost + state.CarbonTax * 0.5f + state.GasPrice; } }

    void Start()
    {
        valve.value = 0.2f;
        valve.minValue = 0f;
        valve.maxValue = maxPower;
        state = GameState.Instance;
        state.AddPowerPlant(this);
        costMeter.fillAmount = baseCost * 0.2f;
    }

    void Update()
    {
        costMeter.fillAmount = GetCost() / maxCost;
        powerMeter.fillAmount = GetPower() / maxPower;
    }

    public override float GetPower()
    {
        return valve.value;
    }

    public override float GetCost()
    {
        return valve.value * Cost;
    }
}