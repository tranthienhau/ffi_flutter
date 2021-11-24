enum ImageFilter {
  original,
  duoToneGreenEx1,
  duoToneGreenEx2,
  duoToneGreenEx3,
  duoToneGreenEx4,
  duoToneGreenEx5,
  duoToneGreenEx6,

  duoToneRedEx1,
  duoToneRedEx2,
  duoToneRedEx3,
  duoToneRedEx4,
  duoToneRedEx5,
  duoToneRedEx6,


  duoToneBlueEx1,
  duoToneBlueEx2,
  duoToneBlueEx3,
  duoToneBlueEx4,
  duoToneBlueEx5,
  duoToneBlueEx6,
  duoToneBlueEx7,
  duoToneBlueEx8,
  duoToneBlueEx9,
  duoToneBlueEx10,

  duoToneBlueGreenEx1,
  duoToneBlueGreenEx2,
  duoToneBlueGreenEx3,
  duoToneBlueGreenEx4,
  duoToneBlueGreenEx5,
  duoToneBlueGreenEx6,
  duoToneBlueGreenEx7,
  duoToneBlueGreenEx8,
  duoToneBlueGreenEx9,
  duoToneBlueGreenEx10,
  
  duoToneBlueGreenDartEx1,
  duoToneBlueGreenDartEx2,
  duoToneBlueGreenDartEx3,
  duoToneBlueGreenDartEx4,
  duoToneBlueGreenDartEx5,
  duoToneBlueGreenDartEx6,
  duoToneBlueGreenDartEx7,
  duoToneBlueGreenDartEx8,
  duoToneBlueGreenDartEx9,
  duoToneBlueGreenDartEx10,

  duoToneGreenRedDartEx1,
  duoToneGreenRedDartEx2,
  duoToneGreenRedDartEx3,
  duoToneGreenRedDartEx4,
  duoToneGreenRedDartEx5,
  duoToneGreenRedDartEx6,
  duoToneGreenRedDartEx7,
  duoToneGreenRedDartEx8,
  duoToneGreenRedDartEx9,
  duoToneGreenRedDartEx10,

  duoToneGreenRedEx1,
  duoToneGreenRedEx2,
  duoToneGreenRedEx3,
  duoToneGreenRedEx4,
  duoToneGreenRedEx5,
  duoToneGreenRedEx6,
  duoToneGreenRedEx7,
  duoToneGreenRedEx8,
  duoToneGreenRedEx9,
  duoToneGreenRedEx10,
  
  
  cartoon,
  gray,
  sepia,
  edgePreserving,
  stylization,

  invert,
  pencilSketch,
  sharpen,
  hdr
}

class ProcessImageArguments {
  final String inputPath;
  final String outputPath;
  final ImageFilter filter;

  ProcessImageArguments({
    required this.inputPath,
    required this.outputPath,
    required this.filter,
  });
}
