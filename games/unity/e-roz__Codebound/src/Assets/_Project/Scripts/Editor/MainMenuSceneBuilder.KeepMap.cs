using Codebound.App;
using Codebound.Core;
using Codebound.UI;
using TMPro;
using UnityEditor;
using UnityEngine;
using UnityEngine.UI;

namespace Codebound.EditorTools
{
    public static partial class MainMenuSceneBuilder
    {
        const string DataFolder = "Assets/_Project/Data";
        const string CatalogPath = DataFolder + "/KeepCatalog.asset";
        const int DoorCount = 6;
        static readonly Color StatusColor = new Color(0.95f, 0.9f, 0.75f);

        static KeepCatalogAsset LoadOrCreateCatalog()
        {
            var catalog = AssetDatabase.LoadAssetAtPath<KeepCatalogAsset>(CatalogPath);
            if (catalog != null) return catalog;

            if (!AssetDatabase.IsValidFolder(DataFolder)) AssetDatabase.CreateFolder("Assets/_Project", "Data");
            catalog = ScriptableObject.CreateInstance<KeepCatalogAsset>();
            catalog.chapters = KeepCatalogSeed.Create();
            AssetDatabase.CreateAsset(catalog, CatalogPath);
            AssetDatabase.SaveAssets();
            return catalog;
        }

