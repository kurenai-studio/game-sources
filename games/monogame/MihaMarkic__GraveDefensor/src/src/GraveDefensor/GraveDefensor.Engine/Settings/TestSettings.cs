namespace GraveDefensor.Engine.Settings
{
    public static class TestSettings
    {
        public static Master CreateTestMaster()
        {
            return new Master
            {
                Enemies = new Enemies
                {
                    CreepyWorm = new CreepyWorm { Name = "Creepy Worm", Speed = 40, Health = 120, Award = 25 },
                    Skeleton = new Skeleton { Name = "Skeleton", Speed = 15, Health = 180, Award = 30 }
                },
                Weapons = new Weapons
                {
                    MiniGun = new MiniGun
                    {
                        Name = "Mini gun",
                        Price = 200,
                        FiringRange = 140,
                        TrackingRange = 150,
                        Power = 5,
                        RotationalSpeed = 260,
                        AirCapability = true,
                        GroundCapability = true,
                        CenterOffsetX = 9,
                        ReloadTime = 100,
                        FiringTime = 5,
                    },
                    Vulcan = new Vulcan
                    {
                        Name = "Vulcan",
                        Price = 250,
                        FiringRange = 65,
                        TrackingRange = 70,
                        Power = 4,
                        RotationalSpeed = 214,
                        AirCapability = true,
                        GroundCapability = true
                    },
                    Cannon = new Cannon
                    {
                        Name = "Cannon",
                        Price = 500,
                        FiringRange = 110,
                        TrackingRange = 120,
                        Power = 125,
                        RotationalSpeed = 12,
                        AirCapability = false,
                        GroundCapability = true
                    }
                },
                Battles = new Battle[]
                {
                    CreateTestBattle()
                }
            };
        }
        public static Battle CreateTestBattle()
        {
            return new Battle
            {
                Background = "Battle1",
                Health = 500,
                Amount = 200,
                WeaponPlaces = new[] {
                    new WeaponPod
                    {
                        Center = new Point { X = 100, Y = 220},
                        Size = new Size { Width = 32, Height = 32 }
                    },
                    new WeaponPod
                    {
                        Center = new Point { X = 200, Y = 270},
                        Size = new Size { Width = 32, Height = 32 }
                    },
                    new WeaponPod
                    {
                        Center = new Point { X = 280, Y = 330},
                        Size = new Size { Width = 32, Height = 32 }
                    },
                    new WeaponPod
                    {
                        Center = new Point { X = 240, Y = 580 },
                        Size = new Size { Width = 32, Height = 32 }
                    }
                },
                Paths = new Path[]
                {
                    new Path
                    {
                        Id = "Core",
                        Points = new Point[]
                        {
                            new Point { X = -10, Y = 170 },
                            new Point { X = 300, Y = 170 },
                            new Point { X = 320, Y = 190 },
                            new Point { X = 320, Y = 520 },
                            new Point { X = 300, Y = 540 },
                            new Point { X = 32, Y = 540 },
                        }
                    }
                },
                Waves = new EnemyWave[]
                {
                    new EnemyWave
                    {
                        Sets = new EnemySet[]
                        {
                            new EnemySet
                            {
                                Id = "First",
                                PathId = "Core",
                                EnemyId = "CreepyWorm",
                                StartTimeOffset = 500,
                                Interval = 4000,
                                EnemiesCount = 10
                            }
                        }
                    }
                },
                WeaponNames = new string[] { nameof(MiniGun), nameof(Vulcan) }
            };
        }
    }
}
