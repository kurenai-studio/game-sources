using System.Collections.Generic;
using Codebound.UI;
using TMPro;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

namespace Codebound.EditorTools
{
    public static partial class MainMenuSceneBuilder
    {
        const string ScenesFolder = "Assets/_Project/Scenes";
        const string ScenePath = ScenesFolder + "/MainMenu.unity";

        static readonly Color PanelColor = new Color(0.106f, 0.106f, 0.184f);
        static readonly Color ButtonNormal = new Color(0.72f, 0.72f, 0.72f);
        static readonly Color ButtonHighlight = Color.white;
        static readonly Color ButtonPressed = new Color(0.55f, 0.55f, 0.55f);
        static readonly Color ButtonDisabled = new Color(0.35f, 0.35f, 0.35f, 0.6f);

        const string ArtFolder = "Assets/_Project/Art";
        static Sprite _frameBrown;
        static Sprite _frameDark;
        static TMP_FontAsset _uiFont;
        static readonly Color HintColor = new Color(0.7f, 0.7f, 0.8f);
        static readonly Color NoticeColor = new Color(1f, 0.8f, 0.4f);

        [MenuItem("Codebound/Build Main Menu Scene")]
        public static void Build()
        {
            if (TMP_Settings.instance == null)
            {
                EditorUtility.DisplayDialog("TextMeshPro setup needed",
                    "Import the TMP Essentials first:\nWindow > TextMeshPro > Import TMP Essentials.\nThen run this menu item again.",
                    "OK");
                return;
            }

            _uiFont = FontAssetBuilder.LoadUiFont();
            var catalog = LoadOrCreateCatalog();
            _frameBrown = AssetDatabase.LoadAssetAtPath<Sprite>(ArtFolder + "/UI/frame_brown.png");
            _frameDark = AssetDatabase.LoadAssetAtPath<Sprite>(ArtFolder + "/UI/frame_dark.png");
            var look1 = AssetDatabase.LoadAssetAtPath<Sprite>(ArtFolder + "/Characters/warden_look1.png");
            var look2 = AssetDatabase.LoadAssetAtPath<Sprite>(ArtFolder + "/Characters/warden_look2.png");
            var clickClip = AssetDatabase.LoadAssetAtPath<AudioClip>("Assets/_Project/Audio/Sfx/ui_click.ogg");
            if (_uiFont == null || _frameBrown == null || _frameDark == null || look1 == null || look2 == null || clickClip == null)
            {
                EditorUtility.DisplayDialog("Assets missing",
                    "Art, font or audio files are missing from Assets/_Project. See Plans/ASSETS_PHASE.md.", "OK");
                return;
            }

            if (AssetDatabase.LoadAssetAtPath<SceneAsset>(ScenePath) != null &&
                !EditorUtility.DisplayDialog("Rebuild the Main Menu?",
                    "MainMenu.unity already exists and will be replaced. Any manual edits in it will be lost.",
                    "Replace", "Cancel"))
                return;

            if (!EditorSceneManager.SaveCurrentModifiedScenesIfUserWantsTo()) return;

            var scene = EditorSceneManager.NewScene(NewSceneSetup.DefaultGameObjects, NewSceneMode.Single);
            SetUpCamera();

            var canvas = CreateCanvas();
            new GameObject("EventSystem", typeof(EventSystem), typeof(StandaloneInputModule));

            var title = CreatePanel(canvas, "TitlePanel");
            var settings = CreatePanel(canvas, "SettingsPanel");
            var credits = CreatePanel(canvas, "CreditsPanel");
            var confirmNewGame = CreatePanel(canvas, "ConfirmNewGamePanel");
            var confirmQuit = CreatePanel(canvas, "ConfirmQuitPanel");
            var nameLookPanel = CreatePanel(canvas, "NameLookPanel");
            var placeholder = CreatePanel(canvas, "PlaceholderPanel");
            var keepWings = CreatePanel(canvas, "KeepWingsPanel");
            var keepRooms = CreatePanel(canvas, "KeepRoomsPanel");
            var keepMenu = CreatePanel(canvas, "KeepMenuPanel");
            var confirmTitle = CreatePanel(canvas, "ConfirmTitlePanel");

            CreateText(title.transform, "LogoText", "CODEBOUND", 120, new Vector2(0, 380), new Vector2(1400, 160));
            CreateText(title.transform, "SubtitleText", "The Programming Dungeon", 48, new Vector2(0, 270), new Vector2(900, 60));
            var column = CreateColumn(title.transform, "ButtonColumn", new Vector2(0, -60), new Vector2(500, 420), 16);
            var newGame = CreateLayoutButton(column, "NewGameButton", "New Game");
            var continueButton = CreateLayoutButton(column, "ContinueButton", "Continue");
            var settingsButton = CreateLayoutButton(column, "SettingsButton", "Settings");
            var creditsButton = CreateLayoutButton(column, "CreditsButton", "Credits");
            var quitButton = CreateLayoutButton(column, "QuitButton", "Quit");
            var noSaveHint = CreateText(title.transform, "NoSaveHint", "No saved game yet", 32,
                new Vector2(0, -320), new Vector2(700, 50), HintColor);
            var notice = CreateText(title.transform, "NoticeText", string.Empty, 30,
                new Vector2(0, -390), new Vector2(1400, 50), NoticeColor);

            CreateText(settings.transform, "SettingsTitle", "Settings", 90, new Vector2(0, 380), new Vector2(900, 120));
            var settingsColumn = CreateColumn(settings.transform, "SettingsColumn", new Vector2(0, -20), new Vector2(700, 500), 30);
            CreateLayoutLabel(settingsColumn, "MusicLabel", "Music");
            var musicSlider = CreateSlider(settingsColumn, "MusicSlider");
            CreateLayoutLabel(settingsColumn, "SfxLabel", "Effects");
            var sfxSlider = CreateSlider(settingsColumn, "SfxSlider");
            var settingsBack = CreateLayoutButton(settingsColumn, "BackButton", "Back");

            CreateText(credits.transform, "CreditsTitle", "Credits", 90, new Vector2(0, 380), new Vector2(900, 120));
            var creditsBody = CreateText(credits.transform, "CreditsBody",
                ReadCredits(), 36, new Vector2(0, -50), new Vector2(1500, 540));
            creditsBody.enableAutoSizing = true;
            creditsBody.fontSizeMin = 18;
            creditsBody.fontSizeMax = 36;
            var creditsBack = CreateButton(credits.transform, "BackButton", "Back", new Vector2(0, -400), new Vector2(400, 70));

            CreateText(confirmNewGame.transform, "Message",
                "Starting a new game replaces your saved progress. Continue?", 48, new Vector2(0, 120), new Vector2(1200, 200));
            var newGameYes = CreateButton(confirmNewGame.transform, "YesButton", "Yes, start new", new Vector2(-240, -100), new Vector2(420, 70));
            var newGameNo = CreateButton(confirmNewGame.transform, "NoButton", "No, go back", new Vector2(240, -100), new Vector2(420, 70));

            CreateText(confirmQuit.transform, "Message", "Quit Codebound?", 60, new Vector2(0, 120), new Vector2(1200, 200));
            var quitYes = CreateButton(confirmQuit.transform, "YesButton", "Yes, quit", new Vector2(-240, -100), new Vector2(420, 70));
            var quitNo = CreateButton(confirmQuit.transform, "NoButton", "No, stay", new Vector2(240, -100), new Vector2(420, 70));

            CreateText(nameLookPanel.transform, "NameLookTitle", "Who are you, Warden?", 80, new Vector2(0, 420), new Vector2(1800, 120));
            var lookButtons = new[]
            {
                CreateButton(nameLookPanel.transform, "Look1Button", "Look 1", new Vector2(-220, 170), new Vector2(300, 300)),
                CreateButton(nameLookPanel.transform, "Look2Button", "Look 2", new Vector2(220, 170), new Vector2(300, 300))
            };
            AddPortrait(lookButtons[0], look1);
            AddPortrait(lookButtons[1], look2);
            var selectedLabels = new[]
            {
                CreateText(nameLookPanel.transform, "Look1Selected", "Selected", 32, new Vector2(-220, 0), new Vector2(300, 40), NoticeColor),
                CreateText(nameLookPanel.transform, "Look2Selected", string.Empty, 32, new Vector2(220, 0), new Vector2(300, 40), NoticeColor)
            };
            var nameInput = CreateInputField(nameLookPanel.transform, "NameInput", "Apprentice", new Vector2(0, -110), new Vector2(600, 70));
            var counterText = CreateText(nameLookPanel.transform, "CounterText", "0/16", 32, new Vector2(420, -110), new Vector2(160, 50), HintColor);
            var previewText = CreateText(nameLookPanel.transform, "PreviewText", string.Empty, 34, new Vector2(0, -215), new Vector2(1600, 120), HintColor);
            var nameLookStart = CreateButton(nameLookPanel.transform, "StartButton", "Start", new Vector2(-240, -380), new Vector2(420, 70));
            var nameLookBack = CreateButton(nameLookPanel.transform, "BackButton", "Back", new Vector2(240, -380), new Vector2(420, 70));

            var nameLook = nameLookPanel.AddComponent<NameLookPanelController>();
            var nameLookSo = new SerializedObject(nameLook);
            Assign(nameLookSo, "_nameInput", nameInput);
            Assign(nameLookSo, "_counterText", counterText);
            Assign(nameLookSo, "_previewText", previewText);
            AssignArray(nameLookSo, "_lookButtons", lookButtons);
            AssignArray(nameLookSo, "_selectedLabels", selectedLabels);
            Assign(nameLookSo, "_startButton", nameLookStart);
            Assign(nameLookSo, "_backButton", nameLookBack);
            nameLookSo.ApplyModifiedPropertiesWithoutUndo();

            var keepMap = BuildKeepMap(keepWings, keepRooms, keepMenu, confirmTitle, catalog, look1, look2);

            var placeholderText = CreateText(placeholder.transform, "PlaceholderText", "Coming soon.", 48,
                new Vector2(0, 60), new Vector2(1200, 300));
            var placeholderBack = CreateButton(placeholder.transform, "BackButton", "Back", new Vector2(0, -250), new Vector2(400, 70));

            var controllerObject = new GameObject("MenuController");
            var sfxSource = controllerObject.AddComponent<AudioSource>();
            sfxSource.playOnAwake = false;
            var controller = controllerObject.AddComponent<MainMenuController>();
            var so = new SerializedObject(controller);
            Assign(so, "_titlePanel", title);
            Assign(so, "_settingsPanel", settings);
            Assign(so, "_creditsPanel", credits);
            Assign(so, "_confirmNewGamePanel", confirmNewGame);
            Assign(so, "_confirmQuitPanel", confirmQuit);
            Assign(so, "_placeholderPanel", placeholder);
            Assign(so, "_nameLookPanel", nameLookPanel);
            Assign(so, "_nameLook", nameLook);
            Assign(so, "_keepMap", keepMap);
            Assign(so, "_keepWingsPanel", keepWings);
            Assign(so, "_keepRoomsPanel", keepRooms);
            Assign(so, "_keepMenuPanel", keepMenu);
            Assign(so, "_confirmTitlePanel", confirmTitle);
            Assign(so, "_newGameButton", newGame);
            Assign(so, "_continueButton", continueButton);
            Assign(so, "_settingsButton", settingsButton);
            Assign(so, "_creditsButton", creditsButton);
            Assign(so, "_quitButton", quitButton);
            Assign(so, "_noSaveHint", noSaveHint.gameObject);
            Assign(so, "_noticeText", notice);
            Assign(so, "_musicSlider", musicSlider);
            Assign(so, "_sfxSlider", sfxSlider);
            Assign(so, "_settingsBackButton", settingsBack);
            Assign(so, "_creditsBackButton", creditsBack);
            Assign(so, "_confirmNewGameYesButton", newGameYes);
            Assign(so, "_confirmNewGameNoButton", newGameNo);
            Assign(so, "_confirmQuitYesButton", quitYes);
            Assign(so, "_confirmQuitNoButton", quitNo);
            Assign(so, "_placeholderText", placeholderText);
            Assign(so, "_placeholderBackButton", placeholderBack);
            Assign(so, "_sfxSource", sfxSource);
            Assign(so, "_clickClip", clickClip);
            so.ApplyModifiedPropertiesWithoutUndo();

            if (!AssetDatabase.IsValidFolder(ScenesFolder))
                AssetDatabase.CreateFolder("Assets/_Project", "Scenes");
            EditorSceneManager.SaveScene(scene, ScenePath);
            AddToBuildSettings();

            Selection.activeGameObject = controllerObject;
            Debug.Log("MainMenu scene built and saved to " + ScenePath);
        }

