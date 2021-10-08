using UnityEngine;

[CreateAssetMenu(fileName = "New Set Piece", menuName = "Set Piece")]
public class SetPieceSO : ScriptableObject
{
    public uint id;
    public int minLevel;
    public GameObject[] variants;
    public float size;
}
