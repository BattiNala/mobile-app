class DetectionConfig {
  // CONFIDENCE THRESHOLDS
  static const double mlKitMinConfidence = 0.45;
  static const double inferenceMinConfidence = 0.40;
  static const double imagePropertiesMinConfidence = 0.45;
  static const double rejectionMinConfidence =
      0.65; // Higher to avoid false rejections

  // SHAPE DETECTION THRESHOLDS
  static const double tallAspectRatio = 2.2;
  static const double tallMinArea = 4000;
  static const double boxAspectRatioMin = 0.6;
  static const double boxAspectRatioMax = 1.5;
  static const double boxMinArea = 2500;
  static const double linearAspectRatio = 0.35;
  static const double linearWidthMultiplier = 3.5;
  static const double circularAspectRatioMin = 0.75;
  static const double circularAspectRatioMax = 1.25;
  static const double circularMinArea = 1800;

  // BOOST VALUES
  static const double shapeConfidenceBoost = 0.20;
  static const double multiKeywordBoost = 0.10;
  static const double contextBoostPerSignal = 0.08;
  static const double maxContextBoost = 0.20;

  // IMAGE PROPERTY THRESHOLDS
  static const double firePercentageThreshold = 0.05;
  static const double emergencyFireThreshold = 0.12;
  static const double highContrastThreshold = 0.22;
  static const double darkPixelsThreshold = 0.30;
  static const double brownPercentageThreshold = 0.12;
  static const double metalLikeBrightnessMin = 180;
  static const double metalLikeBrightnessMax = 240;

  // KEYWORD CONFIDENCE SCALING
  static const double exactMatchBoost = 0.15;
  static const double partialMatchBoost = 0.05;
}

class DetectionKeywords {
  // ELECTRICAL INFRASTRUCTURE - Expanded and prioritized
  static const Map<String, List<KeywordEntry>> electrical = {
    'Electric Pole': [
      KeywordEntry('pole', priority: 10, exactMatch: true),
      KeywordEntry('utility pole', priority: 10, exactMatch: true),
      KeywordEntry('power pole', priority: 10, exactMatch: true),
      KeywordEntry('electric pole', priority: 10, exactMatch: true),
      KeywordEntry('telephone pole', priority: 9, exactMatch: true),
      KeywordEntry('wooden pole', priority: 8),
      KeywordEntry('concrete pole', priority: 8),
      KeywordEntry('post', priority: 6),
      KeywordEntry('pillar', priority: 5),
      KeywordEntry('column', priority: 5),
      KeywordEntry('vertical', priority: 3),
      KeywordEntry('tall', priority: 3),
    ],
    'Wire': [
      KeywordEntry('wire', priority: 10, exactMatch: true),
      KeywordEntry('cable', priority: 10, exactMatch: true),
      KeywordEntry('power line', priority: 10, exactMatch: true),
      KeywordEntry('electrical line', priority: 9, exactMatch: true),
      KeywordEntry('overhead cable', priority: 9),
      KeywordEntry('transmission line', priority: 9),
      KeywordEntry('conductor', priority: 7),
      KeywordEntry('line', priority: 4),
      KeywordEntry('hanging', priority: 5),
      KeywordEntry('suspended', priority: 5),
    ],
    'Transformer': [
      KeywordEntry('transformer', priority: 10, exactMatch: true),
      KeywordEntry('electrical transformer', priority: 10, exactMatch: true),
      KeywordEntry('power transformer', priority: 10, exactMatch: true),
      KeywordEntry('distribution box', priority: 9),
      KeywordEntry('electrical box', priority: 9),
      KeywordEntry('utility box', priority: 8),
      KeywordEntry('junction box', priority: 8),
      KeywordEntry('box', priority: 4),
      KeywordEntry('equipment', priority: 5),
      KeywordEntry('container', priority: 3),
    ],
    'Street Light': [
      KeywordEntry('street light', priority: 10, exactMatch: true),
      KeywordEntry('lamppost', priority: 10, exactMatch: true),
      KeywordEntry('light pole', priority: 9),
      KeywordEntry('street lamp', priority: 9),
      KeywordEntry('lamp', priority: 6),
      KeywordEntry('lighting', priority: 6),
      KeywordEntry('light', priority: 4),
    ],
  };

