import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../shared/models/user_model.dart';

final profileProvider = FutureProvider<AcademicProfileModel>((ref) async {
  final client = ApiClient();
  final resp = await client.dio.get(ApiEndpoints.profile);
  if (resp.statusCode == 200) {
    return AcademicProfileModel.fromJson(resp.data);
  }
  throw Exception('Failed to load profile: ${resp.statusCode}');
});
