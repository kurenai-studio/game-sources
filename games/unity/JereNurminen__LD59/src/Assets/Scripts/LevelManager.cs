using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.UI;
using System.Collections;

[System.Serializable]
public struct SignalData
{
    public Vector2 position;
    public float distanceFromBase;
    public bool revealed;
}

public class LevelManager : MonoBehaviour
{
    [SerializeField]
    private float signalLowThresholdDistance = 120f;

    [SerializeField]
    private float signalPerfectThresholdDistance = 10f;

    [Header("Level Bounds")]
    [SerializeField]
    private Vector2 levelBoundsHalfExtents = new Vector2(500f, 500f);

    [Header("Signal Placement")]
    [SerializeField]
    private float baseAreaRadius = 50f; // how far from origin the base point can be

    [SerializeField]
    private float deadZoneHorizontal = 30f; // left/right dead zone width

    [SerializeField]
    private float deadZoneVertical = 30f; // top/bottom dead zone width

    [SerializeField]
    private float signalMinDistance = 60f; // min distance from base point

    [SerializeField]
    private float signalMaxDistance = 120f; // max distance from base point

    [SerializeField]
    private PlayerController player;

    [SerializeField]
    private InterfaceController interfaceController;

    private Vector2 basePosition;

    public Vector2 BasePosition => basePosition;

    [SerializeField]
    private SignalData[] signals = new SignalData[3];

    private bool allSignalsRevealed = false;

    [SerializeField]
    private GameObject beamPrefab;

    [SerializeField]
    private GameObject alienPrefab;
    private GameObject alien;
    private CameraController cam;
    private InputAction beamAction;
    private InputAction restartAction;
    private bool canRestart = false;

    [SerializeField]
    private float endFadeDelay = 1f;

    [SerializeField]
    private float endFadeTime = 1f;

    [SerializeField]
    private Image endScreenImage;

    [SerializeField]
    private Image gameOverScreenImage;

    [SerializeField]
    private TerrainController terrainController;

    [SerializeField]
    private PropSpawner propSpawner;

    [Header("Danger Level 1")]
    [SerializeField]
    private GameObject targetPrefab;

    [SerializeField]
    private float targetSpawnInterval = 3f;

    [SerializeField]
    private float targetSpawnMinDistance = 15f;

    [SerializeField]
    private float targetSpawnMaxDistance = 30f;

    [SerializeField]
    private float targetSpawnAngleSpread = 45f;

    private float targetSpawnTimer = 0f;

    [Header("Danger Level 2")]
    [SerializeField]
    private float target2SpawnInterval = 4f;

    [SerializeField]
    private float target2SpawnMinDistance = 20f;

    [SerializeField]
    private float target2SpawnMaxDistance = 40f;

    [SerializeField]
    private int target2Count = 3;

    [SerializeField]
    private float target2LateralSpread = 2f;

    [SerializeField]
    private float target2SlowSpeedThreshold = 3f;

    [SerializeField]
    private float target2SlowGracePeriod = 2f;

    private float target2SpawnTimer = 0f;
    private float target2SlowTimer = 0f;

    [Header("Danger Level 3")]
    [SerializeField]
    private float target3SpawnInterval = 5f;

    [SerializeField]
    private float target3DistanceAhead = 25f;

    [SerializeField]
    private int target3Count = 5;

    [SerializeField]
    private float target3Spacing = 3f;

    [SerializeField]
    private float target3StaggerDelay = 0.15f;

    [SerializeField]
    private float target3BaseSafeRadius = 20f;

    private float target3SpawnTimer = 0f;
    private int target3PatternIndex = 0;

    private int dangerLevel = 0;

    private AudioSource audioSource;

    [SerializeField]
    private AudioClip beamSound;

    [SerializeField]
    private AudioClip signalRevealClip;

    [Header("Signal Beep")]
    [SerializeField]
    private AudioClip beepFarClip;

    [SerializeField]
    private AudioClip beepMediumClip;

    [SerializeField]
    private AudioClip beepCloseClip;

    [SerializeField]
    private float beepMaxInterval = 2f;

    [SerializeField]
    private float beepMinInterval = 0.1f;

    private float beepTimer = 0f;

