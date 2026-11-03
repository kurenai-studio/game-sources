using NUnit.Framework;
using QapaqInqa.Core;

namespace QapaqInqa.Core.Tests
{
    public class MotorTests
    {
        static PlayerMotor Start(LevelMap map)
        {
            var motor = new PlayerMotor(map.Start);
            motor.Step(map, InputFrame.None, Sim.Dt);
            return motor;
        }

        [Test]
        public void FallsOntoTheGroundAndStandsThere()
        {
            LevelMap map = Sim.Map(
                "   P  E   ",
                "          ",
                "          ",
                "##########");
            var motor = new PlayerMotor(map.Start);
            MoveEvents events = Sim.Frames(motor, map, InputFrame.None, Sim.Seconds(1f));
            Assert.That(motor.Y, Is.EqualTo(1f));
            Assert.That(motor.Grounded, Is.True);
            Assert.That(motor.VelocityY, Is.EqualTo(0f));
            Assert.That(events & MoveEvents.Landed, Is.EqualTo(MoveEvents.Landed));
        }

        [Test]
        public void RunsUpToRunSpeedAndFacesTheWayItRuns()
        {
            LevelMap map = Sim.Map(Sim.Flat(60));
            PlayerMotor motor = Start(map);
            Sim.Frames(motor, map, Sim.Hold(x: -1f), 2);
            Assert.That(motor.Facing, Is.EqualTo(-1));
            Sim.Frames(motor, map, Sim.Hold(x: 1f), Sim.Seconds(0.5f));
            Assert.That(motor.VelocityX, Is.EqualTo(Tuning.RunSpeed));
            Assert.That(motor.Facing, Is.EqualTo(1));
            Assert.That(motor.Y, Is.EqualTo(1f), "running on flat ground stays on the ground");
        }

        [Test]
        public void StopsFlushAgainstAWall()
        {
            LevelMap map = Sim.Map(
                "              ",
                "              ",
                " P      #   E ",
                "##############");
            PlayerMotor motor = Start(map);
            Sim.Frames(motor, map, Sim.Hold(x: 1f), Sim.Seconds(2f));
            Assert.That(motor.X + Tuning.PlayerWidth / 2f, Is.EqualTo(8f).Within(0.01f));
            Assert.That(motor.VelocityX, Is.EqualTo(0f));
            Assert.That(motor.HitWall, Is.True);
        }

        [Test]
        public void HeldJumpRisesAboutTwoAndAHalfTiles()
        {
            LevelMap map = Sim.Map(Sim.Flat());
            PlayerMotor motor = Start(map);
            MoveEvents events = motor.Step(map, Sim.Press(), Sim.Dt);
            Assert.That(events & MoveEvents.Jumped, Is.EqualTo(MoveEvents.Jumped));
            float peak = motor.Y;
            for (int i = 0; i < 120; i++)
            {
                motor.Step(map, Sim.Hold(jump: true), Sim.Dt);
                peak = System.Math.Max(peak, motor.Y);
            }
            Assert.That(peak - 1f, Is.InRange(2.4f, 2.8f));
            Assert.That(motor.Grounded, Is.True, "lands again");
        }

        [Test]
        public void ATappedJumpIsAShortHop()
        {
            LevelMap map = Sim.Map(Sim.Flat());
            PlayerMotor motor = Start(map);
            motor.Step(map, Sim.Press(), Sim.Dt);
            float peak = motor.Y;
            for (int i = 0; i < 120; i++)
            {
                motor.Step(map, InputFrame.None, Sim.Dt);
                peak = System.Math.Max(peak, motor.Y);
            }
            Assert.That(peak - 1f, Is.LessThan(0.8f));
        }

        [Test]
        public void CannotJumpInMidAirButCoyoteTimeForgivesALateJump()
        {
            LevelMap map = Sim.Map(
                "            ",
                "            ",
                "            ",
                "            ",
                " P        E ",
                "####        ",
                "            ",
                "            ",
                "            ",
                "############");
            PlayerMotor late = Start(map);
            // Run off the edge, then press jump a few frames after the ground is gone.
            while (late.X < 4f + Tuning.PlayerWidth / 2f + 0.05f) late.Step(map, Sim.Hold(x: 1f), Sim.Dt);
            Assert.That(late.Grounded, Is.False);
            MoveEvents coyote = late.Step(map, Sim.Press(x: 1f), Sim.Dt);
            Assert.That(coyote & MoveEvents.Jumped, Is.EqualTo(MoveEvents.Jumped), "a jump just after the edge still counts");

            PlayerMotor tooLate = Start(map);
            while (tooLate.X < 4f + Tuning.PlayerWidth / 2f + 0.05f) tooLate.Step(map, Sim.Hold(x: 1f), Sim.Dt);
            Sim.Frames(tooLate, map, Sim.Hold(x: 1f), Sim.Seconds(0.2f));
            MoveEvents air = tooLate.Step(map, Sim.Press(x: 1f), Sim.Dt);
            Assert.That(air & MoveEvents.Jumped, Is.EqualTo(MoveEvents.None), "no jump once coyote time is over");
        }

