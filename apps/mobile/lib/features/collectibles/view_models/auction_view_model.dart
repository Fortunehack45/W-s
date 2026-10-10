import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../models/auction_models.dart';

class AuctionViewModel extends ChangeNotifier {
  final ApiClient _apiClient;

  List<AuctionListingItem> _activeListings = [];
  bool _isLoading = false;
  String? _errorMessage;

  AuctionViewModel({required ApiClient apiClient}) : _apiClient = apiClient;

  List<AuctionListingItem> get activeListings => _activeListings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchActiveAuctions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _apiClient.get('/auctions/active');
      final list = (res['listings'] as List<dynamic>?)
              ?.map((e) => AuctionListingItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      _activeListings = list;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createListing({
    required String cardInstanceId,
    required int minimumBidW,
    required int durationMinutes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiClient.post('/auctions/listings', {
        'cardInstanceId': cardInstanceId,
        'minimumBidW': minimumBidW,
        'durationMinutes': durationMinutes,
        'feePercentage': 5.0,
      });
      await fetchActiveAuctions();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> placeBid({
    required String listingId,
    required int bidAmountW,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiClient.post('/auctions/$listingId/bid', {
        'bidAmountW': bidAmountW,
      });
      await fetchActiveAuctions();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> settleAuction(String listingId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiClient.post('/auctions/$listingId/settle', {});
      await fetchActiveAuctions();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
