import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../shared/models/analytics_model.dart';

final analyticsProvider = FutureProvider<AnalyticsOverviewModel>((ref) async {
  final client = ApiClient();
  final resp = await client.dio.get(ApiEndpoints.analytics);
  if (resp.statusCode == 200) {
    return AnalyticsOverviewModel.fromJson(resp.data);
  }
  throw Exception('Failed to load analytics: ${resp.statusCode}');
});
