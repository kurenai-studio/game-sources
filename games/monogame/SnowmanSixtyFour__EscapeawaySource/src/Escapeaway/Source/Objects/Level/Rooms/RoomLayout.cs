using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Escapeaway.Source.Graphics;
using System.Diagnostics;

namespace Escapeaway.Source.Objects.Level.Rooms
{
    internal class RoomLayout
    {
        private List<RoomGround> currentRoomLayout = new List<RoomGround>();
        public Color screenColor = CustomColor.Red;

        // Very unoptimized, I rushed it for the game jam
        private List<StaticSprite>
            firstRoom = new List<StaticSprite>(),
            room1 = new List<StaticSprite>(),
            room2 = new List<StaticSprite>(),
            room3 = new List<StaticSprite>(),
            room4 = new List<StaticSprite>(),
            room5 = new List<StaticSprite>(),
            room6 = new List<StaticSprite>(),
            room7 = new List<StaticSprite>(),
            room8 = new List<StaticSprite>(),
            room9 = new List<StaticSprite>(),
            room10 = new List<StaticSprite>(),
            room11 = new List<StaticSprite>(),
            room12 = new List<StaticSprite>(),
            lastRoom = new List<StaticSprite>();

        public RoomGround ground;

        public int selectedRoomLayout = 0;

        private Random random = new Random();

        public RoomLayout()
        {
            // Set Rooms
            firstRoom.Add(new StaticSprite(Global.ground, new Rectangle(0, 160, Global.resWidth, 120), screenColor, true));

            room1.Add(new StaticSprite(Global.ground, new Rectangle(0, 160, Global.resWidth / 4 - 10, 120), screenColor, true));
            room1.Add(new StaticSprite(Global.ground, new Rectangle(Global.resWidth / 2 - 20, 160, 40, 120), screenColor, true));
            room1.Add(new StaticSprite(Global.ground, new Rectangle(Global.resWidth / 2 + 80, 160, 72, 120), screenColor, true));
            room1.Add(new StaticSprite(Global.ground, new Rectangle(Global.resWidth - 20, 32, 20, 106), screenColor, true));
            
            room2.Add(new StaticSprite(Global.ground, new Rectangle(0, 160, 40, 120), screenColor, true));
            room2.Add(new StaticSprite(Global.ground, new Rectangle(Global.resWidth - 14, 160, 20, 120), screenColor, true));
            room2.Add(new StaticSprite(Global.ground, new Rectangle(Global.resWidth / 2 - 40, 140, 35, 20), screenColor, true));
            room2.Add(new StaticSprite(Global.ground, new Rectangle(Global.resWidth / 2 + 50, 140, 35, 20), screenColor, true));

            room3.Add(new StaticSprite(Global.ground, new Rectangle(0, 160, Global.resWidth - 86, 120), screenColor, true));
            room3.Add(new StaticSprite(Global.ground, new Rectangle(Global.resWidth - 20, 160, 20, 120), screenColor, true));
            room3.Add(new StaticSprite(Global.ground, new Rectangle(Global.resWidth / 4 - 10, 32, 20, 100), screenColor, true));

            room4.Add(new StaticSprite(Global.ground, new Rectangle(0, 160, 40, 120), screenColor, true));
            room4.Add(new StaticSprite(Global.ground, new Rectangle(Global.resWidth - 20, 160, 20, 120), screenColor, true));
            room4.Add(new StaticSprite(Global.ground, new Rectangle(Global.resWidth / 2 - 40, 140, 30, 120), screenColor, true));
            room4.Add(new StaticSprite(Global.ground, new Rectangle(Global.resWidth / 2 + 40, 120, 30, 120), screenColor, true));

            room5.Add(new StaticSprite(Global.ground, new Rectangle(0, 160, Global.resWidth / 2 - 30, 120), screenColor, true));
            room5.Add(new StaticSprite(Global.ground, new Rectangle(Global.resWidth / 2 + 30, 160, 110, 120), screenColor, true));

            room6.Add(new StaticSprite(Global.ground, new Rectangle(0, 160, Global.resWidth / 2, 120), screenColor, true));
            room6.Add(new StaticSprite(Global.ground, new Rectangle(88, 131, 40, 140), screenColor, true));
            room6.Add(new StaticSprite(Global.ground, new Rectangle(Global.resWidth / 2 + 60, 160, 80, 120), screenColor, true));
            room6.Add(new StaticSprite(Global.ground, new Rectangle(Global.resWidth / 2 + 60, 131, 40, 150), screenColor, true));
            room6.Add(new StaticSprite(Global.ground, new Rectangle(Global.resWidth - 48, 28, 20, 78), screenColor, true));

            room7.Add(new StaticSprite(Global.ground, new Rectangle(0, 160, Global.resWidth / 4, 120), screenColor, true));
            room7.Add(new StaticSprite(Global.ground, new Rectangle(120, 160, 40, 120), screenColor, true));
            room7.Add(new StaticSprite(Global.ground, new Rectangle(Global.resWidth - 40, 160, 40, 120), screenColor, true));

            room8.Add(new StaticSprite(Global.ground, new Rectangle(0, 160, Global.resWidth / 2, 120), screenColor, true));
            room8.Add(new StaticSprite(Global.ground, new Rectangle(Global.resWidth / 2 + 60, 160, 80, 120), screenColor, true));
            room8.Add(new StaticSprite(Global.ground, new Rectangle(Global.resWidth - 42, 32, 20, 98), screenColor, true));

            room9.Add(new StaticSprite(Global.ground, new Rectangle(0, 160, 46, 120), screenColor, true));
            room9.Add(new StaticSprite(Global.ground, new Rectangle(Global.resWidth - 40, 160, 40, 120), screenColor, true));
            room9.Add(new StaticSprite(Global.ground, new Rectangle(90, 130, Global.resWidth - 160, 20), screenColor, true));
            room9.Add(new StaticSprite(Global.ground, new Rectangle(Global.resWidth - 90, 25, 20, 80), screenColor, true));

            room10.Add(new StaticSprite(Global.ground, new Rectangle(0, 160, Global.resWidth, 120), screenColor, true));
            room10.Add(new StaticSprite(Global.ground, new Rectangle(50, 32, 20, 98), screenColor, true));
            room10.Add(new StaticSprite(Global.ground, new Rectangle(Global.resWidth - 50, 32, 20, 98), screenColor, true));
            room10.Add(new StaticSprite(Global.ground, new Rectangle(110, 140, 50, 20), screenColor, true));

            room11.Add(new StaticSprite(Global.ground, new Rectangle(0, 160, Global.resWidth, 120), screenColor, true));
            room11.Add(new StaticSprite(Global.ground, new Rectangle(50, 32, 20, 98), screenColor, true));
            room11.Add(new StaticSprite(Global.ground, new Rectangle(Global.resWidth - 50, 32, 20, 98), screenColor, true));

            room12.Add(new StaticSprite(Global.ground, new Rectangle(0, 160, Global.resWidth - 80, 120), screenColor, true));
            room12.Add(new StaticSprite(Global.ground, new Rectangle(Global.resWidth - 20, 160, 20, 120), screenColor, true));
            room12.Add(new StaticSprite(Global.ground, new Rectangle(40, 25, 20, 110), screenColor, true));
            room12.Add(new StaticSprite(Global.ground, new Rectangle(Global.resWidth - 130, 115, 50, 20), screenColor, true));

            lastRoom.Add(new StaticSprite(Global.ground, new Rectangle(0, 160, Global.resWidth, 120), screenColor, true));

            // Add Rooms to List
            currentRoomLayout.Add(new RoomGround(firstRoom));
            currentRoomLayout.Add(new RoomGround(room1));
            currentRoomLayout.Add(new RoomGround(room2));
            currentRoomLayout.Add(new RoomGround(room3));
            currentRoomLayout.Add(new RoomGround(room4));
            currentRoomLayout.Add(new RoomGround(room5));
            currentRoomLayout.Add(new RoomGround(room6));
            currentRoomLayout.Add(new RoomGround(room7));
            currentRoomLayout.Add(new RoomGround(room8));
            currentRoomLayout.Add(new RoomGround(room9));
            currentRoomLayout.Add(new RoomGround(room10));
            currentRoomLayout.Add(new RoomGround(room11));
            currentRoomLayout.Add(new RoomGround(room12));
            currentRoomLayout.Add(new RoomGround(lastRoom));

            SetRoom();
        }

