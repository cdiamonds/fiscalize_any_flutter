enum ImportStep {
  idle,
  reading,
  extracting,
  fiscalizing,
  stamping,
  saving,
  done,
  error,
}

extension ImportStepX on ImportStep {
  String get label {
    switch (this) {
      case ImportStep.reading:     return 'Reading document';
      case ImportStep.extracting:  return 'Extracting invoice text';
      case ImportStep.fiscalizing: return 'Fiscalizing with ZIMRA';
      case ImportStep.stamping:    return 'Stamping fiscal data';
      case ImportStep.saving:      return 'Saving document';
      case ImportStep.done:        return 'Complete';
      case ImportStep.error:       return 'Error';
      case ImportStep.idle:        return '';
    }
  }

  bool get isTerminal => this == ImportStep.done || this == ImportStep.error;
  bool get isActive => this != ImportStep.idle && this != ImportStep.done && this != ImportStep.error;

  static ImportStep fromString(String s) {
    switch (s) {
      case 'reading':     return ImportStep.reading;
      case 'extracting':  return ImportStep.extracting;
      case 'fiscalizing': return ImportStep.fiscalizing;
      case 'stamping':    return ImportStep.stamping;
      case 'saving':      return ImportStep.saving;
      case 'done':        return ImportStep.done;
      case 'error':       return ImportStep.error;
      default:            return ImportStep.idle;
    }
  }
}

class ImportProgress {
  final ImportStep step;
  final String label;
  final String? error;

  const ImportProgress({required this.step, required this.label, this.error});

  factory ImportProgress.fromMap(Map<Object?, Object?> map) => ImportProgress(
    step: ImportStepX.fromString((map['step'] as String?) ?? ''),
    label: (map['label'] as String?) ?? '',
    error: map['error'] as String?,
  );
}
