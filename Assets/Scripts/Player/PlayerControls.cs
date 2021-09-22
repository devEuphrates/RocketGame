#if UNITY_EDITOR
#define PC_CONTROLS
#endif

using UnityEngine;
using UnityEngine.EventSystems;

public class PlayerControls : MonoBehaviour
{

    Rigidbody _rigidbody;
    Animator _animator;

    GameObject _flyEffects;
    ParticleSystem _deathEffects;
    GameObject _meshObject;

    // Input and movement.
    Vector2 _startPos = Vector2.zero;
    Vector2 _curPos = Vector2.zero;
    Vector2 _moveVector = Vector2.zero;

    RocketState _currentState = RocketState.Landed;
    bool _launching = false;
    [Header("Launch Parameters")]
    [SerializeField] float _launchSeconds = 2f;
    [SerializeField] float _startHeight = 6f;
    [SerializeField] float _speed = 8f;

    [Header("Flight Constraints"), Space]
    [SerializeField] float _maxHeight = 9f;
    [SerializeField] float _minHeight = 2f;
    [SerializeField] float _horizontalDistance = 2f;

    float _fuel = 0f;
    [SerializeField] float _fuelConsumption = 4f;
    [SerializeField] float _phaseTwoMultiplier = 4f;

    [SerializeField] Transform _target;
    [SerializeField] float _targetOffset = 5f;

    Transform _visuals;

    bool _mSet = false;
    public float fuel
    {
        get { return _fuel; }
    }

    float _ms = 0f;

    [Header("Events"), Space]
    [SerializeField] EventChannelSO _flightStartEvent;
    [SerializeField] FloatPassChannelSO _addFuelEvent;
    [SerializeField] FloatPassChannelSO _fuelChangedEvent;
    [SerializeField] EventChannelSO _phaseTwoEvent;
    [SerializeField] FloatPassChannelSO _gameEndEvent;
    [SerializeField] EventChannelSO _deathEvent;

    

    void Awake()
    {
        if (_addFuelEvent != null) _addFuelEvent.onTrigger += AddFuel;
        _visuals = transform.GetChild(0);
    }

    void Start()
    {
        _visuals = transform.GetChild(0);
        _meshObject = _visuals.GetChild(0).gameObject;
        _flyEffects = _visuals.GetChild(1).gameObject;
        _deathEffects = _visuals.GetChild(2).GetComponent<ParticleSystem>();

        _rigidbody = transform.GetComponent<Rigidbody>();
        _animator = transform.GetComponent<Animator>();

        GetReady();
    }

    void Update()
    {
#if PC_CONTROLS
        if (Input.GetKeyDown(KeyCode.Space) && _currentState == RocketState.Landed)
            Launch();

        if (Input.GetKey(KeyCode.W))
            _moveVector = (_moveVector.normalized + Vector2.up).normalized * 20f;

        if (Input.GetKey(KeyCode.A))
            _moveVector = (_moveVector.normalized + Vector2.left).normalized * 20f;

        if (Input.GetKey(KeyCode.S))
            _moveVector = (_moveVector.normalized + Vector2.down).normalized * 20f;

        if (Input.GetKey(KeyCode.D))
            _moveVector = (_moveVector.normalized + Vector2.right).normalized * 20f;
#endif

        if (Input.touchCount < 1) return;

        Touch tch = Input.GetTouch(0);

        switch (_currentState)
        {
            case RocketState.Landed:
                if (EventSystem.current.IsPointerOverGameObject(tch.fingerId) || tch.phase != TouchPhase.Began || _launching) return;
                
                Launch();
                return;

            case RocketState.Flying:
                _curPos = tch.position;

                switch (tch.phase)
                {
                    case TouchPhase.Began:
                        _startPos = _curPos;
                        return;

                    case TouchPhase.Moved:
                    case TouchPhase.Stationary:
                        _moveVector = _curPos - _startPos;
                        break;

                    case TouchPhase.Ended:
                    case TouchPhase.Canceled:
                        _startPos = Vector2.zero;
                        _moveVector = Vector2.zero;
                        break;
                }
                return;

            case RocketState.Dead:
                return;

            default:
                return;
        }
    }

