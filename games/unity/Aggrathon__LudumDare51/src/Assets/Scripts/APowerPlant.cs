using UnityEngine;

public abstract class APowerPlant : MonoBehaviour
{
    protected const float maxPower = 0.5f;
    protected const float maxCost = 0.5f;

    public abstract float GetPower();

    public abstract float GetCost();
}