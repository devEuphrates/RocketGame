using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CamTestBehaivour : MonoBehaviour
{
    [SerializeField, Range(0f, 2f)] float _speed = .5f;
    [SerializeField] float _maxDist = 10f;
    [SerializeField] float _startDist = -60f;

    void FixedUpdate()
    {
        transform.position += new Vector3(0f, 0f, _speed);
        if (transform.position.z > _maxDist)transform.position = new Vector3(transform.position.x, transform.position.y, _startDist);
    }
}
