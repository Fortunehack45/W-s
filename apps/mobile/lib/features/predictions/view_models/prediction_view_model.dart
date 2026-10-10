import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../models/prediction_models.dart';

class PredictionViewModel extends ChangeNotifier {
  final ApiClient _apiClient;

  List<PredictionMarketItem> _markets = [];
  List<UserPredictionRecord> _myPredictions = [];
  bool _isLoading = false;
  String? _errorMessage;

  PredictionViewModel({required ApiClient apiClient}) : _apiClient = apiClient;

  List<PredictionMarketItem> get markets => _markets;
  List<UserPredictionRecord> get myPredictions => _myPredictions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchMarkets() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _apiClient.get('/predictions/markets');
      final list = (res['markets'] as List<dynamic>?)
              ?.map((e) => PredictionMarketItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      _markets = list;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMyPredictions() async {
    try {
      final res = await _apiClient.get('/predictions/my');
      final list = (res['predictions'] as List<dynamic>?)
              ?.map((e) => UserPredictionRecord.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      _myPredictions = list;
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> placePrediction({
    required String marketId,
    required String optionId,
    required int points,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiClient.post('/predictions/markets/$marketId/predict', {
        'optionId': optionId,
        'points': points,
      });
      await fetchMarkets();
      await fetchMyPredictions();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