        static void SetUpCamera()
        {
            var light = GameObject.Find("Directional Light");
            if (light != null) Object.DestroyImmediate(light);

            var camera = Camera.main;
            if (camera == null) return;
            camera.clearFlags = CameraClearFlags.SolidColor;
            camera.backgroundColor = PanelColor;
            camera.orthographic = true;
        }

        static Transform CreateCanvas()
        {
            var go = new GameObject("Canvas", typeof(Canvas), typeof(CanvasScaler), typeof(GraphicRaycaster));
            go.GetComponent<Canvas>().renderMode = RenderMode.ScreenSpaceOverlay;
            var scaler = go.GetComponent<CanvasScaler>();
            scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
            scaler.referenceResolution = new Vector2(1920, 1080);
            scaler.matchWidthOrHeight = 0.5f;
            return go.transform;
        }

        static GameObject CreatePanel(Transform parent, string name)
        {
            var go = new GameObject(name, typeof(RectTransform), typeof(Image));
            go.transform.SetParent(parent, false);
            Stretch((RectTransform)go.transform);
            go.GetComponent<Image>().color = PanelColor;
            return go;
        }

        static void Stretch(RectTransform rect)
        {
            rect.anchorMin = Vector2.zero;
            rect.anchorMax = Vector2.one;
            rect.offsetMin = Vector2.zero;
            rect.offsetMax = Vector2.zero;
        }

