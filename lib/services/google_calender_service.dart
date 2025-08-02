import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import '../models/calendar_event.dart';

class GoogleCalendarService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '225433860092-j3ucf08fpqqpctfgk6uc6nmcl48nq9lt.apps.googleusercontent.com',
    scopes: [
      calendar.CalendarApi.calendarReadonlyScope,
    ],
  );

  // Sign in and return account info
  Future<GoogleSignInAccount?> signInAccount() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      return account;
    } catch (e) {
      print('Error signing in: $e');
      return null;
    }
  }

  // Get today's events for the signed-in account
  Future<List<CalendarEvent>> getTodaysEvents() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signInSilently();
      if (account == null) {
        print('No account signed in');
        return [];
      }

      final authHeaders = await account.authHeaders;
      final authenticateClient = GoogleAuthClient(authHeaders);
      final calendarApi = calendar.CalendarApi(authenticateClient);

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      print('Fetching events for ${account.email}');
      
      final events = await calendarApi.events.list(
        'primary',
        timeMin: startOfDay,
        timeMax: endOfDay,
        singleEvents: true,
        orderBy: 'startTime',
        maxResults: 20,
      );

      print('Found ${events.items?.length ?? 0} events');

      return events.items?.map((event) => _convertToCalendarEvent(event, account.email)).toList() ?? [];
    } catch (e) {
      print('Error fetching events: $e');
      return [];
    }
  }

  // Convert Google Calendar Event to our CalendarEvent model
  CalendarEvent _convertToCalendarEvent(calendar.Event event, String accountEmail) {
    final start = event.start?.dateTime ?? 
                  (event.start?.date != null ? DateTime.parse(event.start!.date! as String) : DateTime.now());
    final end = event.end?.dateTime ?? 
                (event.end?.date != null ? DateTime.parse(event.end!.date! as String) : start.add(const Duration(hours: 1)));
    
    // Extract meeting links from description
    String? meetingLink;
    final description = event.description ?? '';
    final meetingRegex = RegExp(r'(https?://[^\s]+(?:zoom|meet|teams)[^\s]*)');
    final match = meetingRegex.firstMatch(description);
    if (match != null) {
      meetingLink = match.group(1);
    }

    // Check for meeting links in location or hangout link
    if (meetingLink == null) {
      if (event.location != null && event.location!.contains('http')) {
        meetingLink = event.location;
      } else if (event.hangoutLink != null) {
        meetingLink = event.hangoutLink;
      }
    }

    return CalendarEvent(
      id: event.id!,
      title: event.summary ?? 'No Title',
      description: description,
      startTime: start,
      endTime: end,
      accountEmail: accountEmail,
      meetingLink: meetingLink,
      attendees: event.attendees?.map((a) => a.email ?? '').where((e) => e.isNotEmpty).toList() ?? [],
      location: event.location,
      isAllDay: event.start?.date != null,
      status: event.status ?? 'confirmed',
    );
  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  // Check if user is signed in
  Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }

  // Get current signed in account
  Future<GoogleSignInAccount?> getCurrentAccount() async {
    return await _googleSignIn.signInSilently();
  }
}

// Helper class for authenticated HTTP client
class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }

  @override
  void close() {
    _client.close();
  }
}