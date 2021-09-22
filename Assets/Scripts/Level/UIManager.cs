using TMPro;
using UnityEngine;

public class UIManager : MonoBehaviour
{
    [Header("Elements")]
    [SerializeField] TextMeshProUGUI _fuelText;
    [SerializeField] GameObject _reloadButton;
    [SerializeField] GameObject _modeButton;

    [Header("Events"), Space]
    [SerializeField] EventChannelSO _flightStart;
    [SerializeField] FloatPassChannelSO _fuelChanged;
    [SerializeField] FloatPassChannelSO _gameEnd;
    [SerializeField] EventChannelSO _death;
    [SerializeField] EventChannelSO _reloadGame;

    private void Awake()
    {
        SubscribeToEvents();
    }

    void Start() => SetForStart();

    public void SubscribeToEvents()
    {
        if (_flightStart != null) _flightStart.onTrigger += () => { ToggleModeButton(false); ToggleFuelText(true); };
        if (_fuelChanged != null) _fuelChanged.onTrigger += (float fuel) => SetFuelText(fuel);
        if (_gameEnd != null) _gameEnd.onTrigger += (float pts) => ToggleReloadButton(true);
        if (_death != null) _death.onTrigger += () => ToggleReloadButton(true);
    }

    void SetForStart()
    {
        if (_fuelText != null) _fuelText.gameObject.SetActive(false);
        if (_reloadButton != null) _reloadButton.SetActive(false);
        if (_modeButton != null) _modeButton.SetActive(true);

        //UnityAction<bool> handler = (bool par) => LevelGenerator._secondMode = par;
        //_modeButton.transform.GetChild(0).GetComponent<Toggle>().onValueChanged.AddListener(handler);
    }

    void SetFuelText(float fuel)
    {
        if (_fuelText == null) return;

        _fuelText.text = Mathf.CeilToInt(fuel).ToString();
    }

    void ToggleFuelText(bool state)
    {
        if (_fuelText == null) return;
        _fuelText.gameObject.SetActive(state);
    }

    void ToggleReloadButton(bool state)
    {
        if (_reloadButton == null) return;
        _reloadButton.SetActive(state);
    }

    void ToggleModeButton(bool state)
    {
        if (_modeButton == null) return;
        _modeButton.SetActive(state);
    }

    public void ReloadClicked()
    {
        _reloadGame.Invoke();
        SetForStart();
    }
}
