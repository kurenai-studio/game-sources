using UnityEngine;

public class MusicController : MonoBehaviour {
	private AudioSource music;
	public AudioClip[] clips;
	public int score;


	// Start is called before the first frame update
	void Start() {
		music = GetComponent<AudioSource>();
		music.Play();

	}

	// Update is called once per frame
	void Update() {

	}

	public void Score(int score) {
		music.clip = clips[score];
	}
}
