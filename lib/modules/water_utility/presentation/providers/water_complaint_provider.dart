import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/water_complaint.dart';
import '../../domain/repositories/water_complaint_repository.dart';
import '../../data/datasources/water_complaint_local_datasource.dart';
import '../../data/datasources/water_complaint_remote_datasource.dart';
import '../../data/repositories/water_complaint_repository_impl.dart';

final waterComplaintRepositoryProvider = Provider<WaterComplaintRepository>((ref) {
  return WaterComplaintRepositoryImpl(
    remoteDataSource: WaterComplaintRemoteDataSource(),
    localDataSource: WaterComplaintLocalDataSource(),
  );
});

class MyComplaintsNotifier extends StateNotifier<AsyncValue<List<WaterComplaint>>> {
  final WaterComplaintRepository repository;
  MyComplaintsNotifier(this.repository) : super(const AsyncValue.loading());

  Future<void> fetchComplaints({String? status}) async {
    state = const AsyncValue.loading();
    try {
      final complaints = await repository.getMyComplaints(status: status);
      state = AsyncValue.data(complaints);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final myComplaintsProvider = StateNotifierProvider<MyComplaintsNotifier, AsyncValue<List<WaterComplaint>>>((ref) {
  final repository = ref.watch(waterComplaintRepositoryProvider);
  return MyComplaintsNotifier(repository)..fetchComplaints();
});

final complaintDetailsProvider = FutureProvider.family<WaterComplaint, int>((ref, id) {
  final repository = ref.watch(waterComplaintRepositoryProvider);
  return repository.getComplaintDetail(id);
});

class OfflineCountNotifier extends StateNotifier<int> {
  final WaterComplaintRepository repository;
  OfflineCountNotifier(this.repository) : super(0) {
    checkOfflineCount();
  }

  Future<void> checkOfflineCount() async {
    state = await repository.getOfflineCount();
  }

  Future<void> sync() async {
    await repository.syncOfflineComplaints();
    await checkOfflineCount();
  }
}

final offlineCountProvider = StateNotifierProvider<OfflineCountNotifier, int>((ref) {
  final repository = ref.watch(waterComplaintRepositoryProvider);
  return OfflineCountNotifier(repository);
});

class RaiseComplaintNotifier extends StateNotifier<AsyncValue<void>?> {
  final WaterComplaintRepository repository;
  RaiseComplaintNotifier(this.repository) : super(null);

  Future<void> submitComplaint(WaterComplaint complaint) async {
    state = const AsyncValue.loading();
    try {
      await repository.raiseComplaint(complaint);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void reset() {
    state = null;
  }
}

final raiseComplaintProvider = StateNotifierProvider<RaiseComplaintNotifier, AsyncValue<void>?>((ref) {
  final repository = ref.watch(waterComplaintRepositoryProvider);
  return RaiseComplaintNotifier(repository);
});

class AiClassificationState {
  final bool isLoading;
  final String? error;
  final String? predictedIssue;
  final double? confidence;
  final String? suggestedSeverity;

  AiClassificationState({
    this.isLoading = false,
    this.error,
    this.predictedIssue,
    this.confidence,
    this.suggestedSeverity,
  });

  AiClassificationState copyWith({
    bool? isLoading,
    String? error,
    String? predictedIssue,
    double? confidence,
    String? suggestedSeverity,
  }) {
    return AiClassificationState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      predictedIssue: predictedIssue ?? this.predictedIssue,
      confidence: confidence ?? this.confidence,
      suggestedSeverity: suggestedSeverity ?? this.suggestedSeverity,
    );
  }
}

class AiClassificationNotifier extends StateNotifier<AiClassificationState> {
  final WaterComplaintRepository repository;
  AiClassificationNotifier(this.repository) : super(AiClassificationState());

  Future<void> classify(String imagePath) async {
    state = state.copyWith(isLoading: true);
    try {
      final result = await repository.classifyImage(imagePath);
      state = AiClassificationState(
        predictedIssue: result['predicted_issue'] as String,
        confidence: (result['confidence_score'] as num).toDouble(),
        suggestedSeverity: result['severity_suggestion'] as String,
      );
    } catch (e) {
      state = AiClassificationState(error: e.toString());
    }
  }

  void clear() {
    state = AiClassificationState();
  }
}

final aiClassificationProvider = StateNotifierProvider<AiClassificationNotifier, AiClassificationState>((ref) {
  final repository = ref.watch(waterComplaintRepositoryProvider);
  return AiClassificationNotifier(repository);
});
