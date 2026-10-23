using UnityEngine;
#if ENABLE_INPUT_SYSTEM
using UnityEngine.InputSystem;
#endif

namespace SimpleRPG
{
    public static class InputHelper
    {
        /// <summary>F3: bật/tắt hiệu ứng hậu kỳ (bloom, vignette).</summary>
        public static bool GetToggleFxDown()
        {
#if ENABLE_INPUT_SYSTEM
            var kb = Keyboard.current;
            return kb != null && kb.f3Key.wasPressedThisFrame;
#else
            return Input.GetKeyDown(KeyCode.F3);
#endif
        }

        public static Vector2 GetMoveInput()
        {
            Vector2 input = Vector2.zero;

#if ENABLE_INPUT_SYSTEM
            var kb = Keyboard.current;
            if (kb != null)
            {
                if (kb.wKey.isPressed || kb.upArrowKey.isPressed) input.y += 1f;
                if (kb.sKey.isPressed || kb.downArrowKey.isPressed) input.y -= 1f;
                if (kb.aKey.isPressed || kb.leftArrowKey.isPressed) input.x -= 1f;
                if (kb.dKey.isPressed || kb.rightArrowKey.isPressed) input.x += 1f;

                if (Gamepad.current != null)
                {
                    Vector2 stick = Gamepad.current.leftStick.ReadValue();
                    if (stick.sqrMagnitude > 0.04f)
                        input += stick;
                }
            }
#else
            input.x = Input.GetAxisRaw("Horizontal");
            input.y = Input.GetAxisRaw("Vertical");
#endif
            return Vector2.ClampMagnitude(input, 1f);
        }

        public static Vector2 GetAimWorldPosition(Camera cam)
        {
            if (cam == null) cam = Camera.main;
            if (cam == null) return Vector2.zero;

#if ENABLE_INPUT_SYSTEM
            var mouse = Mouse.current;
            if (mouse != null)
            {
                Vector2 screenPos = mouse.position.ReadValue();
                Vector3 world = cam.ScreenToWorldPoint(new Vector3(screenPos.x, screenPos.y, -cam.transform.position.z));
                return new Vector2(world.x, world.y);
            }
#else
            Vector3 m = Input.mousePosition;
            Vector3 worldM = cam.ScreenToWorldPoint(new Vector3(m.x, m.y, -cam.transform.position.z));
            return new Vector2(worldM.x, worldM.y);
#endif
            return Vector2.zero;
        }

        public static bool GetAttackDown()
        {
#if ENABLE_INPUT_SYSTEM
            var mouse = Mouse.current;
            var kb = Keyboard.current;
            bool clicked = mouse != null && mouse.leftButton.wasPressedThisFrame;
            bool key = kb != null && (kb.spaceKey.wasPressedThisFrame || kb.jKey.wasPressedThisFrame);
            return clicked || key;
#else
            return Input.GetMouseButtonDown(0) || Input.GetKeyDown(KeyCode.Space) || Input.GetKeyDown(KeyCode.J);
#endif
        }

        public static bool GetAttackHeld()
        {
#if ENABLE_INPUT_SYSTEM
            var mouse = Mouse.current;
            var kb = Keyboard.current;
            bool clicked = mouse != null && mouse.leftButton.isPressed;
            bool key = kb != null && (kb.spaceKey.isPressed || kb.jKey.isPressed);
            return clicked || key;
#else
            return Input.GetMouseButton(0) || Input.GetKey(KeyCode.Space) || Input.GetKey(KeyCode.J);
#endif
        }

        public static bool GetDashDown()
        {
#if ENABLE_INPUT_SYSTEM
            var mouse = Mouse.current;
            var kb = Keyboard.current;
            bool clicked = mouse != null && mouse.rightButton.wasPressedThisFrame;
            bool shift = kb != null && (kb.leftShiftKey.wasPressedThisFrame || kb.rightShiftKey.wasPressedThisFrame || kb.spaceKey.wasPressedThisFrame || kb.kKey.wasPressedThisFrame);
            return clicked || shift;
#else
            return Input.GetMouseButtonDown(1) || Input.GetKeyDown(KeyCode.LeftShift) || Input.GetKeyDown(KeyCode.Space) || Input.GetKeyDown(KeyCode.K);
#endif
        }

        public static bool GetSpecialDown()
        {
#if ENABLE_INPUT_SYSTEM
            var kb = Keyboard.current;
            return kb != null && (kb.qKey.wasPressedThisFrame || kb.eKey.wasPressedThisFrame || kb.uKey.wasPressedThisFrame);
#else
            return Input.GetKeyDown(KeyCode.Q) || Input.GetKeyDown(KeyCode.E) || Input.GetKeyDown(KeyCode.U);
#endif
        }

        public static bool GetInteractDown()
        {
#if ENABLE_INPUT_SYSTEM
            var kb = Keyboard.current;
            return kb != null && (kb.eKey.wasPressedThisFrame || kb.fKey.wasPressedThisFrame);
#else
            return Input.GetKeyDown(KeyCode.E) || Input.GetKeyDown(KeyCode.F);
#endif
        }

        public static bool GetRestartDown()
        {
#if ENABLE_INPUT_SYSTEM
            var kb = Keyboard.current;
            return kb != null && kb.rKey.wasPressedThisFrame;
#else
            return Input.GetKeyDown(KeyCode.R);
#endif
        }

        public static bool GetPauseDown()
        {
#if ENABLE_INPUT_SYSTEM
            var kb = Keyboard.current;
            bool esc = kb != null && kb.escapeKey.wasPressedThisFrame;
            bool startBtn = Gamepad.current != null && Gamepad.current.startButton.wasPressedThisFrame;
            return esc || startBtn;
#else
            return Input.GetKeyDown(KeyCode.Escape);
#endif
        }
    }
}
