using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Input;
using MonoGameLibrary.Archetypes;
using MonoGameLibrary.Components;
using MonoGameLibrary.Components.Infrastructure;
using MonoGameLibrary.Input;
using MonoGameLibrary.Systems.Infrastructure;
using MonoGameLibrary.UI;
using Proto4X.Sandbox.Components;
using System;
using System.Collections.Generic;

namespace Proto4X.Sandbox.Systems
{
    /// <summary>
    /// Click to select a unit, double click to select every unit of that kind, drag to box-select,
    /// hold shift to add to the selection. Only the player's own units can be selected.
    /// </summary>
    /// <remarks>
    /// Selection is written straight into each entity's <c>Selectable</c> component, so there is no
    /// selected-entity list to keep in sync with the world - a unit that dies simply stops existing
    /// and stops being selected. That sidesteps needing entity ids.
    ///
    /// The box test runs in screen space (the drag rectangle is a screen rectangle) while the click
    /// test runs in world space (the pick radius is a world radius). Doing each in its own space
    /// keeps both correct while the camera is zoomed or rotated.
    /// </remarks>
    public class SelectionSystem(Camera camera) : ISystem, IUpdateSystem
    {
        private const float DragThresholdPixels = 6f;
        private const float DoubleClickSeconds = 0.35f;
        private const float DoubleClickSlopPixels = 8f;

        private Vector2? dragStartScreen;
        private Vector2 lastClickScreen;
        private float secondsSinceLastClick = float.MaxValue;

        /// <summary>The in-progress drag rectangle in screen space, for the overlay renderer. Null when not dragging.</summary>
        public (Vector2 Start, Vector2 Current)? DragScreenRectangle { get; private set; }

        private static readonly ComponentRef[] requiredComponentProviders =
            [ComponentRef.Of<Position>(), ComponentRef.Of<Selectable>(), ComponentRef.Of<Faction>(), ComponentRef.Of<UnitType>()];

        public IReadOnlyList<ComponentRef> RequiredComponentProviders => requiredComponentProviders;

        public void Update(GameTime gameTime, List<ArchetypeChunk> archetypeChunks)
        {
            secondsSinceLastClick += (float)gameTime.ElapsedGameTime.TotalSeconds;

            var mouse = InputManager.Instance.MouseInfo;
            var mouseScreen = mouse.Position.ToVector2();

            if (mouse.WasButtonJustPressed(MouseButton.Left))
            {
                dragStartScreen = mouseScreen;
            }

            if (dragStartScreen is not Vector2 dragStart)
            {
                DragScreenRectangle = null;
                return;
            }

            if (mouse.IsButtonDown(MouseButton.Left))
            {
                DragScreenRectangle = (dragStart, mouseScreen);
                return;
            }

            DragScreenRectangle = null;
            dragStartScreen = null;

            if (!mouse.WasButtonJustReleased(MouseButton.Left))
            {
                return;
            }

            var keyboard = InputManager.Instance.KeyboardInfo;
            var isAdditive = keyboard.IsKeyDown(Keys.LeftShift) || keyboard.IsKeyDown(Keys.RightShift);

            var dragDelta = mouseScreen - dragStart;
            if (MathF.Abs(dragDelta.X) >= DragThresholdPixels || MathF.Abs(dragDelta.Y) >= DragThresholdPixels)
            {
                SelectWithinBox(archetypeChunks, dragStart, mouseScreen, isAdditive);
                secondsSinceLastClick = float.MaxValue;
                return;
            }

            var isDoubleClick = secondsSinceLastClick <= DoubleClickSeconds
                && Vector2.Distance(mouseScreen, lastClickScreen) <= DoubleClickSlopPixels;

            SelectAtPoint(archetypeChunks, mouseScreen, isAdditive, isDoubleClick);

            lastClickScreen = mouseScreen;
            // A double click consumes both clicks, so a third click starts a fresh pair rather than
            // chaining into another select-all.
            secondsSinceLastClick = isDoubleClick ? float.MaxValue : 0f;
        }