        [Test]
        public void AJumpPressedJustBeforeLandingIsBuffered()
        {
            LevelMap map = Sim.Map(Sim.Flat());
            PlayerMotor motor = Start(map);
            motor.Step(map, Sim.Press(), Sim.Dt);
            // Fall back down until just above the floor, then press jump while still airborne.
            Sim.Frames(motor, map, Sim.Hold(jump: true), 10);
            while (!(motor.VelocityY < 0f && motor.Y < 1.25f)) motor.Step(map, Sim.Hold(jump: true), Sim.Dt);
            Assert.That(motor.Grounded, Is.False);
            motor.Step(map, Sim.Press(), Sim.Dt);
            MoveEvents events = Sim.Frames(motor, map, Sim.Hold(jump: true), 5);
            Assert.That(events & MoveEvents.Jumped, Is.EqualTo(MoveEvents.Jumped));
            Assert.That(motor.VelocityY, Is.GreaterThan(0f));
        }

        [Test]
        public void LedgesHoldFromAboveLetYouJumpUpThroughAndDropDown()
        {
            LevelMap map = Sim.Map(
                "          ",
                "          ",
                "          ",
                "   ===    ",
                "   P   E  ",
                "##########");
            PlayerMotor motor = Start(map);
            Assert.That(motor.Y, Is.EqualTo(1f));
            motor.Step(map, Sim.Press(), Sim.Dt);
            Sim.Frames(motor, map, Sim.Hold(jump: true), Sim.Seconds(1.2f));
            Assert.That(motor.Y, Is.EqualTo(3f), "jumped up through the ledge and landed on it");
            Assert.That(motor.Grounded, Is.True);

            motor.Step(map, Sim.Press(y: -1f), Sim.Dt);
            Sim.Frames(motor, map, Sim.Hold(y: -1f), Sim.Seconds(1f));
            Assert.That(motor.Y, Is.EqualTo(1f), "down + jump drops through");
        }

        [Test]
        public void BonksItsHeadOnStone()
        {
            LevelMap map = Sim.Map(
                "          ",
                "   #####  ",
                "          ",
                "   P   E  ",
                "##########");
            PlayerMotor motor = Start(map);
            MoveEvents events = motor.Step(map, Sim.Press(), Sim.Dt);
            events |= Sim.Frames(motor, map, Sim.Hold(jump: true), 20);
            Assert.That(events & MoveEvents.Bonked, Is.EqualTo(MoveEvents.Bonked));
            Assert.That(motor.Y + Tuning.PlayerHeight, Is.LessThanOrEqualTo(3f));
        }

        [Test]
        public void ClimbsALadderAndStepsOntoItsTop()
        {
            LevelMap map = Sim.Map(
                "          ",
                "          ",
                "   H      ",
                "   H      ",
                "   H      ",
                "   P   E  ",
                "##########");
            PlayerMotor motor = Start(map);
            MoveEvents events = Sim.Frames(motor, map, Sim.Hold(y: 1f), 2);
            Assert.That(motor.Climbing, Is.True);
            Assert.That(events & MoveEvents.StartedClimbing, Is.EqualTo(MoveEvents.StartedClimbing));
            Assert.That(motor.X, Is.EqualTo(3.5f), "snaps onto the rungs");
            Sim.Frames(motor, map, Sim.Hold(y: 1f), Sim.Seconds(2f));
            Assert.That(motor.Climbing, Is.False);
            Assert.That(motor.Y, Is.EqualTo(5f), "stands on the top rung");
            Sim.Frames(motor, map, InputFrame.None, 30);
            Assert.That(motor.Y, Is.EqualTo(5f), "the top rung holds like a ledge");

            Sim.Frames(motor, map, Sim.Hold(y: -1f), Sim.Seconds(2f));
            Assert.That(motor.Y, Is.EqualTo(1f), "climbs back down to the floor");
            Assert.That(motor.Climbing, Is.False);
        }

        [Test]
        public void KnockbackPushesAwayAndBrieflyIgnoresTheStick()
        {
            LevelMap map = Sim.Map(Sim.Flat());
            PlayerMotor motor = Start(map);
            motor.Knockback(motor.X - 1f);
            Assert.That(motor.VelocityX, Is.EqualTo(Tuning.KnockbackX));
            Assert.That(motor.VelocityY, Is.EqualTo(Tuning.KnockbackY));
            motor.Step(map, Sim.Hold(x: -1f), Sim.Dt);
            Assert.That(motor.Facing, Is.EqualTo(1), "the stick does not turn the player during the lock");
            Assert.That(motor.VelocityX, Is.GreaterThan(0f), "still flying away from the hit");
            Sim.Frames(motor, map, Sim.Hold(x: -1f), Sim.Seconds(0.15f));
            Assert.That(motor.VelocityX, Is.EqualTo(Tuning.KnockbackX), "the hit carries the body during the lock");
            Assert.That(motor.Y, Is.GreaterThan(1.5f), "and lifts it");
            Sim.Frames(motor, map, Sim.Hold(x: -1f), Sim.Seconds(0.6f));
            Assert.That(motor.VelocityX, Is.LessThan(0f), "control comes back");
            Assert.That(motor.Facing, Is.EqualTo(-1));
        }
    }
}
