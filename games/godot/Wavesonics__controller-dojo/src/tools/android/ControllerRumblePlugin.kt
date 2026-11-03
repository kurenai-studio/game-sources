package com.godot.game.rumble

import android.media.AudioAttributes
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.view.InputDevice
import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.UsedByGodot

class ControllerRumblePlugin(godot: Godot) : GodotPlugin(godot) {

	private val gameAudioAttributes: AudioAttributes = AudioAttributes.Builder()
		.setUsage(AudioAttributes.USAGE_GAME)
		.setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
		.build()

	override fun getPluginName() = PLUGIN_NAME

	@UsedByGodot
	fun getGamepadIds(): IntArray = gamepads().map { it.id }.toIntArray()

	@UsedByGodot
	fun getGamepadName(deviceId: Int): String = InputDevice.getDevice(deviceId)?.name ?: ""

	@UsedByGodot
	fun hasVibrator(deviceId: Int): Boolean = vibratorFor(deviceId) != null

	@UsedByGodot
	fun rumbleDevice(deviceId: Int, amplitude: Float, durationMs: Int): Boolean {
		if (amplitude <= 0f || durationMs <= 0) {
			return false
		}
		val vibrator = vibratorFor(deviceId) ?: return false
		vibrate(vibrator, amplitude, durationMs)
		return true
	}

	@UsedByGodot
	fun rumble(amplitude: Float, durationMs: Int): Boolean {
		var vibrated = false
		for (device in gamepads()) {
			vibrated = rumbleDevice(device.id, amplitude, durationMs) || vibrated
		}
		return vibrated
	}

	@UsedByGodot
	fun stopRumble() {
		for (device in gamepads()) {
			vibratorFor(device.id)?.cancel()
		}
	}

	private fun gamepads(): List<InputDevice> = InputDevice.getDeviceIds()
		.toList()
		.mapNotNull { InputDevice.getDevice(it) }
		.filter { it.isGamepadLike() }

	private fun InputDevice.isGamepadLike(): Boolean {
		val isGamepad = sources and InputDevice.SOURCE_GAMEPAD == InputDevice.SOURCE_GAMEPAD
		val isJoystick = sources and InputDevice.SOURCE_JOYSTICK == InputDevice.SOURCE_JOYSTICK
		return !isVirtual && (isGamepad || isJoystick)
	}

	private fun vibratorFor(deviceId: Int): Vibrator? {
		val device = InputDevice.getDevice(deviceId) ?: return null
		val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
			device.vibratorManager.defaultVibrator
		} else {
			@Suppress("DEPRECATION")
			device.vibrator
		}
		return vibrator?.takeIf { it.hasVibrator() }
	}

	private fun vibrate(vibrator: Vibrator, amplitude: Float, durationMs: Int) {
		val duration = durationMs.toLong().coerceIn(MIN_DURATION_MS, MAX_DURATION_MS)
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
			val strength = if (vibrator.hasAmplitudeControl()) {
				(amplitude.coerceIn(0f, 1f) * MAX_AMPLITUDE).toInt().coerceIn(1, MAX_AMPLITUDE)
			} else {
				VibrationEffect.DEFAULT_AMPLITUDE
			}
			vibrator.vibrate(VibrationEffect.createOneShot(duration, strength), gameAudioAttributes)
		} else {
			@Suppress("DEPRECATION")
			vibrator.vibrate(duration, gameAudioAttributes)
		}
	}

	private companion object {
		const val PLUGIN_NAME = "ControllerRumble"
		const val MIN_DURATION_MS = 1L
		const val MAX_DURATION_MS = 5000L
		const val MAX_AMPLITUDE = 255
	}
}
