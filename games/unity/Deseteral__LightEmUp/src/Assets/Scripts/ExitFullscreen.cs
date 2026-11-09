using UnityEngine;

public class ExitFullscreen : MonoBehaviour {
    private void Update() {
        if (Input.GetKey(KeyCode.Escape)) {
            Screen.fullScreen = false;
        }
    }
}