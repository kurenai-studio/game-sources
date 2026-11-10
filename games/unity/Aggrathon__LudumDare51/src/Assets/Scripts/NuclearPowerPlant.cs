using UnityEngine;
using UnityEngine.UI;
using TMPro;

public class NuclearPowerPlant : APowerPlant
{
    // [SerializeField] float heatCapacity = 50f;
    // float heatContent;
    // [SerializeField] float energyPerHeat = 1.0f;
    // [SerializeField] float coolingRate = 0.2f;
    [SerializeField] float fuelCost = 0.35f;
    GameState state;

    [Header("UI")]
    [SerializeField] Slider valve;
    // [SerializeField] Image heatMeter;
    // [SerializeField] TextMeshProUGUI heatDelta;
    [SerializeField] Image powerMeter;
    [SerializeField] Image costMeter;
    // bool cooling;


    void Start()
    {
        // heatContent = heatCapacity;
        valve.value = 0.3f;// coolingRate;
        valve.minValue = 0f;
        valve.maxValue = maxPower;
        // cooling = true;
        // heatDelta.text = ">";
        state = GameState.Instance;
        state.AddPowerPlant(this);
        costMeter.fillAmount = GetCost() / maxCost;
    }

    void Update()
    {
        powerMeter.fillAmount = GetPower() / maxPower;
        costMeter.fillAmount = GetCost() / maxCost;
    }

    public override float GetPower()
    {
        return valve.value;
    }

    public override float GetCost()
    {
        return valve.value * fuelCost;
    }
}