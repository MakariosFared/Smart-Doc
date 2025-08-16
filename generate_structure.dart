import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty) {
    print(
      '❌ Please provide a screen name.\nUsage: dart generate_screen_structure.dart <screen_name>',
    );
    return;
  }

  final screenName = args[0].toLowerCase();
  final basePath = 'lib/';

  final folders = [
    '$basePath/Core/utils',
    '$basePath/Core/Services',
    '$basePath/Features/$screenName/data/models',
    '$basePath/Features/$screenName/data/repo',
    '$basePath/Features/$screenName/presentation/cubit',
    '$basePath/Features/$screenName/presentation/view/widgets',
  ];

  for (var folder in folders) {
    final dir = Directory(folder);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
      print('✅ Created: ${dir.path}');
    } else {
      print('⚠️ Already exists: ${dir.path}');
    }
  }

  print('\n🎉 Done setting up "$screenName" structure!');
}
