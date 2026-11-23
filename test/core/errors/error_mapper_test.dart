import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:audifi/core/errors/app_exception.dart';
import 'package:audifi/core/errors/error_mapper.dart';
import 'package:audifi/core/errors/failure.dart';

void main() {
  group('ErrorMapper Exception Mapping', () {
    test('maps Dio connection timeouts to TimeoutException', () {
      final dioErr = DioException(
        requestOptions: RequestOptions(path: '/tracks'),
        type: DioExceptionType.connectionTimeout,
      );

      final exception = ErrorMapper.mapToException(dioErr);
      expect(exception, isA<TimeoutException>());
      expect(exception.message, contains('timed out'));
    });

    test('maps Dio connection error to NetworkException', () {
      final dioErr = DioException(
        requestOptions: RequestOptions(path: '/tracks'),
        type: DioExceptionType.connectionError,
        message: 'Failed host lookup',
      );

      final exception = ErrorMapper.mapToException(dioErr);
      expect(exception, isA<NetworkException>());
    });

    test('maps HTTP status codes to corresponding AppExceptions', () {
      DioException createHttpError(int statusCode) {
        return DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.badResponse,
          response: Response(
            statusCode: statusCode,
            requestOptions: RequestOptions(path: '/test'),
            data: {'error': 'Detail for $statusCode'},
          ),
        );
      }

      expect(
        ErrorMapper.mapToException(createHttpError(400)),
        isA<BadRequestException>(),
      );
      expect(
        ErrorMapper.mapToException(createHttpError(401)),
        isA<UnauthorizedException>(),
      );
      expect(
        ErrorMapper.mapToException(createHttpError(403)),
        isA<ForbiddenException>(),
      );
      expect(
        ErrorMapper.mapToException(createHttpError(404)),
        isA<NotFoundException>(),
      );
      expect(
        ErrorMapper.mapToException(createHttpError(429)),
        isA<RateLimitException>(),
      );
      expect(
        ErrorMapper.mapToException(createHttpError(500)),
        isA<ServerException>(),
      );
      expect(
        ErrorMapper.mapToException(createHttpError(503)),
        isA<ServerException>(),
      );
    });

    test('maps SocketException to NetworkException', () {
      const socketErr = SocketException('No internet');
      final exception = ErrorMapper.mapToException(socketErr);

      expect(exception, isA<NetworkException>());
    });

    test('maps FormatException and TypeError to ParsingException', () {
      const formatErr = FormatException('Invalid JSON payload');
      final typeErr = TypeError();

      expect(ErrorMapper.mapToException(formatErr), isA<ParsingException>());
      expect(ErrorMapper.mapToException(typeErr), isA<ParsingException>());
    });

    test('maps unknown exceptions to UnknownException', () {
      final unknownErr = Exception('Something arbitrary');
      final exception = ErrorMapper.mapToException(unknownErr);

      expect(exception, isA<UnknownException>());
    });

    test('passes existing AppException through unchanged', () {
      const customEx = NotFoundException(message: 'Item missing');
      final result = ErrorMapper.mapToException(customEx);

      expect(identical(result, customEx), isTrue);
    });
  });

  group('ErrorMapper Failure Mapping', () {
    test(
      'maps NetworkException and TimeoutException to user-friendly failures',
      () {
        const netEx = NetworkException(message: 'Connection reset');
        const timeEx = TimeoutException(message: 'Timed out');

        expect(ErrorMapper.mapToFailure(netEx), isA<NetworkFailure>());
        expect(ErrorMapper.mapToFailure(timeEx), isA<TimeoutFailure>());
      },
    );

    test('maps 404 NotFoundException to NotFoundFailure', () {
      const notFoundEx = NotFoundException(message: 'Track not found');
      final failure = ErrorMapper.mapToFailure(notFoundEx);

      expect(failure, isA<NotFoundFailure>());
      expect(failure.code, 'not_found');
      expect(failure.message, 'The requested content could not be found.');
    });

    test('maps 429 RateLimitException to RateLimitFailure', () {
      const rateLimitEx = RateLimitException(message: 'Too many requests');
      final failure = ErrorMapper.mapToFailure(rateLimitEx);

      expect(failure, isA<RateLimitFailure>());
    });

    test('maps direct DioException directly to safe Failure', () {
      final dioErr = DioException(
        requestOptions: RequestOptions(path: '/search'),
        type: DioExceptionType.receiveTimeout,
      );

      final failure = ErrorMapper.mapToFailure(dioErr);
      expect(failure, isA<TimeoutFailure>());
    });
  });
}
