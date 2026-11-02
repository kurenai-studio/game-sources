-verbose

-dontwarn android.support.**
-dontwarn com.badlogic.gdx.backends.android.AndroidFragmentApplication
-dontwarn com.badlogic.gdx.utils.GdxRuntimeException

# libGDX
-keep class com.badlogic.gdx.** { *; }
-keep class com.badlogic.gdx.backends.android.** { *; }

# Game classes
-keep class com.darumahq.rainbowclimb.** { *; }
