import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/feature_flags/feature_flags.dart';

final featureFlagsProvider = Provider<FeatureFlags>((ref) => FeatureFlags());
