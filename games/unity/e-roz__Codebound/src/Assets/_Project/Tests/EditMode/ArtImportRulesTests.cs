using Codebound.EditorTools;
using NUnit.Framework;
using UnityEditor;
using UnityEngine;

namespace Codebound.Tests
{
    public class ArtImportRulesTests
    {
        [TestCase("Assets/_Project/Art/Characters/a.png", true)]
        [TestCase("Assets/_Project/Art/UI/frame_x.png", true)]
        [TestCase("Assets/_Project/Fonts/a.ttf", false)]
        [TestCase("Assets/Other/Art/a.png", false)]
        public void IsArtPath_OnlyMatchesArtFolder(string path, bool expected)
        {
            Assert.AreEqual(expected, ArtImportRules.IsArtPath(path));
        }

        [TestCase("Assets/_Project/Art/UI/frame_brown.png", true)]
        [TestCase("Assets/_Project/Art/UI/button.png", false)]
        public void IsFrame_MatchesFramePrefix(string path, bool expected)
        {
            Assert.AreEqual(expected, ArtImportRules.IsFrame(path));
        }

        [Test]
        public void EveryArtTexture_IsCrispSixteenPpuSprite()
        {
            var guids = AssetDatabase.FindAssets("t:Texture2D", new[] { "Assets/_Project/Art" });
            Assert.IsNotEmpty(guids, "No art found to check.");

            foreach (var guid in guids)
            {
                var path = AssetDatabase.GUIDToAssetPath(guid);
                var importer = (TextureImporter)AssetImporter.GetAtPath(path);
                Assert.AreEqual(TextureImporterType.Sprite, importer.textureType, path);
                Assert.AreEqual(FilterMode.Point, importer.filterMode, path);
                Assert.AreEqual(TextureImporterCompression.Uncompressed, importer.textureCompression, path);
                Assert.AreEqual(ArtImportRules.PixelsPerUnit, importer.spritePixelsPerUnit, path);
                Assert.IsFalse(importer.mipmapEnabled, path);
            }
        }

        [Test]
        public void FrameSprites_HaveNineSliceBorders()
        {
            var importer = (TextureImporter)AssetImporter.GetAtPath("Assets/_Project/Art/UI/frame_brown.png");
            Assert.AreEqual(new Vector4(6, 6, 6, 6), importer.spriteBorder);
        }
    }
}
