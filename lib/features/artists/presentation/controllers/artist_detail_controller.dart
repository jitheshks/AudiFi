import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_exceptions.dart';
import '../../../tracks/data/repositories/track_repository_impl.dart';
import '../../../tracks/domain/entities/track.dart';
import '../../../tracks/domain/repositories/track_repository.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';

/// Aggregated state containing an artist profile and their published tracks.
class ArtistDetailState {
  const ArtistDetailState({required this.user, required this.tracks});

  /// The artist's public user profile.
  final User user;

  /// List of tracks created by the artist.
  final List<Track> tracks;
}

/// Riverpod FutureProvider family fetching artist profile and tracks.
final artistDetailProvider = FutureProvider.autoDispose
    .family<ArtistDetailState, String>((ref, userId) async {
      final UserRepository userRepo = ref.watch(userRepositoryProvider);
      final TrackRepository trackRepo = ref.watch(trackRepositoryProvider);

      final user = await userRepo.getUser(userId);
      if (user == null) {
        throw const ApiException(
          message: 'Artist not found',
          type: ApiExceptionType.notFound,
          statusCode: 404,
        );
      }

      final tracks = await trackRepo.getUserTracks(userId);
      return ArtistDetailState(user: user, tracks: tracks);
    });

/// Riverpod FutureProvider family fetching related/similar artists for a user ID.
final relatedArtistsProvider = FutureProvider.autoDispose
    .family<List<User>, String>((ref, userId) async {
      final UserRepository userRepo = ref.watch(userRepositoryProvider);
      return userRepo.getRelatedUsers(userId);
    });
