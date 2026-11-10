using UnityEngine;
using UnityEngine.UI;
using TMPro;

public class WaterPowerPlant : APowerPlant
{
    [SerializeField] float waterCapacity = 50f;
    float waterContent;
    [SerializeField] float energyPerWater = 1.0f;
    [SerializeField] float rainRefillRate = 0.2f;
    GameState state;

    [Header("UI")]
    [SerializeField] Slider valve;
    [SerializeField] Image waterMeter;
    [SerializeField] TextMeshProUGUI waterDelta;
    [SerializeField] Image powerMeter;
    [SerializeField] Image costMeter;
    bool filling;

    float RefillRate
    {
        get
        {
            float rain = 1f;
            if (state.CurrentEvent != null)
                rain = Mathf.Max(0.2f, rain + state.CurrentEvent.rain);
            return rainRefillRate * rain;
        }
    }

    void Start()
    {
        waterContent = waterCapacity;
        valve.value = rainRefillRate * 1.5f;
        valve.minValue = 0f;
        valve.maxValue = maxPower;
        filling = true;
        waterDelta.text = ">";
        state = GameState.Instance;
        state.AddPowerPlant(this);
        costMeter.fillAmount = GetCost() / maxCost;
    }

    void Update()
    {
        float refill = RefillRate;
        waterContent += (refill - valve.value) * Time.deltaTime;
        if (waterContent < 0f)
        {
            waterContent = 0f;
        }
        else if (waterContent > waterCapacity)
        {
            waterContent = waterCapacity;
        }
        if ((valve.value > refill) == filling)
        {
            filling = !filling;
            waterDelta.text = filling ? ">" : "<";
        }
        waterMeter.fillAmount = waterContent / waterCapacity;
        powerMeter.fillAmount = GetPower() / maxPower;
    }

    public override float GetPower()
    {
        return Mathf.Min(waterCapacity + RefillRate, valve.value) * energyPerWater;
    }

    public override float GetCost()
    {
        return 0.05f;
    }
}