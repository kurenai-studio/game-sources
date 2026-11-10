using UnityEngine;
using UnityEngine.UI;
using TMPro;

public class WindPowerPlant : APowerPlant
{
    [SerializeField] float energyMax = 0.3f;
    [SerializeField] float perlinScale = 0.1f;
    GameState state;

    [Header("UI")]
    [SerializeField] Image powerMeter;
    [SerializeField] Image costMeter;

    float Wind
    {
        get
        {
            float wind = Mathf.PerlinNoise1D(Time.time * perlinScale) * 0.9f;
            wind += Mathf.PerlinNoise1D(Time.time * perlinScale * 3f) * 0.1f;
            if (state.CurrentEvent != null)
            {
                wind = Mathf.Max(wind + state.CurrentEvent.wind, 0f);
            }
            return wind;
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
        return Wind * energyMax;
    }

    public override float GetCost()
    {
        return 0.03f;
    }
}