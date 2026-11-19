class ThingDetail {
  const ThingDetail(this.label, this.value);

  final String label;
  final String value;
}

class DetectedThing {
  const DetectedThing({
    required this.name,
    required this.kind,
    required this.details,
  });

  final String name;
  final String kind;
  final List<ThingDetail> details;
}

DetectedThing? thingForUid(String? uid) {
  final key = (uid ?? '').replaceAll(RegExp(r'[^0-9A-Fa-f]'), '').toUpperCase();
  const mario = DetectedThing(
    name: 'Mario',
    kind: 'Toy',
    details: [
      ThingDetail('Character', 'Mario'),
      ThingDetail('Item', 'Toy figure'),
      ThingDetail('Sticker on', 'This toy'),
    ],
  );
  const known = {
    '045315EC390289': mario,
    '041360013B0289': mario,
    '04437E033B0289': mario,
  };
  return known[key];
}

String announcementFor(String? uid) {
  final thing = thingForUid(uid);
  if (thing == null) {
    return 'Unknown thing detected.';
  }
  final details = thing.details
      .map((detail) => '${detail.label}. ${detail.value}.')
      .join(' ');
  return 'This item is ${thing.name}. ${thing.kind}. $details';
}
