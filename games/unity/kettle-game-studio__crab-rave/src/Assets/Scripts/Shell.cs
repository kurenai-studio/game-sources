using UnityEngine;

public class Shell : MonoBehaviour
{
    public Transform shell;
    public Collider shellCollider;

    public enum ShellType
    {
        Shell,
        Gem,
    }
    public ShellType @type;

    Vector3 startPosition;
    float time;
    bool grabbed;

    void Start()
    {
        startPosition = shell.localPosition;
    }

    void Update()
    {
        if (grabbed)
        {
            return;
        }

        time += Time.deltaTime;
        shell.localPosition = startPosition + 0.3f * Mathf.Sin(time) * Vector3.up;
        shell.Rotate(new Vector3(0, Time.deltaTime * 50, 0));
    }

    public void GetGrabbed(Transform transform)
    {
        grabbed = true;
        this.transform.parent = transform;
        shellCollider.enabled = false;
    }

    public void GetRetrieved()
    {
        Destroy(this.gameObject);
    }
}
