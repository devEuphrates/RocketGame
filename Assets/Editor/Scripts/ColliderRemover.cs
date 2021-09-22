using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using static UnityEditor.PrefabUtility;

public class ColliderRemover
{
    [MenuItem("Tools/Remove Colliders From Selected Prefabs #%l")]
    static public void RemoveCollidersFromSelectedPrefabs()
    {
        GameObject[] selGOs = Selection.gameObjects;
        string assetPath = "";

        for (int i = 0; i < selGOs.Length; i++)
        {
            assetPath = AssetDatabase.GetAssetPath(selGOs[i]);

            using (var editScope = new EditPrefabContentsScope(assetPath))
            {
                var prefabRoot = editScope.prefabContentsRoot;

                foreach (var col in prefabRoot.GetComponents<Collider>())
                {
                    Object.DestroyImmediate(col);
                }
            }
        }
    }
}
