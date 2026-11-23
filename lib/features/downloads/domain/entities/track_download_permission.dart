/// Represents creator-authorized download permission states.
enum TrackDownloadPermission {
  /// Creator has explicitly authorized free public downloads.
  authorized,

  /// Creator has disabled downloads for this track.
  disabled,

  /// Download is restricted behind an access gate (purchase, NFT, follow).
  gated,

  /// Permission is actively being queried from the remote API.
  checking,

  /// Network or API error occurred while checking permissions.
  error,
}

extension TrackDownloadPermissionX on TrackDownloadPermission {
  bool get isAuthorized => this == TrackDownloadPermission.authorized;
  bool get isDisabled => this == TrackDownloadPermission.disabled;
  bool get isGated => this == TrackDownloadPermission.gated;
  bool get isChecking => this == TrackDownloadPermission.checking;
  bool get isError => this == TrackDownloadPermission.error;

  /// User-facing descriptive reason for the permission state.
  String get statusMessage {
    switch (this) {
      case TrackDownloadPermission.authorized:
        return 'Download available';
      case TrackDownloadPermission.disabled:
        return "Downloads aren't available for this track.";
      case TrackDownloadPermission.gated:
        return 'This download requires creator access.';
      case TrackDownloadPermission.checking:
        return 'Checking download permissions…';
      case TrackDownloadPermission.error:
        return 'Unable to verify download permission';
    }
  }

  /// Concise user-facing explanation for the permission state.
  String get explanation => statusMessage;

  /// Short action/button title for the permission state.
  String get actionTitle {
    switch (this) {
      case TrackDownloadPermission.authorized:
        return 'Download';
      case TrackDownloadPermission.disabled:
        return 'Download Unavailable';
      case TrackDownloadPermission.gated:
        return 'Download Gated';
      case TrackDownloadPermission.checking:
        return 'Checking Permissions…';
      case TrackDownloadPermission.error:
        return 'Retry Permission Check';
    }
  }
}
