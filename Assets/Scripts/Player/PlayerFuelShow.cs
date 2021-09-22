using TMPro;
using UnityEngine;

public class PlayerFuelShow : MonoBehaviour
{
    [SerializeField] FloatPassChannelSO _fuelChanged;
    [SerializeField] EventChannelSO _launch;

    [SerializeField] GameObject _canvas;
    [SerializeField] TextMeshPro _text;

    private void Awake()
    {
        if (_fuelChanged != null) _fuelChanged.onTrigger += ChangeText;
        if (_launch != null) _launch.onTrigger += HandleLaunch;
    }

    void Update()
    {
        _canvas.transform.up = Camera.main.transform.up;
        _canvas.transform.right = Camera.main.transform.right;
    }

    void ChangeText(float fuel)
    {
        if (_text == null) return;
        _text.text = Mathf.CeilToInt(fuel).ToString("#L; #L; 0");
    }

    void HandleLaunch()
    {
        if (_canvas == null) return;
        _canvas.SetActive(true);
    }
}
