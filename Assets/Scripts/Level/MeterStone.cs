using UnityEngine;
using TMPro;

[RequireComponent(requiredComponent: typeof(MeshRenderer))]
public class MeterStone : MonoBehaviour
{
    int _xthMeter;
    MeshRenderer _meshRenderer;
    TextMeshPro _text;

    public void Set()
    {
        _xthMeter = 0;
        _meshRenderer = transform.GetComponent<MeshRenderer>();
        _text = transform.GetChild(0).GetComponent<TextMeshPro>();
    }

    public void SetColor(Color color) => _meshRenderer.material.color = color;

    public void SetMeter(int meter)
    {
        _xthMeter = meter;
        _text.text = meter.ToString("+#M;-#M;0M");
    }

    public int GetMeter() => _xthMeter;
}
