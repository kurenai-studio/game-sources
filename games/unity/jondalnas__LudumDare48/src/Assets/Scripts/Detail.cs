using UnityEngine;
using UnityEngine.Tilemaps;

public class Detail : MonoBehaviour {
	private Tilemap tilemap;

	//private float currColorH, currColorS, currColorV;
	//private float changeColorH, changeColorS, changeColorV;
	private Color targetColor;
	private Color currColor;

	private float timer;
	private float speed;

	private Vector3 colPos;

	void Start() {
		tilemap = GetComponent<Tilemap>();
		SetColor(Color.red);
	}

	void Update() {
		//Debug.Log(changeColorH + ", " + currColorH + ", " + ((changeColorH - currColorH) > 0 ? Mathf.Lerp(changeColorH, currColorH, timer / maxTimer) : Mathf.Lerp(changeColorH + 1, currColorH, timer / maxTimer)));

		//Color c = Color.HSVToRGB((changeColorH - currColorH) > 0 ? Mathf.Lerp(changeColorH, currColorH, timer / maxTimer) : Mathf.Lerp(changeColorH - currColorH, currColorH, timer / maxTimer), Mathf.Lerp(changeColorS, currColorS, timer / maxTimer), Mathf.Lerp(changeColorV, currColorV, timer / maxTimer));
		//Color c = Color.HSVToRGB(Mathf.Lerp(changeColorH, currColorH, timer / maxTimer), Mathf.Lerp(changeColorS, currColorS, timer / maxTimer), Mathf.Lerp(changeColorV, currColorV, timer / maxTimer));

		Vector3Int colCelPos = tilemap.WorldToCell(colPos);

		foreach (Vector3Int pos in tilemap.cellBounds.allPositionsWithin) {
			float dist = (pos - colCelPos).sqrMagnitude;

			tilemap.RemoveTileFlags(pos, TileFlags.LockColor);
			tilemap.SetColor(pos, dist < timer * timer * speed ? targetColor : currColor);
			tilemap.SetTileFlags(pos, TileFlags.LockColor);
		}

		timer += Time.deltaTime;
	}

	public void SetColor(Color color) {
		foreach (Vector3Int pos in tilemap.cellBounds.allPositionsWithin) {
			tilemap.RemoveTileFlags(pos, TileFlags.LockColor);
			tilemap.SetColor(pos, color);
			tilemap.SetTileFlags(pos, TileFlags.LockColor);
		}

		//Color.RGBToHSV(color, out currColorH, out currColorS, out currColorV);

		currColor = color;
		targetColor = color;
	}

	/*public void ChangeColor(Color color, float time) {
		Color.RGBToHSV(color, out changeColorH, out changeColorS, out changeColorV);
		maxTimer = timer = time;
	}*/

	public void ColorFromPos(Color color, float colorSpeed, Vector3 colorPos) {
		currColor = targetColor;
		targetColor = color;
		timer = 0;
		speed = colorSpeed * colorSpeed;
		colPos = colorPos;
	}
}
