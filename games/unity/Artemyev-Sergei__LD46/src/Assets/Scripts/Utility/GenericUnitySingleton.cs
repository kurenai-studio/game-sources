using UnityEngine;

/// <summary>
/// Singleton pattern for Unity.
/// </summary>
/// <typeparam name="T"></typeparam>
public class GenericUnitySingleton<T> : MonoBehaviour where T : Component
{
    [SerializeField]
    private bool dontDestroyOnLoad = true;

    private static T instance;
    public static T Instance
    {
        get
        {
            if (!HasInstance())
            {
                Debug.LogErrorFormat("{0} is null!", typeof(T).Name);
                instance = FindObjectOfType<T>();
                if (!HasInstance())
                {
                    GameObject obj = new GameObject
                    {
                        name = typeof(T).Name
                    };
                    instance = obj.AddComponent<T>();
                }
            }
            return instance;
        }
    }

    protected virtual void Awake()
    {
        if (!HasInstance())
        {
            instance = this as T;
            Initialize();
            if (this.dontDestroyOnLoad)
            {
                DontDestroyOnLoad(this.gameObject);
            }
        }
        else
        {
            Debug.LogWarningFormat("{0} already exists!", typeof(T).Name);
            Destroy(this.gameObject);
        }
    }

    protected virtual void OnDestroy()
    {
        if (instance == this)
        {
            instance = null;
        }
    }

    protected virtual void Initialize()
    {

    }

    public static bool HasInstance()
    {
        return instance != null;
    }
}