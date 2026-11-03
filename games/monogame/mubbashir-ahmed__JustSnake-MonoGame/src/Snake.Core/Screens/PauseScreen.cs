using Snake.Core.Events;
using Snake.Core.Localization;
using Snake.Core.Models;

namespace Snake.Core.Screens
{
    /// <summary>
    /// A screen that displays pause menu options.
    /// </summary>
    public class PauseScreen : MenuScreen
    {
        /// <summary>
        /// Resume menu entry.
        /// </summary>
        private readonly MenuEntry resumeEntry;

        /// <summary>
        /// Exit menu entry.
        /// </summary>
        private readonly MenuEntry exitEntry;

        /// <summary>
        /// Initializes a new instance of the PauseScreen class.
        /// </summary>
        public PauseScreen() : base(Resources.PauseScreenTitle)
        {
            resumeEntry = new MenuEntry(Resources.ResumeMenuText);
            exitEntry = new MenuEntry(Resources.ExitMenuText);

            resumeEntry.Selected += OnCancel;
            exitEntry.Selected += ExitMenuEntrySelected;

            MenuEntries.Add(resumeEntry);
            MenuEntries.Add(exitEntry);
        }

        /// <summary>
        /// Handles the exit menu entry selection.
        /// </summary>
        /// <param name="sender">The event sender.</param>
        /// <param name="e">The event arguments.</param>
        private void ExitMenuEntrySelected(object sender, PlayerIndexEventArgs e)
        {
            string message = Resources.ExitMenuQuestion;

            MessageBoxScreen confirmExitMessageBox = new MessageBoxScreen(message);
            confirmExitMessageBox.Accepted += ConfirmExitMessageBoxAccepted;
            ScreenManager.AddScreen(confirmExitMessageBox, ControllingPlayer);
        }

        /// <summary>
        /// Handles the confirm exit message box acceptance.
        /// </summary>
        /// <param name="sender">The event sender.</param>
        /// <param name="e">The event arguments.</param>
        private void ConfirmExitMessageBoxAccepted(object sender, PlayerIndexEventArgs e)
        {
            LoadingScreen.Load(ScreenManager, false, ControllingPlayer, new BackgroundScreen(), new MainMenuScreen());
        }
    }
}
