import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/calendar_event.dart';
import '../utils/constants.dart';

class CalendarEventCard extends StatefulWidget {
  final CalendarEvent event;

  const CalendarEventCard({super.key, required this.event});

  @override
  State<CalendarEventCard> createState() => _CalendarEventCardState();
}

class _CalendarEventCardState extends State<CalendarEventCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and time
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status indicator
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 6, right: 8),
                    decoration: BoxDecoration(
                      color: _getStatusColor(),
                      shape: BoxShape.circle,
                    ),
                  ),
                  // Title and time
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.event.title,
                          style: AppConstants.titleStyle.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: _isExpanded ? null : 2,
                          overflow: _isExpanded ? null : TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.event.timeDisplay,
                          style: AppConstants.captionStyle.copyWith(
                            color: _getStatusColor(),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Expand/collapse button
                  InkWell(
                    onTap: () => setState(() => _isExpanded = !_isExpanded),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: _getStatusColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        size: 16,
                        color: _getStatusColor(),
                      ),
                    ),
                  ),
                ],
              ),
              
              // Expanded details
              if (_isExpanded) ...[
                const SizedBox(height: 12),
                
                // Description
                if (widget.event.description.isNotEmpty) ...[
                  Text(
                    widget.event.description,
                    style: AppConstants.bodyStyle.copyWith(fontSize: 12),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                ],
                
                // Location
                if (widget.event.location != null && widget.event.location!.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.event.location!,
                          style: AppConstants.captionStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                
                // Attendees
                if (widget.event.attendees.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(Icons.people, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.event.attendees.length} attendees',
                        style: AppConstants.captionStyle,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                
                // Action buttons
                Row(
                  children: [
                    // Join meeting button
                    if (widget.event.meetingLink != null)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _launchMeetingLink(),
                          icon: const Icon(Icons.videocam, size: 16),
                          label: const Text('Join', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            minimumSize: const Size(0, 32),
                          ),
                        ),
                      ),
                    
                    if (widget.event.meetingLink != null) const SizedBox(width: 8),
                    
                    // Open in calendar button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openInCalendar(),
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: const Text('Calendar', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          minimumSize: const Size(0, 32),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    if (widget.event.isPast) return Colors.grey[500]!;
    if (widget.event.isHappening) return Colors.green[600]!;
    return Colors.blue[600]!;
  }

  Future<void> _launchMeetingLink() async {
    if (widget.event.meetingLink != null) {
      final Uri url = Uri.parse(widget.event.meetingLink!);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    }
  }

  Future<void> _openInCalendar() async {
    // Open Google Calendar in web
    final startTime = widget.event.startTime.millisecondsSinceEpoch ~/ 1000;
    final endTime = widget.event.endTime.millisecondsSinceEpoch ~/ 1000;
    final calendarUrl = 'https://calendar.google.com/calendar/event?eid=${widget.event.id}';
    
    final Uri url = Uri.parse(calendarUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}