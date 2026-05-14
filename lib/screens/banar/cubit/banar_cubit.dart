import 'package:flutter_bloc/flutter_bloc.dart';

import 'banar_state.dart';

class BathProgressResult {
  const BathProgressResult({
    this.warning,
    this.completed = false,
  });

  final String? warning;
  final bool completed;

  bool get hasWarning => warning != null;
}

class BanarCubit extends Cubit<BanarState> {
  BanarCubit() : super(const BanarState());

  void setDraggingBathTool(bool value) {
    emit(
      state.copyWith(
        draggingBathTool: value,
        dragOffset: value ? 0 : state.dragOffset,
        activeDraggedToolLabel: value ? state.activeDraggedToolLabel : null,
      ),
    );
  }

  void setActiveDraggedToolLabel(String? label) {
    emit(state.copyWith(activeDraggedToolLabel: label));
  }

  void setDragOffset(double value) {
    emit(state.copyWith(dragOffset: value));
  }

  bool canAcceptTool({
    required String? label,
    required bool canUseBathTools,
    required bool applyingBathReward,
  }) {
    if (!state.petInTub || label == null) return false;
    if (!canUseBathTools) return false;
    return label == 'Jabon' ||
        label == 'Estropajo' ||
        label == 'Manguera' ||
        (label == 'Toalla' && state.canUseTowel && !applyingBathReward);
  }

  void enterTub({required bool resetProgress}) {
    emit(
      state.copyWith(
        petInTub: true,
        soapProgress: resetProgress ? 0 : null,
        soapProgressRaw: resetProgress ? 0 : null,
        scrubProgress: resetProgress ? 0 : null,
        scrubProgressRaw: resetProgress ? 0 : null,
        rinseProgress: resetProgress ? 0 : null,
        rinseProgressRaw: resetProgress ? 0 : null,
        towelProgress: resetProgress ? 0 : null,
        towelProgressRaw: resetProgress ? 0 : null,
        petIsCalm: resetProgress ? false : null,
        calmProgress: resetProgress ? 0 : null,
        calmProgressRaw: resetProgress ? 0 : null,
        toolResetNonce: resetProgress ? 0 : null,
        bathEscapeCount: resetProgress ? 0 : null,
        bathStatusMessage: null,
      ),
    );
  }

  void exitTub({bool clearStatus = false}) {
    emit(
      state.copyWith(
        petInTub: false,
        bathStatusMessage: clearStatus ? null : state.bathStatusMessage,
      ),
    );
  }

  void resetPersonalityEffects({bool resetPosition = true}) {
    emit(
      state.copyWith(
        petTubOffsetX: resetPosition ? 0 : null,
        petTubOffsetY: resetPosition ? 0 : null,
        petIsCalm: false,
        calmProgress: 0,
        calmProgressRaw: 0,
      ),
    );
  }

  void movePetInsideTub({required double offsetX, required double offsetY}) {
    emit(state.copyWith(petTubOffsetX: offsetX, petTubOffsetY: offsetY));
  }

  void registerEscape(String message) {
    emit(
      state.copyWith(
        bathEscapeCount: state.bathEscapeCount + 1,
        petInTub: false,
        bathStatusMessage: message,
      ),
    );
  }

  void expireCalm(String message) {
    emit(
      state.copyWith(
        petIsCalm: false,
        calmProgress: 0,
        calmProgressRaw: 0,
        draggingBathTool: false,
        activeDraggedToolLabel: null,
        toolResetNonce: state.toolResetNonce + 1,
        bathStatusMessage: message,
      ),
    );
  }

  void updateCalmProgress({
    required double rawProgress,
    required int steppedProgress,
    required bool petIsCalm,
    required String message,
  }) {
    emit(
      state.copyWith(
        calmProgressRaw: rawProgress,
        calmProgress: steppedProgress,
        petIsCalm: petIsCalm,
        petTubOffsetX: petIsCalm ? 0 : state.petTubOffsetX,
        petTubOffsetY: petIsCalm ? 0 : state.petTubOffsetY,
        bathStatusMessage: message,
      ),
    );
  }

  void increaseSoapProgress(double delta) {
    if (delta <= 0 || state.soapProgress >= 100) return;
    final nextRaw = (state.soapProgressRaw + delta).clamp(0.0, 100.0);
    emit(
      state.copyWith(
        bathStatusMessage: null,
        soapProgressRaw: nextRaw,
        soapProgress: nextRaw.round().clamp(0, 100),
      ),
    );
  }

  void showBathWarning(String message) {
    emit(state.copyWith(bathStatusMessage: message));
  }

  BathProgressResult scrub(double delta) {
    if (delta <= 0) return const BathProgressResult();
    if (state.soapProgressRaw <= 0) {
      return const BathProgressResult(
        warning: 'No uses el estropajo sin jabon. Puedes lastimar a la mascota.',
      );
    }

    final nextRaw = (state.scrubProgressRaw + delta).clamp(0.0, 100.0);
    emit(
      state.copyWith(
        bathStatusMessage: null,
        scrubProgressRaw: nextRaw,
        scrubProgress: nextRaw.round().clamp(0, 100),
      ),
    );
    return const BathProgressResult();
  }

  BathProgressResult rinseSoap(double delta) {
    if (delta <= 0) return const BathProgressResult();
    if (state.scrubProgressRaw <= 0) {
      return const BathProgressResult(
        warning: 'Antes de usar la manguera, talla la suciedad con el estropajo.',
      );
    }
    if (state.soapProgressRaw <= 0) {
      return const BathProgressResult(
        warning: 'Ya no queda jabon por enjuagar.',
      );
    }

    final effectiveDelta = delta.clamp(0.0, state.soapProgressRaw);
    final nextSoapRaw = (state.soapProgressRaw - effectiveDelta).clamp(
      0.0,
      100.0,
    );
    final nextRinseRaw = (state.rinseProgressRaw + effectiveDelta).clamp(
      0.0,
      100.0,
    );
    emit(
      state.copyWith(
        bathStatusMessage: null,
        soapProgressRaw: nextSoapRaw,
        rinseProgressRaw: nextRinseRaw,
        soapProgress: nextSoapRaw.round().clamp(0, 100),
        rinseProgress: nextRinseRaw.round().clamp(0, 100),
      ),
    );
    return const BathProgressResult();
  }

  BathProgressResult dry({
    required double delta,
    required bool applyingBathReward,
  }) {
    if (delta <= 0 || applyingBathReward) return const BathProgressResult();
    if (!state.canUseTowel) {
      return const BathProgressResult(
        warning:
            'La toalla se usa cuando el enjuague este al 100% y ya no quede jabon.',
      );
    }

    final nextRaw = (state.towelProgressRaw + delta).clamp(0.0, 100.0);
    final nextProgress = nextRaw.round().clamp(0, 100);
    emit(
      state.copyWith(
        bathStatusMessage: null,
        towelProgressRaw: nextRaw,
        towelProgress: nextProgress,
      ),
    );
    return BathProgressResult(
      completed: nextRaw >= 100 && nextProgress >= 100,
    );
  }

  void finishBathReward(String message) {
    emit(state.copyWith(bathStatusMessage: message));
  }
}
