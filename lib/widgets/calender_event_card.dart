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
                    'Description:',
                    style: AppConstants.captionStyle.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.event.description,
                    style: AppConstants.bodyStyle.copyWith(fontSize: 12),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                ],
                
                // Meeting Link (prominent display)
                if (widget.event.meetingLink != null && widget.event.meetingLink!.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getMeetingButtonColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _getMeetingButtonColor().withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(_getMeetingIcon(), size: 14, color: _getMeetingButtonColor()),
                            const SizedBox(width: 4),
                            Text(
                              'Meeting Link',
                              style: AppConstants.captionStyle.copyWith(
                                color: _getMeetingButtonColor(),
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Meeting Link Button (only one button now)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _launchMeetingLink(),
                            icon: Icon(_getMeetingIcon(), size: 16),
                            label: Text('Join ${_getMeetingButtonText()}', style: const TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _getMeetingButtonColor(),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                
                // Event Information Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Event Information Header
                      Row(
                        children: [
                          Icon(Icons.info_outline, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            'Event Information',
                            style: AppConstants.captionStyle.copyWith(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Description (if available)
                      if (widget.event.description.isNotEmpty) ...[
                        _buildInfoRow('Description', widget.event.description, Icons.description),
                        const SizedBox(height: 6),
                      ],
                      
                      // Location (if available)
                      if (widget.event.location != null && widget.event.location!.isNotEmpty) ...[
                        _buildInfoRow('Location', widget.event.location!, Icons.location_on),
                        const SizedBox(height: 6),
                      ],
                      
                      // Attendees (if available)
                      if (widget.event.attendees.isNotEmpty) ...[
                        _buildInfoRow(
                          'Attendees (${widget.event.attendees.length})', 
                          widget.event.attendees.take(3).join(', ') + 
                          (widget.event.attendees.length > 3 ? '...' : ''), 
                          Icons.people
                        ),
                        const SizedBox(height: 6),
                      ],
                      
                      // Organizer
                      _buildInfoRow('Time', widget.event.timeDisplay, Icons.access_time),
                      
                      // If no additional info, show a message
                      if (widget.event.description.isEmpty && 
                          (widget.event.location == null || widget.event.location!.isEmpty) && 
                          widget.event.attendees.isEmpty) ...[
                        Row(
                          children: [
                            Icon(Icons.info, size: 12, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              'No additional details available',
                              style: AppConstants.captionStyle.copyWith(
                                color: Colors.grey[500],
                                fontSize: 10,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 12, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppConstants.captionStyle.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppConstants.captionStyle.copyWith(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor() {
    if (widget.event.isPast) return Colors.grey[500]!;
    if (widget.event.isHappening) return Colors.green[600]!;
    return Colors.blue[600]!;
  }

  IconData _getMeetingIcon() {
    final link = widget.event.meetingLink?.toLowerCase() ?? '';
    if (link.contains('zoom')) return Icons.videocam;
    if (link.contains('meet') || link.contains('hangout')) return Icons.video_call;
    if (link.contains('teams')) return Icons.groups;
    if (link.contains('webex')) return Icons.video_camera_front;
    return Icons.videocam; // Default
  }

  String _getMeetingButtonText() {
    final link = widget.event.meetingLink?.toLowerCase() ?? '';
    if (link.contains('zoom')) return 'Zoom';
    if (link.contains('meet') || link.contains('hangout')) return 'Meet';
    if (link.contains('teams')) return 'Teams';
    if (link.contains('webex')) return 'Webex';
    return 'Join'; // Default
  }

  Color _getMeetingButtonColor() {
    final link = widget.event.meetingLink?.toLowerCase() ?? '';
    if (link.contains('zoom')) return Colors.blue[600]!;
    if (link.contains('meet') || link.contains('hangout')) return Colors.green[600]!;
    if (link.contains('teams')) return Colors.purple[600]!;
    if (link.contains('webex')) return Colors.orange[600]!;
    return Colors.blue[600]!; // Default
  }

  Future<void> _launchMeetingLink() async {
    if (widget.event.meetingLink != null && widget.event.meetingLink!.isNotEmpty) {
      final Uri url = Uri.parse(widget.event.meetingLink!);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    }
  }

  Future<void> _openInCalendar() async {
    // Open Google Calendar event directly
    final calendarUrl = 'https://calendar.google.com/calendar/event?eid=${widget.event.id}';
    
    final Uri url = Uri.parse(calendarUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}