    void FixedUpdate()
    {
        switch (_currentState)
        {
            case RocketState.Landed:
                if (!_launching) return;
                _rigidbody.velocity = new Vector3(0f, _ms, _speed);

                if (transform.position.y >= _startHeight)
                {
                    _rigidbody.velocity = new Vector3(0f, 0f, _speed);
                    transform.position = new Vector3(0f, _startHeight, transform.position.z);
                    _target.position = new Vector3(0f, _startHeight, transform.position.z + _targetOffset);
                    _launching = false;
                    _currentState = RocketState.Flying;
                }
                return;

            case RocketState.Flying:
                _moveVector /= 200f;

                float moveX = _moveVector.x;
                float moveY = _moveVector.y;

                moveX = moveX > 0 && moveX + _target.position.x > _horizontalDistance ? _horizontalDistance - _target.position.x : moveX;
                moveX = moveX < 0 && moveX + _target.position.x < -_horizontalDistance ? -_horizontalDistance - _target.position.x : moveX;

                moveY = moveY > 0 && moveY + _target.position.y > _maxHeight ? _maxHeight - _target.position.y : moveY;
                moveY = moveY < 0 && moveY + _target.position.y < _minHeight ? _minHeight - _target.position.y : moveY;

                _target.position += new Vector3(moveX, moveY, 0f);
                _target.position = new Vector3(_target.position.x, _target.position.y, transform.position.z + _targetOffset);

                _startPos = _curPos;

                transform.position = Vector3.Lerp(transform.position, new Vector3(_target.position.x, _target.position.y, transform.position.z), 0.1f);
                _visuals.up = (_target.position - transform.position).normalized;

                AddFuel(-Time.fixedDeltaTime * _fuelConsumption);
                break;

            case RocketState.PhaseTwo:
                transform.position = Vector3.Lerp(transform.position, new Vector3(0f, 3f, transform.position.z), .2f);

                AddFuel(-Time.fixedDeltaTime * _fuelConsumption * _phaseTwoMultiplier);
                break;

            case RocketState.Dead:
                break;

            default:
                break;
        }
    }

    void OnCollisionEnter(Collision collision)
    {
        if (collision.gameObject.layer == 10)
        {
            MeterStone ms = collision.gameObject.GetComponent<MeterStone>();
            int meter = ms.GetMeter();
            Debug.Log($"Went {meter} meters");
            BlowUp();
            _currentState = RocketState.Dead;
            _gameEndEvent.Invoke(fuel);
            return;
        }

        if (collision.gameObject.layer != 8)
        {
            Die();
            return;
        }

        BossScript boss = collision.transform.parent.parent.GetComponent<BossScript>();
        boss.Die();
        BlowUp();
        _currentState = RocketState.Dead;
        _gameEndEvent.Invoke(fuel);
        collision.rigidbody.AddForce(Vector3.forward * 100f, ForceMode.Impulse);
    }

    void GetReady()
    {
        _flyEffects.SetActive(false);

        _ms = (_startHeight - transform.position.y) / _launchSeconds;

        if (_phaseTwoEvent != null) _phaseTwoEvent.onTrigger += () => {
            _currentState = RocketState.PhaseTwo;
            _rigidbody.velocity = new Vector3(0f, 0f, _speed * _phaseTwoMultiplier);
        };

        _currentState = RocketState.Landed;
        _fuel = 0;
        AddFuel(30);
    }

    public void AddFuel(float amount)
    {
        _fuel += amount;

        if (_fuel <= 0)
        {
            _fuel = 0;
            _currentState = RocketState.Dead;
            if (_rigidbody != null) _rigidbody.useGravity = true;
            _flyEffects.SetActive(false);
        }

        _fuelChangedEvent?.Invoke(_fuel);
    }

    void Launch()
    {
        if (_launching) return;
        _launching = true;

        _flightStartEvent.Invoke();
        _flyEffects.SetActive(true);

        _animator.SetTrigger("Launch");
    }

    void Die()
    {
        BlowUp();

        _currentState = RocketState.Dead;
        _deathEvent.Invoke();
    }

    void BlowUp()
    {
        _flyEffects.SetActive(false);
        _deathEffects.Play(true);
        _rigidbody.isKinematic = true;
        _meshObject.SetActive(false);
    }
}

public enum RocketState { Landed, Flying, Dead, PhaseTwo }