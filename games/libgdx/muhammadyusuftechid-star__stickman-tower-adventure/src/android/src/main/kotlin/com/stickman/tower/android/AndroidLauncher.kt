package com.stickman.tower.android

import android.os.Build
import android.os.Bundle
import android.view.KeyEvent
import android.window.OnBackInvokedDispatcher
import com.badlogic.gdx.backends.android.AndroidApplication
import com.badlogic.gdx.backends.android.AndroidApplicationConfiguration
import com.stickman.tower.StickmanGame

/**
 * Android Launcher resmi untuk Stickman Tower Adventure.
 * Menghubungkan hardware key events (termasuk tombol BACK virtual 3-tombol dan
 * navigasi gestur usap tepi layar Android modern) langsung ke loop input libGDX.
 */
class AndroidLauncher : AndroidApplication() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        initialize(StickmanGame(), AndroidApplicationConfiguration().apply {
            useImmersiveMode = true
            useWakelock = true
            useAccelerometer = false
            useCompass = false
        })

        // Daftarkan Predictive Back Callback di Android 13+ (API 33+) agar gesture usap dari pinggir layar
        // memanggil dispatchBackEvent() alih-alih diabaikan OS saat Immersive Mode aktif
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            onBackInvokedDispatcher.registerOnBackInvokedCallback(
                OnBackInvokedDispatcher.PRIORITY_DEFAULT
            ) {
                dispatchBackEvent()
            }
        }
    }

    /**
     * Memancarkan event KEYCODE_BACK ke antrian input libGDX
     * sehingga Gdx.input.isKeyJustPressed(Keys.BACK) langsung aktif pada Screen yang berjalan.
     */
    private fun dispatchBackEvent() {
        val view = graphics?.view
        val downEvent = KeyEvent(KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_BACK)
        val upEvent = KeyEvent(KeyEvent.ACTION_UP, KeyEvent.KEYCODE_BACK)
        input?.onKey(view, KeyEvent.KEYCODE_BACK, downEvent)
        input?.onKey(view, KeyEvent.KEYCODE_BACK, upEvent)
    }

    override fun onBackPressed() {
        dispatchBackEvent()
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (keyCode == KeyEvent.KEYCODE_BACK && event != null) {
            val view = graphics?.view
            if (input?.onKey(view, keyCode, event) == true) {
                return true
            }
        }
        return super.onKeyDown(keyCode, event)
    }

    override fun onKeyUp(keyCode: Int, event: KeyEvent?): Boolean {
        if (keyCode == KeyEvent.KEYCODE_BACK && event != null) {
            val view = graphics?.view
            if (input?.onKey(view, keyCode, event) == true) {
                return true
            }
        }
        return super.onKeyUp(keyCode, event)
    }
}
