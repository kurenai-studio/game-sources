using System.Collections;
using System.Collections.Generic;
using TMPro;
using Unity.VisualScripting;
using UnityEditor;
using UnityEngine;
using UnityEngine.SceneManagement;

public class Systemd : MonoBehaviour
{
    [SerializeField]
    private List<DemonRequest> DemonRequest;
    public float Timeout = 15;
    public int InitialQueueSurge = 1;
    public TextMeshProUGUI Text;

    public bool ShuffleRequests;
    public int DemonsToShuffle = -1;

    public RectTransform UIPole;
    public RectTransform UITarget;

    private Queue<DemonRequest> Queue = new Queue<DemonRequest>();
    private int totalDemonsSent = 0;

    private Queue<DemonConfiguration> RespawnQueue = new Queue<DemonConfiguration>();

    void Start()
    {
        SetText();
        StartCoroutine(DistributionCoroutine());
    }

    IEnumerator DistributionCoroutine()
    {
        if (ShuffleRequests)
        {
            for (var i = 0; i != DemonsToShuffle; i++)
            {
                var req = new DemonRequest
                {
                    HornsId = RandomItem(new[] { -1, -1, 1, 2, 3, 4 }),
                    FeatureId = RandomItem(new[] { -1, -1, 0, 1, 2, 3 }),
                };
                yield return QueueDemonRequest(req);
            }
            while (totalDemonsSent != DemonsToShuffle)
            {
                yield return null;
            }
        }
        else
        {
            foreach (var req in DemonRequest)
            {
                yield return QueueDemonRequest(req);
            }
            while (totalDemonsSent != DemonRequest.Count)
            {
                yield return null;
            }
        }
        StartCoroutine(EndLevelCoroutine());
    }

    IEnumerator EndLevelCoroutine()
    {
        Destroy(FindAnyObjectByType<CameraMovement>());
        var start = UIPole.position;
        var finish = UITarget.position;
        var iters = 60;
        for (var i = 0; i < iters; i++)
        {
            
            UIPole.position = Vector3.Lerp(start, finish, (float)i / (iters - 1));
            yield return new WaitForSeconds(1f / iters);
        }
    }

    public void LoadNextLevel()
    {
        SceneManager.LoadSceneAsync(SceneManager.GetActiveScene().buildIndex + 1);
    }

    public int RandomItem(int[] array)
    {
        return array[Random.Range(0, array.Length)];
    }

    IEnumerator QueueDemonRequest(DemonRequest req)
    {
        Queue.Enqueue(req);
        if (InitialQueueSurge > 0)
        {
            InitialQueueSurge--;
            yield break;
        }
        while (Queue.Count != 0)
        {
            yield return null;
        }
        yield return new WaitForSeconds(Timeout);
    }

    public DemonRequest PopDemonRequest()
    {
        if (Queue.Count == 0) return null;

        return Queue.Dequeue();
    }

    public DemonConfiguration PopRespawndDemon()
    {
        if (RespawnQueue.Count == 0) return null;

        return RespawnQueue.Dequeue();
    }


    public void DemonSent(DemonConfiguration config)
    {
        totalDemonsSent++;
        SetText();
        StartCoroutine(RespawnCoroutine(config));
    }

    void SetText()
    {
        if (ShuffleRequests)
        {
            if (DemonsToShuffle == -1)
            {
                Text.text = $"{totalDemonsSent}";
            }
            else
            {
                Text.text = $"{totalDemonsSent}/{DemonsToShuffle}";
            }
        }
        else
        {
            Text.text = $"{totalDemonsSent}/{DemonRequest.Count}";
        }
    }

    IEnumerator RespawnCoroutine(DemonConfiguration config)
    {
        yield return new WaitForSeconds(5);

        RespawnQueue.Enqueue(config);
    }
}
