using UnityEngine;
using TMPro;

public class FuelHoop : MonoBehaviour
{
    [SerializeField] FloatPassChannelSO _playerFuelChange;
    [SerializeField] float[] _canBe;

    TextMeshPro _text;

    float _fuelAmount = 0f;

    void Start()
    {
        _text = transform.parent.GetChild(1).GetComponent<TextMeshPro>();

        if (_canBe == null || _canBe.Length == 0) return;
        int selIndex = Random.Range(0, _canBe.Length);
        _fuelAmount = _canBe[selIndex];

        _text.text = Mathf.FloorToInt(_fuelAmount).ToString("+#;-#;0");
    }

    private void OnTriggerEnter(Collider other)
    {
        if (other.gameObject.layer != 7) return;
        _playerFuelChange.Invoke(_fuelAmount);
    }

    public void SetFuel(float fuel) => _fuelAmount = fuel;
}
