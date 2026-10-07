// test/voice_item_name_test.dart
//
// "Dakshini needs 2 kg sugar for 50 rupees" came back as an item
// called "Needs sugar". The customer and the price were extracted
// correctly; the verb between them was not stripped, and the item-name
// extractor keeps whatever survives after the units, prices and
// customer span are removed.
//
// It is the kind of defect that looks like a transcription error to
// the shopkeeper, so they retry the dictation instead of reporting it.

import 'package:flutter_test/flutter_test.dart';
import 'package:billzap/utils/voice_parser.dart';

void main() {
  test('a verb between the customer and the item is not part of it', () {
    final parsed = VoiceParser.parse('dakshini needs 2 kg sugar for 50 rupees');
    expect(parsed.items, hasLength(1));
    final item = parsed.items.single;
    expect(item.name.toLowerCase(), 'sugar',
        reason: 'got "${item.name}"');
    expect(item.qty, 2);
    expect(item.price, 50);
    expect(parsed.customerName?.toLowerCase(), 'dakshini');
  });

  test('the other connecting verbs go too', () {
    // Without a leading name on purpose. A bare name the customer
    // patterns do not recognise stays in the item text, which is a
    // separate and older limitation — these are about the verb.
    for (final phrase in [
      'wants 1 kg rice for 40 rupees',
      'bought 1 kg rice for 40 rupees',
      'ordered 1 kg rice for 40 rupees',
      'give 1 kg rice for 40 rupees',
    ]) {
      final parsed = VoiceParser.parse(phrase);
      expect(parsed.items, isNotEmpty, reason: phrase);
      expect(parsed.items.single.name.toLowerCase(), 'rice',
          reason: '"$phrase" gave "${parsed.items.single.name}"');
    }
  });

  test('a plain order still parses the way it always did', () {
    // The shape the app has always advertised on its own hint text.
    final parsed =
        VoiceParser.parse('For Ravi 2 kg sugar 50 rupees and 1 kg salt 20 rupees');
    expect(parsed.items, hasLength(2));
    expect(parsed.items[0].name.toLowerCase(), contains('sugar'));
    expect(parsed.items[1].name.toLowerCase(), contains('salt'));
    expect(parsed.items[0].price, 50);
    expect(parsed.items[1].price, 20);
  });

  test('a foreign currency word is a price, not part of the name', () {
    // The international half of the same extractor: without the
    // currency word in the marker list, "four hundred shillings" ended
    // up in the item name and the line billed zero.
    final parsed = VoiceParser.parse('2 kg rice at 400 shillings');
    expect(parsed.items, isNotEmpty);
    expect(parsed.items.single.price, 400);
    expect(parsed.items.single.name.toLowerCase(), isNot(contains('shilling')));
  });
}
