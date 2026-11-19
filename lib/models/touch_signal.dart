enum TouchSignal { waiting, detected, completed, interrupted }

extension TouchSignalText on TouchSignal {
  String get label {
    switch (this) {
      case TouchSignal.waiting:
        return 'Screen touch not detected yet';
      case TouchSignal.detected:
        return 'Finger contact detected';
      case TouchSignal.completed:
        return 'Touch detected on the last demo scan';
      case TouchSignal.interrupted:
        return 'Contact ended before the demo scan finished';
    }
  }
}