        static TextMeshProUGUI CreateText(Transform parent, string name, string text, float size,
            Vector2 position, Vector2 dimensions, Color? color = null)
        {
            var go = new GameObject(name, typeof(RectTransform));
            go.transform.SetParent(parent, false);
            var rect = (RectTransform)go.transform;
            rect.anchorMin = rect.anchorMax = rect.pivot = new Vector2(0.5f, 0.5f);
            rect.anchoredPosition = position;
            rect.sizeDelta = dimensions;

            var label = go.AddComponent<TextMeshProUGUI>();
            label.font = _uiFont != null ? _uiFont : TMP_Settings.defaultFontAsset;
            label.text = text;
            label.fontSize = size;
            label.alignment = TextAlignmentOptions.Center;
            label.color = color ?? Color.white;
            label.raycastTarget = false;
            return label;
        }

        static RectTransform CreateColumn(Transform parent, string name, Vector2 position, Vector2 dimensions, float spacing)
        {
            var go = new GameObject(name, typeof(RectTransform), typeof(VerticalLayoutGroup));
            go.transform.SetParent(parent, false);
            var rect = (RectTransform)go.transform;
            rect.anchorMin = rect.anchorMax = rect.pivot = new Vector2(0.5f, 0.5f);
            rect.anchoredPosition = position;
            rect.sizeDelta = dimensions;

            var layout = go.GetComponent<VerticalLayoutGroup>();
            layout.spacing = spacing;
            layout.childAlignment = TextAnchor.MiddleCenter;
            layout.childControlWidth = true;
            layout.childControlHeight = true;
            layout.childForceExpandWidth = true;
            layout.childForceExpandHeight = false;
            return rect;
        }

