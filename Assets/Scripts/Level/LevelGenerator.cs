using System.Collections.Generic;
using UnityEngine;

public class LevelGenerator : MonoBehaviour
{
    public static Transform SetPieceParent;

    public static bool _secondMode = false;

    [Header("Spawn Parameters")]
    [SerializeField] SetPieceSO[] _setPieces;
    [SerializeField] uint _setPieceCount = 10;
    [SerializeField] float _turnSize = 30f;
    //[SerializeField] Color[] _meterColors;
    [SerializeField] float _offset = 90f;

    [Header("Events"), Space]
    [SerializeField] EventChannelSO _generateLevelTrigger;
    [SerializeField] EventChannelSO _gameReload;

    [Header("References"), Space]
    [SerializeField] Transform _boss;
    [SerializeField] Transform _wall;
    [SerializeField] GameObject _distancePrefab;
    [SerializeField] Transform _phaseTwoTrigger;
    [SerializeField] GameObject _floorPrefab;
    [SerializeField] Transform _floorsParent;
    [SerializeField] float _floorStartOffset = 40f;
    [SerializeField] int _extraFloors = 0;


    List<SetPieceSpawn> _curLevelSPs = new List<SetPieceSpawn>();
    List<GameObject> _spawnedSetPieces = new List<GameObject>();
    List<GameObject> _spawnedMilestones = new List<GameObject>();

    void Awake()
    {
        SetPieceParent = transform;
        if (_generateLevelTrigger != null) _generateLevelTrigger.onTrigger += GenerateCurLevel;
    }

    public void GenerateCurLevel()
    {
        if (_setPieces != null && _setPieces.Length != 0)
        {
            uint level = PlayerInfo.PlayerLevel;
            _curLevelSPs.Clear();

            for (int i = 0; i < _setPieces.Length; i++)
                if (_setPieces[i].minLevel <= level)
                    _curLevelSPs.Add(new SetPieceSpawn(_setPieces[i]));

            List<SetPieceSpawn> noSpwn;
            SetPieceSpawn sel = null;
            for (int i = 0; i < _setPieceCount; i++)
            {
                noSpwn = _curLevelSPs.FindAll(p => p.GetCount() == 0);
                sel = noSpwn == null || noSpwn.Count == 0 ? _curLevelSPs[Random.Range(0, _curLevelSPs.Count)] : noSpwn[Random.Range(0, noSpwn.Count)];

                _spawnedSetPieces.Add(sel.Spawn(_turnSize));

            }
        }

        int x = Mathf.CeilToInt((_setPieceCount + 1) * _turnSize + _offset - _floorStartOffset + 5);
        int floorCount = x / 10;
        floorCount = x % 10 == 0 ? floorCount : floorCount + 1;
        floorCount += _extraFloors;
        if (_floorPrefab != null && _floorsParent != null)
            for (int i = 0; i < floorCount; i++)
                Instantiate(_floorPrefab, new Vector3(0f, 0f, _floorStartOffset + i * 10f), Quaternion.identity, _floorsParent);

        //if (_secondMode)
        //{
        //    StartCoroutine(SecMode());
        //    return;
        //}

        if (_wall != null) _wall.position = new Vector3(0f, 5f, (_setPieceCount + 1) * _turnSize + _offset);
        if (_boss != null) _boss.position = new Vector3(0f, 0f, (_setPieceCount + 1) * _turnSize + _offset - 10f);
    }

    //IEnumerator<WaitForEndOfFrame> SecMode()
    //{
    //    if (_distancePrefab == null) yield break;

    //    for (int i = 0; i < 1000; i++)
    //    {
    //        GameObject go = Instantiate(_distancePrefab, new Vector3(0f, 0f, _setPieceCount * _turnSize + i + _offset), Quaternion.identity, transform);
    //        MeterStone ms = go.GetComponent<MeterStone>();

    //        ms.Set();
    //        int index = i % _meterColors.Length;
    //        ms.SetColor(_meterColors[index]);
    //        ms.SetMeter(i + 1);

    //        go.name = (i + 1).ToString("#th Meter");
    //        _spawnedMilestones.Add(go);

    //        if (i % 40 == 0) yield return new WaitForEndOfFrame();
    //    }

    //    if (_phaseTwoTrigger != null) _phaseTwoTrigger.position = new Vector3(0f, 5f, _setPieceCount * _turnSize + _offset - 1);
    //}

    void DestroyAll()
    {
        _spawnedSetPieces.ForEach(p => Destroy(p.gameObject));
        _spawnedMilestones.ForEach(p => Destroy(p.gameObject));
    }

    class SetPieceSpawn
    {
        SetPieceSO _sp;
        uint _spawnCount;

        public SetPieceSpawn(SetPieceSO setPiece)
        {
            _sp = setPiece;
            _spawnCount = 0;
        }

        public uint GetCount() => _spawnCount;

        public SetPieceSO GetSetPiece() => _sp;

        public GameObject Spawn(float lastPos)
        {
            if (_sp == null) return null;

            GameObject selVariant = _sp.variants[Random.Range(0, _sp.variants.Length)];

            _spawnCount++;
            return Instantiate(selVariant, new Vector3(0f, 0f, 0f), Quaternion.identity, LevelGenerator.SetPieceParent);
        }
    }
}
