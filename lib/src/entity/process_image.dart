
enum ImageFilter { cartoon, gray, sepia, edgePreserving, stylization }

class ProcessImageArguments {
  final String inputPath;
  final String outputPath;
  final ImageFilter filter;

  ProcessImageArguments(
      {required this.inputPath,
        required this.outputPath,
        required this.filter});
}
