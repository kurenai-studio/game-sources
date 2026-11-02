using UnityEngine;
using System.Collections;

namespace Assets.Scripts.UI
{
    public class CameraSlider : MonoBehaviour
    {
        const float fps = 60;

        public IEnumerator Slide(SlideDirection direction)
        {
            Vector3 startPosition = this.transform.position;
            Vector3 targetPosition;

            if (direction == SlideDirection.Left)
            {
                targetPosition = startPosition - new Vector3(50, 0, 0);

            }
            else
            {
                targetPosition = startPosition + new Vector3(50, 0, 0);
            }

            for (float i = 0; i < fps; i++)
            {
                Debug.Log(i / fps);
                this.gameObject.transform.position = Vector3.Lerp(startPosition, targetPosition, i / fps);
                yield return new WaitForFixedUpdate();
            }
        }
    }
}
