using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Executor : MonoBehaviour
{
    public void Execute(IEnumerator coroutine) {
        StartCoroutine(coroutine);
    }
}
