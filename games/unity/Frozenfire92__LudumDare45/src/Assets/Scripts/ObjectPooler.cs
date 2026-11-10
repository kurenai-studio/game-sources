
using UnityEngine;
using System.Collections.Generic;
using System.Collections;
using System;

public class ObjectPooler : MonoBehaviour
{
    public static ObjectPooler instance;

    public bool autoGrow = true;

    Dictionary<Type, List<GameObject>> pools;
    Dictionary<Type, GameObject> parents;

    public void Awake()
    {
        if (instance == null)
        {
            instance = this;
        }
        else if (instance != this)
        {
            Destroy(gameObject);
            DontDestroyOnLoad(gameObject);
        }
        pools = new Dictionary<Type, List<GameObject>>();  //Pools must be registered by some object in Start()
        parents = new Dictionary<Type, GameObject>();
    }
    public void CreatePool(GameObject poolObject, Type type, int baseSize = 4)
    {
        parents[type] = new GameObject(type.ToString() + "s");
        parents[type].transform.SetParent(transform);
        pools[type] = new List<GameObject>();
        for (int i = 0; i < baseSize; i++)
        {
            AddObject(type, poolObject, i);
        }
    }
    void AddObject(Type type, GameObject poolObject, int i)
    {
        pools[type].Add(Instantiate<GameObject>(poolObject));
        pools[type][i].transform.SetParent(parents[type].transform);
        pools[type][i].name = type.ToString() + i;
        pools[type][i].gameObject.SetActive(false);
    }
    public GameObject GetObject(Type type)
    {
        //return the first available (turned off), if none available -> autogrow? add new : return null;
        foreach (GameObject g in pools[type])
        {
            if (!g.activeInHierarchy)
            {
                g.SetActive(true);
                return g;
            }
        }

        if (!autoGrow) return null;

        AddObject(type, pools[type][0].gameObject, pools[type].Count);
        return pools[type][pools[type].Count - 1];
    }
}