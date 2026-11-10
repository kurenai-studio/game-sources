using System;
using UnityEngine;
using UnityEngine.U2D;

public class CameraController : MonoBehaviour {
	public Transform target;
	public float cameraMouseFollow = 0.01f;
	public float cameraTargetFollow = 5f;
	public Shader blackAndWhite;
	public Shader grain;
	private Material blackAndWhiteMat;
	private Material grainMat;
	[HideInInspector]
	public float grainyness = 0;
	private float blend;
	public Transform replayPoint;
	public int scalex;
	public int scaley;

	void Start() {
		blackAndWhiteMat = new Material(blackAndWhite);
		grainMat = new Material(grain);

		transform.position = target.position;
	}

	void FixedUpdate() {
		if (Replay.IN_REPLAY && Replay.forwards) {
			transform.position = replayPoint.position;
			GetComponent<PixelPerfectCamera>().refResolutionX = 16*scalex;
			GetComponent<PixelPerfectCamera>().refResolutionY = 9*scaley;
		}

		Vector3 mouseWorldPos = Camera.main.ScreenToWorldPoint(Input.mousePosition);

		Vector3 targetToMouse = mouseWorldPos - target.position;

		transform.position += (target.transform.position.x * Vector3.right + target.transform.position.y * Vector3.up + targetToMouse * cameraMouseFollow) * cameraTargetFollow * Time.deltaTime;
		transform.position /= 1 + cameraTargetFollow * Time.deltaTime;
		transform.position = transform.position.x * Vector3.right + transform.position.y * Vector3.up + 10 * Vector3.back;
	}

	void OnRenderImage(RenderTexture source, RenderTexture destination) {
		blend = (blend * 19.0f + Time.timeScale) * 0.05f;

		if (Time.timeScale == 1) {
			Graphics.Blit(source, destination, grainMat);
			grainMat.SetFloat("_Strength", grainyness + 0.05f);
			return;
		}

		blackAndWhiteMat.SetFloat("_blend", blend);
		Graphics.Blit(source, destination, blackAndWhiteMat);
	}

	internal void SetTarget(Transform target) {
		this.target = target;
	}
}
