import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class SensorService {
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;

  Function(double x, double y)? onPositionChanged;
  Function(double intensity)? onShakeDetected;
  
  // ValueNotifiers para estados reactivos
  final ValueNotifier<bool> isShakingActive = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isDeviceMoving = ValueNotifier<bool>(false);

  // Posición normalizada (-1.0 a 1.0)
  double _positionX = 0.0;
  double _positionY = 0.0;

  // Velocidad
  double _velocityX = 0.0;
  double _velocityY = 0.0;

  static const double _boundaryLimit = 1.0;
  static const double _friction = 0.80;
  static const double _restThreshold = 0.002;
  static const double _bounceRestitution = 0.15;

  // Gravedad
  double _gravX = 0.0;
  double _gravY = 0.0;
  double _gravZ = 0.0;
  static const double _gravSmooth = 0.03;

  double _rawX = 0.0;
  double _rawY = 0.0;
  double _rawZ = 0.0;

  double _gyroX = 0.0;
  double _gyroZ = 0.0;
  static const double _gyroSmooth = 0.15;
  static const double _gyroDeadzone = 0.12;

  static const double _gyroForce = 0.020;
  static const double _accelForce = 0.006;
  static const double _accelDeadzone = 0.25;

  // Configuración de sacudida
  double _shakeThreshold = 15.0;
  
  // === ESTADO DE SACUDIDA CONTINUA ===
  Timer? _shakeEndTimer;
  
  // Valores para cálculo de movimiento
  double _lastMagnitude = 0.0;
  final List<double> _recentMagnitudes = [];
  final List<double> _recentGyroX = [];
  final List<double> _recentGyroZ = [];
  
  // Umbrales
  static const double _motionThreshold = 0.9;
  static const double _gyroMotionThreshold = 0.18;
  static const int _historySizeForMotion = 4;
  static const double _motionRatioRequired = 0.65;
  static const int _shakeEndDelayMs = 800; // Aumentado para mejor detección
  
  // Para quietud de la bola
  bool _deviceIsStill = true;
  DateTime? _lastMotionTime;
  static const int _stillTimeoutMs = 900;

  Timer? _physicsTimer;
  bool _isRunning = false;

  bool get isListening => _isRunning;

  void setShakeSensitivity(double sensitivity) {
    _shakeThreshold = 22.0 - (sensitivity * 12.0);
    _shakeThreshold = _shakeThreshold.clamp(9.0, 22.0);
  }

  void startListening() {
    if (_isRunning) return;
    _isRunning = true;
    _physicsTimer = Timer.periodic(
      const Duration(milliseconds: 16),
      (_) => _stepPhysics(),
    );
    _accelerometerSubscription =
        accelerometerEvents.listen(_onAccelerometerEvent);
    _gyroscopeSubscription =
        gyroscopeEvents.listen(_onGyroscopeEvent);
  }

  void stopListening() {
    _isRunning = false;
    _physicsTimer?.cancel();
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _physicsTimer = null;
    _accelerometerSubscription = null;
    _gyroscopeSubscription = null;
    _cancelShakeEndTimer();
    if (isShakingActive.value) {
      isShakingActive.value = false;
    }
    if (isDeviceMoving.value) {
      isDeviceMoving.value = false;
    }
  }

  void resetPosition() {
    _positionX = 0.0;
    _positionY = 0.0;
    _velocityX = 0.0;
    _velocityY = 0.0;
    _lastMotionTime = null;
    _deviceIsStill = true;
    onPositionChanged?.call(0.0, 0.0);
  }

  void dispose() {
    stopListening();
    _cancelShakeEndTimer();
    isShakingActive.dispose();
    isDeviceMoving.dispose();
    onPositionChanged = null;
    onShakeDetected = null;
  }

  void _cancelShakeEndTimer() {
    _shakeEndTimer?.cancel();
    _shakeEndTimer = null;
  }

  void _onAccelerometerEvent(AccelerometerEvent event) {
    if (!_isRunning) return;

    _rawX = event.x;
    _rawY = event.y;
    _rawZ = event.z;

    _gravX += (event.x - _gravX) * _gravSmooth;
    _gravY += (event.y - _gravY) * _gravSmooth;
    _gravZ += (event.z - _gravZ) * _gravSmooth;

    final rawMag = math.sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );
    
    _updateShakingState(rawMag);
    _detectShakeEvent(rawMag);
    _updateStillState(rawMag);
  }

  void _onGyroscopeEvent(GyroscopeEvent event) {
    if (!_isRunning) return;
    _gyroX += (event.x - _gyroX) * _gyroSmooth;
    _gyroZ += (event.z - _gyroZ) * _gyroSmooth;
  }

  void _updateShakingState(double magnitude) {
    _recentMagnitudes.add(magnitude);
    _recentGyroX.add(_gyroX.abs());
    _recentGyroZ.add(_gyroZ.abs());
    
    while (_recentMagnitudes.length > _historySizeForMotion) {
      _recentMagnitudes.removeAt(0);
    }
    while (_recentGyroX.length > _historySizeForMotion) {
      _recentGyroX.removeAt(0);
      _recentGyroZ.removeAt(0);
    }
    
    bool hasMotion = _hasSignificantMotion();
    
    // Actualizar isDeviceMoving
    if (isDeviceMoving.value != hasMotion) {
      isDeviceMoving.value = hasMotion;
    }
    
    if (hasMotion) {
      _cancelShakeEndTimer();
      
      if (!isShakingActive.value) {
        isShakingActive.value = true;
        HapticFeedback.lightImpact();
      }
    } else {
      if (isShakingActive.value && (_shakeEndTimer == null || !_shakeEndTimer!.isActive)) {
        _shakeEndTimer = Timer(Duration(milliseconds: _shakeEndDelayMs), () {
          if (_isRunning && isShakingActive.value) {
            isShakingActive.value = false;
          }
          _shakeEndTimer = null;
        });
      }
    }
    
    _lastMagnitude = magnitude;
  }
  
  bool _hasSignificantMotion() {
    if (_recentMagnitudes.length < _historySizeForMotion) return false;
    
    int motionFrames = 0;
    
    for (int i = 1; i < _recentMagnitudes.length; i++) {
      final delta = (_recentMagnitudes[i] - _recentMagnitudes[i - 1]).abs();
      if (delta > _motionThreshold) {
        motionFrames++;
      }
    }
    
    for (int i = 0; i < _recentGyroX.length; i++) {
      if (_recentGyroX[i] > _gyroMotionThreshold || 
          _recentGyroZ[i] > _gyroMotionThreshold) {
        motionFrames++;
      }
    }
    
    final totalChecks = (_recentMagnitudes.length - 1) + _recentGyroX.length;
    if (totalChecks == 0) return false;
    
    final motionRatio = motionFrames / totalChecks;
    return motionRatio >= _motionRatioRequired;
  }

  void _detectShakeEvent(double magnitude) {
    if (_recentMagnitudes.length < 2) return;
    
    double maxDelta = 0;
    for (int i = 1; i < _recentMagnitudes.length; i++) {
      final delta = (_recentMagnitudes[i] - _recentMagnitudes[i - 1]).abs();
      if (delta > maxDelta) maxDelta = delta;
    }
    
    if (maxDelta > _shakeThreshold) {
      final intensity = ((maxDelta - _shakeThreshold) / 5.0).clamp(0.3, 1.5);
      HapticFeedback.mediumImpact();
      onShakeDetected?.call(intensity);
    }
  }

  void _stepPhysics() {
    if (!_isRunning) return;

    if (!_deviceIsStill) {
      final linX = _rawX - _gravX;
      final linY = _rawY - _gravY;
      final linZ = _rawZ - _gravZ;

      final screenFX = linX;
      final screenFY = linY * 0.4 + linZ * 0.7;
      final linearMag = math.sqrt(screenFX * screenFX + screenFY * screenFY);

      if (linearMag > _accelDeadzone) {
        _velocityX += screenFX * _accelForce;
        _velocityY += -screenFY * _accelForce;
      }

      if (_gyroX.abs() > _gyroDeadzone) {
        _velocityY += -_gyroX * _gyroForce;
      }
      if (_gyroZ.abs() > _gyroDeadzone) {
        _velocityX += _gyroZ * _gyroForce;
      }
    }

    _velocityX *= _friction;
    _velocityY *= _friction;

    if (_velocityX.abs() < _restThreshold) _velocityX = 0.0;
    if (_velocityY.abs() < _restThreshold) _velocityY = 0.0;

    _positionX += _velocityX;
    _positionY += _velocityY;

    if (_positionX > _boundaryLimit) {
      _positionX = _boundaryLimit;
      _velocityX = -_velocityX.abs() * _bounceRestitution;
    } else if (_positionX < -_boundaryLimit) {
      _positionX = -_boundaryLimit;
      _velocityX = _velocityX.abs() * _bounceRestitution;
    }
    if (_positionY > _boundaryLimit) {
      _positionY = _boundaryLimit;
      _velocityY = -_velocityY.abs() * _bounceRestitution;
    } else if (_positionY < -_boundaryLimit) {
      _positionY = -_boundaryLimit;
      _velocityY = _velocityY.abs() * _bounceRestitution;
    }

    if (_deviceIsStill) {
      _positionX *= 0.95;
      _positionY *= 0.95;
      _velocityX = 0.0;
      _velocityY = 0.0;
    }

    onPositionChanged?.call(_positionX, _positionY);
  }

  void _updateStillState(double rawMag) {
    const double gravity = 9.8;
    final deviation = (rawMag - gravity).abs();
    final gyroActive = _gyroX.abs() > _gyroDeadzone || _gyroZ.abs() > _gyroDeadzone;

    if (deviation > 0.40 || gyroActive) {
      _deviceIsStill = false;
      _lastMotionTime = DateTime.now();
    } else if (_lastMotionTime != null) {
      final elapsed = DateTime.now().difference(_lastMotionTime!).inMilliseconds;
      if (elapsed > _stillTimeoutMs) _deviceIsStill = true;
    } else {
      _deviceIsStill = true;
    }
  }
}