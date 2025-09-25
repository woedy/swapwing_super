import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:swapwing/config/environment.dart';
import 'package:swapwing/models/listing.dart';
import 'package:swapwing/services/auth_service.dart';
import 'package:swapwing/services/sample_data.dart';

/// Payload used when creating a listing through [ListingService].
class CreateListingRequest {
  final String title;
  final String description;
  final ListingCategory category;
  final List<String> tags;
  final double? estimatedValue;
  final bool isTradeUpEligible;
  final String? location;
  final List<String> mediaFilePaths;
  final List<String> mediaUrls;

  const CreateListingRequest({
    required this.title,
    required this.description,
    required this.category,
    this.tags = const [],
    this.estimatedValue,
    this.isTradeUpEligible = false,
    this.location,
    this.mediaFilePaths = const [],
    this.mediaUrls = const [],
  });

  Map<String, String> toFields() {
    final fields = <String, String>{
      'title': title.trim(),
      'description': description.trim(),
      'category': category.name,
      'is_trade_up_eligible': isTradeUpEligible ? 'true' : 'false',
    };

    if (tags.isNotEmpty) {
      fields['tags'] = jsonEncode(tags);
    }

    if (estimatedValue != null) {
      fields['estimated_value'] = estimatedValue!.toString();
    }

    if (location != null && location!.trim().isNotEmpty) {
      fields['location'] = location!.trim();
    }

    if (mediaUrls.isNotEmpty) {
      fields['media_urls'] = jsonEncode(mediaUrls);
    }

    return fields;
  }
}

class ListingServiceException implements Exception {
  final String message;

  const ListingServiceException(this.message);

  @override
  String toString() => 'ListingServiceException: $message';
}

class ListingService {
  const ListingService();

  Future<List<SwapListing>> fetchListings({
    String? search,
    List<ListingCategory>? categories,
    bool? tradeUpEligible,
    double? minValue,
    double? maxValue,
    String? ordering,
    http.Client? client,
  }) async {
    if (EnvironmentConfig.useMockData) {
      return _fetchMockListings(
        search: search,
        categories: categories,
        tradeUpEligible: tradeUpEligible,
        minValue: minValue,
        maxValue: maxValue,
        ordering: ordering,
      );
    }

    final token = await AuthService.getAuthToken();
    if (token == null || token.isEmpty) {
      throw const ListingServiceException(
        'Sign in to browse live marketplace listings.',
      );
    }

    final querySegments = <String>[];
    void addParam(String key, String value) {
      if (value.isEmpty) return;
      querySegments.add(
        '${Uri.encodeQueryComponent(key)}=${Uri.encodeQueryComponent(value)}',
      );
    }

    if (search != null && search.trim().isNotEmpty) {
      addParam('search', search.trim());
    }
    if (categories != null && categories.isNotEmpty) {
      for (final category in categories) {
        addParam('category', category.name);
      }
    }
    if (tradeUpEligible != null) {
      addParam('trade_up_eligible', tradeUpEligible ? 'true' : 'false');
    }
    if (minValue != null) {
      addParam('min_value', minValue.toString());
    }
    if (maxValue != null) {
      addParam('max_value', maxValue.toString());
    }
    if (ordering != null && ordering.trim().isNotEmpty) {
      addParam('ordering', ordering.trim());
    }

    final baseUrl = EnvironmentConfig.apiBaseUrl;
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final queryString = querySegments.isEmpty ? '' : '?${querySegments.join('&')}';
    final uri = Uri.parse('$normalizedBase/api/listings/$queryString');

    final httpClient = client ?? http.Client();
    late http.Response response;
    try {
      response = await httpClient.get(
        uri,
        headers: {
          'Authorization': 'Token $token',
          'Accept': 'application/json',
        },
      );
    } catch (_) {
      throw const ListingServiceException(
        'Unable to reach the SwapWing marketplace. Check your connection and try again.',
      );
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }

    if (response.statusCode != 200) {
      throw _mapError(response);
    }

    try {
      final decoded = jsonDecode(response.body);
      final rawListings = _extractListings(decoded);
      return rawListings.map(SwapListing.fromApi).toList();
    } catch (_) {
      throw const ListingServiceException(
        'We ran into an issue decoding listings from the server. Please try again shortly.',
      );
    }
  }

