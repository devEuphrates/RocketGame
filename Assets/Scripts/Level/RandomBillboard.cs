using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RandomBillboard : MonoBehaviour
{
    List<GameObject> _boards = new List<GameObject>();

    private void Awake()
    {
        for (int i = 0; i < transform.childCount; i++)
        {
            GameObject go = transform.GetChild(i).gameObject;
            go.SetActive(false);
            _boards.Add(go);
        }
            
    }

    private void Start()
    {
        int selIndex = Random.Range(0, _boards.Count);
        _boards[selIndex].SetActive(true);
    }
}
