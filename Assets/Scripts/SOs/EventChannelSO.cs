using UnityEngine;
using UnityEngine.Events;

[CreateAssetMenu(fileName = "New Channel", menuName = "Events/Event Channel")]
public class EventChannelSO : ScriptableObject
{
    public event UnityAction onTrigger;
    public void Invoke() => onTrigger?.Invoke();
    public void Reset() => onTrigger = null;
}