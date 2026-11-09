using System.Collections;
using System.Collections.Generic;
using Unity.Entities;
using UnityEngine;
using UnityEngine.SceneManagement;

public class SceneSwitcher : MonoBehaviour
{
    public void LoadScene(int index) {
        var mgr = World.Active.EntityManager;
        mgr.ExclusiveEntityTransactionDependency.Complete();
        var ent = mgr.GetAllEntities();
        for (int i = 0; i < ent.Length; i++)
        {
            mgr.DestroyEntity(ent);
        }
        ent.Dispose();
        mgr.ExclusiveEntityTransactionDependency.Complete();
        SceneManager.LoadScene(index);
        mgr.ExclusiveEntityTransactionDependency.Complete();
    }

    public void Restart() {
       LoadScene(SceneManager.GetActiveScene().buildIndex);
    }

    private void OnApplicationQuit() {
        if (!Application.isEditor) {
            World.DisposeAllWorlds();
            System.Diagnostics.Process.GetCurrentProcess().Kill();
        } 
    }
}
