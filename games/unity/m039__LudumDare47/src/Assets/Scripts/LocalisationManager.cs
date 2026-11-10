using System;
using System.Collections.Generic;
using UnityEngine;
using m039.Common;

public static class LocalisationManager
{
	static SimpleLocalisationSystem __Instance;

	static SimpleLocalisationSystem _Instance
	{
		get
		{
			if (__Instance == null)
			{
				__Instance = new SimpleLocalisationSystem();
				__Instance.LoadData();

				// Take a default language from the prefs and set it.
				var currentLanguage = StorageSystem.Settings.GetSelectedLanguage();
				if (currentLanguage != null)
				{
					if (__Instance.Languages.IndexOf(currentLanguage) != -1)
					{
						__Instance.CurrentLanguage = currentLanguage;
					}
				}

				
			}

			return __Instance;
		}
	}

	public static List<string> GetLanguages()
	{
		return _Instance.Languages;
	}

	public static string GetCurrentLanguage()
	{
		return _Instance.CurrentLanguage;
	}

	public static void SetLanguage(string language)
	{
		_Instance.CurrentLanguage = language;
	}

	public static string GetString(string key)
	{
		return _Instance[key];
	}

	public static void SelectNextLanguage()
	{
		_Instance.SelectNextLanguage();
	}

	public static void SelectPrevLanguage()
	{
		_Instance.SelectPrevLanguage();
	}
}
