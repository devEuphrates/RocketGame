using System.Collections.Generic;
using UnityEngine;

public class BossScript : MonoBehaviour
{
    [SerializeField] bool _toggleRagdoll = false;
    List<Rigidbody> _rigidBodies;
    Animator _animator;
    bool cur = false;

    private void Start()
    {
        _animator = transform.GetComponent<Animator>();

        _rigidBodies = new List<Rigidbody>();
        Rigidbody[] rba = transform.GetComponentsInChildren<Rigidbody>();

        for (int i = 0; i < rba.Length; i++)
            _rigidBodies.Add(rba[i]);

        ToggleRagdoll(false);
    }

    private void Update()
    {
        if (_toggleRagdoll)
        {
            ToggleRagdoll(!cur);
            cur = !cur;
            _toggleRagdoll = false;
        }
    }

    public void Die()
    {
        ToggleRagdoll(true);
        _animator.enabled = false;
    }

    void ToggleRagdoll(bool state) => _rigidBodies.ForEach(p => p.isKinematic = !state);
}
