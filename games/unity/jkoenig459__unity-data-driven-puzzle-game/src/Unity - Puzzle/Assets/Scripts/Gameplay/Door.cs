using UnityEngine;

[RequireComponent(typeof(Collider2D))]
public class Door2D : MonoBehaviour
{
    [SerializeField] private string doorId = "DoorA";
    [SerializeField] private bool startsClosed = true;

    private Collider2D col;
    private SpriteRenderer sr;

    public string DoorId => doorId;

    private void Awake()
    {
        col = GetComponent<Collider2D>();
        sr = GetComponent<SpriteRenderer>();

        SetClosed(startsClosed);
    }

    public void Initialize(string id, bool closed)
    {
        doorId = id;
        SetClosed(closed);
    }

    public void SetClosed(bool closed)
    {
        if (col != null) col.enabled = closed;
        if (sr != null) sr.enabled = closed; // hide when open
    }

    public void Toggle()
    {
        bool isClosed = col != null && col.enabled;
        SetClosed(!isClosed);
    }
}
