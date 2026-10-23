using Audio;
using BouncingBehaviors;
using Playfield;
using ScriptableObjects;
using UnityEngine;
using Random = UnityEngine.Random;

public class Ball : MonoBehaviour
{
    public BallData RuntimeBallData { get; private set; }
    public Vector2 Direction { get; set; }
    
    [SerializeField]
    private BallData ballDataTemplate;
    
    // Components
    private new Rigidbody2D rigidbody;
    
    private void Awake()
    {
        rigidbody = GetComponent<Rigidbody2D>();
    }

    private void Start()
    {
        RuntimeBallData = Instantiate(ballDataTemplate);

        Launch();
    }

    private void FixedUpdate()
    {
        RuntimeBallData.speed = Mathf.Clamp(RuntimeBallData.speed, ballDataTemplate.speed, ballDataTemplate.maxSpeed);
        rigidbody.linearVelocity = Direction * RuntimeBallData.speed;
    }

    private void OnCollisionEnter2D(Collision2D other)
    {
        if (other.gameObject.TryGetComponent<IBouncingBehaviorProvider>(out var bounceProvider))
        {
            AudioManager.Instance.Play(bounceProvider.SurfaceType);
            
            bounceProvider.BounceBehavior.Bounce(this, other);
        }
    }

    private void OnTriggerEnter2D(Collider2D other)
    {
        if (other.TryGetComponent<GoalLine>(out _))
        {
            AudioManager.Instance.PlayPointClip();
            
            ResetPosition();
        }
    }
    
    private void Launch()
    {
        transform.position = Vector2.zero;
        
        RuntimeBallData.speed = ballDataTemplate.speed;
        Direction = RandomizeDirection();
    }
    
    private void ResetPosition()
    {
        Launch();
    }
    
    private Vector2 RandomizeDirection(Side side = Side.Right)
    {
        var bounceAngleInRadians = ballDataTemplate.maxBounceAngleInDegrees * Mathf.Deg2Rad;
        var angle = Random.Range(-bounceAngleInRadians, bounceAngleInRadians);
        
        var direction = new Vector2(Mathf.Cos(angle), Mathf.Sin(angle));

        return side switch
        {
            Side.Right => direction,
            Side.Left => Vector2.Reflect(direction, Vector2.left),
            _ => Vector2.zero
        };
    }
}
