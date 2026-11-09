using UnityEngine;

namespace JGM.UI.Tutorial
{
    public class HandAnimation : MonoBehaviour
    {
        [SerializeField] private float distance = 70f;
        [SerializeField] private float speed = 90f;

        private Vector2 startPos;

        private void Start()
        {
            startPos = transform.position;
        }

        private void Update()
        {
            PlayAnimation();
        }

        private void PlayAnimation()
        {
            float yOffset = Mathf.Repeat(Time.time * speed, distance);
            transform.position = startPos + new Vector2(0, yOffset);
        }
    }
}
