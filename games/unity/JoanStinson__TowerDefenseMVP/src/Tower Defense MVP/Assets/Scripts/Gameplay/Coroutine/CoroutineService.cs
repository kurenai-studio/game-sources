using System.Collections;
using UnityEngine;

namespace JGM.Gameplay
{
    public class CoroutineService : MonoBehaviour
    {
        public Coroutine Run(IEnumerator coroutine)
        {
            return StartCoroutine(coroutine);
        }

        public void Stop(IEnumerator coroutine)
        {
            if (coroutine != null)
            {
                StopCoroutine(coroutine);
            }
        }
    }
}
