using UnityEngine;

[CreateAssetMenu(fileName = "New Set Piece", menuName = "Set Piece")]
public class SetPieceSO : ScriptableObject
{
    public int minLevel;
    public GameObject[] variants;
}
