using GraveDefensor.Shared.Core;
using GraveDefensor.Shared.Drawable;
using GraveDefensor.Shared.Services.Implementation;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Input;
using NUnit.Framework;
using System;
using System.Diagnostics;

namespace GraveDefensor.Shared.Test.Drawable
{
    public class ClickableDrawableTest: BaseTest<MockClickableDrawable>
    {
        [TestFixture]
        public class Init: ClickableDrawableTest
        {
            [Test]
            public void AfterInit_StateIsNone()
            {
                Target.Init();

                Assert.That(Target.ClickState, Is.EqualTo(ClickState.None));
            }
        }
        [TestFixture]
        public class Update: ClickableDrawableTest
        {
            [DebuggerStepThrough]
            internal static UpdateContext GetUpdateContext(ButtonState buttonState, int x = 0, int y = 0) => 
                new UpdateContext(new GameTime(),
                    new MouseState(x, y, default, leftButton: buttonState, default, default, default, default),
                    new TouchState(),
                    new Point(x, y),
                    default);

            [SetUp]
            public new void SetUp()
            {
                Target.Init();
            }
            [Test]
            public void WhenButtonIsPressedAndOutsideBounds_ClickStateIsNone()
            {
                Target.Update(GetUpdateContext(ButtonState.Pressed));

                Assert.That(Target.ClickState, Is.EqualTo(ClickState.None));
            }
            [Test]
            public void WhenButtonIsPressedAndOutsideBounds_ClickPositionIsNotStored()
            {
                Target.Update(GetUpdateContext(ButtonState.Pressed, x: 1, y: 2));

                Assert.That(Target.ClickPosition, Is.EqualTo(new Point(0, 0)));
            }
            [Test]
            public void WhenDisabledAndButtonIsPressedAndInsideBounds_ClickStateIsNone()
            {
                Target.SetIsEnabled(false);
                Target.OnIsClickWithinBoundaries = s => true;

                Target.Update(GetUpdateContext(ButtonState.Pressed));

                Assert.That(Target.ClickState, Is.EqualTo(ClickState.None));
            }
            [Test]
            public void WhenEnabledAndButtonIsPressedAndInsideBounds_ClickStateIsPressed()
            {
                Target.SetIsEnabled(true);
                Target.OnIsClickWithinBoundaries = s => true;

                Target.Update(GetUpdateContext(ButtonState.Pressed));

                Assert.That(Target.ClickState, Is.EqualTo(ClickState.Pressed));
            }
            [Test]
            public void WhenEnabledAndButtonIsPressedAndInsideBounds_ClickPositionIsStored()
            {
                Target.SetIsEnabled(true);
                Target.OnIsClickWithinBoundaries = s => true;

                Target.Update(GetUpdateContext(ButtonState.Pressed, x:1, y:2));

                Assert.That(Target.ClickPosition, Is.EqualTo(new Point(1, 2)));
            }
            [Test]
            public void WhenEnabledAndMovedWhilePressed_ClickStateIsMoved()
            {
                Target.SetIsEnabled(true);
                Target.OnIsClickWithinBoundaries = s => true;
                Target.Update(GetUpdateContext(ButtonState.Pressed, x: 0, y: 0));

                Target.Update(GetUpdateContext(ButtonState.Pressed, x: 1, y: 2));

                Assert.That(Target.ClickState, Is.EqualTo(ClickState.Moved));
            }
            [Test]
            public void WhenEnabledAndNotMovedWhilePressed_ClickStateIsPressed()
            {
                Target.SetIsEnabled(true);
                Target.OnIsClickWithinBoundaries = s => true;
                Target.Update(GetUpdateContext(ButtonState.Pressed, x: 1, y: 2));

                Target.Update(GetUpdateContext(ButtonState.Pressed, x: 1, y: 2));

                Assert.That(Target.ClickState, Is.EqualTo(ClickState.Pressed));
            }
            [Test]
            public void WhenEnabledAndButtonIsReleasedAfterPressed_ClickStateIsClicked()
            {
                Target.SetIsEnabled(true);
                Target.OnIsClickWithinBoundaries = s => true;
                Target.Update(GetUpdateContext(ButtonState.Pressed, x: 1, y: 2));

                Target.Update(GetUpdateContext(ButtonState.Released, x: 1, y: 2));

                Assert.That(Target.ClickState, Is.EqualTo(ClickState.Clicked));
            }
            [Test]
            public void InNextIterationAfterButtonWasClicked_ClickStateIsNone()
            {
                Target.OnIsClickWithinBoundaries = s => true;
                Target.Update(GetUpdateContext(ButtonState.Pressed, x: 1, y: 2));
                Target.Update(GetUpdateContext(ButtonState.Released, x: 1, y: 2));

                Target.Update(GetUpdateContext(ButtonState.Released));

                Assert.That(Target.ClickState, Is.EqualTo(ClickState.None));
            }
            [Test]
            public void WhenStateIsMovedAndButtonIsReleased_ClickStateIsNone()
            {
                Target.OnIsClickWithinBoundaries = s => true;
                Target.Update(GetUpdateContext(ButtonState.Pressed, x: 1, y: 2));
                Target.Update(GetUpdateContext(ButtonState.Pressed, x: 5, y: 2));

                Target.Update(GetUpdateContext(ButtonState.Released));

                Assert.That(Target.ClickState, Is.EqualTo(ClickState.None));
            }
        }
    }

    public class MockClickableDrawable: ClickableDrawable
    {
        public Func<Point, bool> OnIsClickWithinBoundaries;

        public void SetIsEnabled(bool isEnabled) => IsEnabled = isEnabled;
        public new void Init() => base.Init();
        public override bool IsClickWithinBoundaries(Point point) => OnIsClickWithinBoundaries?.Invoke(point) ?? false;
    }
}
