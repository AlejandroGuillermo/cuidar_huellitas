import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/disaster_repository.dart';
import '../../data/repositories/mission_repository.dart';
import '../../domain/entities/pending_disaster.dart';
import '../../domain/entities/pending_mission.dart';

class MissionState {
  final bool isLoading;
  final bool hasLoadedOnce;
  final List<PendingMission> missions;
  final List<PendingDisaster> disasters;

  const MissionState({
    this.isLoading = false,
    this.hasLoadedOnce = false,
    this.missions = const [],
    this.disasters = const [],
  });

  MissionState copyWith({
    bool? isLoading,
    bool? hasLoadedOnce,
    List<PendingMission>? missions,
    List<PendingDisaster>? disasters,
  }) {
    return MissionState(
      isLoading: isLoading ?? this.isLoading,
      hasLoadedOnce: hasLoadedOnce ?? this.hasLoadedOnce,
      missions: missions ?? this.missions,
      disasters: disasters ?? this.disasters,
    );
  }
}

class MissionCubit extends Cubit<MissionState> {
  final MissionRepository _missionRepository;
  final DisasterRepository _disasterRepository;
  StreamSubscription<List<PendingMission>>? _missionsSub;
  StreamSubscription<List<PendingDisaster>>? _disastersSub;
  String? _activeMascotaId;

  List<PendingMission> _latestMissions = const [];
  List<PendingDisaster> _latestDisasters = const [];
  bool _receivedMissions = false;
  bool _receivedDisasters = false;

  MissionCubit({
    required MissionRepository missionRepository,
    required DisasterRepository disasterRepository,
  }) : _missionRepository = missionRepository,
       _disasterRepository = disasterRepository,
       super(const MissionState());

  Future<void> hydrate(String mascotaId) async {
    if (mascotaId.isEmpty) {
      await _stopWatching();
      emit(const MissionState(isLoading: false));
      return;
    }

    if (_activeMascotaId == mascotaId &&
        _missionsSub != null &&
        _disastersSub != null) {
      return;
    }

    await _startWatching(mascotaId);
  }

  Future<void> _startWatching(String mascotaId) async {
    await _stopWatching();
    _activeMascotaId = mascotaId;
    _latestMissions = const [];
    _latestDisasters = const [];
    _receivedMissions = false;
    _receivedDisasters = false;

    emit(
      state.copyWith(
        isLoading: true,
        hasLoadedOnce: false,
        missions: const [],
        disasters: const [],
      ),
    );

    _missionsSub = _missionRepository
        .watchPending(mascotaId)
        .listen(
          (missions) {
            _latestMissions = missions;
            _receivedMissions = true;
            _emitLatestSnapshot();
          },
          onError: (_) {
            _receivedMissions = true;
            _emitLatestSnapshot();
          },
        );

    _disastersSub = _disasterRepository
        .watchPending(mascotaId)
        .listen(
          (disasters) {
            _latestDisasters = disasters;
            _receivedDisasters = true;
            _emitLatestSnapshot();
          },
          onError: (_) {
            _receivedDisasters = true;
            _emitLatestSnapshot();
          },
        );
  }

  void _emitLatestSnapshot() {
    final hasLoadedOnce = _receivedMissions && _receivedDisasters;
    emit(
      state.copyWith(
        isLoading: !hasLoadedOnce,
        hasLoadedOnce: hasLoadedOnce,
        missions: _latestMissions,
        disasters: _latestDisasters,
      ),
    );
  }

  Future<void> _stopWatching() async {
    await _missionsSub?.cancel();
    await _disastersSub?.cancel();
    _missionsSub = null;
    _disastersSub = null;
    _activeMascotaId = null;
  }

  Future<void> reset() async {
    await _stopWatching();
    _latestMissions = const [];
    _latestDisasters = const [];
    _receivedMissions = false;
    _receivedDisasters = false;
    emit(const MissionState());
  }

  @override
  Future<void> close() async {
    await _stopWatching();
    return super.close();
  }
}
