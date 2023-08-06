import 'dart:typed_data';
import 'package:convert/convert.dart';

class ModbusCardUtils {
  static Uint16List packCard(int apartment, List<int> uid) {
    assert((uid.length == 4 || uid.length == 7),
        "Card should be 4 or 7 bytes only");
    BytesBuilder builder = BytesBuilder();
    builder.add(Uint8List.fromList([apartment << 8, apartment]));
    builder.add([uid.length]);
    builder.add(Uint8List.fromList(uid));
    if (uid.length == 4) {
      builder.add([0, 0, 0]);
    }

    Uint16List registers = builder.toBytes().buffer.asUint16List(0, 5);
    //Convert for little to big endian
    for (int i = 0; i < 5; i++) {
      registers[i] =
          ((registers[i] >> 8) & 0x00FF) | (0xFF00 & (registers[i] << 8));
    }

    return registers;
  }

  static List unpackCardfromUint8List(Uint8List data) {
    int apartment = data[0] << 8 | data[1];
    Uint8List uid = Uint8List(data[2]);
    uid = data.sublist(3);

    return [apartment, uid];
  }

  static List unpackCardfromUint16List(Uint16List registers) {
    int apartment = registers[0];
    int size = (registers[1] >> 8) & 0x00FF;
    Uint8List uid = Uint8List(size);

    uid[0] = (registers[1]) & 0x00FF;
    uid[1] = (registers[2] >> 8) & 0x00FF;
    uid[2] = (registers[2]) & 0x00FF;
    uid[3] = (registers[3] >> 8) & 0x00FF;
    if (size > 4) {
      uid[4] = (registers[3]) & 0x00FF;
      uid[5] = (registers[4] >> 8) & 0x00FF;
      uid[6] = (registers[4]) & 0x00FF;
    }
    return [apartment, uid];
  }

  static String unpackCardasSrting(data) {
    List card = [];
    if (data is Uint8List) {
      card = unpackCardfromUint8List(data);
    } else if (data is Uint16List) {
      card = unpackCardfromUint16List(data);
    }

    String cardasString = "{ apartment: ";
    cardasString += card[0].toString();
    cardasString += ", uid: 0x";
    cardasString += hex.encode(card[1]).toString();
    cardasString += " }";
    return cardasString;
  }
}
