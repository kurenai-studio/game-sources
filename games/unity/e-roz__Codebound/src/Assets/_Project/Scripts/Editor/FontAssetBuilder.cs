using TMPro;
using UnityEditor;
using UnityEngine;
using UnityEngine.TextCore.LowLevel;

namespace Codebound.EditorTools
{
    public static class FontAssetBuilder
    {
        const string FontsFolder = "Assets/_Project/Fonts";
        public const string UiFontAssetPath = FontsFolder + "/Silkscreen_UI.asset";
        public const string CodeFontAssetPath = FontsFolder + "/JetBrainsMono_Code.asset";

        const string Characters =
            " !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~" +
            "ÑñÁÉÍÓÚáéíóú";

        [MenuItem("Codebound/Build Font Assets")]
        public static void BuildAll()
        {
            Ensure(FontsFolder + "/Silkscreen-Regular.ttf", UiFontAssetPath);
            Ensure(FontsFolder + "/JetBrainsMono-Regular.ttf", CodeFontAssetPath);
            UseCodeFontForAmpersand();
            SetTmpDefault(AssetDatabase.LoadAssetAtPath<TMP_FontAsset>(UiFontAssetPath));
            AssetDatabase.SaveAssets();
        }

        // Silkscreen draws & like "¢", which hides the && in the Chapter 2 rooms.
        // Drop its glyph and fall back to the code font, which draws it properly.
        static void UseCodeFontForAmpersand()
        {
            var ui = AssetDatabase.LoadAssetAtPath<TMP_FontAsset>(UiFontAssetPath);
            var code = AssetDatabase.LoadAssetAtPath<TMP_FontAsset>(CodeFontAssetPath);
            if (ui == null || code == null) return;

            var changed = false;
            if (!ui.fallbackFontAssetTable.Contains(code))
            {
                ui.fallbackFontAssetTable.Add(code);
                changed = true;
            }

            if (ui.characterTable.RemoveAll(c => c.unicode == '&') > 0) changed = true;

            // Dynamic mode would put the glyph straight back from the font file.
            if (ui.atlasPopulationMode != AtlasPopulationMode.Static)
            {
                ui.atlasPopulationMode = AtlasPopulationMode.Static;
                changed = true;
            }

            if (!changed) return;
            ui.ReadFontAssetDefinition();
            EditorUtility.SetDirty(ui);
        }

        public static TMP_FontAsset LoadUiFont()
        {
            BuildAll();
            return AssetDatabase.LoadAssetAtPath<TMP_FontAsset>(UiFontAssetPath);
        }

        static void Ensure(string fontPath, string assetPath)
        {
            if (AssetDatabase.LoadAssetAtPath<TMP_FontAsset>(assetPath) != null) return;

            var font = AssetDatabase.LoadAssetAtPath<Font>(fontPath);
            if (font == null)
            {
                Debug.LogError("FontAssetBuilder: font file not found at " + fontPath);
                return;
            }

            var asset = TMP_FontAsset.CreateFontAsset(font, 64, 5, GlyphRenderMode.SDFAA, 1024, 1024,
                AtlasPopulationMode.Dynamic, true);
            AssetDatabase.CreateAsset(asset, assetPath);
            AssetDatabase.AddObjectToAsset(asset.material, asset);
            foreach (var texture in asset.atlasTextures)
                AssetDatabase.AddObjectToAsset(texture, asset);

            asset.TryAddCharacters(Characters, out _);
            EditorUtility.SetDirty(asset);
            AssetDatabase.SaveAssets();
        }

        static void SetTmpDefault(TMP_FontAsset asset)
        {
            if (asset == null || TMP_Settings.instance == null) return;
            var so = new SerializedObject(TMP_Settings.instance);
            var property = so.FindProperty("m_defaultFontAsset");
            if (property == null) return;
            property.objectReferenceValue = asset;
            so.ApplyModifiedPropertiesWithoutUndo();
        }
    }
}
