using UnityEngine;
using UnityEngine.Events;

public class UTrigger : MonoBehaviour
{
    [Header("Trigger Enter")]
    [SerializeField] LayerMask _triggerEnterLayer;
    [SerializeField] UnityEvent _onTriggerEnter;

    [Header("Trigger Exit"), Space]
    [SerializeField] LayerMask _triggerExitLayer;
    [SerializeField] UnityEvent _onTriggerExit;

    [Header("Collision Enter"), Space]
    [SerializeField] LayerMask _collisionEnterLayer;
    [SerializeField] UnityEvent _onCollisionEnter;

    [Header("Collision Exit"), Space]
    [SerializeField] LayerMask _collisionExitLayer;
    [SerializeField] UnityEvent _onCollisionExit;

    private void OnTriggerEnter(Collider other)
    {
        if (_triggerEnterLayer.value == (_triggerEnterLayer.value | (1 << other.gameObject.layer)))
            _onTriggerEnter?.Invoke();
    }
    private void OnTriggerExit(Collider other)
    {
        if (_triggerExitLayer.value == (_triggerExitLayer.value | (1 << other.gameObject.layer)))
            _onTriggerExit?.Invoke();
    }
    private void OnCollisionEnter(Collision collision)
    {
        if (_collisionEnterLayer.value == (_collisionEnterLayer.value | (1 << collision.gameObject.layer)))
            _onCollisionEnter?.Invoke();
    }
    private void OnCollisionExit(Collision collision)
    {
        if (_collisionExitLayer.value == (_collisionExitLayer.value | (1 << collision.gameObject.layer)))
            _onCollisionExit?.Invoke();
    }
}
