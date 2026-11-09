using UnityEngine;

public class SoundEffectPlayer : MonoBehaviour {
    private readonly Timer destroyTimer = new Timer();
    
    void Start() {
        destroyTimer.Set(1000);
    }

    private void FixedUpdate() {
        destroyTimer.Update();
        if (destroyTimer.Check()) {
            Destroy(gameObject);
        }
    }
}