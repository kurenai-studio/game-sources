# ProGuard & R8 Optimization and Obfuscation Rules
# Stickman Tower Adventure - Release Hardening

-verbose

-dontwarn android.support.**
-dontwarn com.badlogic.gdx.backends.android.AndroidFragmentApplication

# Needed by LibGDX Controllers
-keep class com.badlogic.gdx.controllers.android.AndroidControllers { *; }

# Needed by Box2D / Physics if present
-keepclassmembers class com.badlogic.gdx.physics.box2d.World {
   boolean contactFilter(long, long);
   boolean getUseDefaultContactFilter();
   void    beginContact(long);
   void    endContact(long);
   void    preSolve(long, long);
   void    postSolve(long, long);
   boolean reportFixture(long);
   float   reportRayFixture(long, float, float, float, float, float);
}

# Keep LibGDX Core, Scene2D, Graphics & Backends
-keep public class com.badlogic.gdx.backends.android.** { *; }
-keep public class com.badlogic.gdx.scenes.scene2d.** { *; }
-keep public class com.badlogic.gdx.graphics.g2d.BitmapFont { *; }
-keep public class com.badlogic.gdx.graphics.Color { *; }
-keep interface com.badlogic.gdx.** { *; }

# CRITICAL: Keep Game Models, RPG Stats, Quests & SaveData Serializers
# Mencegah obfuscation merusak JSON reflection pada SaveData dan SaveManager
-keep class com.stickman.tower.rpg.** { *; }
-keep class com.stickman.tower.bestiary.** { *; }
-keep class com.stickman.tower.quest.** { *; }
-keep class com.stickman.tower.achievement.** { *; }
-keep class com.stickman.tower.leaderboard.** { *; }
-keep class com.stickman.tower.bounty.** { *; }
-keep class com.stickman.tower.challenge.** { *; }
-keep class com.stickman.tower.relic.** { *; }
-keep class com.stickman.tower.talent.** { *; }
-keep class com.stickman.tower.world.** { *; }
-keep class com.stickman.tower.character.** { *; }
-keep class com.stickman.tower.enemy.** { *; }
-keep class com.stickman.tower.combat.** { *; }
-keep class com.stickman.tower.audio.** { *; }
-keep class com.stickman.tower.input.** { *; }
-keep class com.stickman.tower.ui.** { *; }
-keep class com.stickman.tower.vfx.** { *; }
-keep class com.stickman.tower.tools.** { *; }

# Keep Enums for serialization and string lookup
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Retain attributes for Stacktraces & Retracing
-keepattributes *Annotation*,EnclosingMethod,Signature,InnerClasses,LineNumberTable,SourceFile
-renamesourcefileattribute SourceFile
