using UnityEngine;
using UnityEngine.Events;
using UnityEngine.SceneManagement;

public class SceneMaster : MonoBehaviour
{
    [Header("Triggers")]
    [SerializeField] EventChannelSO _reloadGameTrigger;
    [SerializeField] UnityEvent _onReloadEnd;

    [Header("Events To Reset"), Space]
    [SerializeField] EventChannelSO[] _eventChannels;
    [SerializeField] FloatPassChannelSO[] _floatPass;

    void Awake()
    {
        if (_reloadGameTrigger != null) _reloadGameTrigger.onTrigger += ReloadGame;
        SceneManager.LoadScene("GameScene", LoadSceneMode.Additive);
    }

    void ReloadGame()
    {
        ResetEvents();
        AsyncOperation ao = SceneManager.UnloadSceneAsync("GameScene");
        ao.completed += (AsyncOperation p) => SceneManager.LoadScene("GameScene", LoadSceneMode.Additive);
    }

    void ResetEvents()
    {
        if (_eventChannels != null)
            for (int i = 0; i < _eventChannels.Length; i++)
                _eventChannels[i].Reset();

        if (_floatPass != null)
            for (int i = 0; i < _floatPass.Length; i++)
                _floatPass[i].Reset();

        _onReloadEnd?.Invoke();
    }
}
