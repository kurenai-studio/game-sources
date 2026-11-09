using UnityEngine;

public class Toad : MonoBehaviour
{
    public Player player;
    public CameraController cameraController;
    public Transform leftSide;
    public Transform rightSide;

    public Animator animator;
    public Transform toadBody;
    public CollisionChecker collisionChecker;
    public Hittable hittable;
    public TriggerChecker distanceTrigger;
    public SpriteRenderer shadow;
    public TriggerChecker tongue;

    public AudioSource audioSource;
    public AudioClip firstScream;
    public AudioClip[] screams;
    public float takeDamageTime = 0.1f;

    [HideInInspector]
    public Vector2 position;
    [HideInInspector]
    public float scaleDirection;
    [HideInInspector]
    public float shadowTransparency;

    int takenDamage = 0;

    void Start()
    {
        position.x = transform.position.x;
        position.y = toadBody.transform.localPosition.y;
        shadowTransparency = 0;
        scaleDirection = 1;

        hittable.callback += OnHit;
    }

    void Update()
    {
        transform.position = new Vector3(position.x, transform.position.y, transform.position.z);
        toadBody.transform.localPosition = new Vector3(
            toadBody.transform.localPosition.x,
            position.y,
            toadBody.transform.localPosition.z
        );
        float powTransparency = shadowTransparency * shadowTransparency;
        shadow.color = new Color(shadow.color.r, shadow.color.g, shadow.color.b, 1 - powTransparency);
        toadBody.transform.localScale = new Vector3(scaleDirection, 1, 1);
    }

    void OnHit(Transform from)
    {
        if (takenDamage == 0)
        {
            audioSource.clip = firstScream;
            audioSource.Play();
        }
        else if (!(audioSource.isPlaying && audioSource.time < 0.5))
        {
            audioSource.clip = screams[Random.Range(0, screams.Length - 1)];
            audioSource.Play();
        }
        takenDamage++;
    }

    public void playRandom(AudioClip[] clips)
    {
        audioSource.clip = clips[Random.Range(0, clips.Length - 1)];
        audioSource.Play();
    }
}
