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
    // Builds the Room scene with the same helpers as the menu (fonts, frames, buttons).
    public static partial class MainMenuSceneBuilder
    {
        const string RoomScenePath = ScenesFolder + "/Room.unity";
        const string TilesFolder = ArtFolder + "/Tiles/Dungeon";
        const int CodeRows = 8;

        static readonly Color ThreadColor = new Color(0.95f, 0.8f, 0.45f);

        [MenuItem("Codebound/Build Room Scene")]
        public static void BuildRoom()
        {
            _uiFont = FontAssetBuilder.LoadUiFont();
            _frameBrown = AssetDatabase.LoadAssetAtPath<Sprite>(ArtFolder + "/UI/frame_brown.png");
            _frameDark = AssetDatabase.LoadAssetAtPath<Sprite>(ArtFolder + "/UI/frame_dark.png");
            var guard1 = AssetDatabase.LoadAssetAtPath<Sprite>(TilesFolder + "/tile_0096.png");
            var guard2 = AssetDatabase.LoadAssetAtPath<Sprite>(TilesFolder + "/tile_0097.png");
            var chest = AssetDatabase.LoadAssetAtPath<Sprite>(TilesFolder + "/tile_0089.png");
            var sword = AssetDatabase.LoadAssetAtPath<Sprite>(TilesFolder + "/tile_0104.png");
            var clickClip = AssetDatabase.LoadAssetAtPath<AudioClip>("Assets/_Project/Audio/Sfx/ui_click.ogg");
            if (_uiFont == null || AssetDatabase.LoadAssetAtPath<TMP_FontAsset>(FontAssetBuilder.CodeFontAssetPath) == null || _frameBrown == null || _frameDark == null || guard1 == null ||
                guard2 == null || chest == null || sword == null || clickClip == null)
            {
                EditorUtility.DisplayDialog("Assets missing",
                    "Art, font or audio files are missing from Assets/_Project. See Plans/ASSETS_PHASE.md.", "OK");
                return;
            }

            if (AssetDatabase.LoadAssetAtPath<SceneAsset>(RoomScenePath) != null &&
                !EditorUtility.DisplayDialog("Rebuild the Room scene?",
                    "Room.unity already exists and will be replaced. Any manual edits in it will be lost.",
                    "Replace", "Cancel"))
                return;

            if (!EditorSceneManager.SaveCurrentModifiedScenesIfUserWantsTo()) return;

            var scene = EditorSceneManager.NewScene(NewSceneSetup.DefaultGameObjects, NewSceneMode.Single);
            // Load after NewScene: the new scene unloads assets that were loaded before it.
            var codeFont = AssetDatabase.LoadAssetAtPath<TMP_FontAsset>(FontAssetBuilder.CodeFontAssetPath);
            SetUpCamera();
            var canvas = CreateCanvas();
            new GameObject("EventSystem", typeof(EventSystem), typeof(StandaloneInputModule));

            var background = CreatePanel(canvas, "Background");
            background.GetComponent<Image>().raycastTarget = false;

            var backButton = CreateButton(canvas, "BackButton", "Back to Keep", new Vector2(-730, 475), new Vector2(440, 70));
            var ticket = CreateText(canvas, "TicketText", "Ticket", 32, new Vector2(270, 475), new Vector2(1300, 80));
            ticket.alignment = TextAlignmentOptions.MidlineLeft;

            // Keep view (left side)
            CreateFrame(canvas, "KeepFrame", new Vector2(-430, 50), new Vector2(1000, 740));
            var threads = new Image[2];
            for (var i = 0; i < 2; i++) threads[i] = CreateThread(canvas, $"Thread{i + 1}");

            var guardPositions = new[] { new Vector2(-640, 200), new Vector2(-220, 200) };
            var chestPositions = new[] { new Vector2(-640, -20), new Vector2(-220, -20) };
            var guardRoots = new RectTransform[2];
            var guardLabels = new TextMeshProUGUI[2];
            for (var i = 0; i < 2; i++)
            {
                guardRoots[i] = CreateIcon(canvas, $"Guard{i + 1}", i == 0 ? guard1 : guard2, guardPositions[i], 180);
                guardLabels[i] = CreateText(guardRoots[i], "Label", "vaultA", 32, new Vector2(0, 125), new Vector2(380, 50));
            }

            var chestRoots = new RectTransform[2];
            var chestImages = new Image[2];
            var chestLabels = new TextMeshProUGUI[2];
            var chestSwords = new GameObject[2];
            for (var j = 0; j < 2; j++)
            {
                chestRoots[j] = CreateIcon(canvas, $"Chest{j + 1}", chest, chestPositions[j], 200);
                chestImages[j] = chestRoots[j].GetComponent<Image>();
                chestLabels[j] = CreateText(chestRoots[j], "Label", "Chest #1", 30, new Vector2(0, -125), new Vector2(380, 50));
                chestSwords[j] = CreateIcon(chestRoots[j], "Sword", sword, new Vector2(70, 70), 90).gameObject;
            }

            // Gate rows (Chapter 2): bool variables and evaluation steps as text.
            var gateRows = new TextMeshProUGUI[6];
            for (var g = 0; g < gateRows.Length; g++)
            {
                gateRows[g] = CreateText(canvas, $"GateRow{g + 1}", string.Empty, 36, new Vector2(-430, 340 - 62 * g), new Vector2(900, 54));
                // The pixel UI font draws && badly, so rules are shown in the code font.
                UseFont(gateRows[g], codeFont);
            }

            // Log Reader / Test Runner (Chapter 3): a header and two lines under the rows.
            var logRows = new TextMeshProUGUI[3];
            for (var l = 0; l < logRows.Length; l++)
            {
                logRows[l] = CreateText(canvas, $"LogRow{l + 1}", string.Empty, 30, new Vector2(-430, -20 - 55 * l), new Vector2(900, 50));
                UseFont(logRows[l], codeFont);
            }

            var caption = CreateText(canvas, "CaptionText", string.Empty, 30, new Vector2(-430, -215), new Vector2(940, 70), HintColor);
            var output = CreateText(canvas, "OutputText", string.Empty, 34, new Vector2(-430, -275), new Vector2(940, 50));

            var keepViewObject = new GameObject("KeepView");
            var keepView = keepViewObject.AddComponent<KeepView>();
            var keepSo = new SerializedObject(keepView);
            AssignArray(keepSo, "_guardRoots", guardRoots);
            AssignArray(keepSo, "_guardLabels", guardLabels);
            AssignArray(keepSo, "_threads", threads);
            AssignArray(keepSo, "_chestRoots", chestRoots);
            AssignArray(keepSo, "_chestImages", chestImages);
            AssignArray(keepSo, "_chestLabels", chestLabels);
            AssignArray(keepSo, "_chestSwords", chestSwords);
            AssignArray(keepSo, "_gateRows", gateRows);
            AssignArray(keepSo, "_logRows", logRows);
            Assign(keepSo, "_captionText", caption);
            Assign(keepSo, "_outputText", output);
            keepSo.ApplyModifiedPropertiesWithoutUndo();

            // Code panel (right side)
            CreateFrame(canvas, "CodeFrame", new Vector2(540, 255), new Vector2(780, 330));
            var rowObjects = new GameObject[CodeRows];
            var rowTexts = new TMP_Text[CodeRows];
            var rowHighlights = new Image[CodeRows];
            for (var r = 0; r < CodeRows; r++)
            {
                var row = new GameObject($"CodeRow{r + 1}", typeof(RectTransform), typeof(Image));
                row.transform.SetParent(canvas, false);
                var rect = (RectTransform)row.transform;
                rect.anchorMin = rect.anchorMax = rect.pivot = new Vector2(0.5f, 0.5f);
                rect.anchoredPosition = new Vector2(540, 375 - r * 62);
                rect.sizeDelta = new Vector2(740, 54);
                rowHighlights[r] = row.GetComponent<Image>();
                rowHighlights[r].color = new Color(1, 1, 1, 0);
                rowHighlights[r].raycastTarget = false;

                var text = CreateText(row.transform, "Text", string.Empty, 32, Vector2.zero, rect.sizeDelta);
                Stretch(text.rectTransform);
                UseFont(text, codeFont);
                text.alignment = TextAlignmentOptions.MidlineLeft;
                text.margin = new Vector4(14, 0, 0, 0);
                text.enableWordWrapping = false;
                rowObjects[r] = row;
                rowTexts[r] = text;
            }

            var codePanelObject = new GameObject("CodePanel");
            var codePanel = codePanelObject.AddComponent<CodePanelView>();
            var codeSo = new SerializedObject(codePanel);
            AssignArray(codeSo, "_rows", rowObjects);
            AssignArray(codeSo, "_texts", rowTexts);
            AssignArray(codeSo, "_highlights", rowHighlights);
            codeSo.ApplyModifiedPropertiesWithoutUndo();

            var chestClassButton = CreateButton(canvas, "ChestClassButton", "Chest class", new Vector2(540, 55), new Vector2(420, 60));
            chestClassButton.GetComponentInChildren<TextMeshProUGUI>().fontSize = 32;
            var chestClassBox = CreateFrame(canvas, "ChestClassBox", new Vector2(540, 255), new Vector2(780, 330));
            chestClassBox.GetComponent<Image>().color = new Color(0.3f, 0.3f, 0.42f);
            var chestClassText = CreateText(chestClassBox, "Text", string.Empty, 22, Vector2.zero, new Vector2(740, 300));
            UseFont(chestClassText, codeFont);
            chestClassText.alignment = TextAlignmentOptions.MidlineLeft;
            chestClassText.enableWordWrapping = false;

            // Flow panel (right side, under the code)
            CreateFrame(canvas, "FlowFrame", new Vector2(540, -190), new Vector2(780, 420));
            var prompt = CreateText(canvas, "PromptText", string.Empty, 26, new Vector2(540, -18), new Vector2(740, 76), NoticeColor);
            var body = CreateText(canvas, "BodyText", string.Empty, 26, new Vector2(540, -150), new Vector2(740, 170));
            body.alignment = TextAlignmentOptions.Top;
            var verdict = CreateText(canvas, "VerdictText", string.Empty, 32, new Vector2(540, -312), new Vector2(740, 44));
            var notice = CreateText(canvas, "NoticeText", string.Empty, 20, new Vector2(540, -362), new Vector2(740, 70), HintColor);
            var optionButtons = new Button[4];
            var optionLabels = new TMP_Text[4];
            for (var i = 0; i < 4; i++)
            {
                optionButtons[i] = CreateButton(canvas, $"Option{i + 1}Button", string.Empty, new Vector2(540, -90 - i * 76), new Vector2(740, 68));
                optionLabels[i] = optionButtons[i].GetComponentInChildren<TextMeshProUGUI>();
                optionLabels[i].fontSize = 22;
                optionLabels[i].margin = new Vector4(16, 4, 16, 4);
            }
            var hintButton = CreateButton(canvas, "HintButton", "Hint", new Vector2(390, -455), new Vector2(330, 70));
            var nextButton = CreateButton(canvas, "NextButton", "Next", new Vector2(750, -455), new Vector2(380, 70));
            var hintLabel = hintButton.GetComponentInChildren<TextMeshProUGUI>();
            var nextLabel = nextButton.GetComponentInChildren<TextMeshProUGUI>();
            hintLabel.fontSize = 30;
            nextLabel.fontSize = 30;

            var flowObject = new GameObject("RoomFlowView");
            var flowView = flowObject.AddComponent<RoomFlowPresenter>();
            var flowSo = new SerializedObject(flowView);
            Assign(flowSo, "_promptText", prompt);
            Assign(flowSo, "_bodyText", body);
            Assign(flowSo, "_noticeText", notice);
            Assign(flowSo, "_verdictText", verdict);
            AssignArray(flowSo, "_optionButtons", optionButtons);
            AssignArray(flowSo, "_optionLabels", optionLabels);
            Assign(flowSo, "_nextButton", nextButton);
            Assign(flowSo, "_nextLabel", nextLabel);
            Assign(flowSo, "_hintButton", hintButton);
            Assign(flowSo, "_hintLabel", hintLabel);
            flowSo.ApplyModifiedPropertiesWithoutUndo();

            // Controls
            var run = CreateButton(canvas, "RunButton", "Run", new Vector2(-760, -420), new Vector2(300, 80));
            var step = CreateButton(canvas, "StepButton", "Step", new Vector2(-430, -420), new Vector2(300, 80));
            var reset = CreateButton(canvas, "ResetButton", "Reset", new Vector2(-100, -420), new Vector2(300, 80));

            var sfx = new GameObject("SfxSource", typeof(AudioSource));
            sfx.GetComponent<AudioSource>().playOnAwake = false;

            var controllerObject = new GameObject("RoomScene");
            var controller = controllerObject.AddComponent<RoomSceneController>();
            var so = new SerializedObject(controller);
            Assign(so, "_ticketText", ticket);
            Assign(so, "_codePanel", codePanel);
            Assign(so, "_keepView", keepView);
            Assign(so, "_flowView", flowView);
            Assign(so, "_runButton", run);
            Assign(so, "_stepButton", step);
            Assign(so, "_resetButton", reset);
            Assign(so, "_backButton", backButton);
            Assign(so, "_chestClassButton", chestClassButton);
            Assign(so, "_chestClassBox", chestClassBox.gameObject);
            Assign(so, "_chestClassText", chestClassText);
            Assign(so, "_sfxSource", sfx.GetComponent<AudioSource>());
            Assign(so, "_clickClip", clickClip);
            so.ApplyModifiedPropertiesWithoutUndo();

            if (!AssetDatabase.IsValidFolder(ScenesFolder)) AssetDatabase.CreateFolder("Assets/_Project", "Scenes");
            EditorSceneManager.SaveScene(scene, RoomScenePath);
            AddRoomToBuildSettings();

            Selection.activeGameObject = controllerObject;
            Debug.Log("Room scene built and saved to " + RoomScenePath);
        }

        static void UseFont(TMP_Text text, TMP_FontAsset font)
        {
            text.font = font;
            text.fontSharedMaterial = font.material;
            if (text.font != font) Debug.LogWarning($"Could not set font {font.name} on {text.name}; it shows {text.font.name}.");
        }

        static RectTransform CreateFrame(Transform parent, string name, Vector2 position, Vector2 dimensions)
        {
            var go = new GameObject(name, typeof(RectTransform), typeof(Image));
            go.transform.SetParent(parent, false);
            var rect = (RectTransform)go.transform;
            rect.anchorMin = rect.anchorMax = rect.pivot = new Vector2(0.5f, 0.5f);
            rect.anchoredPosition = position;
            rect.sizeDelta = dimensions;
            var image = go.GetComponent<Image>();
            image.sprite = _frameDark;
            image.type = Image.Type.Sliced;
            image.color = new Color(0.45f, 0.45f, 0.55f);
            image.raycastTarget = false;
            return rect;
        }

        static RectTransform CreateIcon(Transform parent, string name, Sprite sprite, Vector2 position, float size)
        {
            var go = new GameObject(name, typeof(RectTransform), typeof(Image));
            go.transform.SetParent(parent, false);
            var rect = (RectTransform)go.transform;
            rect.anchorMin = rect.anchorMax = rect.pivot = new Vector2(0.5f, 0.5f);
            rect.anchoredPosition = position;
            rect.sizeDelta = new Vector2(size, size);
            var image = go.GetComponent<Image>();
            image.sprite = sprite;
            image.preserveAspect = true;
            image.raycastTarget = false;
            return rect;
        }

        static Image CreateThread(Transform parent, string name)
        {
            var go = new GameObject(name, typeof(RectTransform), typeof(Image));
            go.transform.SetParent(parent, false);
            var rect = (RectTransform)go.transform;
            rect.anchorMin = rect.anchorMax = rect.pivot = new Vector2(0.5f, 0.5f);
            rect.sizeDelta = new Vector2(100, 10);
            var image = go.GetComponent<Image>();
            image.color = ThreadColor;
            image.raycastTarget = false;
            go.SetActive(false);
            return image;
        }

        static void AddRoomToBuildSettings()
        {
            var scenes = new List<EditorBuildSettingsScene>(EditorBuildSettings.scenes);
            if (!scenes.Exists(s => s.path == RoomScenePath)) scenes.Add(new EditorBuildSettingsScene(RoomScenePath, true));
            EditorBuildSettings.scenes = scenes.ToArray();
        }
    }
}
