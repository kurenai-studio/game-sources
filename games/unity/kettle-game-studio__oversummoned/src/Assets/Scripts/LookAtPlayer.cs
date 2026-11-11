using UnityEngine;

public class LookAtPlayer : MonoBehaviour
{
    public SpriteRenderer[] prioritableSprites;
    public int[] defaultPriorities;
    public float scale = 1;

    private Camera _cachedCamera;

    void Start()
    {
        _cachedCamera = Camera.main;
        transform.localScale = new Vector3(1, Mathf.Sqrt(2), 1) * scale;
    }

    void Update()
    {
        transform.rotation = Quaternion.identity;
        transform.Rotate(Vector3.up, _cachedCamera.transform.rotation.eulerAngles.y);

        for (var i = 0; i < prioritableSprites.Length; i++) {
            prioritableSprites[i].sortingOrder = defaultPriorities[i] - ((int)Vector3.Distance(_cachedCamera.transform.position, transform.position) * 100);
        }
    }
}
