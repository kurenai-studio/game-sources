namespace Snake.Core.Enums
{
    /// <summary>
    /// Represents the state of a screen.
    /// </summary>
    public enum ScreenState
    {
        /// <summary>
        /// The screen is transitioning in.
        /// </summary>
        TransitionOn,
        
        /// <summary>
        /// The screen is active.
        /// </summary>
        Active,
        
        /// <summary>
        /// The screen is transitioning out.
        /// </summary>
        TransitionOff,
        
        /// <summary>
        /// The screen is hidden.
        /// </summary>
        Hidden,
    }
}
