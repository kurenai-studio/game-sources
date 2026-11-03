using UnityEngine;

namespace PixelLeap.Player
{
    /// <summary>平滑跟随相机：朝向前瞻 + 竖直死区 + 关卡边界限制 + 震屏。</summary>
    public class CameraFollow2D : MonoBehaviour
    {
        public Transform target;
        public float smoothTime = 0.14f;
        public float lookAhead = 2.2f;
        public float verticalDeadZone = 1.2f;
        public Rect bounds = new Rect(-1000, -1000, 2000, 2000);

        static float shakeTime, shakeStrength;
        Vector3 velocity;
        float focusY;
        PlayerController2D player;
        Camera cam;

        public static void Shake(float duration, float strength)
        {
            shakeTime = Mathf.Max(shakeTime, duration);
            shakeStrength = Mathf.Max(shakeStrength, strength);
        }

        void Start()
        {
            cam = GetComponent<Camera>();
            if (target) { player = target.GetComponent<PlayerController2D>(); focusY = target.position.y; }
        }

        void LateUpdate()
        {
            if (!target) return;
            Vector3 p = target.position;
            if (Mathf.Abs(p.y - focusY) > verticalDeadZone || (player && player.Grounded))
                focusY = Mathf.Lerp(focusY, p.y, 6f * Time.deltaTime);

            float ahead = player ? player.Facing * lookAhead : 0f;
            Vector3 desired = new Vector3(p.x + ahead, focusY + 1f, transform.position.z);

            if (cam)
            {
                float halfH = cam.orthographicSize, halfW = halfH * cam.aspect;
                desired.x = Mathf.Clamp(desired.x, bounds.xMin + halfW, Mathf.Max(bounds.xMin + halfW, bounds.xMax - halfW));
                desired.y = Mathf.Clamp(desired.y, bounds.yMin + halfH, Mathf.Max(bounds.yMin + halfH, bounds.yMax - halfH));
            }

            Vector3 pos = Vector3.SmoothDamp(transform.position, desired, ref velocity, smoothTime);
            if (shakeTime > 0f)
            {
                shakeTime -= Time.unscaledDeltaTime;
                pos += (Vector3)(Random.insideUnitCircle * shakeStrength);
                if (shakeTime <= 0f) shakeStrength = 0f;
            }
            transform.position = pos;
        }
    }
}
