package com.otalona.neondash;

import android.os.Bundle;
import com.badlogic.gdx.backends.android.AndroidApplication;
import com.badlogic.gdx.backends.android.AndroidApplicationConfiguration;

public class AndroidLauncher extends AndroidApplication {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        AndroidApplicationConfiguration config = new AndroidApplicationConfiguration();
        config.useAccelerometer = false;
        config.useCompass = false;
        config.useImmersiveMode = true;
        // Avoid requesting multisampling at startup; it is optional and can
        // prevent EGL context creation on some devices and emulator images.
        config.numSamples = 0;
        initialize(new NeonDashGame(), config);
    }
}
