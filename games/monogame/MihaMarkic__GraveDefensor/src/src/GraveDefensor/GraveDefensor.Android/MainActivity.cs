using Android.App;
using Android.Content.PM;
using Android.OS;
using Android.Views;
using GraveDefensor.Engine.Core;
using GraveDefensor.Shared;

namespace GraveDefensor.Android
{
    [Activity(Label = "Grave Defensor"
        , MainLauncher = true
        , Icon = "@drawable/icon"
        , Theme = "@style/Theme.Splash"
        , AlwaysRetainTaskState = true
        , LaunchMode = LaunchMode.SingleInstance
        , ScreenOrientation = ScreenOrientation.FullUser
        , ConfigurationChanges = ConfigChanges.Orientation | ConfigChanges.Keyboard | ConfigChanges.KeyboardHidden | ConfigChanges.ScreenSize)]
    public class MainActivity: Microsoft.Xna.Framework.AndroidGameActivity
    {
        protected override void OnCreate(Bundle bundle)
        {
            base.OnCreate(bundle);
            ScreenInfo.Default = ScreenInfo.FullScreen(hasMouse: false);
            var g = new GraveDefensorGame();
            SetContentView((View)g.Services.GetService(typeof(View)));
            g.Run();
        }
    }
}

