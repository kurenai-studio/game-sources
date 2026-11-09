using UnityEditor;
using UnityEngine;

namespace Codebound.EditorTools
{
    public class ArtImportRules : AssetPostprocessor
    {
        public const string ArtFolder = "Assets/_Project/Art/";
        public const int PixelsPerUnit = 16;
        public const float FrameBorder = 6f;
        const string FramePrefix = "frame_";

        public static bool IsArtPath(string assetPath) =>
            assetPath.StartsWith(ArtFolder, System.StringComparison.OrdinalIgnoreCase);

        public static bool IsFrame(string assetPath) =>
            System.IO.Path.GetFileName(assetPath).StartsWith(FramePrefix, System.StringComparison.OrdinalIgnoreCase);

        public static void Apply(TextureImporter importer)
        {
            importer.textureType = TextureImporterType.Sprite;
            importer.spriteImportMode = SpriteImportMode.Single;
            importer.spritePixelsPerUnit = PixelsPerUnit;
            importer.filterMode = FilterMode.Point;
            importer.textureCompression = TextureImporterCompression.Uncompressed;
            importer.mipmapEnabled = false;
            importer.alphaIsTransparency = true;
            importer.wrapMode = TextureWrapMode.Clamp;
            importer.isReadable = false;
            importer.spriteBorder = IsFrame(importer.assetPath)
                ? new Vector4(FrameBorder, FrameBorder, FrameBorder, FrameBorder)
                : Vector4.zero;
        }

        public override uint GetVersion() => 1;

        void OnPreprocessTexture()
        {
            if (IsArtPath(assetPath)) Apply((TextureImporter)assetImporter);
        }
    }
}
