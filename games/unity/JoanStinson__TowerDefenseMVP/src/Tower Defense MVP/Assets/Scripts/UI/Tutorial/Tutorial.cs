using System.Collections;
using UnityEngine;

namespace JGM.UI.Tutorial
{
    public class Tutorial : MonoBehaviour
    {
        [SerializeField]
        private float duration = 4f;

        private void Start()
        {
            StartCoroutine(DisableAfterDelay());
        }

        private IEnumerator DisableAfterDelay()
        {
            yield return new WaitForSeconds(duration);
            gameObject.SetActive(false);
        }
    }
}
