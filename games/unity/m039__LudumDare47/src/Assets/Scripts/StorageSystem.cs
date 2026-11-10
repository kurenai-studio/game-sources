using System;
using UnityEngine;

public static class StorageSystem
{
	public static class Settings
	{
		const string _SettingsSelectedLanguage = "settings_selected_language";

		public static string GetSelectedLanguage()
		{
			return PlayerPrefs.GetString(_SettingsSelectedLanguage, null);
		}

		public static void SetSelectedLanguage(string language)
		{
			PlayerPrefs.SetString(_SettingsSelectedLanguage, language);
			PlayerPrefs.Save();
		}
	}
}