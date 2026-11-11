using UnityEngine;
using UnityEngine.UI;

public class MatildaScript : MonoBehaviour
{
    public RectTransform Pole;
    public Image Eyes;

    public bool EyesClosed = true;

    private float _timeUntilBlink;

    void Start(){

    }

    void Update() {
        var angle = Mathf.Sin(Time.time) * 2.5f;
        Pole.rotation = Quaternion.Euler(0, 0, angle);
        HandleBlink();
    }
    
    void HandleBlink()
    {
        _timeUntilBlink -= Time.deltaTime;
        if (_timeUntilBlink > 0) return;
            
        if (EyesClosed)
        {
            _timeUntilBlink = Random.Range(1.0f, 3.0f);
        } else {
            _timeUntilBlink = 0.1f;
        }

        EyesClosed = !EyesClosed;
        ApplyConfig();
    }

    void ApplyConfig() {
        Eyes.enabled = EyesClosed;
    }
}
