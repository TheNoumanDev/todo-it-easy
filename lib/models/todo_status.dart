enum TodoStatus {
  todo('Todo', 'To Do'),
  pending('Pending', 'Pending'),
  doing('Doing', 'In Progress'),
  done('Done', 'Completed');

  const TodoStatus(this.value, this.displayName);
  
  final String value;
  final String displayName;

  static TodoStatus fromString(String value) {
    // Handle migration from old needsReview status
    if (value == 'needsReview' || value == 'NeedsReview') {
      return TodoStatus.doing; // Convert old review tasks to "doing"
    }
    return TodoStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => TodoStatus.todo,
    );
  }
}