import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

class SensorService {
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  Timer? _shakeCoolDownTimer;

  Function(double x, double y, double z)? onPositionChanged;
  Function(double magnitude)? onShakeDetected;
  Function()? onShakeEnded;

  double _velocityX = 0.0;
  double _velocityY = 0.0;
  double _velocityZ = 0.0;
  double _positionX = 0.0;
  double _positionY = 0.0;
  double _positionZ = 0.0;
  
  static const double _friction = 0.94;
  static const double _sensitivity = 0.02;
  static const double _maxVelocity = 12.0;
  static const double _springForce = 0.1;
  static const double _borderLimit = 0.85;
  static const double _idleMovement = 0.0003;
  
  double _smoothAccelX = 0.0;
  double _smoothAccelY = 0.0;
  double _smoothAccelZ = 0.0;
  static const double _smoothFactor = 0.12;
  
  static const double _shakeDebounce = 1000;
  double _shakeThreshold = 2.5;
  DateTime? _lastShakeTime;
  int _shakeCount = 0;
  static const int _maxShakesPerMinute = 10;
  bool _isShaking = false;
  bool _isInCoolDown = false;
  
  final List<double> _magnitudeHistory = [];
  static const int _historySize = 5;
  
  DateTime? _lastUpdateTime;

  void setShakeSensitivity(double sensitivity) {
    _shakeThreshold = sensitivity.clamp(1.5, 10.0);
  }

  void startListening() {
    if (_accelerometerSubscription != null) return;
    _lastUpdateTime = DateTime.now();
    _accelerometerSubscription = accelerometerEvents.listen(_onAccelerometerEvent);
  }

  void _onAccelerometerEvent(AccelerometerEvent event) {
    final now = DateTime.now();
    final deltaTime = _lastUpdateTime != null 
        ? (now.difference(_lastUpdateTime!).inMicroseconds / 1000000.0).clamp(0.001, 0.1)
        : 0.016;
    _lastUpdateTime = now;
    
    _smoothAccelX += (event.x - _smoothAccelX) * _smoothFactor;
    _smoothAccelY += (event.y - _smoothAccelY) * _smoothFactor;
    _smoothAccelZ += (event.z - _smoothAccelZ) * _smoothFactor;
    
    final rawMagnitude = math.sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );
    _magnitudeHistory.add(rawMagnitude);
    if (_magnitudeHistory.length > _historySize) {
      _magnitudeHistory.removeAt(0);
    }
    
    final peakMagnitude = _magnitudeHistory.isNotEmpty
        ? _magnitudeHistory.reduce(math.max)
        : rawMagnitude;
    _detectShake(peakMagnitude);
    
    _updatePhysics(_smoothAccelX, _smoothAccelY, _smoothAccelZ, deltaTime);
  }

  void _updatePhysics(double accelX, double accelY, double accelZ, double deltaTime) {
    _velocityX += accelX * _sensitivity * deltaTime * 60.0;
    _velocityY += accelY * _sensitivity * deltaTime * 60.0;
    _velocityZ += accelZ * _sensitivity * deltaTime * 60.0;
    
    final speed = math.sqrt(_velocityX * _velocityX + _velocityY * _velocityY + _velocityZ * _velocityZ);
    if (speed > _maxVelocity) {
      final scale = _maxVelocity / speed;
      _velocityX *= scale;
      _velocityY *= scale;
      _velocityZ *= scale;
    }
    
    _velocityX *= _friction;
    _velocityY *= _friction;
    _velocityZ *= _friction;
    
    if (speed < 0.01) {
      _velocityX += (math.Random().nextDouble() - 0.5) * _idleMovement;
      _velocityY += (math.Random().nextDouble() - 0.5) * _idleMovement;
      _velocityZ += (math.Random().nextDouble() - 0.5) * _idleMovement;
    }
    
    _positionX += _velocityX * deltaTime * 60.0;
    _positionY += _velocityY * deltaTime * 60.0;
    _positionZ += _velocityZ * deltaTime * 60.0;
    
    _applyBorderSpring(_positionX, _velocityX, _borderLimit, (newPos, newVel) {
      _positionX = newPos;
      _velocityX = newVel;
    });
    _applyBorderSpring(_positionY, _velocityY, _borderLimit, (newPos, newVel) {
      _positionY = newPos;
      _velocityY = newVel;
    });
    _applyBorderSpring(_positionZ, _velocityZ, _borderLimit, (newPos, newVel) {
      _positionZ = newPos;
      _velocityZ = newVel;
    });
    
    onPositionChanged?.call(_positionX, _positionY, _positionZ);
  }

  void _applyBorderSpring(double position, double velocity, double limit, Function(double, double) onUpdate) {
    if (position > limit) {
      final overshoot = position - limit;
      velocity -= overshoot * _springForce;
      position = limit;
      if (velocity > 0) velocity *= -0.4;
      onUpdate(position, velocity);
    } else if (position < -limit) {
      final overshoot = -limit - position;
      velocity += overshoot * _springForce;
      position = -limit;
      if (velocity < 0) velocity *= -0.4;
      onUpdate(position, velocity);
    }
  }

  void _detectShake(double magnitude) {
    if (_isInCoolDown) return;

    final now = DateTime.now();
    
    if (_lastShakeTime == null || now.difference(_lastShakeTime!).inSeconds > 60) {
      _shakeCount = 0;
    }

    final timeSinceLastShake = _lastShakeTime == null
        ? _shakeDebounce + 1
        : now.difference(_lastShakeTime!).inMilliseconds.toDouble();

    if (magnitude > _shakeThreshold && 
        timeSinceLastShake > _shakeDebounce && 
        _shakeCount < _maxShakesPerMinute) {
      if (!_isShaking) {
        _isShaking = true;
        _shakeCount++;
        _lastShakeTime = now;
        HapticFeedback.mediumImpact();
        onShakeDetected?.call(magnitude);
        if (_shakeCount >= _maxShakesPerMinute) {
          _startCoolDown();
        }
      }
    } else if (magnitude < _shakeThreshold * 0.3 && _isShaking) {
      _isShaking = false;
      onShakeEnded?.call();
    }
  }

  void _startCoolDown() {
    _isInCoolDown = true;
    _shakeCoolDownTimer?.cancel();
    _shakeCoolDownTimer = Timer(const Duration(seconds: 20), () {
      _isInCoolDown = false;
      _shakeCount = 0;
    });
  }

  void resetPosition() {
    _positionX = 0.0;
    _positionY = 0.0;
    _positionZ = 0.0;
    _velocityX = 0.0;
    _velocityY = 0.0;
    _velocityZ = 0.0;
    _smoothAccelX = 0.0;
    _smoothAccelY = 0.0;
    _smoothAccelZ = 0.0;
    _magnitudeHistory.clear();
  }

  bool get isListening => _accelerometerSubscription != null;
  bool get isShaking => _isShaking;

  void dispose() {
    stopListening();
    _shakeCoolDownTimer?.cancel();
    onPositionChanged = null;
    onShakeDetected = null;
    onShakeEnded = null;
  }

  void stopListening() {
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
  }
}