  // SEWAGE INFRASTRUCTURE - Expanded
  static const Map<String, List<KeywordEntry>> sewage = {
    'Manhole': [
      KeywordEntry('manhole', priority: 10, exactMatch: true),
      KeywordEntry('sewer manhole', priority: 10, exactMatch: true),
      KeywordEntry('manhole cover', priority: 10, exactMatch: true),
      KeywordEntry('access cover', priority: 9),
      KeywordEntry('drain cover', priority: 9),
      KeywordEntry('grate', priority: 8),
      KeywordEntry('metal grate', priority: 8),
      KeywordEntry('sewer access', priority: 9),
      KeywordEntry('cover', priority: 4),
      KeywordEntry('hole', priority: 5),
      KeywordEntry('circular', priority: 3),
    ],
    'Overflow': [
      KeywordEntry('overflow', priority: 10, exactMatch: true),
      KeywordEntry('sewage overflow', priority: 10, exactMatch: true),
      KeywordEntry('drain overflow', priority: 10, exactMatch: true),
      KeywordEntry('flooding', priority: 9),
      KeywordEntry('waterlogging', priority: 9),
      KeywordEntry('overflowing', priority: 9),
      KeywordEntry('flood', priority: 8),
      KeywordEntry('water', priority: 5),
      KeywordEntry('puddle', priority: 6),
      KeywordEntry('wet', priority: 4),
    ],
    'Pipe Damage': [
      KeywordEntry('broken pipe', priority: 10, exactMatch: true),
      KeywordEntry('damaged pipe', priority: 10, exactMatch: true),
      KeywordEntry('cracked pipe', priority: 10, exactMatch: true),
      KeywordEntry('leaking pipe', priority: 10, exactMatch: true),
      KeywordEntry('pipe', priority: 7),
      KeywordEntry('sewer pipe', priority: 9),
      KeywordEntry('leak', priority: 8),
      KeywordEntry('crack', priority: 7),
      KeywordEntry('damage', priority: 6),
      KeywordEntry('broken', priority: 6),
    ],
  };

  // REJECTION KEYWORDS - More precise
  static const List<KeywordEntry> rejection = [
    // PEOPLE
    KeywordEntry('person', priority: 10),
    KeywordEntry('people', priority: 10),
    KeywordEntry('human', priority: 10),
    KeywordEntry('face', priority: 9),
    KeywordEntry('man', priority: 8),
    KeywordEntry('woman', priority: 8),
    KeywordEntry('child', priority: 9),
    KeywordEntry('boy', priority: 8),
    KeywordEntry('girl', priority: 8),

    // VEHICLES
    KeywordEntry('car', priority: 10),
    KeywordEntry('vehicle', priority: 10),
    KeywordEntry('automobile', priority: 10),
    KeywordEntry('truck', priority: 9),
    KeywordEntry('bus', priority: 9),
    KeywordEntry('motorcycle', priority: 9),
    KeywordEntry('bicycle', priority: 8),

    // ANIMALS
    KeywordEntry('animal', priority: 9),
    KeywordEntry('dog', priority: 9),
    KeywordEntry('cat', priority: 9),
    KeywordEntry('bird', priority: 8),

    // INDOOR/NON-INFRASTRUCTURE
    KeywordEntry('furniture', priority: 9),
    KeywordEntry('indoor', priority: 7),
    KeywordEntry('room', priority: 8),
    KeywordEntry('table', priority: 7),
    KeywordEntry('chair', priority: 7),
  ];

  // PRIORITY INDICATORS
  static const Map<String, List<KeywordEntry>> priority = {
    'HIGH': [
      KeywordEntry('fire', priority: 10),
      KeywordEntry('burning', priority: 10),
      KeywordEntry('flame', priority: 10),
      KeywordEntry('smoke', priority: 9),
      KeywordEntry('sparking', priority: 10),
      KeywordEntry('spark', priority: 9),
      KeywordEntry('leaning', priority: 9),
      KeywordEntry('falling', priority: 10),
      KeywordEntry('collapsed', priority: 10),
      KeywordEntry('exposed wire', priority: 10),
      KeywordEntry('danger', priority: 9),
      KeywordEntry('emergency', priority: 10),
      KeywordEntry('flood', priority: 9),
      KeywordEntry('severe', priority: 8),
    ],
    'NORMAL': [
      KeywordEntry('broken', priority: 7),
      KeywordEntry('damaged', priority: 7),
      KeywordEntry('crack', priority: 6),
      KeywordEntry('hanging', priority: 6),
      KeywordEntry('leak', priority: 7),
      KeywordEntry('blocked', priority: 6),
      KeywordEntry('clogged', priority: 6),
      KeywordEntry('worn', priority: 5),
    ],
  };

  // CONTEXT KEYWORDS - Help boost confidence
  static const List<KeywordEntry> positiveContext = [
    KeywordEntry('outdoor', priority: 5),
    KeywordEntry('street', priority: 6),
    KeywordEntry('road', priority: 6),
    KeywordEntry('urban', priority: 5),
    KeywordEntry('infrastructure', priority: 8),
    KeywordEntry('public', priority: 5),
    KeywordEntry('utility', priority: 7),
    KeywordEntry('municipal', priority: 6),
    KeywordEntry('city', priority: 5),
    KeywordEntry('metal', priority: 4),
    KeywordEntry('concrete', priority: 4),
    KeywordEntry('structure', priority: 5),
  ];
}

class KeywordEntry {
  final String keyword;
  final int priority; // 1-10, higher = more important
  final bool exactMatch; // true = must match exactly, not just contain

  const KeywordEntry(
    this.keyword, {
    this.priority = 5,
    this.exactMatch = false,
  });
}
