import 'package:json_annotation/json_annotation.dart';

part 'calendar_event.g.dart';

@JsonSerializable()
class CalendarEvent {
  final String id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String accountEmail;
  final String? meetingLink;
  final List<String> attendees;
  final String? location;
  final bool isAllDay;
  final String status;

  CalendarEvent({
    required this.id,
    required this.title,
    this.description = '',
    required this.startTime,
    required this.endTime,
    required this.accountEmail,
    this.meetingLink,
    this.attendees = const [],
    this.location,
    this.isAllDay = false,
    this.status = 'confirmed',
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) => _$CalendarEventFromJson(json);
  Map<String, dynamic> toJson() => _$CalendarEventToJson(this);

  bool get isHappening {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  bool get isUpcoming {
    final now = DateTime.now();
    return now.isBefore(startTime);
  }

  bool get isPast {
    final now = DateTime.now();
    return now.isAfter(endTime);
  }

  String get timeDisplay {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(startTime.year, startTime.month, startTime.day);
    
    if (isAllDay) {
      return 'All day';
    }
    
    if (eventDay == today) {
      // Today - just show time
      return '${_formatTime(startTime)} - ${_formatTime(endTime)}';
    } else {
      // Other day - show date and time
      return '${startTime.day}/${startTime.month} ${_formatTime(startTime)}';
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:$minute $period';
  }

  String get statusColor {
    if (isPast) return 'grey';
    if (isHappening) return 'green';
    return 'blue';
  }
}