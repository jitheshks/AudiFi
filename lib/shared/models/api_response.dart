/// Standard wrapper for Audius REST API responses as documented in `references/api/api.json`.
class ApiResponse<T> {
  const ApiResponse({
    required this.data,
    this.signature,
    this.timestamp,
    this.latestChainBlock,
    this.latestIndexedBlock,
  });

  /// The primary payload data.
  final T data;

  /// Optional cryptographic signature provided by the indexed node.
  final String? signature;

  /// Timestamp of the indexed block.
  final String? timestamp;

  /// Latest blockchain block height at query time.
  final int? latestChainBlock;

  /// Latest indexed block height at query time.
  final int? latestIndexedBlock;

  /// Deserializes a raw JSON map into an [ApiResponse] with custom data parser.
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic data) dataParser,
  ) {
    return ApiResponse<T>(
      data: dataParser(json['data']),
      signature: json['signature'] as String?,
      timestamp: json['timestamp'] as String?,
      latestChainBlock: json['latest_chain_block'] as int?,
      latestIndexedBlock: json['latest_indexed_block'] as int?,
    );
  }

  @override
  String toString() => 'ApiResponse(data: $data, timestamp: $timestamp)';
}
