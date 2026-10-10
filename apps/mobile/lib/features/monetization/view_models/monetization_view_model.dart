import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../models/ad_and_monetization_models.dart';

class MonetizationViewModel extends ChangeNotifier {
  final ApiClient _apiClient;

  MonetizationSummary? _summary;
  List<AdCampaign> _myCampaigns = [];
  bool _isLoading = false;
  String? _errorMessage;

  MonetizationViewModel({required ApiClient apiClient}) : _apiClient = apiClient;

  MonetizationSummary? get summary => _summary;
  List<AdCampaign> get myCampaigns => _myCampaigns;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchSummary() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _apiClient.get('/monetization/summary');
      _summary = MonetizationSummary.fromJson(res);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> buyPremium() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiClient.post('/profiles/premium/buy', {});
      await fetchSummary();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> applyForMonetization() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiClient.post('/monetization/apply', {});
      await fetchSummary();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> requestPayout({
    required int amountCents,
    required String method,
    required String account,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiClient.post('/monetization/payouts', {
        'amountCents': amountCents,
        'method': method,
        'account': account,
      });
      await fetchSummary();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> createCampaign({
    required String videoId,
    required String name,
    required String headline,
    required String ctaUrl,
    required String ctaLabel,
    required int budgetCents,
    required int cpmBidCents,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _apiClient.post('/ads/campaigns', {
        'videoId': videoId,
        'name': name,
        'headline': headline,
        'callToActionUrl': ctaUrl,
        'callToActionLabel': ctaLabel,
        'budgetCents': budgetCents,
        'cpmBidCents': cpmBidCents,
      });
      final camp = AdCampaign.fromJson(res);
      _myCampaigns.insert(0, camp);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
