using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SaturationController : ProcessingControllerBase
{
    public override void SetValue(float value)
    {
        var newGradingSettings = m_profile.colorGrading.settings;
        newGradingSettings.basic.saturation = value;
        m_profile.colorGrading.settings = newGradingSettings;
    }
}
