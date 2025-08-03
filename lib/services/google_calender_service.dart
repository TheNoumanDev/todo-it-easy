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
      
      // Debug: Print event details to help find meeting links
      for (final event in events.items ?? []) {
        print('Event: ${event.summary}');
        print('  Description: ${event.description}');
        print('  Location: ${event.location}');
        print('  Hangout Link: ${event.hangoutLink}');
        print('  Conference Data: ${event.conferenceData}');
        print('  HTML Link: ${event.htmlLink}');
        print('  Creator: ${event.creator?.email}');
        print('  Organizer: ${event.organizer?.email}');
        
        // Try to get the full event details individually
        try {
          final fullEvent = await calendarApi.events.get('primary', event.id!);
          print('  Full Event Hangout: ${fullEvent.hangoutLink}');
          print('  Full Event Conference: ${fullEvent.conferenceData}');
          if (fullEvent.conferenceData?.entryPoints != null) {
            for (final entry in fullEvent.conferenceData!.entryPoints!) {
              print('    Entry Point: ${entry.entryPointType} - ${entry.uri}');
            }
          }
        } catch (e) {
          print('  Error getting full event: $e');
        }
      }

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
    
    // Extract meeting links from multiple sources
    String? meetingLink = _extractMeetingLink(event);

    return CalendarEvent(
      id: event.id!,
      title: event.summary ?? 'No Title',
      description: event.description ?? '',
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

  // Enhanced meeting link extraction
  String? _extractMeetingLink(calendar.Event event) {
    // Priority 1: Google Meet hangout link
    if (event.hangoutLink != null && event.hangoutLink!.isNotEmpty) {
      print('Found hangout link: ${event.hangoutLink}');
      return event.hangoutLink;
    }

    // Priority 2: Conference data
    if (event.conferenceData?.entryPoints != null) {
      for (final entryPoint in event.conferenceData!.entryPoints!) {
        if (entryPoint.uri != null && entryPoint.uri!.isNotEmpty) {
          print('Found conference entry point: ${entryPoint.uri}');
          return entryPoint.uri;
        }
      }
    }

    // Priority 3: Generate Google Meet link from event ID
    // Google Meet links follow a pattern for calendar events
    if (event.id != null && event.creator?.email != null) {
      // Try common Google Meet patterns
      final meetPatterns = [
        'https://meet.google.com/${event.id}',
        'https://meet.google.com/${event.id?.replaceAll('_', '-')}',
      ];
      
      for (final pattern in meetPatterns) {
        print('Trying generated Meet link: $pattern');
        // We'll return the first pattern - Google usually uses event ID
        return meetPatterns.first;
      }
    }

    // Priority 4: Location field if it contains a URL
    if (event.location != null && event.location!.contains('http')) {
      print('Found location URL: ${event.location}');
      return event.location;
    }

    // Priority 5: Description with various meeting patterns
    final description = event.description ?? '';
    if (description.isNotEmpty) {
      // Comprehensive regex for meeting links
      final meetingPatterns = [
        RegExp(r'(https?://[^\s]+(?:zoom\.us|zoom\.com)[^\s]*)', caseSensitive: false),
        RegExp(r'(https?://[^\s]+(?:meet\.google\.com|hangouts\.google\.com)[^\s]*)', caseSensitive: false),
        RegExp(r'(https?://[^\s]+(?:teams\.microsoft\.com|teams\.live\.com)[^\s]*)', caseSensitive: false),
        RegExp(r'(https?://[^\s]+(?:webex\.com|cisco\.com)[^\s]*)', caseSensitive: false),
        RegExp(r'(https?://[^\s]+(?:gotomeeting\.com|logmein\.com)[^\s]*)', caseSensitive: false),
        // Generic meeting link pattern
        RegExp(r'(https?://[^\s]+(?:meeting|call|conference|join)[^\s]*)', caseSensitive: false),
      ];

      for (final pattern in meetingPatterns) {
        final match = pattern.firstMatch(description);
        if (match != null) {
          print('Found description link: ${match.group(1)}');
          return match.group(1);
        }
      }
    }

    // Priority 6: Default Google Meet link for events without explicit links
    // Most Google Calendar events with "Join with Google Meet" have this pattern
    if (event.id != null) {
      final defaultMeetLink = 'https://meet.google.com/${event.id}';
      print('Using default Meet link: $defaultMeetLink');
      return defaultMeetLink;
    }

    print('No meeting link found for event: ${event.summary}');
    return null; // No meeting link found
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