    void Start()
    {
        player = GameObject.Find("Player").GetComponent<PlayerController>();
        interfaceController = GameObject.Find("UI").GetComponent<InterfaceController>();
        cam = Camera.main.GetComponent<CameraController>();
        beamAction = InputSystem.actions.FindAction("Beam");
        restartAction = InputSystem.actions.FindAction("Restart");
        audioSource = GetComponent<AudioSource>();

        // Pick base position inside a circle around the world origin, clamped to level bounds
        Vector2 baseDir = Random.insideUnitCircle.normalized;
        float baseDist = Random.Range(0f, baseAreaRadius);
        basePosition = baseDir * baseDist;
        basePosition.x = Mathf.Clamp(
            basePosition.x,
            -levelBoundsHalfExtents.x,
            levelBoundsHalfExtents.x
        );
        basePosition.y = Mathf.Clamp(
            basePosition.y,
            -levelBoundsHalfExtents.y,
            levelBoundsHalfExtents.y
        );

        for (int i = 0; i < signals.Length; i++)
        {
            const int maxAttempts = 100;
            SignalData best = new SignalData { position = basePosition, distanceFromBase = 0f };
            bool found = false;

            for (int attempt = 0; attempt < maxAttempts; attempt++)
            {
                float angle = Random.Range(0f, 360f) * Mathf.Deg2Rad;
                float distance = Random.Range(signalMinDistance, signalMaxDistance);
                Vector2 candidate =
                    basePosition + new Vector2(Mathf.Cos(angle), Mathf.Sin(angle)) * distance;

                // Reject if outside level bounds or within dead zone perimeter
                Vector2 safeExtents =
                    levelBoundsHalfExtents - new Vector2(deadZoneHorizontal, deadZoneVertical);
                if (
                    Mathf.Abs(candidate.x) > safeExtents.x || Mathf.Abs(candidate.y) > safeExtents.y
                )
                    continue;

                // Track last in-bounds candidate as fallback
                best = new SignalData { position = candidate, distanceFromBase = distance };

                // Reject if too close to another signal
                bool tooClose = false;
                for (int j = 0; j < i; j++)
                {
                    if (Vector2.Distance(candidate, signals[j].position) < signalMinDistance)
                    {
                        tooClose = true;
                        break;
                    }
                }

                if (!tooClose)
                {
                    signals[i] = best;
                    found = true;
                    break;
                }
            }

            if (!found)
                signals[i] = best;
        }
    }

    void Update()
    {
        if (player == null)
            return;

        Vector2 playerPos = player.transform.position;
        int? closestIndex = null;
        float? closestDistance = null;

        for (int i = 0; i < signals.Length; i++)
        {
            var s = signals[i];
            if (s.revealed)
                continue;

            float dist = Vector2.Distance(playerPos, s.position);
            if (closestDistance == null || dist < closestDistance)
            {
                closestDistance = dist;
                closestIndex = i;
            }
        }

        if (closestIndex != null && closestDistance != null)
        {
            float signalStrength = Mathf.InverseLerp(
                signalLowThresholdDistance,
                signalPerfectThresholdDistance,
                closestDistance.Value
            );

            if (
                closestDistance.Value < signalPerfectThresholdDistance
                && interfaceController.IsPhoneActive
                && !signals[closestIndex.Value].revealed
            )
                RevealSignalDistance(closestIndex.Value);

            interfaceController.SetSignalStrength(allSignalsRevealed ? 1f : signalStrength);

            Vector2 dirToSignal = (signals[closestIndex.Value].position - playerPos).normalized;
            interfaceController.SetGPSDirection(dirToSignal, closestDistance.Value);
        }
        else
        {
            interfaceController.SetGPSDirection(Vector2.zero, float.MaxValue);
        }

        UpdateSignalBeep(closestDistance);

        interfaceController.UpdateMap(playerPos, signals, levelBoundsHalfExtents);

        if (!canRestart)
        {
            switch (dangerLevel)
            {
                case 1:
                    DangerLevel1();
                    break;
                case 2:
                    DangerLevel1();
                    DangerLevel2();
                    break;
                case 3:
                    DangerLevel1();
                    DangerLevel2();
                    DangerLevel3();
                    break;
            }
        }

#if (UNITY_EDITOR)
        if (beamAction.WasPressedThisFrame())
        {
            BeamEmUp();
        }
#endif

        if (restartAction.WasPressedThisFrame() && canRestart)
        {
            UnityEngine.SceneManagement.SceneManager.LoadScene(
                UnityEngine.SceneManagement.SceneManager.GetActiveScene().name
            );
        }
    }

