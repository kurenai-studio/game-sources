using UnityEngine;
using UnityEngine.AI;

public class WolfController : BarkTarget
{
    private SheepController target = null;
    private NavMeshAgent navMeshAgent;

    private Animator wolfAnimator;

    private float speed = 0.5f;

    private float unitSize;

    private WolfSpawn[] wolfSpawns;

    private bool isReturningHome;

    private Vector3 homeDestination;

    // Start is called before the first frame update
    void Start()
    {
        navMeshAgent = GetComponent<NavMeshAgent>();
        navMeshAgent.updateUpAxis = false;

        wolfAnimator = GetComponent<Animator>();
        unitSize = GetComponent<Collider>().bounds.size.z;

        wolfSpawns = FindObjectsOfType<WolfSpawn>();
    }

    // Update is called once per frame
    void Update()
    {
        if(!isReturningHome)
        {
            if (target == null || target.IsDead())
            {
                SheepController[] sheep = FindObjectsOfType<SheepController>();
                if (sheep.Length == 0)
                {
                    StopRunningAnimation();
                    return;
                }
                target = sheep[Random.Range(0, sheep.Length)];
            }

            navMeshAgent.isStopped = false;
            navMeshAgent.SetDestination(target.GetPosition());
            PlayRunningAnimation();

            TurnTowardsTarget();

            if (!navMeshAgent.pathPending)
            {
                if (navMeshAgent.remainingDistance <= (unitSize + navMeshAgent.stoppingDistance))
                {
                    if (!navMeshAgent.hasPath || navMeshAgent.velocity.sqrMagnitude <= 0.6f)
                    {
                        navMeshAgent.isStopped = true;
                        target = null;
                        StopRunningAnimation();
                    }
                }
            }
        } else
        {
            navMeshAgent.isStopped = false;
            navMeshAgent.SetDestination(homeDestination);
            PlayRunningAnimation();

            TurnTowardsTarget();
        }
        
    }

    private void TurnTowardsTarget()
    {
        // Determine which direction to rotate towards
        Vector3 targetDirection;
        if(!isReturningHome)
        {
            targetDirection = target.GetPosition() - transform.position;
        } else
        {
            targetDirection = homeDestination - transform.position;
        }
        

        // The step size is equal to speed times frame time.
        float singleStep = speed * Time.deltaTime;

        // Rotate the forward vector towards the target direction by one step
        Vector3 newDirection = Vector3.RotateTowards(transform.forward, -targetDirection, singleStep, 0.0f);

        // Draw a ray pointing at our target in
        Debug.DrawRay(transform.position, newDirection, Color.red);

        // Calculate a rotation a step closer to the target and applies rotation to this object
        transform.rotation = Quaternion.LookRotation(newDirection);
    }

    void OnCollisionEnter(Collision collision)
    {
        if(!isReturningHome)
        {
            SheepController sheepController = collision.gameObject.GetComponent<SheepController>();
            if (sheepController != null && !sheepController.IsDead())
            {
                sheepController.KillSheep();
            }
        }
    }

    private void PlayRunningAnimation()
    {
        wolfAnimator.SetTrigger("Run");
        wolfAnimator.ResetTrigger("Stop");
    }

    private void StopRunningAnimation()
    {
        wolfAnimator.SetTrigger("Stop");
        wolfAnimator.ResetTrigger("Run");
    }

    private void ReturnHome()
    {
        WolfSpawn home = null;
        Vector3 smallestDiff = Vector3.zero;
        foreach(WolfSpawn spawn in wolfSpawns)
        {
            Vector3 diffToWolf = spawn.gameObject.transform.position - transform.position;
            if (smallestDiff == Vector3.zero || smallestDiff.sqrMagnitude > diffToWolf.sqrMagnitude)
            {
                smallestDiff = diffToWolf;
                home = spawn;
            }
        }
        homeDestination = home.gameObject.transform.position;
        Debug.Log("New home: " + homeDestination);
        isReturningHome = true;
        Destroy(gameObject, 2f);
    }

    public bool IsReturningHome()
    {
        return isReturningHome;
    }

    public override void OnBark()
    {
        Debug.Log("Wolf: Bark received!");
        ReturnHome();
    }
}