        private void SelectAtPoint(List<ArchetypeChunk> archetypeChunks, Vector2 clickScreen, bool isAdditive, bool isDoubleClick)
        {
            var clickWorld = Vector2.Transform(clickScreen, Matrix.Invert(camera.GetCameraTransform()));

            var closestDistanceSquared = float.MaxValue;
            var pickedChunk = -1;
            var pickedIndex = -1;

            for (var chunkIndex = 0; chunkIndex < archetypeChunks.Count; chunkIndex++)
            {
                var archetypeChunk = archetypeChunks[chunkIndex];
                var positionSpan = archetypeChunk.GetSpan<Position>();
                var selectableSpan = archetypeChunk.GetSpan<Selectable>();
                var factionSpan = archetypeChunk.GetSpan<Faction>();

                for (var i = 0; i < archetypeChunk.EntityCount; i++)
                {
                    if (factionSpan[i].Id != FactionId.Player)
                    {
                        continue;
                    }

                    var pickRadius = selectableSpan[i].PickRadius;
                    var distanceSquared = Vector2.DistanceSquared(positionSpan[i].Location, clickWorld);
                    if (distanceSquared <= pickRadius * pickRadius && distanceSquared < closestDistanceSquared)
                    {
                        closestDistanceSquared = distanceSquared;
                        pickedChunk = chunkIndex;
                        pickedIndex = i;
                    }
                }
            }

            if (!isAdditive)
            {
                ClearSelection(archetypeChunks);
            }

            if (pickedChunk < 0)
            {
                return;
            }

            if (isDoubleClick)
            {
                SelectAllOfKind(archetypeChunks, archetypeChunks[pickedChunk].GetSpan<UnitType>()[pickedIndex].Kind);
                return;
            }

            archetypeChunks[pickedChunk].GetSpan<Selectable>()[pickedIndex].IsSelected = true;
        }

        /// <summary>
        /// Selects every player unit of one kind, anywhere on the map. Age of Empires limits the
        /// equivalent to what's on screen; map-wide is the more useful half of that behaviour here,
        /// where the map is only a couple of screens across and "grab all my miners" is the point.
        /// </summary>
        private static void SelectAllOfKind(List<ArchetypeChunk> archetypeChunks, UnitKind kind)
        {
            foreach (var archetypeChunk in archetypeChunks)
            {
                var selectableSpan = archetypeChunk.GetSpan<Selectable>();
                var factionSpan = archetypeChunk.GetSpan<Faction>();
                var unitTypeSpan = archetypeChunk.GetSpan<UnitType>();

                for (var i = 0; i < archetypeChunk.EntityCount; i++)
                {
                    if (factionSpan[i].Id == FactionId.Player && unitTypeSpan[i].Kind == kind)
                    {
                        selectableSpan[i].IsSelected = true;
                    }
                }
            }
        }

        private void SelectWithinBox(List<ArchetypeChunk> archetypeChunks, Vector2 dragStart, Vector2 dragEnd, bool isAdditive)
        {
            if (!isAdditive)
            {
                ClearSelection(archetypeChunks);
            }

            var minimum = Vector2.Min(dragStart, dragEnd);
            var maximum = Vector2.Max(dragStart, dragEnd);
            var worldToScreen = camera.GetCameraTransform();

            foreach (var archetypeChunk in archetypeChunks)
            {
                var positionSpan = archetypeChunk.GetSpan<Position>();
                var selectableSpan = archetypeChunk.GetSpan<Selectable>();
                var factionSpan = archetypeChunk.GetSpan<Faction>();

                for (var i = 0; i < archetypeChunk.EntityCount; i++)
                {
                    if (factionSpan[i].Id != FactionId.Player)
                    {
                        continue;
                    }

                    var screenLocation = Vector2.Transform(positionSpan[i].Location, worldToScreen);
                    if (screenLocation.X >= minimum.X && screenLocation.X <= maximum.X &&
                        screenLocation.Y >= minimum.Y && screenLocation.Y <= maximum.Y)
                    {
                        selectableSpan[i].IsSelected = true;
                    }
                }
            }
        }

        private static void ClearSelection(List<ArchetypeChunk> archetypeChunks)
        {
            foreach (var archetypeChunk in archetypeChunks)
            {
                var selectableSpan = archetypeChunk.GetSpan<Selectable>();
                for (var i = 0; i < archetypeChunk.EntityCount; i++)
                {
                    selectableSpan[i].IsSelected = false;
                }
            }
        }
    }
}
