using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.PostProcessing;

public abstract class ProcessingControllerBase : MonoBehaviour
{
    public enum ValueCalculate
    {
        BetweenValues,
        Remainder,
        MinimumLargerThanMaximum,
    }

    public float MinimumValue;
    public float MaximumValue;

    [SerializeField]
    protected GameController m_game;

    [SerializeField]
    protected PostProcessingProfile m_profile;

    protected PlayerController m_player;

    public ValueCalculate CalculateValue = ValueCalculate.BetweenValues;

    void Start()
    {
        SetDefaultValue();
    }

    void FixedUpdate()
    {
        //No better way of naming these
        switch(CalculateValue)
        {
            case ValueCalculate.BetweenValues:
                SetValue(BetweenValues());
                break;
            case ValueCalculate.Remainder:
                SetValue(Remainder());
                break;
            case ValueCalculate.MinimumLargerThanMaximum:
                SetValue(MinimumLargerThanMaximum());
                break;
        }
    }

    public void OnDestroy()
    {
        SetDefaultValue();
    }

    void SetDefaultValue()
    {
        SetValue(MinimumValue);
    }

    public abstract void SetValue(float value);

    float BetweenValues()
    {
        var percentage = (m_game.Player.CurrentHealth / 100) * Constants.PLAYER_TOTAL_HEALTH;
        var range = MinimumValue + MaximumValue;
        float betweenOneZero = (float)percentage / 100;
        var value = range * betweenOneZero;
        var inverted = MaximumValue - value;
        return inverted;
    }

    float Remainder()
    {
        var percentage = (m_game.Player.CurrentHealth / 100) * Constants.PLAYER_TOTAL_HEALTH;
        var range = MinimumValue + MaximumValue;
        float betweenOneZero = (float)percentage / 100;
        var value = range * betweenOneZero;
        var inverted = 1 - value;
        return inverted;
    }

    float MinimumLargerThanMaximum()
    {
        var percentage = (m_game.Player.CurrentHealth / 100) * Constants.PLAYER_TOTAL_HEALTH;
        float betweenOneZero = (float)percentage / 100; //percetage as a number between 1 and 0

        var range = MinimumValue - MaximumValue;
        var value = range * betweenOneZero;
        var inverted = MaximumValue + value;
        return inverted;
    }
}
