using QapaqInqa.Core;
using UnityEngine;
using UnityEngine.InputSystem;

namespace QapaqInqa.Game
{
    /// <summary>
    /// Keyboard and gamepad through the Input System. Play: A/D or arrows or the left stick move,
    /// W/S or up/down climb (down + jump drops through a ledge), Space/Z/K or the south button
    /// jump, J/X/T or the west button or a trigger shoot, Esc/P or Start pause. Menus: up/down,
    /// left/right to change a value, Enter/Space or south to choose, Esc or east to go back.
    /// </summary>
    public sealed class GameInput
    {
        const float DeadZone = 0.35f;
        int lastStickY;
        int lastStickX;

        static Keyboard Keys => Keyboard.current;
        static Gamepad Pad => Gamepad.current;

        /// <summary>True when the gamepad was used last (the HUD shows pad prompts then).</summary>
        public bool UsingGamepad { get; private set; }

        public InputFrame Read()
        {
            float x = 0f, y = 0f;
            bool jumpPressed = false, jumpHeld = false, fire = false;
            Keyboard k = Keys;
            if (k != null)
            {
                x += (k.dKey.isPressed || k.rightArrowKey.isPressed ? 1f : 0f) - (k.aKey.isPressed || k.leftArrowKey.isPressed ? 1f : 0f);
                y += (k.wKey.isPressed || k.upArrowKey.isPressed ? 1f : 0f) - (k.sKey.isPressed || k.downArrowKey.isPressed ? 1f : 0f);
                jumpPressed |= k.spaceKey.wasPressedThisFrame || k.zKey.wasPressedThisFrame || k.kKey.wasPressedThisFrame;
                jumpHeld |= k.spaceKey.isPressed || k.zKey.isPressed || k.kKey.isPressed;
                fire |= k.jKey.isPressed || k.xKey.isPressed || k.tKey.isPressed || k.leftCtrlKey.isPressed;
                if (k.anyKey.wasPressedThisFrame) UsingGamepad = false;
            }
            Gamepad p = Pad;
            if (p != null)
            {
                Vector2 stick = p.leftStick.ReadValue() + p.dpad.ReadValue();
                if (Mathf.Abs(stick.x) > DeadZone) x += Mathf.Sign(stick.x) * Mathf.Min(1f, Mathf.Abs(stick.x) * 1.25f);
                if (Mathf.Abs(stick.y) > DeadZone) y += Mathf.Sign(stick.y);
                bool south = p.buttonSouth.isPressed;
                jumpPressed |= p.buttonSouth.wasPressedThisFrame;
                jumpHeld |= south;
                fire |= p.buttonWest.isPressed || p.rightTrigger.isPressed || p.rightShoulder.isPressed;
                if (south || p.buttonWest.isPressed || stick.sqrMagnitude > DeadZone * DeadZone) UsingGamepad = true;
            }
            return new InputFrame(x, y, jumpPressed, jumpHeld, fire);
        }

        public bool Pause =>
            (Keys != null && (Keys.escapeKey.wasPressedThisFrame || Keys.pKey.wasPressedThisFrame)) ||
            (Pad != null && Pad.startButton.wasPressedThisFrame);

        public bool Confirm =>
            (Keys != null && (Keys.enterKey.wasPressedThisFrame || Keys.numpadEnterKey.wasPressedThisFrame ||
                              Keys.spaceKey.wasPressedThisFrame || Keys.zKey.wasPressedThisFrame)) ||
            (Pad != null && (Pad.buttonSouth.wasPressedThisFrame || Pad.startButton.wasPressedThisFrame));

        public bool Back =>
            (Keys != null && (Keys.escapeKey.wasPressedThisFrame || Keys.backspaceKey.wasPressedThisFrame || Keys.xKey.wasPressedThisFrame)) ||
            (Pad != null && Pad.buttonEast.wasPressedThisFrame);

        /// <summary>-1 for up, +1 for down, once per press (the stick repeats only after returning to centre).</summary>
        public int Vertical()
        {
            int step = 0;
            if (Keys != null)
            {
                if (Keys.upArrowKey.wasPressedThisFrame || Keys.wKey.wasPressedThisFrame) step = -1;
                if (Keys.downArrowKey.wasPressedThisFrame || Keys.sKey.wasPressedThisFrame) step = 1;
            }
            if (Pad != null)
            {
                if (Pad.dpad.up.wasPressedThisFrame) step = -1;
                if (Pad.dpad.down.wasPressedThisFrame) step = 1;
                float y = Pad.leftStick.ReadValue().y;
                int sign = y > 0.6f ? -1 : y < -0.6f ? 1 : 0;
                if (sign != 0 && sign != lastStickY) step = sign;
                lastStickY = sign;
            }
            return step;
        }

        /// <summary>-1 for left, +1 for right, once per press.</summary>
        public int Horizontal()
        {
            int step = 0;
            if (Keys != null)
            {
                if (Keys.leftArrowKey.wasPressedThisFrame || Keys.aKey.wasPressedThisFrame) step = -1;
                if (Keys.rightArrowKey.wasPressedThisFrame || Keys.dKey.wasPressedThisFrame) step = 1;
            }
            if (Pad != null)
            {
                if (Pad.dpad.left.wasPressedThisFrame) step = -1;
                if (Pad.dpad.right.wasPressedThisFrame) step = 1;
                float x = Pad.leftStick.ReadValue().x;
                int sign = x > 0.6f ? 1 : x < -0.6f ? -1 : 0;
                if (sign != 0 && sign != lastStickX) step = sign;
                lastStickX = sign;
            }
            return step;
        }
    }
}
