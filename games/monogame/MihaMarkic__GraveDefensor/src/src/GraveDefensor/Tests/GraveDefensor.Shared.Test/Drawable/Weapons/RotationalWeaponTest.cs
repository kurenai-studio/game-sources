using GraveDefensor.Shared.Drawable.Weapons;
using NUnit.Framework;
using System;
using Settings = GraveDefensor.Engine.Settings;

namespace GraveDefensor.Shared.Test.Drawable.Weapons
{
    public class RotationalWeaponTest
    {
    }

    public class MockRotationalWeapon : RotationalWeapon<MockRotationalWeaponSettings>
    {
        internal override string WeaponAssetName => "Weapon";
    }
    public class MockRotationalWeaponSettings : Settings.RotationalWeapon
    {

    }
}
