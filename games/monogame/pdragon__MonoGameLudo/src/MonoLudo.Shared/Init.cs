using System;
using System.Collections.Generic;
using System.Text;
using System.Xml;
using LudoGame.Helpers;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using MonoLudo.Core;
using MonoLudo.Shared.Scenes.Game;
using MonoLudo.Shared.Helpers;

namespace MonoLudo.Shared
{
    public class Init
    {
        public Texture2D LoadTokenTexture(GraphicsDevice graphicsDevice, Color color)
        {
            //return CreateCircleTexture(graphicsDevice, int radius, color);
            return Render.CreateCircleTexture(graphicsDevice, 16, color);
        }

        public void LoadSettings()
        {
            XmlDocument xDoc = new XmlDocument();
            xDoc.Load("./"+Main.AssetDirectory+"/settings.xml");
            // получим корневой элемент
            XmlElement xRoot = xDoc.DocumentElement;
            if (xRoot != null)
            {
                // обход всех узлов в корневом элементе
                foreach (XmlElement itemNode in xRoot)
                {
                    //HomeTiles
                    // получаем атрибут name
                    XmlNode attr = itemNode.Attributes.GetNamedItem("type");
                    if (attr != null)
                    {
                        //switch (attr.Value?.ToString())
                        //{
                        //    case "Common":
                                Board.Tiles = LoadTiles(itemNode);
                        //        break;
                        //}
                    }

                }
            }
        }

        private Dictionary<short, Tile> LoadTiles(XmlElement itemNode, Config.ColorIndex playerId = Config.ColorIndex.Neutral)
        {
            var tiles = new Dictionary<short, Tile>();
            foreach (XmlNode childnode in itemNode.ChildNodes)
            {
                switch (childnode.Name)
                {
                    case "tile":
                        Tile tile = new();

                        if (childnode.Attributes == null)
                        {
                            throw new Exception("attr was not exists in settings.xml");
                        }
                        XmlNode id = childnode.Attributes.GetNamedItem("Id") ?? throw new Exception("tile.Id not found in settings.xml");
                        XmlNode properties = childnode.Attributes.GetNamedItem("Properties") ?? throw new Exception("tile.Properties not found in settings.xml");
                        XmlNode position = childnode.Attributes.GetNamedItem("Position") ?? throw new Exception("tile.Position not found in settings.xml");
                        XmlNode color = childnode.Attributes.GetNamedItem("Color");
                        tile.Id = id != null ? Utils.ConvertStringToShort(id.InnerText.ToString()) : (short)0;
                        tile.PropertiesBitSet = int.Parse(properties.InnerText.ToString());
                        //tile.Color = playerId;
                        var pos = position.InnerText.ToString().GetVector2();
                        if (pos == null)
                        {
                            throw new Exception("position of tile in setting.xml is empty or wrong format");
                        }
                        tile.Position = pos ?? new Vector2();
                        tile.Color = String.IsNullOrEmpty(color?.InnerText.ToString()) ? Config.ColorIndex.Neutral : (Config.ColorIndex)short.Parse(color.InnerText.ToString());
                        tiles.Add(tile.Id, tile);
                        break;
                }
            }
            return tiles;
        }
    }
}
