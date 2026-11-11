using UnityEngine;

public class FirstPersonController : MonoBehaviour
{
    [SerializeField] private int health = 2;
    [SerializeField] private bool frozen = false;
    [SerializeField] private float attackKickback = 1.5f;
    [SerializeField] private float interactDistance = 2.0f;
    private float freezeTime = 0.0f;
    [SerializeField] private float moveSpeed = 4.0f;
    [SerializeField] private float rotationSpeed = 5.0f;
    [SerializeField] private float aimFov = 50;
    [SerializeField] private float readyToShootFov = 55;
    [SerializeField] private float regularFov = 60;
    [SerializeField] private float timeBetweenShots = 0.7f;
    [SerializeField] private float timeFromDeathToGameOver = 2.0f;
    private float timeSinceDeath = 0.0f;
    private bool isDead = false;
    private float timeSinceLastShot = 0.0f;

    [SerializeField] private CharacterController controller;
    [SerializeField] private Transform cameraTransform;
    [SerializeField] private Camera viewCamera;
    [SerializeField] private AudioSource gunshotSource;
    [SerializeField] private GameObject crosshair;
    [SerializeField] private Transform bulletOrigin;
    [SerializeField] private AudioSource breatheInSource;
    [SerializeField] private AudioSource doorSource;
    [SerializeField] private AudioSource lockedDoorSource;
    [SerializeField] private AudioSource keySource;

    [SerializeField] private AnimationCurve aimCurve;
    private float aimTime = 0.0f;

    private void Start()
    {
        controller = GetComponent<CharacterController>();
        Cursor.visible = false;
        Cursor.lockState = CursorLockMode.Locked;
    }

    private void Update()
    {
        if(isDead)
        {
            timeSinceDeath += Time.deltaTime;
            if(timeSinceDeath >= timeFromDeathToGameOver)
            {
                UnityEngine.SceneManagement.SceneManager.LoadScene(2);
            }
            return;
        }

        timeSinceLastShot += Time.deltaTime;

        if(viewCamera.fieldOfView <= readyToShootFov)
        {
            crosshair.SetActive(true);
        }
        else
        {
            crosshair.SetActive(false);
        }

        if(!frozen)
        {
            FirstPersonControls();
        }
        else
        {
            freezeTime -= Time.deltaTime;
            if(freezeTime <= 0.0f)
            {
                frozen = false;
                controller.Move(transform.forward * -attackKickback);
            }
        }
    }

    private void FirstPersonControls()
    {
        float moveY = 0;
        float moveX = 0;

        if(Input.GetMouseButtonDown(1))
        {
            if(!breatheInSource.isPlaying)
            {
                breatheInSource.Play();
            }
        }
        if(Input.GetMouseButton(1))
        {
            aimTime += Time.deltaTime;
            float aimValue = aimCurve.Evaluate(aimTime);
            viewCamera.fieldOfView = Mathf.Lerp(regularFov, aimFov, aimValue);
            if(viewCamera.fieldOfView <= readyToShootFov)
            {
                if(Input.GetMouseButtonDown(0))
                {
                    if(timeSinceLastShot >= timeBetweenShots)
                    {
                        RaycastHit hit;
                        if(Physics.Raycast(bulletOrigin.position, bulletOrigin.forward, out hit, 20.0f))
                        {
                            if(hit.collider.CompareTag("Enemy Body"))
                            {
                                DamageEnemyFromRaycast(hit, false);
                            }
                            else if(hit.collider.CompareTag("Enemy Head"))
                            {
                                DamageEnemyFromRaycast(hit, true);
                            }
                        }

                        gunshotSource.Play();
                        timeSinceLastShot = 0.0f;
                    }
                }
            }
        }
        else
        {
            aimTime = 0.0f;
            viewCamera.fieldOfView = regularFov;
            if(Input.GetKey(KeyCode.W))
            {
                moveY += 1;
            }
            if(Input.GetKey(KeyCode.S))
            {
                moveY -= 1;
            }
            if(Input.GetKey(KeyCode.A))
            {
                moveX -= 1;
            }
            if(Input.GetKey(KeyCode.D))
            {
                moveX += 1;
            }
        }

        if(Input.GetKeyDown(KeyCode.F))
        {
            RaycastHit hit;
            if(Physics.Raycast(bulletOrigin.position, bulletOrigin.forward, out hit, interactDistance))
            {
                if(hit.collider.CompareTag("Door"))
                {
                    if(!hit.collider.GetComponent<DoorScript>().IsLocked())
                    {
                        Transform doorTarget = hit.collider.GetComponent<DoorScript>().GetDoorTarget();
                        controller.enabled = false;
                        transform.position = doorTarget.position;
                        controller.enabled = true;
                        transform.rotation = doorTarget.rotation;
                        doorSource.Play();
                    }
                    else
                    {
                        lockedDoorSource.Play();
                    }
                }
                else if(hit.collider.CompareTag("Key"))
                {
                    hit.collider.GetComponent<KeyScript>().Pickup();
                    keySource.Play();
                }
            }
        }

        Vector3 movement = new Vector3(moveX, 0, moveY).normalized * moveSpeed;
        movement = transform.TransformDirection(movement);
        controller.Move(movement * Time.deltaTime);
    
        float mouseX = Input.GetAxis("Mouse X");
        float mouseY = Input.GetAxis("Mouse Y");
        transform.Rotate(Vector3.up, mouseX * rotationSpeed * Time.deltaTime);
        cameraTransform.Rotate(Vector3.right, -mouseY * rotationSpeed * Time.deltaTime);
    }

    private void DamageEnemyFromRaycast(RaycastHit hit, bool headshot)
    {
        GameObject enemy = hit.collider.transform.parent.parent.gameObject;
        enemy.GetComponent<EnemyBase>().TakeDamage(headshot);
    }

    public void DamagePlayer(float time, Vector3 enemyHeadPosition)
    {
        health--;
        frozen = true;
        freezeTime = time;
        aimTime = 0.0f;
        viewCamera.fieldOfView = regularFov;
        if(health <= 0)
        {
            Debug.Log("Game Over");
            isDead = true;
        }

        Vector3 directionOfEnemy = enemyHeadPosition - transform.position;
        transform.forward = new Vector3(directionOfEnemy.x, 0, directionOfEnemy.z);
        cameraTransform.rotation = Quaternion.Euler(
            -20, 
            cameraTransform.rotation.eulerAngles.y, 
            cameraTransform.rotation.eulerAngles.z
        );
    }
}