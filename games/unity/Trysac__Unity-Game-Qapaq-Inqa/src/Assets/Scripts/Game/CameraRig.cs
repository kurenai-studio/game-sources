using QapaqInqa.Core;
using UnityEngine;

namespace QapaqInqa.Game
{
    /// <summary>
    /// Follows the player with a little look-ahead, stays inside the level, shakes on impacts and
    /// snaps to whole screen pixels so the pixel art never shimmers.
    /// </summary>
    [RequireComponent(typeof(Camera))]
    public sealed class CameraRig : MonoBehaviour
    {
        public const float HalfHeight = 7.5f;

        Camera view;
        Vector2 focus;
        float lookAhead;
        float trauma;

        public Camera View => view != null ? view : view = GetComponent<Camera>();
        public bool ShakeEnabled { get; set; } = true;

        public void Shake(float amount) => trauma = Mathf.Min(1f, trauma + amount);

        public void Snap(Stage stage)
        {
            lookAhead = 0f;
            trauma = 0f;
            focus = Target(stage);
            Place(stage);
        }

        public void Follow(Stage stage, float dt)
        {
            float wanted = stage.Player.Facing * 2.2f;
            lookAhead = Mathf.MoveTowards(lookAhead, wanted, dt * 4f);
            Vector2 target = Target(stage);
            focus.x = Mathf.Lerp(focus.x, target.x, 1f - Mathf.Exp(-dt * 7f));
            // Vertically only follow firmly when the player lands or leaves the screen band.
            float band = stage.Player.Grounded || stage.Player.Climbing ? 0f : 2.2f;
            float dy = target.y - focus.y;
            if (Mathf.Abs(dy) > band) focus.y = Mathf.Lerp(focus.y, target.y - Mathf.Sign(dy) * band, 1f - Mathf.Exp(-dt * 5f));
            trauma = Mathf.Max(0f, trauma - dt * 1.6f);
            Place(stage);
        }

        Vector2 Target(Stage stage) => new Vector2(stage.Player.X + lookAhead, stage.Player.Y + 1.5f);

        void Place(Stage stage)
        {
            Camera cam = View;
            float halfWidth = HalfHeight * cam.aspect;
            float width = stage.Map.Width;
            float height = stage.Map.Height;
            float x = width > halfWidth * 2f ? Mathf.Clamp(focus.x, halfWidth, width - halfWidth) : width / 2f;
            float y = height > HalfHeight * 2f ? Mathf.Clamp(focus.y, HalfHeight, height - HalfHeight) : HalfHeight;
            if (ShakeEnabled && trauma > 0f)
            {
                float s = trauma * trauma * 0.45f;
                float t = Time.unscaledTime * 40f;
                x += (Mathf.PerlinNoise(t, 0.3f) - 0.5f) * 2f * s;
                y += (Mathf.PerlinNoise(0.7f, t) - 0.5f) * 2f * s;
            }
            float unitsPerPixel = HalfHeight * 2f / Mathf.Max(1, cam.pixelHeight);
            x = Mathf.Round(x / unitsPerPixel) * unitsPerPixel;
            y = Mathf.Round(y / unitsPerPixel) * unitsPerPixel;
            transform.position = new Vector3(x, y, -10f);
        }
    }
}