        /// <summary>
        /// Set the layout of the room to a random layout.
        /// </summary>
        public void RandomizeRoom()
        {
            // Randomize next room
            int nextRoomLayout = random.Next(1, (currentRoomLayout.Count - 1));
            
            // Randomize again if next room is the same
            if (nextRoomLayout == selectedRoomLayout) RandomizeRoom();
            else selectedRoomLayout = nextRoomLayout;
        }

        private void UpdateColor(Color color)
        {
            // I know it's bad, I KNOW, this was temporary code for the game jam. PLEASE don't smite me

            foreach (var room in firstRoom) room.SetColor(color);
            foreach (var room in room1) room.SetColor(color);
            foreach (var room in room2) room.SetColor(color);
            foreach (var room in room3) room.SetColor(color);
            foreach (var room in room4) room.SetColor(color);
            foreach (var room in room5) room.SetColor(color);
            foreach (var room in room6) room.SetColor(color);
            foreach (var room in room7) room.SetColor(color);
            foreach (var room in room8) room.SetColor(color);
            foreach (var room in room9) room.SetColor(color);
            foreach (var room in room10) room.SetColor(color);
            foreach (var room in room11) room.SetColor(color);
            foreach (var room in room12) room.SetColor(color);
            foreach (var room in lastRoom) room.SetColor(color);
        }

        public void GoToFirstRoom()
        {
            // Set Current Room to First Room
            selectedRoomLayout = 0;
            SetRoom();
        }

        public void GoToLastRoom()
        {
            // Set Current Room to Last Room
            selectedRoomLayout = (currentRoomLayout.Count - 1);
            SetRoom();
        }

        private void SetRoom()
        {
            ground = currentRoomLayout[selectedRoomLayout];
        }

        public void Update(GameTime gameTime, Color screenColor, Player player)
        {
            UpdateColor(screenColor);
            SetRoom();

            // If in Final Boss Room
            if (selectedRoomLayout == (currentRoomLayout.Count - 1))
            {
                if (player.centered && player.moving)
                {
                    // Move Ground Texture to Simulate Room Movement
                    foreach (var sprite in lastRoom) sprite.xOffset += 120f * (float)gameTime.ElapsedGameTime.TotalSeconds;
                }
                else
                {
                    foreach (var sprite in lastRoom) sprite.xOffset = 0f;
                }
            }
        }

        public void Draw(SpriteBatch spriteBatch)
        {
            ground.Draw(spriteBatch);
        }
    }
}
