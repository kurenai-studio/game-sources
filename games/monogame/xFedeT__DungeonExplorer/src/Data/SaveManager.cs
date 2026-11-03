using System.IO;
using System.Text.Json;

namespace DungeonExplorer.Data
{
    /// <summary>
    /// Gestisce il salvataggio e il caricamento del gioco su file JSON.
    /// </summary>
    public class SaveManager
    {
        private readonly JsonSerializerOptions _options;

        public SaveManager()
        {
            _options = new JsonSerializerOptions
            {
                WriteIndented = true // per rendere il JSON leggibile
            };
        }

        /// <summary>
        /// Salva i dati di gioco in un file JSON.
        /// </summary>
        public void SaveGame(GameData data, string filePath)
        {
            var json = JsonSerializer.Serialize(data, _options);
            File.WriteAllText(filePath, json);
        }

        /// <summary>
        /// Carica i dati di gioco da un file JSON.
        /// </summary>
        public GameData LoadGame(string filePath)
        {
            if (!File.Exists(filePath))
                return null;

            var json = File.ReadAllText(filePath);
            return JsonSerializer.Deserialize<GameData>(json, _options);
        }
    }
}