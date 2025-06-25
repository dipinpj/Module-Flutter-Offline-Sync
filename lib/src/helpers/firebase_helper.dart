import 'dart:convert';
import 'package:http/http.dart' as http;

class FirestoreHelper {
  final String projectId;
  final String apiKey;

  FirestoreHelper({
    required this.projectId,
    required this.apiKey,
  });

  String get baseUrl =>
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents';

  Future<bool> addDocument(String collection, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/$collection?key=$apiKey');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'fields': _encodeFields(data)}),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }

  Future<Map<String, dynamic>> addDocumentInPath(
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) async {
    final url = Uri.parse('$baseUrl/$collection/$docId?key=$apiKey');

    try {
      final response = await http.patch(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'fields': _encodeFields(data)}),
      );

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return {'success': false, 'message': responseData['error']['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Unexpected Error: $e'};
    }
  }

  Future<void> updateDocument(
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) async {
    final url = Uri.parse(
      '$baseUrl/$collection/$docId?key=$apiKey&updateMask.fieldPaths=${data.keys.join(",")}',
    );
    final response = await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'fields': _encodeFields(data)}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update document: ${response.body}');
    }
  }

  Future<void> deleteDocument(String collection, String docId) async {
    final url = Uri.parse('$baseUrl/$collection/$docId?key=$apiKey');
    final response = await http.delete(url);
    if (response.statusCode != 200) {
      throw Exception('Failed to delete document: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> createUser(Map<String, dynamic> data) async {
    try {
      final url = Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey',
      );
      final map = {
        'email': data['email'],
        'password': data['password'],
        'returnSecureToken': false,
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(map),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'localId': responseData['localId'],
          'email': responseData['email'],
          'idToken': responseData['idToken'],
        };
      } else {
        String errorMessage;
        switch (responseData['error']['message']) {
          case 'EMAIL_EXISTS':
            errorMessage = 'Email already exists.';
            break;
          case 'INVALID_PASSWORD':
            errorMessage = 'Invalid password.';
            break;
          case 'EMAIL_NOT_FOUND':
            errorMessage = 'Email not found.';
            break;
          case 'WEAK_PASSWORD':
            errorMessage = 'Weak password. ';
            break;
          default:
            errorMessage =
                'An unexpected error occurred. Please try again later.';
        }
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      return {'success': false, 'message': 'Unexpected Error: $e'};
    }
  }

  Future<bool> deleteUser(String idToken) async {
    final url = Uri.parse(
      'https://identitytoolkit.googleapis.com/v1/accounts:delete?key=$apiKey',
    );
    final map = {'idToken': idToken};
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(map),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> sendResetPasswordLink(String email) async {
    final url = Uri.parse(
      'https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode?key=$apiKey',
    );
    final data = {'requestType': 'PASSWORD_RESET', 'email': email};
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }

  // Helper to encode Firestore fields
  Map<String, dynamic> _encodeFields(Map<String, dynamic> data) {
    return data.map((key, value) => MapEntry(key, _encodeValue(value)));
  }

  Map<String, dynamic> _encodeValue(dynamic value) {
    if (value is String) return {'stringValue': value};
    if (value is int) return {'integerValue': value.toString()};
    if (value is double) return {'doubleValue': value};
    if (value is bool) return {'booleanValue': value};
    if (value is Map) {
      return {
        'mapValue': {'fields': _encodeFields(Map<String, dynamic>.from(value))},
      };
    }
    if (value is List) {
      return {
        'arrayValue': {'values': value.map((v) => _encodeValue(v)).toList()},
      };
    }
    return {'nullValue': null};
  }
}
