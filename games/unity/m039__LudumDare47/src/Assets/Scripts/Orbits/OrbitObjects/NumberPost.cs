using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;

public class NumberPost : BaseOrbitObject
{

    public int number = 1;

    public TextMeshPro textMeshPro;

    protected override void OnEnable()
    {
        base.OnEnable();

        UpdateTMP();
    }

    protected override void OnValidate()
    {
        base.OnValidate();

        UpdateTMP();
    }

    void UpdateTMP()
    {
        if (textMeshPro != null)
        {
            textMeshPro.text = number.ToString();
        }
    }

}
