void printColoredMessage(String message, {String color = 'reset'}) {
  Map<String, String> colors = {
    'reset': '\x1B[0m',
    'red': '\x1B[31m',
    'green': '\x1B[32m',
    'yellow': '\x1B[33m',
    'blue': '\x1B[34m',
    'magenta': '\x1B[35m',
    'cyan': '\x1B[36m',
    'white': '\x1B[37m',
  };
  String? colorCode = colors[color] ?? colors['reset'];

  print('$colorCode$message${colors['reset']}');
}