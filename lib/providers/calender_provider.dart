import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_it_easy/services/google_calender_service.dart';
import '../models/calendar_event.dart';

// Google Calendar Service Provider
final googleCalendarServiceProvider = Provider<GoogleCalendarService>((ref) {
  return GoogleCalendarService();
});

// Current signed in user email
final currentUserProvider = StateProvider<String?>((ref) => null);

// Today's events
final todaysEventsProvider = FutureProvider<List<CalendarEvent>>((ref) async {
  final service = ref.read(googleCalendarServiceProvider);
  try {
    final events = await service.getTodaysEvents();
    return events;
  } catch (e) {
    print('Error loading calendar events: $e');
    return [];
  }
});

// Sign in status
final isSignedInProvider = FutureProvider<bool>((ref) async {
  final service = ref.read(googleCalendarServiceProvider);
  return await service.isSignedIn();
});