        static Button CreateButton(Transform parent, string name, string label, Vector2 position, Vector2 dimensions)
        {
            var go = new GameObject(name, typeof(RectTransform), typeof(Image), typeof(Button));
            go.transform.SetParent(parent, false);
            var rect = (RectTransform)go.transform;
            rect.anchorMin = rect.anchorMax = rect.pivot = new Vector2(0.5f, 0.5f);
            rect.anchoredPosition = position;
            rect.sizeDelta = dimensions;

            var image = go.GetComponent<Image>();
            image.sprite = _frameBrown;
            image.type = Image.Type.Sliced;
            image.color = Color.white;

            var button = go.GetComponent<Button>();
            button.targetGraphic = image;
            var colors = button.colors;
            colors.normalColor = ButtonNormal;
            colors.highlightedColor = ButtonHighlight;
            colors.selectedColor = ButtonHighlight;
            colors.pressedColor = ButtonPressed;
            colors.disabledColor = ButtonDisabled;
            colors.colorMultiplier = 1f;
            button.colors = colors;

            var text = CreateText(go.transform, "Label", label, 40, Vector2.zero, dimensions);
            Stretch(text.rectTransform);
            return button;
        }

        static void AddPortrait(Button button, Sprite sprite)
        {
            var go = new GameObject("Portrait", typeof(RectTransform), typeof(Image));
            go.transform.SetParent(button.transform, false);
            var rect = (RectTransform)go.transform;
            rect.anchorMin = rect.anchorMax = rect.pivot = new Vector2(0.5f, 0.5f);
            rect.anchoredPosition = new Vector2(0, 20);
            rect.sizeDelta = new Vector2(200, 200);
            var image = go.GetComponent<Image>();
            image.sprite = sprite;
            image.preserveAspect = true;
            image.raycastTarget = false;

            var label = button.GetComponentInChildren<TextMeshProUGUI>();
            label.alignment = TextAlignmentOptions.Bottom;
            label.fontSize = 30;
            label.margin = new Vector4(0, 0, 0, 14);
        }

