using System.Collections.Generic;
using System.Linq;
using UnityEngine;

public class LevelGenerator : MonoBehaviour
{
    public static Transform SetPieceParent;
    public static bool _secondMode = false;

    [Header("Spawn Parameters")]
    [SerializeField] SetPieceSO[] _setPieces;
    [SerializeField] uint _setPieceCount = 10;
    [SerializeField] float _offset = 10f;

    [Header("Events"), Space]
    [SerializeField] EventChannelSO _generateLevelTrigger;
    [SerializeField] EventChannelSO _gameReload;

    [Header("References"), Space]
    [SerializeField] Transform _boss;
    [SerializeField] Transform _wall;
    [SerializeField] GameObject _floorPrefab;
    [SerializeField] Transform _floorsParent;
    [SerializeField] float _floorStartOffset = 40f;
    [SerializeField] int _extraFloors = 0;


    List<GameObject> _spawnedSetPieces = new List<GameObject>();

    void Awake()
    {
        SetPieceParent = transform;
        if (_generateLevelTrigger != null) _generateLevelTrigger.onTrigger += GenerateCurLevel;
    }

    void GenerateEnviromentBase(float lastZ)
    {
        if (_floorPrefab == null || _floorsParent == null) return;

        int x = Mathf.CeilToInt(lastZ + 50f + _floorStartOffset);
        int floorCount = x / 10;
        floorCount = x % 10 == 0 ? floorCount : floorCount + 1;
        floorCount += _extraFloors;

            for (int i = 0; i < floorCount; i++)
                Instantiate(_floorPrefab, new Vector3(0f, 0f, _floorStartOffset + i * 10f), Quaternion.identity, _floorsParent);
    }

    public void GenerateCurLevel()
    {
        float lastZ = 0f;

        if (_setPieces != null && _setPieces.Length != 0)
        {
            List<SetPieceSO> curLevelSPs = new List<SetPieceSO>();
            uint level = PlayerInfo.PlayerLevel;
            curLevelSPs.Clear();

            for (int i = 0; i < _setPieces.Length; i++)
                if (_setPieces[i].minLevel <= level)
                    curLevelSPs.Add(_setPieces[i]);

            List<SetPieceSO> notSpawned = new List<SetPieceSO>(curLevelSPs);


            for (int i = 0; i < _setPieceCount; i++)
            {
                SetPieceSO sel;

                if (notSpawned.Count != 0)
                {
                    int rndIndex = UnityEngine.Random.Range(0, notSpawned.Count);
                    sel = notSpawned[rndIndex];
                    notSpawned.Remove(sel);
                }
                else
                {
                    int rndIndex = UnityEngine.Random.Range(0, curLevelSPs.Count);
                    sel = curLevelSPs[rndIndex];
                }


                lastZ += _offset;
                GameObject go = Instantiate(sel.variants[UnityEngine.Random.Range(0, sel.variants.Length)], new Vector3(0f, 0.1f, lastZ + sel.size * 0.5f + _floorStartOffset), Quaternion.identity, transform);
                _spawnedSetPieces.Add(go);
                lastZ += sel.size;
            }
        }

        if (_wall != null) _wall.position = new Vector3(0f, 5f, lastZ + _offset + 40f + _floorStartOffset);
        if (_boss != null) _boss.position = new Vector3(0f, 0f, lastZ + _offset + 30f + _floorStartOffset);

        GenerateEnviromentBase(lastZ);
    }
}
