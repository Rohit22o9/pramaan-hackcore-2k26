import '../lib/core/services/local_agronomy_engine.dart';

void main() {
  final engine = LocalAgronomyEngine();
  final samples = [
    '400 मल बायो इन 200 एल का वॉटर ओं कॉटन का अर्ली प्रोटेक्शन',
    'सोयाबीन पिकावर अळी नियंत्रणासाठी २०० मिली कोराजन फवारणी केली.',
    'कांद्यावर करपा रोगासाठी ५०० ग्रॅम मॅन्कोझेब २०० लिटर पाण्यात मारले.',
    'मिरचीवर बोकड्या रोगासाठी २५० मिली पेगॅसस स्प्रे केला.',
    'गेहूं के खेत में पीला रतुआ दिखा है, 200 मिली प्रोपिकोनाज़ोल का स्प्रे किया।',
    'आज शाम को 500 मिली इफको नैनो यूरिया का पर्णीय छिड़काव धान की फसल में किया गया।'
  ];

  for (final s in samples) {
    final r = engine.parseOfflineObservation(transcript: s);
    print('INPUT: $s');
    print('-> Crop: ${r["crop"]} | Action: ${r["action_type"]} | Product: ${r["product_name"]} | Dose: ${r["dosage"]} | Pest: ${r["target_pest"]}');
    print('------------------------------------------------------------');
  }
}
