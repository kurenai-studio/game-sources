using GraveDefensor.Shared.Core;
using GraveDefensor.Shared.Drawable;
using GraveDefensor.Shared.Service.Abstract;
using GraveDefensor.Shared.Services.Implementation;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Input;
using NUnit.Framework;

namespace GraveDefensor.Shared.Test.Drawable.Dialogs
{
    public class DialogTest: BaseTest<MockDialog>
    {
        internal static UpdateContext GetUpdateContext(ButtonState buttonState, int x = 0, int y = 0) =>
               new UpdateContext(new GameTime(),
                   new MouseState(x, y, default, leftButton: buttonState, default, default, default, default),
                   new TouchState(),
                   new Point(x, y),
                   default);

        [TestFixture]
        public class Init: DialogTest
        {
            [Test]
            public void AfterInit_StateIsOpen()
            {
                Target.Init(default, default, default, default);

                Assert.That(Target.State, Is.EqualTo(DialogState.Init));
            }
            [Test]
            public void AfterInit_WasPressedOutsideIsFalse()
            {
                Target.Init(default, default, default, default);

                Assert.That(Target.WasPressedOutside, Is.False);
            }
            [Test]
            public void WasPressedOutside_WasPressedOutsideIsFalse()
            {
                Target.Init(width: 50, contentHeight: 30, null, null);
                Target.Position(new Point(10, 20));
                // transition from init to open
                Target.Update(GetUpdateContext(ButtonState.Released));
                Target.Update(GetUpdateContext(ButtonState.Pressed));
                Target.Update(GetUpdateContext(ButtonState.Released));

                Target.Init(default, default, default, default);

                Assert.That(Target.WasPressedOutside, Is.False);
            }
            [Test]
            public void WasClosing_WasPressedOutsideIsFalse()
            {
                Target.Init(width: 50, contentHeight: 30, null, null);
                // transition from init to open
                Target.Update(GetUpdateContext(ButtonState.Released));
                Target.Update(GetUpdateContext(ButtonState.Pressed));
                Target.Update(GetUpdateContext(ButtonState.Released));

                Target.Init(default, default, default, default);

                Assert.That(Target.State, Is.EqualTo(DialogState.Init));
            }
        }
        [TestFixture]
        public class Update: DialogTest
        {
            [SetUp]
            public new void SetUp()
            {
                Target.Init(width: 50, contentHeight: 30, null, null);
                Target.Position(new Point(10, 20));
                // transition from init to open
                Target.Update(GetUpdateContext(ButtonState.Released));
            }
            [Test]
            public void WhenClickInsideBounds_WasPressedOutsideIsFalse()
            {
                Target.Update(GetUpdateContext(ButtonState.Pressed, 15, 25));

                Assert.That(Target.WasPressedOutside, Is.False);
            }
            [Test]
            public void WhenClickOutsideBounds_WasPressedOutsideIsFalse()
            {
                Target.Update(GetUpdateContext(ButtonState.Pressed));

                Assert.That(Target.WasPressedOutside, Is.True);
            }
            [Test]
            public void WhenPressedAndReleasedOutsideBounds_StateIsClosing()
            {
                Target.Update(GetUpdateContext(ButtonState.Pressed));
                Target.Update(GetUpdateContext(ButtonState.Released));

                Assert.That(Target.State, Is.EqualTo(DialogState.Closing));
            }
            [Test]
            public void WhenWasNotPressedOutsideAndReleased_StateIsOpen()
            {
                Target.Update(GetUpdateContext(ButtonState.Released));

                Assert.That(Target.State, Is.EqualTo(DialogState.Open));
            }
        }
    }

    public class MockDialog : Dialog
    {
        internal override void DrawContent(IDrawContext context)
        {
            
        }
    }
}
