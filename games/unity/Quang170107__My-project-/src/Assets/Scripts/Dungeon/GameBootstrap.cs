using UnityEngine;

namespace SimpleRPG
{
    public class GameBootstrap : MonoBehaviour
    {
        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
        public static void AutoInitializeGame()
        {
#if UNITY_6000_0_OR_NEWER
            if (FindAnyObjectByType<DungeonManager>() != null) return;
#else
            if (FindObjectOfType<DungeonManager>() != null) return;
#endif

            Debug.Log("<color=#00ff88>[SimpleRPG]</color> Bootstrapping Dungeon Crawler RPG...");

            SetupCamera();
            EnsureManager<AudioManager>("AudioManager");
            EnsureManager<DamageNumberManager>("DamageNumberManager");
            EnsureManager<LootManager>("LootManager");
            EnsureManager<SettingsManager>("SettingsManager");
            EnsureManager<GameUI>("GameUI");
            EnsureManager<ShopManager>("ShopManager");

            SpawnPlayer();

            EnsureManager<DungeonManager>("DungeonManager");

            Debug.Log("<color=#00ff88>[SimpleRPG]</color> Game initialized successfully!");
        }

        private static void SetupCamera()
        {
            Camera cam = Camera.main;
            if (cam == null)
            {
                var camGo = new GameObject("Main Camera");
                cam = camGo.AddComponent<Camera>();
                cam.tag = "MainCamera";
                camGo.AddComponent<AudioListener>();
            }

            cam.orthographic = true;
            cam.orthographicSize = 7.5f;
            cam.backgroundColor = new Color(0.08f, 0.09f, 0.12f);
            cam.clearFlags = CameraClearFlags.SolidColor;

            var follow = cam.GetComponent<CameraFollow>();
            if (follow == null)
            {
                follow = cam.gameObject.AddComponent<CameraFollow>();
            }
        }

        public static GameObject SpawnPlayer()
        {
            var playerGo = new GameObject("Player");
            playerGo.transform.position = new Vector3(0, -4.5f, 0);

            var rb = playerGo.AddComponent<Rigidbody2D>();
            var col = playerGo.AddComponent<CircleCollider2D>();
            var stats = playerGo.AddComponent<CombatStats>();
            var controller = playerGo.AddComponent<PlayerController>();

            // Setup camera target
            if (CameraFollow.Instance != null)
            {
                CameraFollow.Instance.SetTarget(playerGo.transform);
            }

            return playerGo;
        }

        private static T EnsureManager<T>(string name) where T : Component
        {
#if UNITY_6000_0_OR_NEWER
            var existing = FindAnyObjectByType<T>();
#else
            var existing = FindObjectOfType<T>();
#endif
            if (existing != null) return existing;

            var go = new GameObject(name);
            return go.AddComponent<T>();
        }
    }
}
