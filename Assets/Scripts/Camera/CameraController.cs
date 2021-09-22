using Cinemachine;
using UnityEngine;
using UnityEngine.Events;

public class CameraController : MonoBehaviour
{
    [Header("Virtual Cameras")]
    [SerializeField] CinemachineVirtualCamera _startCam;
    [SerializeField] CinemachineVirtualCamera _followCam;
    [SerializeField] CinemachineVirtualCamera _phaseTwoCam;

    [Header("Events"), Space]
    [SerializeField] EventChannelSO _phaseOneEvent;
    [SerializeField] EventChannelSO _phaseTwoEvent;

    UnityAction handler1;
    UnityAction handler2;

    private void Start()
    {
        handler1 = () => SetCamPriority(1);
        handler2 = () => SetCamPriority(2);

        SetCamPriority(0);
        _phaseOneEvent.onTrigger += handler1;
        _phaseTwoEvent.onTrigger += handler2;
    }

    private void SetCamPriority(int index)
    {
        _startCam.Priority = index == 0 ? 1 : 0;
        _followCam.Priority = index == 1 ? 1 : 0;
        _phaseTwoCam.Priority = index == 2 ? 1 : 0;
    }
}
