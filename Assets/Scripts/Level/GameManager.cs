using UnityEngine;
using UnityEngine.Events;

public class GameManager : MonoBehaviour
{
    [Header("Events")]
    [SerializeField] EventChannelSO _generateLevelTrigger;
    [SerializeField] EventChannelSO _launchEvent;
    [SerializeField] FloatPassChannelSO _gameEndEvent;
    [SerializeField] EventChannelSO _deathEvent;

    void Awake()
    {
        if (_gameEndEvent != null) _gameEndEvent.onTrigger += GameEnd;
        if (_deathEvent != null) _deathEvent.onTrigger += PlayerDeath;
        if (_launchEvent != null) _launchEvent.onTrigger += HandleLaunch;
    }

    private void Start()
    {

    }

    void HandleLaunch()
    {
        if (_generateLevelTrigger != null) _generateLevelTrigger.Invoke();
    }

    void GameEnd(float fuel)
    {

    }

    private void PlayerDeath()
    {
    }
}
