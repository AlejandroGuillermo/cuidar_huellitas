class BanarState {
  const BanarState({
    this.petInTub = false,
    this.dragOffset = 0,
    this.draggingBathTool = false,
    this.activeDraggedToolLabel,
    this.soapProgress = 0,
    this.soapProgressRaw = 0,
    this.scrubProgress = 0,
    this.scrubProgressRaw = 0,
    this.rinseProgress = 0,
    this.rinseProgressRaw = 0,
    this.towelProgress = 0,
    this.towelProgressRaw = 0,
    this.bathStatusMessage,
    this.petTubOffsetX = 0,
    this.petTubOffsetY = 0,
    this.petIsCalm = false,
    this.calmProgress = 0,
    this.calmProgressRaw = 0,
    this.toolResetNonce = 0,
    this.bathEscapeCount = 0,
  });

  final bool petInTub;
  final double dragOffset;
  final bool draggingBathTool;
  final String? activeDraggedToolLabel;
  final int soapProgress;
  final double soapProgressRaw;
  final int scrubProgress;
  final double scrubProgressRaw;
  final int rinseProgress;
  final double rinseProgressRaw;
  final int towelProgress;
  final double towelProgressRaw;
  final String? bathStatusMessage;
  final double petTubOffsetX;
  final double petTubOffsetY;
  final bool petIsCalm;
  final int calmProgress;
  final double calmProgressRaw;
  final int toolResetNonce;
  final int bathEscapeCount;

  bool get hasBathProgress =>
      soapProgressRaw > 0 ||
      scrubProgressRaw > 0 ||
      rinseProgressRaw > 0 ||
      towelProgressRaw > 0;

  bool get hasSoapApplied => soapProgressRaw > 0;
  bool get hasScrubbed => scrubProgressRaw > 0;
  bool get hasRinsed => rinseProgressRaw > 0;
  bool get canUseTowel =>
      (hasSoapApplied || hasRinsed) &&
      hasScrubbed &&
      hasRinsed &&
      rinseProgress >= 100 &&
      soapProgress == 0;

  String buildStepStatusText({required bool requiresCalmingBeforeTools}) {
    if (requiresCalmingBeforeTools && !petIsCalm) {
      return calmProgress > 0
          ? 'Acariciala para poder banarla $calmProgress%.'
          : 'Acariciala para que se deje banar.';
    }

    if (towelProgress > 0) {
      if (towelProgress >= 100) {
        return 'Bano completado.';
      }
      return 'Sigue secando con la toalla.';
    }

    if (rinseProgress > 0) {
      if (rinseProgress >= 100 && soapProgress == 0) {
        return 'Siguiente paso: seca con la toalla.';
      }
      return 'Sigue usando la manguera.';
    }

    if (scrubProgress > 0) {
      if (scrubProgress >= 100) {
        return 'Siguiente paso: enjuaga con la manguera.';
      }
      return 'Sigue tallando con el estropajo.';
    }

    if (soapProgress >= 100) {
      return 'Siguiente paso: talla con el estropajo.';
    }

    return 'Sigue aplicando jabon.';
  }

  BanarState copyWith({
    bool? petInTub,
    double? dragOffset,
    bool? draggingBathTool,
    Object? activeDraggedToolLabel = _sentinel,
    int? soapProgress,
    double? soapProgressRaw,
    int? scrubProgress,
    double? scrubProgressRaw,
    int? rinseProgress,
    double? rinseProgressRaw,
    int? towelProgress,
    double? towelProgressRaw,
    Object? bathStatusMessage = _sentinel,
    double? petTubOffsetX,
    double? petTubOffsetY,
    bool? petIsCalm,
    int? calmProgress,
    double? calmProgressRaw,
    int? toolResetNonce,
    int? bathEscapeCount,
  }) {
    return BanarState(
      petInTub: petInTub ?? this.petInTub,
      dragOffset: dragOffset ?? this.dragOffset,
      draggingBathTool: draggingBathTool ?? this.draggingBathTool,
      activeDraggedToolLabel: activeDraggedToolLabel == _sentinel
          ? this.activeDraggedToolLabel
          : activeDraggedToolLabel as String?,
      soapProgress: soapProgress ?? this.soapProgress,
      soapProgressRaw: soapProgressRaw ?? this.soapProgressRaw,
      scrubProgress: scrubProgress ?? this.scrubProgress,
      scrubProgressRaw: scrubProgressRaw ?? this.scrubProgressRaw,
      rinseProgress: rinseProgress ?? this.rinseProgress,
      rinseProgressRaw: rinseProgressRaw ?? this.rinseProgressRaw,
      towelProgress: towelProgress ?? this.towelProgress,
      towelProgressRaw: towelProgressRaw ?? this.towelProgressRaw,
      bathStatusMessage: bathStatusMessage == _sentinel
          ? this.bathStatusMessage
          : bathStatusMessage as String?,
      petTubOffsetX: petTubOffsetX ?? this.petTubOffsetX,
      petTubOffsetY: petTubOffsetY ?? this.petTubOffsetY,
      petIsCalm: petIsCalm ?? this.petIsCalm,
      calmProgress: calmProgress ?? this.calmProgress,
      calmProgressRaw: calmProgressRaw ?? this.calmProgressRaw,
      toolResetNonce: toolResetNonce ?? this.toolResetNonce,
      bathEscapeCount: bathEscapeCount ?? this.bathEscapeCount,
    );
  }

  static const Object _sentinel = Object();
}
