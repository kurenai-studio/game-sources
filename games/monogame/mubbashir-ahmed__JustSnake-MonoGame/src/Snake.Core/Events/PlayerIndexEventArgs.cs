using Microsoft.Xna.Framework;
using System;

namespace Snake.Core.Events
{
    /// <summary>
    /// Represents the event arguments for a player index.
    /// </summary>
    public class PlayerIndexEventArgs : EventArgs
    {
        /// <summary>
        /// The player index.
        /// </summary>
        private PlayerIndex playerIndex;

        /// <summary>
        /// Gets the player index.
        /// </summary>
        /// <returns>The player index.</returns>
        public PlayerIndex PlayerIndex { get => playerIndex; }

        /// <summary>
        /// Initializes a new instance of the PlayerIndexEventArgs class.
        /// </summary>
        /// <param name="playerIndex">The player index.</param>
        public PlayerIndexEventArgs(PlayerIndex playerIndex)
        {
            this.playerIndex = playerIndex;
        }
    }
}
