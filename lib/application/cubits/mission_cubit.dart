import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/disaster_repository.dart';
import '../../data/repositories/mission_repository.dart';
import '../../domain/entities/pending_disaster.dart';
import '../../domain/entities/pending_mission.dart';

class MissionState {
  final bool isLoading;
  final List<PendingMission> missions;
  final List<PendingDisaster> disasters;

  const MissionState({
    this.isLoading = false,
    this.missions = const [],
    this.disasters = const [],
  });

  MissionState copyWith({
    bool? isLoading,
    List<PendingMission>? missions,
    List<PendingDisaster>? disasters,
  }) {
    return MissionState(
      isLoading: isLoading ?? this.isLoading,
      missions: missions ?? this.missions,
      disasters: disasters ?? this.disasters,
    );
  }
}

class MissionCubit extends Cubit<MissionState> {
  final MissionRepository _missionRepository;
  final DisasterRepository _disasterRepository;

  MissionCubit({
    required MissionRepository missionRepository,
    required DisasterRepository disasterRepository,
  }) : _missionRepository = missionRepository,
       _disasterRepository = disasterRepository,
       super(const MissionState());

  Future<void> hydrate(String mascotaId) async {
    if (mascotaId.isEmpty) {
      emit(const MissionState(isLoading: false));
      return;
    }

    emit(state.copyWith(isLoading: true));
    final missions = await _missionRepository.loadPending(mascotaId);
    final disasters = await _disasterRepository.loadPending(mascotaId);
    emit(
      state.copyWith(
        isLoading: false,
        missions: missions,
        disasters: disasters,
      ),
    );
  }
}
