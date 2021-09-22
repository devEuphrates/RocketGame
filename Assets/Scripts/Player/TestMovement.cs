using UnityEngine;

public class TestMovement : MonoBehaviour
{
    public float _moveSpeed;

    private void FixedUpdate()
    {
        transform.position = new Vector3(0f, 3f, transform.position.z + _moveSpeed);
        if (transform.position.z > 100f) transform.position = new Vector3(transform.position.x, transform.position.y, 0f);
    }
}
