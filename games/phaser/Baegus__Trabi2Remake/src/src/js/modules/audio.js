const toggleMute = (scene) => {
	const muted = scene.sound.mute;
	const newState = !muted;
	scene.sound.setMute(newState);
	return newState;
}

const playSound = (scene, name, config=false) => {
	if (scene.sound.mute) return;
	const {rng,sound} = scene;
	const sample = sound.add(name,{
		loop: config.loop || false
	});
	let targetVolume = 1;
	let targetRate = 1;
	if (config) {
		if (config.pitch?.length === 2) {
			targetRate = rng.realInRange(config.pitch[0],config.pitch[1]);
		}
		if (config.pitch?.length === 1) {
			targetRate = config.pitch[0];
		}
		if (config.volume?.length === 2) {
			targetVolume = rng.realInRange(config.volume[0],config.volume[1]);
		}
		if (config.volume?.length === 1) {
			targetVolume = config.volume[0];
		}
	}
	if (scene.sound.mute) {
		targetVolume = 0;
	}
	sample.setRate(targetRate);
	sample.fadeIn = (duration=500) => {
		if (scene.sound.mute) return;
		const helper = {
			value: 0
		};
		const fadeTween = scene.tweens.add({
			targets: helper,
			value: targetVolume,
			duration: duration,
			ease: "Sine.easeIn",
			onUpdate: () => {
				sample.setVolume(helper.value);
			}
		});
	}
	sample.fadeOut = (duration=500) => {
		if (scene.sound.mute) return;
		const helper = {
			value: sample.volumeNode.gain.value || 1
		};
		const fadeTween = scene.tweens.add({
			targets: helper,
			value: 0,
			duration: duration,
			ease: "Sine.easeOut",
			onUpdate: () => {
				sample.setVolume(helper.value);
			},
			onComplete: () => {
				sample.setVolume(0);
				sample.destroy();
			}
		});
	}
	if (config.fadeIn) {
		sample.setVolume(0);
		sample.fadeIn(config.fadeInTime);
	} else {
		sample.setVolume(targetVolume);
	}
	sample.play();
	return sample;
}

const playMusicTrack = (scene, track) => {
	// Ensure a sensible default for musicVolume exists in registry
	if (typeof scene.registry.get("musicVolume") === "undefined") {
		scene.registry.set("musicVolume", 15);
	}
	const steps = scene.registry.get("musicVolume");
	const config = {
		volume: [(steps/15)*0.2]
	};

	// If there's already a music sample playing, fade it out before replacing
	const existing = scene.registry.get("musicSample");
	if (existing) {
		try {
			if (existing.fadeOut) existing.fadeOut(500);
			else existing.destroy();
		} catch (err) {
			try { existing.destroy(); } catch (e) {}
		}
		scene.registry.set("musicSample", null);
	}

	const sample = playSound(scene, `HUDBA.SND-SND${track}`, config);
	// store current music sample and track so other helpers can control it
	scene.registry.set("musicSample", sample);
	scene.registry.set("musicTrack", track);
	return sample;
};

// Set music volume steps in range [0..15]. If steps==0, fade out and clear music sample.
const setMusicVolume = (scene, steps) => {
	// normalize and save
	if (typeof steps !== 'number') return;
	if (steps < 0) steps = 0;
	if (steps > 15) steps = 15;
	scene.registry.set("musicVolume", steps);

	const targetVolume = (steps / 15) * 0.2;
	const sample = scene.registry.get("musicSample");

	if (steps === 0) {
		// immediately stop and remove sample (no fading)
		if (sample) {
			try {
				if (sample.stop) sample.stop();
				sample.destroy();
			} catch (err) {
				try { sample.destroy(); } catch (e) {}
			}
			scene.registry.set("musicSample", null);
		}
		return;
	}

	// steps > 0
	if (sample) {
		try {
			sample.setVolume(targetVolume);
		} catch (err) {
			// ignore
		}
	} else {
		// No music playing — start the previously played track (or track 2 by default)
		const track = scene.registry.get("musicTrack") || 2;
		playMusicTrack(scene, track);
	}
}

export { toggleMute, playSound, playMusicTrack, setMusicVolume }