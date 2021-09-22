using UnityEngine;

public class CamFollow : MonoBehaviour
{
    [SerializeField] Vector3 _offset;
    [SerializeField] Transform _followTarget;

    void FixedUpdate()
    {
        if (_followTarget == null || _offset == null) return;

        transform.position = new Vector3(_offset.x, _offset.y, _followTarget.position.z + _offset.z);
    }
}
