using UnityEngine;

public class DoorReplay : MonoBehaviour, IReplayable {
	public object[] CollectData() {
		return new object[] { transform.position, transform.rotation };
	}

	public void ReplayData(int frame, object[] data) {
		transform.position = (Vector3)data[0];
		transform.rotation = (Quaternion)data[1];
	}

	public void ReplayEnded() { }

	public void ReplayReset() { }
}
