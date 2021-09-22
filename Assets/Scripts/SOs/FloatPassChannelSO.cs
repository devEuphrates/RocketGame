using UnityEngine;
using UnityEngine.Events;

[CreateAssetMenu(fileName = "New Channel", menuName = "Events/Float Pass Channel")]
public class FloatPassChannelSO : ScriptableObject
{
    public event UnityAction<float> onTrigger;
    public void Invoke(float param) => onTrigger?.Invoke(param);
    public void Reset() => onTrigger = null;
}