        static KeepMapController BuildKeepMap(GameObject wings, GameObject rooms, GameObject menu, GameObject confirm,
            KeepCatalogAsset catalog, Sprite look1, Sprite look2)
        {
            var portrait = new GameObject("Portrait", typeof(RectTransform), typeof(Image));
            portrait.transform.SetParent(wings.transform, false);
            var portraitRect = (RectTransform)portrait.transform;
            portraitRect.anchorMin = portraitRect.anchorMax = portraitRect.pivot = new Vector2(0.5f, 0.5f);
            portraitRect.anchoredPosition = new Vector2(-860, 470);
            portraitRect.sizeDelta = new Vector2(90, 90);
            var portraitImage = portrait.GetComponent<Image>();
            portraitImage.sprite = look1;
            portraitImage.preserveAspect = true;
            portraitImage.raycastTarget = false;

            var nameText = CreateText(wings.transform, "PlayerName", "Warden", 40, new Vector2(-460, 470), new Vector2(700, 60));
            nameText.alignment = TextAlignmentOptions.MidlineLeft;
            var starsText = CreateText(wings.transform, "StarsText", "Stars 0 / 30", 36, new Vector2(380, 470), new Vector2(500, 60));
            var menuButton = CreateButton(wings.transform, "MenuButton", "Menu", new Vector2(790, 470), new Vector2(260, 70));

            var count = catalog.chapters.Count;
            var wingButtons = new Button[count];
            var wingNames = new TextMeshProUGUI[count];
            var wingStatuses = new TextMeshProUGUI[count];
            for (var i = 0; i < count; i++)
            {
                var firstRow = i < 3;
                var columns = firstRow ? System.Math.Min(3, count) : count - 3;
                var indexInRow = firstRow ? i : i - 3;
                var position = new Vector2((indexInRow - (columns - 1) / 2f) * 460f, firstRow ? 190 : -90);

                wingButtons[i] = CreateButton(wings.transform, $"Wing{i + 1}Button", catalog.chapters[i].name, position, new Vector2(420, 200));
                wingNames[i] = wingButtons[i].GetComponentInChildren<TextMeshProUGUI>();
                wingNames[i].alignment = TextAlignmentOptions.Top;
                wingNames[i].fontSize = 34;
                wingNames[i].margin = new Vector4(10, 16, 10, 0);
                wingStatuses[i] = CreateText(wingButtons[i].transform, "Status", string.Empty, 26, new Vector2(0, -45), new Vector2(390, 80), StatusColor);
            }

            var talaText = CreateText(wings.transform, "TalaText", string.Empty, 36, new Vector2(0, -330), new Vector2(1700, 100), NoticeColor);

            var roomsTitle = CreateText(rooms.transform, "RoomsTitle", "Chapter 1", 56, new Vector2(-330, 470), new Vector2(1100, 80));
            roomsTitle.alignment = TextAlignmentOptions.MidlineLeft;
            var roomsBack = CreateButton(rooms.transform, "BackButton", "Back to Keep", new Vector2(740, 470), new Vector2(400, 70));

            var doorButtons = new Button[DoorCount];
            var doorLabels = new TextMeshProUGUI[DoorCount];
            var doorStatuses = new TextMeshProUGUI[DoorCount];
            for (var j = 0; j < DoorCount; j++)
            {
                var position = new Vector2((j - (DoorCount - 1) / 2f) * 300f, 150);
                doorButtons[j] = CreateButton(rooms.transform, $"Door{j + 1}Button", "1.1", position, new Vector2(260, 260));
                doorLabels[j] = doorButtons[j].GetComponentInChildren<TextMeshProUGUI>();
                doorLabels[j].alignment = TextAlignmentOptions.Top;
                doorLabels[j].fontSize = 64;
                doorLabels[j].margin = new Vector4(0, 40, 0, 0);
                doorStatuses[j] = CreateText(doorButtons[j].transform, "Status", string.Empty, 26, new Vector2(0, -80), new Vector2(240, 70), StatusColor);
            }

            var infoTitle = CreateText(rooms.transform, "InfoTitle", string.Empty, 52, new Vector2(0, -110), new Vector2(1700, 80));
            var infoDetail = CreateText(rooms.transform, "InfoDetail", string.Empty, 32, new Vector2(0, -200), new Vector2(1700, 90), HintColor);
            var enterButton = CreateButton(rooms.transform, "EnterButton", "Enter room", new Vector2(0, -340), new Vector2(500, 90));

            CreateText(menu.transform, "MenuTitle", "Menu", 90, new Vector2(0, 330), new Vector2(900, 120));
            var menuColumn = CreateColumn(menu.transform, "MenuColumn", new Vector2(0, 0), new Vector2(500, 300), 16);
            var resume = CreateLayoutButton(menuColumn, "ResumeButton", "Resume");
            var menuSettings = CreateLayoutButton(menuColumn, "SettingsButton", "Settings");
            var menuTitle = CreateLayoutButton(menuColumn, "BackToTitleButton", "Back to title");

            CreateText(confirm.transform, "Message", "Go back to the title screen? Your progress is saved.", 48,
                new Vector2(0, 120), new Vector2(1400, 200));
            var confirmYes = CreateButton(confirm.transform, "YesButton", "Yes, go back", new Vector2(-240, -100), new Vector2(420, 70));
            var confirmNo = CreateButton(confirm.transform, "NoButton", "No, stay", new Vector2(240, -100), new Vector2(420, 70));

            var go = new GameObject("KeepMap");
            var controller = go.AddComponent<KeepMapController>();
            var so = new SerializedObject(controller);
            Assign(so, "_catalog", catalog);
            AssignArray(so, "_lookSprites", new[] { look1, look2 });
            Assign(so, "_portrait", portraitImage);
            Assign(so, "_nameText", nameText);
            Assign(so, "_starsText", starsText);
            Assign(so, "_talaText", talaText);
            Assign(so, "_menuButton", menuButton);
            AssignArray(so, "_wingButtons", wingButtons);
            AssignArray(so, "_wingNames", wingNames);
            AssignArray(so, "_wingStatuses", wingStatuses);
            Assign(so, "_roomsTitle", roomsTitle);
            Assign(so, "_roomsBackButton", roomsBack);
            AssignArray(so, "_doorButtons", doorButtons);
            AssignArray(so, "_doorLabels", doorLabels);
            AssignArray(so, "_doorStatuses", doorStatuses);
            Assign(so, "_infoTitle", infoTitle);
            Assign(so, "_infoDetail", infoDetail);
            Assign(so, "_enterButton", enterButton);
            Assign(so, "_resumeButton", resume);
            Assign(so, "_menuSettingsButton", menuSettings);
            Assign(so, "_menuTitleButton", menuTitle);
            Assign(so, "_confirmTitleYesButton", confirmYes);
            Assign(so, "_confirmTitleNoButton", confirmNo);
            so.ApplyModifiedPropertiesWithoutUndo();
            return controller;
        }
    }
}
