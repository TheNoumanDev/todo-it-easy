import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_it_easy/providers/calender_provider.dart';
import 'package:todo_it_easy/widgets/calender_event_card.dart';
import '../models/calendar_event.dart';
import '../utils/constants.dart';

class CalendarColumn extends ConsumerWidget {
  const CalendarColumn({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(todaysEventsProvider);
    final isSignedInAsync = ref.watch(isSignedInProvider);
    final currentUser = ref.watch(currentUserProvider);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        border: Border.all(color: Colors.purple[200]!, width: 1),
      ),
      child: Column(
        children: [
          // Column header with account switcher
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            decoration: BoxDecoration(
              color: Colors.purple[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppConstants.borderRadiusLarge),
                topRight: Radius.circular(AppConstants.borderRadiusLarge),
              ),
            ),
            child: Column(
              children: [
                // Title row
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.purple[600],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Today's Events",
                        style: AppConstants.titleStyle.copyWith(
                          color: Colors.purple[600],
                        ),
                      ),
                    ),
                    // Menu button
                    PopupMenuButton<String>(
                      onSelected: (value) => _handleMenuAction(context, ref, value),
                      icon: Icon(
                        Icons.more_vert,
                        size: 20,
                        color: Colors.purple[600],
                      ),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'switch_account',
                          child: Row(
                            children: [
                              Icon(Icons.switch_account, size: 18),
                              SizedBox(width: 8),
                              Text('Switch Account'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'refresh',
                          child: Row(
                            children: [
                              Icon(Icons.refresh, size: 18),
                              SizedBox(width: 8),
                              Text('Refresh Events'),
                            ],
                          ),
                        ),
                        if (currentUser != null)
                          const PopupMenuItem(
                            value: 'sign_out',
                            child: Row(
                              children: [
                                Icon(Icons.logout, size: 18),
                                SizedBox(width: 8),
                                Text('Sign Out'),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                
                // Current user indicator
                if (currentUser != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.purple[200]!.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.account_circle,
                          size: 16,
                          color: Colors.purple[700],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            currentUser,
                            style: AppConstants.captionStyle.copyWith(
                              color: Colors.purple[700],
                              fontSize: 10,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Events list or sign-in prompt
          Expanded(
            child: isSignedInAsync.when(
              data: (isSignedIn) {
                if (!isSignedIn) {
                  return _buildSignInPrompt(context, ref);
                }
                
                return eventsAsync.when(
                  data: (events) => _buildEventsList(events, ref),
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, stack) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Error loading events',
                          style: AppConstants.bodyStyle.copyWith(
                            color: Colors.red[600],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => ref.refresh(todaysEventsProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => _buildSignInPrompt(context, ref),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignInPrompt(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today,
              size: 48,
              color: Colors.purple[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Sign in to Google',
              style: AppConstants.titleStyle.copyWith(
                color: Colors.purple[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'View your calendar events here',
              style: AppConstants.bodyStyle.copyWith(
                color: Colors.grey[600],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _signIn(context, ref),
              icon: const Icon(Icons.login, size: 18),
              label: const Text('Sign In'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple[600],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsList(List<CalendarEvent> events, WidgetRef ref) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available,
              size: 48,
              color: Colors.purple[300],
            ),
            const SizedBox(height: 8),
            Text(
              'No events today',
              style: AppConstants.bodyStyle.copyWith(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => ref.refresh(todaysEventsProvider),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Refresh'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.purple[600],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Event count header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.purple[100],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(
                Icons.event,
                size: 14,
                color: Colors.purple[600],
              ),
              const SizedBox(width: 4),
              Text(
                '${events.length} event${events.length == 1 ? '' : 's'} today',
                style: AppConstants.captionStyle.copyWith(
                  color: Colors.purple[600],
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        
        // Events list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingSmall),
            itemCount: events.length,
            itemBuilder: (context, index) {
              return CalendarEventCard(event: events[index]);
            },
          ),
        ),
      ],
    );
  }

  Future<void> _handleMenuAction(BuildContext context, WidgetRef ref, String action) async {
    switch (action) {
      case 'switch_account':
        await _switchAccount(context, ref);
        break;
      case 'refresh':
        ref.refresh(todaysEventsProvider);
        break;
      case 'sign_out':
        await _signOut(context, ref);
        break;
    }
  }

  Future<void> _switchAccount(BuildContext context, WidgetRef ref) async {
    try {
      // Sign out current account
      final service = ref.read(googleCalendarServiceProvider);
      await service.signOut();
      
      // Clear current user
      ref.read(currentUserProvider.notifier).state = null;
      
      // Show intermediate state
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signed out. Choose a different account...'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      // Wait a moment for sign out to complete
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Sign in with new account
      await _signIn(context, ref);
      
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account switch failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _signIn(BuildContext context, WidgetRef ref) async {
    try {
      final service = ref.read(googleCalendarServiceProvider);
      final account = await service.signInAccount();
      
      if (account != null) {
        ref.read(currentUserProvider.notifier).state = account.email;
        ref.refresh(isSignedInProvider);
        ref.refresh(todaysEventsProvider);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Signed in as ${account.email}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign in failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    try {
      final service = ref.read(googleCalendarServiceProvider);
      await service.signOut();
      
      ref.read(currentUserProvider.notifier).state = null;
      ref.refresh(isSignedInProvider);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signed out successfully'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign out failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
