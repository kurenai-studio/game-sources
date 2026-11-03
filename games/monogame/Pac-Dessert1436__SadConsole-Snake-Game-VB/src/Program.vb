Imports SadConsole
Imports SadConsole.Configuration

Public Module Program
    Friend Sub Main()
        Settings.WindowTitle = "SadConsole Snake Game"

        Builder.
            GetBuilder().
            SetWindowSizeInPixels(800, 600).
            ConfigureFonts(True).
            SetStartingScreen(Of RootScreen)().
            IsStartingScreenFocused(True).
            Run()
    End Sub
End Module