    private void UpdateSignalBeep(float? closestDistance)
    {
        if (allSignalsRevealed || closestDistance == null)
        {
            beepTimer = 0f;
            return;
        }

        float dist = closestDistance.Value;

        if (dist > signalLowThresholdDistance)
        {
            beepTimer = 0f;
            return;
        }

        float range = signalLowThresholdDistance - signalPerfectThresholdDistance;
        float beepMediumDistance = signalLowThresholdDistance - range / 3f;
        float beepCloseDistance = signalLowThresholdDistance - 2f * range / 3f;

        AudioClip clip;
        if (dist <= beepCloseDistance)
            clip = beepCloseClip;
        else if (dist <= beepMediumDistance)
            clip = beepMediumClip;
        else
            clip = beepFarClip;

        float t = Mathf.InverseLerp(
            signalLowThresholdDistance,
            signalPerfectThresholdDistance,
            dist
        );
        float interval = Mathf.Lerp(beepMaxInterval, beepMinInterval, t);

        beepTimer -= Time.deltaTime;
        if (beepTimer <= 0f && !canRestart)
        {
            beepTimer = interval;
            audioSource.PlayOneShot(clip);
        }
    }

    private void DangerLevel1()
    {
        targetSpawnTimer += Time.deltaTime;
        if (targetSpawnTimer < targetSpawnInterval)
            return;

        targetSpawnTimer = 0f;

        Vector2 playerPos = player.transform.position;
        Vector2 forward =
            player.Velocity.sqrMagnitude > 0.01f ? player.Velocity.normalized : Vector2.up;

        float baseAngle = Mathf.Atan2(forward.y, forward.x) * Mathf.Rad2Deg;
        float randomAngle =
            baseAngle + Random.Range(-targetSpawnAngleSpread, targetSpawnAngleSpread);
        float dist = Random.Range(targetSpawnMinDistance, targetSpawnMaxDistance);
        float rad = randomAngle * Mathf.Deg2Rad;
        Vector2 spawnPos = playerPos + new Vector2(Mathf.Cos(rad), Mathf.Sin(rad)) * dist;

        if (Vector2.Distance(spawnPos, basePosition) >= target3BaseSafeRadius)
            Instantiate(targetPrefab, spawnPos, Quaternion.identity);
    }

    private void DangerLevel2()
    {
        target2SpawnTimer += Time.deltaTime;

        bool isSlow = player.Velocity.magnitude < target2SlowSpeedThreshold;
        if (isSlow)
            target2SlowTimer += Time.deltaTime;
        else
            target2SlowTimer = 0f;

        if (target2SpawnTimer < target2SpawnInterval)
            return;

        target2SpawnTimer = 0f;

        Vector2 playerPos = player.transform.position;

        if (isSlow && target2SlowTimer >= target2SlowGracePeriod)
        {
            // Player is slow — converge targets directly on their position
            for (int i = 0; i < target2Count; i++)
            {
                float lateral = Random.Range(-target2LateralSpread, target2LateralSpread);
                float ahead = Random.Range(-target2LateralSpread, target2LateralSpread);
                Vector2 spawnPos = playerPos + new Vector2(lateral, ahead);
                if (Vector2.Distance(spawnPos, basePosition) >= target3BaseSafeRadius)
                    Instantiate(targetPrefab, spawnPos, Quaternion.identity);
            }
            return;
        }

        Vector2 forward =
            player.Velocity.sqrMagnitude > 0.01f ? player.Velocity.normalized : Vector2.up;
        Vector2 right = new Vector2(forward.y, -forward.x);

        float totalRange = target2SpawnMaxDistance - target2SpawnMinDistance;

        for (int i = 0; i < target2Count; i++)
        {
            float t = target2Count > 1 ? (float)i / (target2Count - 1) : 0.5f;
            float dist = target2SpawnMinDistance + t * totalRange;
            float lateral = Random.Range(-target2LateralSpread, target2LateralSpread);
            Vector2 spawnPos = playerPos + forward * dist + right * lateral;
            if (Vector2.Distance(spawnPos, basePosition) >= target3BaseSafeRadius)
                Instantiate(targetPrefab, spawnPos, Quaternion.identity);
        }
    }

    private void DangerLevel3()
    {
        target3SpawnTimer += Time.deltaTime;
        if (target3SpawnTimer < target3SpawnInterval)
            return;

        target3SpawnTimer = 0f;

        Vector2 playerPos = player.transform.position;
        Vector2 forward =
            player.Velocity.sqrMagnitude > 0.01f ? player.Velocity.normalized : Vector2.up;
        Vector2 right = new Vector2(forward.y, -forward.x);

        bool isPerp = (target3PatternIndex % 2) == 0;
        target3PatternIndex++;

        Vector2 anchor = playerPos + forward * target3DistanceAhead;
        Vector2 lineDir = isPerp ? right : forward;

        StartCoroutine(SpawnLine3(anchor, lineDir));
    }

