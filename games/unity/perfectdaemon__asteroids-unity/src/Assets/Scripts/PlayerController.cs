using UnityEngine;

/// <summary>
/// Контроллер для корабля игрока
/// </summary>
public class PlayerController : MonoBehaviour
{
    /// <summary>
    /// Ось верха для поворота
    /// </summary>
    private readonly Vector3 _upAxis = new Vector3(0, 0, -1);

    /// <summary>
    /// Объект игрока, на который навешан скрипт
    /// </summary>
    private Transform _transform;

    /// <summary>
    /// Переменная для хранения пользовательского ввода вращения
    /// </summary>
    private float _rotateInput;

    /// <summary>
    /// Переменная для хранения пользовательского ввода ускорения
    /// </summary>
    private float _speedInput;

    /// <summary>
    /// Текущий вектор движения
    /// </summary>
    private Vector3 _movement;

    /// <summary>
    /// Внутренний объект игрока, который будет вращаться
    /// </summary>
    [SerializeField]
    public Transform PlayerShip;

    /// <summary>
    /// Скорость поворота корабля
    /// </summary>
    [SerializeField]
    [Range(1f, 100f)]
    public float RotateSpeed = 1f;

    /// <summary>
    /// Скорость ускорения корабля (насколько быстро он добавляет скорость в выбранном направлении)
    /// </summary>
    [SerializeField]
    [Range(1f, 100f)]
    public float AccelerationSpeed = 1f;

    /// <summary>
    /// Максимальная скорость корабля
    /// </summary>
    [SerializeField]
    [Range(1f, 100f)]
    public float MaxSpeed = 10f;

    // Use this for initialization
    public void Start()
    {
        _transform = GetComponent<Transform>();
    }

    // Update is called once per frame
    public void Update()
    {
        // Получаем данные пользовательского ввода
        _rotateInput = Input.GetAxis("Horizontal");
        _speedInput = Input.GetAxis("Vertical");

        // Если значение поворота ненулевое, то вращаем корабль (внутренний объект)
        if (Mathf.Abs(_rotateInput) > Mathf.Epsilon)
        {
            PlayerShip.Rotate(_upAxis, _rotateInput * RotateSpeed * Time.deltaTime);
        }

        // Если значение ускорения ненулевое
        if (_speedInput > Mathf.Epsilon)
        {
            // Добавляем к текущему вектору движения новый вектор
            _movement = _movement + PlayerShip.up * _speedInput * AccelerationSpeed * Time.deltaTime;

            // Ограничиваем максимальную скорость корабля
            if (_movement.magnitude > MaxSpeed)
                _movement = _movement.normalized * MaxSpeed;
        }

        // Перемещаем корабль, используя обновленный вектор движения
        _transform.Translate(_movement * Time.deltaTime, Space.Self);
    }
}

