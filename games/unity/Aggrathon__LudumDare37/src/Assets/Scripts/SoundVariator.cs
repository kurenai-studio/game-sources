using UnityEngine;
using System.Collections;

[RequireComponent(typeof(AudioSource))]
public class SoundVariator : MonoBehaviour
{
	public float maxVolume = 1f;
	public float minVolume = 0f;
	public float volumeSpeed = 2f;
	float volumeLerpStart;
	float volumeLerpEnd;
	float volumeLerpProgression;

	new AudioSource audio;

	void Start()
	{
		volumeLerpEnd = Random.Range(minVolume, maxVolume);
		volumeLerpProgression = 1f;
		audio = GetComponent<AudioSource>();
	}

	void Update()
	{
		volumeLerpProgression += Time.deltaTime / volumeSpeed;
		if(volumeLerpProgression > 1f)
		{
			volumeLerpStart = volumeLerpEnd;
			volumeLerpProgression = 0f;
			volumeLerpEnd = Random.Range(minVolume, maxVolume);
		}
		audio.volume = Mathf.Lerp(volumeLerpStart, volumeLerpEnd, volumeLerpProgression);
	}
}
