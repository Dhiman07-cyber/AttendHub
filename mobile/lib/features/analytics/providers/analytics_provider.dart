import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/local_storage.dart';
import '../../../shared/models/analytics_model.dart';

final analyticsProvider = FutureProvider<AnalyticsOverviewModel>((ref) async {
  final client = ApiClient();
  final storage = LocalStorage();
  try {
    final resp = await client.dio.get(ApiEndpoints.analytics);
    if (resp.statusCode == 200 && resp.data is Map) {
      final dataMap = Map<String, dynamic>.from(resp.data as Map);
      await storage.saveCachedAnalytics(dataMap);
      return AnalyticsOverviewModel.fromJson(dataMap);
    }
    throw Exception('Failed to load analytics: ${resp.statusCode}');
  } catch (e) {
    final cached = await storage.getCachedAnalytics();
    if (cached != null) {
      return AnalyticsOverviewModel.fromJson(cached);
    }
    rethrow;
  }
});
