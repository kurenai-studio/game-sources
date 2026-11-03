using Microsoft.Xna.Framework.Input;
using System.Dynamic;
using System.Threading;

namespace MonoGameLibrary.Input;

public class KeyboardInfo
{
    /// <summary>
    /// Gets state of keyboard input during previous update cycle.
    /// </summary>
    public KeyboardState PreviousState { get; private set; }

    /// <summary>
    /// Gets the state of keyboard input during current input cycle.
    /// </summary>
    public KeyboardState CurrentState { get; private set; }

    /// <summary>
    /// Creates a new KeyboardInfo
    /// </summary>
    public KeyboardInfo()
    {
        PreviousState = new KeyboardState();
        CurrentState = Keyboard.GetState();
    }

    /// <summary>
    /// Updates state information about keyboard inp
    /// </summary>
    public void Update()
    {
        PreviousState = CurrentState;
        CurrentState = Keyboard.GetState();
    }

    /// <summary>
    /// Returns value whether specified key is current down.
    /// </summary>
    /// <param name="key">true if specified key is currently down; otherwise, false</param>
    /// <returns></returns>
    public bool IsKeyDown(Keys key)
    {
        return CurrentState.IsKeyDown(key);
    }

    /// <summary>
    /// Returns value whether specified key is current up.
    /// </summary>
    /// <param name="key">true if specified key is currently up; otherwise false</param>
    /// <returns></returns>
    public bool IsKeyUp(Keys key)
    {
        return CurrentState.IsKeyUp(key);
    }

    /// <summary>
    /// Returns value to indicate if specified key was just pressed in current frame.
    /// </summary>
    /// <param name="key">The key to check</param>
    /// <returns>true if specified key was just pressed on current frame; otherwise, false</returns>
    public bool WasKeyJustPressed(Keys key)
    {
        return CurrentState.IsKeyDown(key) && PreviousState.IsKeyUp(key);
    }

    /// <summary>
    /// Returns value to indicate if specified key was just releaesed in current frame.
    /// </summary>
    /// <param name="key">The key to check</param>
    /// <returns>true if specified key was just released on current frame; otherwise, false</returns>
    public bool WasKeyJustReleased(Keys key)
    {
        return CurrentState.IsKeyUp(key) && PreviousState.IsKeyDown(key);
    }
}