    private IEnumerator SpawnLine3(Vector2 anchor, Vector2 lineDir)
    {
        float halfLen = (target3Count - 1) * target3Spacing * 0.5f;
        for (int i = 0; i < target3Count; i++)
        {
            float offset = -halfLen + i * target3Spacing;
            Vector2 pos = anchor + lineDir * offset;
            if (Vector2.Distance(pos, basePosition) >= target3BaseSafeRadius)
                Instantiate(targetPrefab, pos, Quaternion.identity);
            if (i < target3Count - 1)
                yield return new WaitForSeconds(target3StaggerDelay);
        }
    }

    public void RevealSignalDistance(int index)
    {
        if (index < 0 || index >= signals.Length)
            return;

        signals[index].revealed = true;
        var revealedSignalCount = GetRevealedSignalCount();
        interfaceController.StartCircleReveal(index, signals[index].distanceFromBase);
        interfaceController.SetSignalCount(revealedSignalCount);
        dangerLevel = revealedSignalCount;
        audioSource.PlayOneShot(signalRevealClip);

        if (AllSignalsRevealed())
        {
            interfaceController.MarkTriangulationComplete(basePosition);
        }
    }

    private int GetRevealedSignalCount()
    {
        int count = 0;
        foreach (SignalData s in signals)
            if (s.revealed)
                count++;
        return count;
    }

    public bool AllSignalsRevealed()
    {
        foreach (SignalData s in signals)
            if (!s.revealed)
                return false;

        allSignalsRevealed = true;
        alien = Instantiate(alienPrefab, basePosition, Quaternion.identity);
        alien.GetComponent<AlienController>().levelManager = this;
        return true;
    }

    public void OnAlienSeen()
    {
        player.isControlEnabled = false;
        cam.target = alien.transform;
        dangerLevel = 0;
    }

    public void BeamEmUp()
    {
        var alienBeam = Instantiate(beamPrefab, basePosition, Quaternion.identity);
        alienBeam.GetComponent<SpriteRenderer>().sortingOrder = Mathf.RoundToInt(basePosition.y);
        var playerBeam = Instantiate(beamPrefab, (Vector3)player.BeamPosition, Quaternion.identity);
        playerBeam.GetComponent<SpriteRenderer>().sortingOrder = Mathf.RoundToInt(
            player.BeamPosition.y
        );
        audioSource.PlayOneShot(beamSound);
    }

    public void OnBeamHit()
    {
        player.GetComponent<Renderer>().enabled = false;
        alien.GetComponent<Renderer>().enabled = false;
    }

    public void OnBeamDone()
    {
        endScreenImage.color = new Color(0f, 0f, 0f, 0f);
        StartCoroutine(FadeInScreen(endScreenImage));
        terrainController.isActive = false;
        propSpawner.isActive = false;
        canRestart = true;
    }

    public void OnPlayerDeath()
    {
        gameOverScreenImage.color = new Color(0f, 0f, 0f, 0f);
        StartCoroutine(FadeInScreen(gameOverScreenImage));
        terrainController.isActive = false;
        propSpawner.isActive = false;
        canRestart = true;
    }

    IEnumerator FadeInScreen(Image image)
    {
        yield return new WaitForSeconds(endFadeDelay);

        float elapsed = 0f;
        float duration = endFadeTime;

        while (elapsed < duration)
        {
            elapsed += Time.deltaTime;
            float t = Mathf.Clamp01(elapsed / duration);
            image.color = new Color(1f, 1f, 1f, t);
            yield return null;
        }
    }

    private void OnDrawGizmos()
    {
        // Draw base area
        Gizmos.color = Color.yellow;
        Gizmos.DrawWireSphere(Vector3.zero, baseAreaRadius);

        // Draw level bounds
        Gizmos.color = Color.red;
        Gizmos.DrawWireCube(
            Vector3.zero,
            new Vector3(levelBoundsHalfExtents.x * 2f, levelBoundsHalfExtents.y * 2f, 0f)
        );

        // Draw signals
        Gizmos.color = Color.cyan;
        foreach (SignalData s in signals)
        {
            Gizmos.DrawSphere(s.position, 2f);
            Gizmos.DrawWireSphere(s.position, 5f);
            Gizmos.DrawWireSphere(s.position, s.distanceFromBase);
        }

        // Draw base position
        Gizmos.color = Color.yellow;
        Gizmos.DrawSphere(basePosition, 3f);
    }
}
