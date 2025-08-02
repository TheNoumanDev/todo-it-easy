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
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        border: Border.all(color: Colors.purple[200]!, width: 1),
      ),
      child: Column(
        children: [
          // Column header
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            decoration: BoxDecoration(
              color: Colors.purple[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppConstants.borderRadiusLarge),
                topRight: Radius.circular(AppConstants.borderRadiusLarge),
              ),
            ),
            child: Row(
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
                // Sign in/out button
                isSignedInAsync.when(
                  data: (isSignedIn) => IconButton(
                    icon: Icon(
                      isSignedIn ? Icons.logout : Icons.login,
                      size: 20,
                      color: Colors.purple[600],
                    ),
                    onPressed: () => _handleSignInOut(context, ref, isSignedIn),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  loading: () => const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (_, __) => const SizedBox(),
                ),
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
                  data: (events) => _buildEventsList(events),
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

  Widget _buildEventsList(List<CalendarEvent> events) {
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
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.paddingSmall),
      itemCount: events.length,
      itemBuilder: (context, index) {
        return CalendarEventCard(event: events[index]);
      },
    );
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

  Future<void> _handleSignInOut(BuildContext context, WidgetRef ref, bool isSignedIn) async {
    if (isSignedIn) {
      await _signOut(context, ref);
    } else {
      await _signIn(context, ref);
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