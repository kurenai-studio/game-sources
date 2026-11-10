using UnityEngine;
using System.Collections;

public class AudioController : MonoBehaviour
{
	public static AudioController instance { get; protected set; }
	new private AudioSource audio;

	public AudioClip launchAudio;
	public AudioClip shieldAudio;
	public AudioClip upgradeAudio;
	public AudioClip damageAudio;
	public AudioClip tuneAudio;

	void Start()
	{
		audio = GetComponent<AudioSource>();
		instance = this;
		Tune();
	}

	public static void Launch() { instance.audio.PlayOneShot(instance.launchAudio); }
	public static void Shield() { instance.audio.PlayOneShot(instance.shieldAudio); }
	public static void Upgrade() { instance.audio.PlayOneShot(instance.upgradeAudio); }
	public static void Damage() { instance.audio.PlayOneShot(instance.damageAudio); }
	public static void Tune() { instance.audio.PlayOneShot(instance.tuneAudio); }


}