  Future<SwapListing> createListing(
    CreateListingRequest request, {
    void Function(double progress)? onUploadProgress,
    http.Client? client,
  }) async {
    onUploadProgress?.call(0.0);

    if (EnvironmentConfig.useMockData) {
      final listing = await _createMockListing(request, onUploadProgress);
      onUploadProgress?.call(1.0);
      return listing;
    }

    final token = await AuthService.getAuthToken();
    if (token == null || token.isEmpty) {
      throw const ListingServiceException(
        'You need to be signed in to publish a listing.',
      );
    }

    final baseUrl = EnvironmentConfig.apiBaseUrl;
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final uri = Uri.parse('$normalizedBase/api/listings/');

    final httpClient = client ?? http.Client();
    try {
      final requestFields = request.toFields();
      final multipartRequest = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Token $token'
        ..fields.addAll(requestFields);

      final mediaPaths = request.mediaFilePaths.where((path) => path.trim().isNotEmpty).toList();
      for (var index = 0; index < mediaPaths.length; index++) {
        final path = mediaPaths[index];
        final file = File(path);
        if (!await file.exists()) {
          continue;
        }
        final multipartFile = await http.MultipartFile.fromPath('media_files', path);
        multipartRequest.files.add(multipartFile);
        final progress = mediaPaths.isEmpty ? 0.2 : ((index + 1) / mediaPaths.length) * 0.6;
        onUploadProgress?.call(progress.clamp(0.0, 0.95));
      }

      final streamedResponse = await multipartRequest.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 201) {
        throw _mapError(response);
      }

      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final listing = SwapListing.fromApi(decoded);
          onUploadProgress?.call(1.0);
          return listing;
        }
        throw const ListingServiceException('Unexpected response from the server while creating listing.');
      } catch (error) {
        if (error is ListingServiceException) rethrow;
        throw const ListingServiceException(
          'Unable to parse listing details from server response.',
        );
      }
    } on ListingServiceException {
      rethrow;
    } catch (_) {
      throw const ListingServiceException(
        'We could not publish your listing right now. Please check your connection and try again.',
      );
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }

  Future<SwapListing> _createMockListing(
    CreateListingRequest request,
    void Function(double progress)? onUploadProgress,
  ) async {
    final owner = SampleData.currentUser;
    final listingOwner = ListingOwner.fromUser(owner);

    final id = 'listing_${DateTime.now().millisecondsSinceEpoch}';
    final normalizedMedia = <String>[
      ...request.mediaUrls,
      ...request.mediaFilePaths
          .where((path) => path.trim().isNotEmpty)
          .map((path) => Uri.file(path).toString()),
    ];

    for (var index = 0; index < normalizedMedia.length; index++) {
      await Future<void>.delayed(const Duration(milliseconds: 220));
      final progress = normalizedMedia.isEmpty
          ? 0.8
          : ((index + 1) / normalizedMedia.length) * 0.8;
      onUploadProgress?.call(progress.clamp(0.0, 0.95));
    }

    await Future<void>.delayed(const Duration(milliseconds: 400));

    final listing = SwapListing(
      id: id,
      ownerId: listingOwner.id,
      owner: listingOwner,
      title: request.title.trim(),
      description: request.description.trim(),
      imageUrls: normalizedMedia,
      category: request.category,
      tags: request.tags,
      estimatedValue: request.estimatedValue,
      isTradeUpEligible: request.isTradeUpEligible,
      location: request.location?.trim().isEmpty ?? true ? null : request.location!.trim(),
      status: ListingStatus.active,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    SampleData.addListing(listing);
    return listing;
  }

  List<SwapListing> _fetchMockListings({
    String? search,
    List<ListingCategory>? categories,
    bool? tradeUpEligible,
    double? minValue,
    double? maxValue,
    String? ordering,
  }) {
    final listings = List<SwapListing>.from(SampleData.getListings());

    Iterable<SwapListing> filtered = listings;

    if (search != null && search.trim().isNotEmpty) {
      final query = search.trim().toLowerCase();
      filtered = filtered.where((listing) {
        final haystack = [
          listing.title,
          listing.description,
          listing.location ?? '',
          ...listing.tags,
        ].join(' ').toLowerCase();
        return haystack.contains(query);
      });
    }

    if (categories != null && categories.isNotEmpty) {
      final categoryNames = categories.map((category) => category.name).toSet();
      filtered = filtered.where((listing) => categoryNames.contains(listing.category.name));
    }

    if (tradeUpEligible != null) {
      filtered = filtered.where((listing) => listing.isTradeUpEligible == tradeUpEligible);
    }

    if (minValue != null) {
      filtered = filtered.where((listing) => (listing.estimatedValue ?? 0) >= minValue);
    }

    if (maxValue != null) {
      filtered = filtered.where((listing) => (listing.estimatedValue ?? double.infinity) <= maxValue);
    }

    final results = filtered.toList();

    switch (ordering) {
      case '-created_at':
        results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'created_at':
        results.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'estimated_value':
        results.sort(
          (a, b) => (a.estimatedValue ?? 0).compareTo(b.estimatedValue ?? 0),
        );
        break;
      case '-estimated_value':
        results.sort(
          (a, b) => (b.estimatedValue ?? 0).compareTo(a.estimatedValue ?? 0),
        );
        break;
      default:
        results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    return results;
  }

  ListingServiceException _mapError(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final detail = decoded['detail'];
        if (detail is String && detail.isNotEmpty) {
          return ListingServiceException(detail);
        }

        final message = decoded['message'];
        if (message is String && message.isNotEmpty) {
          return ListingServiceException(message);
        }
      }
    } catch (_) {
      // Ignore decoding failures and fall back to generic messaging.
    }

    if (response.statusCode == 401) {
      return const ListingServiceException(
        'Your session has expired. Please sign in again.',
      );
    }

    return const ListingServiceException(
      'Unable to load listings right now. Please try again shortly.',
    );
  }

  List<Map<String, dynamic>> _extractListings(dynamic decoded) {
    if (decoded is List) {
      return decoded.whereType<Map<String, dynamic>>().toList();
    }

    if (decoded is Map<String, dynamic>) {
      final results = decoded['results'];
      if (results is List) {
        return results.whereType<Map<String, dynamic>>().toList();
      }
    }

    throw const ListingServiceException('Unexpected listings response format.');
  }
}
