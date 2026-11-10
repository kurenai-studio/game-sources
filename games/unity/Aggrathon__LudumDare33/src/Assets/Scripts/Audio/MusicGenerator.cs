using UnityEngine;
using System.Collections;

public class MusicGenerator : MonoBehaviour {
	
	public AudioClip chord1;
	public int chordNote1;
	public AudioClip chord2;
	public int chordNote2;
	public AudioClip chord3;
	public int chordNote3;
	[Space(5)]
	public AudioSource drum;
	public AudioSource chord;
	public AudioSource notes1;
	public AudioSource notes2;
	[Space(5)]
	public float noteLength;
	public float noteStart;
	public int noteNum;
	[Space(5)]
	public AnimationCurve melodyPriority;
	public int melodyMaxJump;

	private int note;
	private bool noteAlt = false;
	private float noteTime;
	private float time = 0;

	void Start () {
		noteTime = drum.clip.length/4;
		chordPlayer();
	}

	void Update() {
		if(drum.time < time) {
			chordPlayer();
		}
		time = drum.time;
	}

	private void chordPlayer () {
		switch(Random.Range(0,3)) {
		case 0:
			chord.PlayOneShot(chord1);
			note = chordNote1;
			break;
		case 1:
			chord.PlayOneShot(chord2);
			note = chordNote2;
			break;
		case 2:
			chord.PlayOneShot(chord3);
			note = chordNote3;
			break;
		}
		StartCoroutine("melodyPlayer");
	}

	private IEnumerator melodyPlayer() {
		int sequence = 0;
		while(true) {
			if(noteAlt) {
				notes1.time = noteStart+noteLength*note;
			} else {
				notes2.time = noteStart+noteLength*note;
			}
			noteAlt = !noteAlt;
			sequence++;
			if(sequence > 3)
				break;
			do {
				note = note + (int)( Mathf.Sign(Random.Range(-1,1))*melodyPriority.Evaluate (Random.Range(0,1f))*melodyMaxJump );
			} while(note != Mathf.Clamp(note, 0, noteNum));
			yield return new WaitForSeconds(noteTime);
		}
	}
}