        static string ReadCredits()
        {
            var path = System.IO.Path.Combine(Application.dataPath, "..", "CREDITS.md");
            if (!System.IO.File.Exists(path)) return "Credits file (CREDITS.md) not found.";

            var lines = new List<string>();
            foreach (var raw in System.IO.File.ReadAllLines(path))
            {
                if (raw.StartsWith("# ")) continue;
                lines.Add(raw.TrimStart('#', ' '));
            }
            return string.Join("\n", lines).Trim();
        }

        static Button CreateLayoutButton(Transform parent, string name, string label)
        {
            var button = CreateButton(parent, name, label, Vector2.zero, new Vector2(500, 70));
            button.gameObject.AddComponent<LayoutElement>().preferredHeight = 70;
            return button;
        }

        static void CreateLayoutLabel(Transform parent, string name, string text)
        {
            var label = CreateText(parent, name, text, 40, Vector2.zero, new Vector2(700, 50));
            label.gameObject.AddComponent<LayoutElement>().preferredHeight = 50;
        }

        static Slider CreateSlider(Transform parent, string name)
        {
            var resources = new DefaultControls.Resources
            {
                standard = _frameBrown,
                background = _frameDark,
                knob = _frameBrown
            };
            var go = DefaultControls.CreateSlider(resources);
            go.name = name;
            go.transform.SetParent(parent, false);
            go.AddComponent<LayoutElement>().preferredHeight = 40;

            var slider = go.GetComponent<Slider>();
            slider.minValue = 0f;
            slider.maxValue = 1f;
            slider.value = 0.8f;
            return slider;
        }

        static TMP_InputField CreateInputField(Transform parent, string name, string hint, Vector2 position, Vector2 dimensions)
        {
            var go = new GameObject(name, typeof(RectTransform), typeof(Image), typeof(TMP_InputField));
            go.transform.SetParent(parent, false);
            var rect = (RectTransform)go.transform;
            rect.anchorMin = rect.anchorMax = rect.pivot = new Vector2(0.5f, 0.5f);
            rect.anchoredPosition = position;
            rect.sizeDelta = dimensions;

            var image = go.GetComponent<Image>();
            image.sprite = _frameDark;
            image.type = Image.Type.Sliced;
            image.color = new Color(0.4f, 0.4f, 0.5f);

            var viewport = new GameObject("Text Area", typeof(RectTransform), typeof(RectMask2D));
            viewport.transform.SetParent(go.transform, false);
            var viewportRect = (RectTransform)viewport.transform;
            Stretch(viewportRect);
            viewportRect.offsetMin = new Vector2(20, 8);
            viewportRect.offsetMax = new Vector2(-20, -8);

            var text = CreateText(viewport.transform, "Text", string.Empty, 40, Vector2.zero, dimensions);
            Stretch(text.rectTransform);
            text.alignment = TextAlignmentOptions.MidlineLeft;
            text.enableWordWrapping = false;

            var placeholder = CreateText(viewport.transform, "Placeholder", hint, 40, Vector2.zero, dimensions,
                new Color(1f, 1f, 1f, 0.4f));
            Stretch(placeholder.rectTransform);
            placeholder.alignment = TextAlignmentOptions.MidlineLeft;
            placeholder.fontStyle = FontStyles.Italic;
            placeholder.enableWordWrapping = false;

            var input = go.GetComponent<TMP_InputField>();
            input.targetGraphic = image;
            input.textViewport = viewportRect;
            input.textComponent = text;
            input.placeholder = placeholder;
            input.lineType = TMP_InputField.LineType.SingleLine;
            return input;
        }

        static void AssignArray<T>(SerializedObject so, string field, T[] values) where T : Object
        {
            var property = so.FindProperty(field);
            if (property == null)
            {
                Debug.LogError("MainMenuSceneBuilder: field '" + field + "' not found on " + so.targetObject.GetType().Name + ".");
                return;
            }
            property.arraySize = values.Length;
            for (var i = 0; i < values.Length; i++)
                property.GetArrayElementAtIndex(i).objectReferenceValue = values[i];
        }

        static void Assign(SerializedObject so, string field, Object value)
        {
            var property = so.FindProperty(field);
            if (property == null)
            {
                Debug.LogError("MainMenuSceneBuilder: field '" + field + "' not found on MainMenuController.");
                return;
            }
            property.objectReferenceValue = value;
        }

        static void AddToBuildSettings()
        {
            var scenes = new List<EditorBuildSettingsScene> { new EditorBuildSettingsScene(ScenePath, true) };
            foreach (var existing in EditorBuildSettings.scenes)
                if (existing.path != ScenePath) scenes.Add(existing);
            EditorBuildSettings.scenes = scenes.ToArray();
        }
    }
}
