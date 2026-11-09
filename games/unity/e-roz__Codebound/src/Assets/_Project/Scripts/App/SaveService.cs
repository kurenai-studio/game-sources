using System;
using System.IO;
using Codebound.Core;
using UnityEngine;

namespace Codebound.App
{
    public class SaveService
    {
        const string FileName = "save.json";
        const string CorruptFileName = "save.corrupt.json";

        readonly string _directory;

        public bool BackedUpCorruptSave { get; private set; }

        public SaveService(string directory)
        {
            _directory = directory;
        }

        string SavePath => Path.Combine(_directory, FileName);

        public bool HasSave() => TryRead(out _);

        public bool TryLoad(out PlayerSave save)
        {
            if (TryRead(out save)) return true;
            BackUpCorruptFile();
            return false;
        }

        public void Save(PlayerSave save)
        {
            if (save == null || !save.IsValid())
                throw new ArgumentException("Cannot save an invalid PlayerSave.", nameof(save));

            Directory.CreateDirectory(_directory);
            var tempPath = SavePath + ".tmp";
            File.WriteAllText(tempPath, JsonUtility.ToJson(save, true));
            if (File.Exists(SavePath)) File.Delete(SavePath);
            File.Move(tempPath, SavePath);
        }

        public void Delete()
        {
            if (File.Exists(SavePath)) File.Delete(SavePath);
        }

        bool TryRead(out PlayerSave save)
        {
            save = null;
            if (!File.Exists(SavePath)) return false;

            try
            {
                var parsed = JsonUtility.FromJson<PlayerSave>(File.ReadAllText(SavePath));
                if (parsed == null || !parsed.IsValid()) return false;
                parsed.EnsureProgress();
                save = parsed;
                return true;
            }
            catch (Exception e) when (e is ArgumentException || e is IOException || e is UnauthorizedAccessException)
            {
                return false;
            }
        }

        void BackUpCorruptFile()
        {
            if (!File.Exists(SavePath)) return;

            var backupPath = Path.Combine(_directory, CorruptFileName);
            try
            {
                if (File.Exists(backupPath)) File.Delete(backupPath);
                File.Move(SavePath, backupPath);
                BackedUpCorruptSave = true;
            }
            catch (Exception e) when (e is IOException || e is UnauthorizedAccessException)
            {
            }
        }
    }
}
