using UnityEngine;
using System.Collections;

public class Player : MonoBehaviour
{
    public float max_speed = 2f;
    public float acceleration_coef = 0.5f;
    public float friction_coef = 0.5f;
    public float viscousity_coef = 0.2f;
    public bool isAbleToControl = true;
    public float hp = 100f;
    public float max_hp = 100f;

    private Vector2 _speed;
    private Rigidbody2D _rb;
    
 
    void Start()
    {
        _rb = GetComponent<Rigidbody2D>();
        G.ModeChanged += OnModeChanged;
    }

    private void Update()
    {
        if (isAbleToControl)
            Rotate(_speed);
    }

    void FixedUpdate()
    {
        if (isAbleToControl)
        {
            _speed = CalculateSpeedVector();
        }
        Move(_speed);
    }

    Vector2 CalculateSpeedVector()
    {
        Vector2 acc_direction = Vector2.zero;
                
        acc_direction.x = Input.GetAxis("Horizontal");
        acc_direction.y = Input.GetAxis("Vertical");
        acc_direction = acc_direction.normalized * acceleration_coef;
        
        Vector2 friction = -acc_direction * friction_coef;

        Vector2 viscousity = -_speed * viscousity_coef;

        Vector2 result_acc = acc_direction + friction + viscousity;

        Vector2 new_speed = _speed + result_acc * Time.fixedDeltaTime;

        if (new_speed.magnitude > max_speed)
            new_speed = new_speed.normalized * max_speed;
        if (new_speed.magnitude < 0.2f && acc_direction.magnitude == 0)
            new_speed = Vector2.zero;

        float magnitude = new_speed.magnitude;

        if ((new_speed.x > 0 && new_speed.y > new_speed.x) || (new_speed.x < 0 && new_speed.y < new_speed.x))
        {
            new_speed.y = new_speed.x;
            new_speed = new_speed.normalized * magnitude;
        }
        else if ((new_speed.x < 0 && new_speed.y > -new_speed.x) || (new_speed.x > 0 && new_speed.y < -new_speed.x))
        {
            new_speed.y = -new_speed.x;
            new_speed = new_speed.normalized * magnitude;
        }

        return new_speed;   
    }

    void Move(Vector2 speed)
    {
        _rb.velocity = speed;
    }

    void Rotate(Vector2 speed)
    {
        float rotation_z;
        
        if (speed.x != 0)
            rotation_z = Mathf.Atan(speed.y/speed.x) * Mathf.Rad2Deg;
        else
        {
            if (speed.y > 0)
                rotation_z = 45;
            else if (speed.y < 0)
                rotation_z = -45;
            else
                return;
        }

        if (speed.x < 0)
        {
            gameObject.transform.Find("Main").gameObject.GetComponent<SpriteRenderer>().flipX = true;
            gameObject.transform.Find("BubbleParticleSystem").gameObject.transform.localPosition = new Vector3(5.72f, -0.37f, 0f);
            gameObject.transform.Find("BubbleParticleSystem").gameObject.transform.eulerAngles = new Vector3(0, 90, 90);
        }
            
        else
        {
            gameObject.transform.Find("Main").gameObject.GetComponent<SpriteRenderer>().flipX = false;
            gameObject.transform.Find("BubbleParticleSystem").gameObject.transform.localPosition = new Vector3(-5.72f, -0.37f, 0f);
            gameObject.transform.Find("BubbleParticleSystem").gameObject.transform.eulerAngles = new Vector3(0, -90, 90);
        }
            

        gameObject.transform.eulerAngles = new Vector3(0, 0, rotation_z);
    }

    private IEnumerator RotateToNormal(float duration)
    {
        float rotZ;
        float initial_rotZ = gameObject.transform.rotation.eulerAngles.z;
        Vector2 initial_speed = _speed; 
        float elapsed = 0f;
        
        while (elapsed < duration)
        {
            if ((initial_speed.x >= 0 && initial_speed.y >= 0) || (initial_speed.x < 0 && initial_speed.y <= 0))
                rotZ = Mathf.Lerp(initial_rotZ, 0, elapsed/duration);
            else
                rotZ = Mathf.Lerp(initial_rotZ, 360, elapsed/duration);
            
               
            gameObject.transform.eulerAngles = new Vector3(0, 0, rotZ);
            elapsed += Time.deltaTime;

            yield return null;
        }
        if ((initial_speed.x >= 0 && initial_speed.y >= 0) || (initial_speed.x < 0 && initial_speed.y <= 0))
            gameObject.transform.eulerAngles = new Vector3(0, 0, 0);
        else
            gameObject.transform.eulerAngles = new Vector3(0, 0, 360);

    }

    private IEnumerator SpeedToNormal(float duration)
    {
        float speed_x;
        float speed_y;
        Vector2 initial_speed = _speed;
        float elapsed = 0f;

        while (elapsed < duration)
        {
            speed_x = Mathf.Lerp(initial_speed.x, 0, elapsed/duration);
            speed_y = Mathf.Lerp(initial_speed.y, 0, elapsed/duration);

            _speed = new Vector2(speed_x, speed_y);
            elapsed += Time.deltaTime;

            yield return null;
        }

        _speed = Vector2.zero;
    }

    private void OnModeChanged()
    {
        isAbleToControl = false;
        StartCoroutine(RotateToNormal(2f));
        StartCoroutine(SpeedToNormal(2f));
    }

    public void Damage(float damage)
    {
        hp -= damage;
        G.OnPlayerDamaged();
    }
}
