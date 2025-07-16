enum TodoStatus {
  todo('Todo', 'To Do'),
  pending('Pending', 'Pending'),
  doing('Doing', 'In Progress'),
  needsReview('NeedsReview', 'Needs Review'),
  done('Done', 'Completed');

  const TodoStatus(this.value, this.displayName);
  
  final String value;
  final String displayName;

  static TodoStatus fromString(String value) {
    return TodoStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => TodoStatus.todo,
    );
  }
}