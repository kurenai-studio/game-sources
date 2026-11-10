using UnityEngine;
using UnityEngine.UI;

public class DoubleEndedMeter : MonoBehaviour
{
    public Image forward;
    public Image reverse;
    [Range(0, 1)] public float maxForward = 1f;

    [Range(0, 1)] public float maxReverse = 1f;


    public float value
    {
        get
        {
            return _value;
        }
        set
        {
            if (value < 0)
            {
                forward.fillAmount = 0f;
                reverse.fillAmount = -value * maxReverse;
            }
            else
            {
                reverse.fillAmount = 0f;
                forward.fillAmount = value * maxForward;
            }
            _value = value;
        }
    }

    float _value = 0f;
}
