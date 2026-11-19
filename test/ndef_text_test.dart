import 'package:flutter_test/flutter_test.dart';
import 'package:smart_health_monitor/models/detected_thing.dart';
import 'package:smart_health_monitor/services/ndef_text.dart';
import 'package:smart_health_monitor/services/nfc_bridge_client.dart';

void main() {
  test('an empty 3M sticker has a chip number and no stored text', () {
    final snapshot = NfcSnapshot.fromJson({
      'ok': true,
      'present': true,
      'readerName': 'ACS ACR122U PICC Interface 0',
      'uid': '0413E9243B0289',
      'pages': [
        '0413E976',
        '243B0289',
        '94480000',
        'E1103E00',
        '0300FE00',
        '00000000',
      ],
    });

    expect(snapshot.uid, '04 13 E9 24 3B 02 89');
    expect(snapshot.message, isNull);
  });

  test('stored sticker text is read from the chip pages', () {
    final text = ndefTextFromPages([
      '00000000',
      '00000000',
      '00000000',
      'E1103E00',
      '0309D101',
      '05540265',
      '6E336DFE',
    ]);

    expect(text, '3m');
  });

  test('the Mario toy sticker opens Mario details', () {
    final thing = thingForUid('04 53 15 EC 39 02 89');

    expect(thing?.name, 'Mario');
    expect(thing?.kind, 'Toy');
    expect(thing?.details.first.value, 'Mario');
    expect(thingForUid('04 13 60 01 3B 02 89')?.name, 'Mario');
    expect(thingForUid('04 43 7E 03 3B 02 89')?.name, 'Mario');
  });

  test('Mario is announced with the full detail', () {
    final speech = announcementFor('04437E033B0289');

    expect(speech, contains('This item is Mario'));
    expect(speech, contains('Toy'));
    expect(speech, contains('Toy figure'));
    expect(announcementFor('00000000000000'), 'Unknown thing detected.');
  });
}
