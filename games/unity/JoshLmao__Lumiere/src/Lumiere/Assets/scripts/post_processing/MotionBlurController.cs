using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.PostProcessing;

public class MotionBlurController : ProcessingControllerBase
{
    public override void SetValue(float value)
    {
        var blurSettings = m_profile.motionBlur.settings;
        blurSettings.frameBlending = value;
        m_profile.motionBlur.settings = blurSettings;
    }
}
