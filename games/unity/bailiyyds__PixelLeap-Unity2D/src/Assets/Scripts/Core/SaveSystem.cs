using System;
using System.IO;
using UnityEngine;

namespace PixelLeap.Core
{
    [Serializable]
    public class SaveData
    {
        public int version = 1;
        public int unlockedLevel = 0;      // 已解锁的最高关卡索引
        public float[] bestTimes = new float[0];
        public int totalDeaths;
    }

    /// <summary>JSON 存档：写入临时文件后再替换，避免写到一半崩溃导致存档损坏。</summary>
    public static class SaveSystem
    {
        static string FilePath => Path.Combine(Application.persistentDataPath, "pixelleap_save.json");

        public static SaveData Load()
        {
            try
            {
                if (File.Exists(FilePath))
                {
                    var data = JsonUtility.FromJson<SaveData>(File.ReadAllText(FilePath));
                    if (data != null) return data;
                }
            }
            catch (Exception e)
            {
                Debug.LogWarning($"[Save] 读取失败，使用新存档：{e.Message}");
            }
            return new SaveData();
        }

        public static void Save(SaveData data)
        {
            try
            {
                string tmp = FilePath + ".tmp";
                File.WriteAllText(tmp, JsonUtility.ToJson(data, true));
                if (File.Exists(FilePath)) File.Delete(FilePath);
                File.Move(tmp, FilePath);
            }
            catch (Exception e)
            {
                Debug.LogError($"[Save] 写入失败：{e.Message}");
            }
        }

        /// <summary>记录通关：更新最佳时间并解锁下一关。</summary>
        public static void RecordClear(SaveData data, int level, float time)
        {
            if (data.bestTimes.Length <= level) Array.Resize(ref data.bestTimes, level + 1);
            if (data.bestTimes[level] <= 0 || time < data.bestTimes[level]) data.bestTimes[level] = time;
            data.unlockedLevel = Mathf.Max(data.unlockedLevel, level + 1);
            Save(data);
        }
    }
}
