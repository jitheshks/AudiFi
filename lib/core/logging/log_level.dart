/// Supported diagnostic logging severity levels.
enum LogLevel {
  debug(0, 'DEBUG'),
  info(1, 'INFO'),
  warning(2, 'WARN'),
  error(3, 'ERROR'),
  none(4, 'NONE');

  const LogLevel(this.priority, this.label);

  final int priority;
  final String label;

  bool operator >=(LogLevel other) => priority >= other.priority;
  bool operator <=(LogLevel other) => priority <= other.priority;
  bool operator >(LogLevel other) => priority > other.priority;
  bool operator <(LogLevel other) => priority < other.priority;
}
