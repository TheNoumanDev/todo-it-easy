import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:todo_it_easy/services/account_storage_service';
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
      
      if (account != null) {
        // Save account to storage
        final storedAccount = StoredAccount(
          email: account.email,
          displayName: account.displayName ?? account.email,
          photoUrl: account.photoUrl,
          lastUsed: DateTime.now(),
        );
        await AccountStorageService.saveAccount(storedAccount);
        print('Saved account to storage: ${account.email}');
      }
      
      return account;
    } catch (e) {
      print('Error signing in: $e');
      return null;
    }
  }

  // Auto-login to all stored accounts and get combined events
  Future<List<CalendarEvent>> getAllAccountsEvents() async {
    final activeAccounts = await AccountStorageService.getActiveAccounts();
    final List<CalendarEvent> allEvents = [];
    
    print('Loading events from ${activeAccounts.length} stored accounts...');
    
    for (final storedAccount in activeAccounts) {
      try {
        print('Attempting to load events for: ${storedAccount.email}');
        
        // Try to sign in silently to this account
        final events = await _getEventsForAccount(storedAccount.email);
        allEvents.addAll(events);
        
        print('Loaded ${events.length} events from ${storedAccount.email}');
      } catch (e) {
        print('Failed to load events for ${storedAccount.email}: $e');
        // Don't remove account, just skip for now
      }
    }
    
    // Sort all events by start time
    allEvents.sort((a, b) => a.startTime.compareTo(b.startTime));
    
    print('Total events from all accounts: ${allEvents.length}');
    return allEvents;
  }

  // Get events for a specific account (try silent sign-in first)
  Future<List<CalendarEvent>> _getEventsForAccount(String accountEmail) async {
    try {
      // Try silent sign-in first
      GoogleSignInAccount? account = await _googleSignIn.signInSilently();
      
      // If no account or wrong account, try to switch
      if (account == null || account.email != accountEmail) {
        print('Need to switch to account: $accountEmail');
        // For web, we can only have one account signed in at a time
        // So we'll try to sign in and hope it's the right account
        account = await _googleSignIn.signInSilently();
      }
      
      if (account == null) {
        print('No account available for: $accountEmail');
        return [];
      }
      
      if (account.email != accountEmail) {
        print('Account mismatch: wanted $accountEmail, got ${account.email}');
        // Still try to get events - user might have switched manually
      }
      
      return await _fetchEventsForSignedInAccount(account);
      
    } catch (e) {
      print('Error getting events for $accountEmail: $e');
      return [];
    }
  }

  // Get today's events for currently signed-in account
  Future<List<CalendarEvent>> getTodaysEvents() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signInSilently();
      if (account == null) {
        print('No account signed in, trying to load from stored accounts...');
        return await getAllAccountsEvents();
      }
      
      return await _fetchEventsForSignedInAccount(account);
    } catch (e) {
      print('Error fetching today\'s events: $e');
      return [];
    }
  }

  // Fetch events for a signed-in account
  Future<List<CalendarEvent>> _fetchEventsForSignedInAccount(GoogleSignInAccount account) async {
    try {
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

      print('Found ${events.items?.length ?? 0} events for ${account.email}');
      
      // Debug: Print event details
      for (final event in events.items ?? []) {
        print('Event: ${event.summary} (${account.email})');
      }

      return events.items?.map((event) => _convertToCalendarEvent(event, account.email)).toList() ?? [];
    } catch (e) {
      print('Error fetching events for ${account.email}: $e');
      return [];
    }
  }

  // Get list of stored accounts
  Future<List<StoredAccount>> getStoredAccounts() async {
    return await AccountStorageService.getStoredAccounts();
  }

  // Remove account from storage
  Future<void> removeStoredAccount(String email) async {
    await AccountStorageService.removeAccount(email);
  }

  // Toggle account active status
  Future<void> toggleAccountActive(String email, bool isActive) async {
    await AccountStorageService.toggleAccountActive(email, isActive);
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
      return event.hangoutLink;
    }

    // Priority 2: Conference data
    if (event.conferenceData?.entryPoints != null) {
      for (final entryPoint in event.conferenceData!.entryPoints!) {
        if (entryPoint.uri != null && entryPoint.uri!.isNotEmpty) {
          return entryPoint.uri;
        }
      }
    }

    // Priority 3: Default Google Meet link for events without explicit links
    if (event.id != null) {
      final defaultMeetLink = 'https://meet.google.com/${event.id}';
      return defaultMeetLink;
    }

    return null;
  }

  // Sign out current account
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
