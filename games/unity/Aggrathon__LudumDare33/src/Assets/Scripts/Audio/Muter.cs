using UnityEngine;
using UnityEngine.Audio;


public class Muter : MonoBehaviour {

	public GameObject music;

	public void ToggleMute() {
		music.SetActive(!music.activeSelf);
	}
}
