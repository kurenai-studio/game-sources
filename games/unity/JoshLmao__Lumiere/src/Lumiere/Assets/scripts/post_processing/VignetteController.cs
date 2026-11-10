using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.PostProcessing;

public class VignetteController : ProcessingControllerBase
{
    public override void SetValue(float value)
    {
        var vigentte = m_profile.vignette.settings;
        vigentte.smoothness = value;
        m_profile.vignette.settings = vigentte;
    }
}
