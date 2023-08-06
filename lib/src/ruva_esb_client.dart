import 'dart:convert';
import 'dart:typed_data';
import 'package:modbus/modbus.dart';
import 'constants.dart';
import 'utils.dart';

class RuvaModbusClient {
  late ModbusClient rClient;
  late int mServerID;
  bool isConnected = false;
  late Duration mMsgFlushTime;

  RuvaModbusClient(
      {String ipAddress = '192.168.4.22',
      int port = 502,
      int serverID = 1,
      ModbusMode mode = ModbusMode.rtu,
      Duration? msgFlushTime,
      Duration? timeout}) {
    rClient = createTcpClient(ipAddress,
        port: port, unitId: serverID, mode: mode, timeout: timeout);
    rClient.setUnitId(serverID);
    mServerID = serverID;
    mMsgFlushTime = msgFlushTime ?? Duration(microseconds: 50);
  }
  Future<void> connect() async {
    await rClient.connect();
    isConnected = true;
  }

  Future<void> close() async {
    isConnected = false;
    await rClient.close();
  }

  void setServer(int serverID) {
    rClient.setUnitId(serverID);
  }

  Future<List> printCards({bool printable = false}) async {
    bool foundDublicates = false;
    var cards = [];
    var ids = [];

    await rClient.writeSingleCoil(Coils.checkMemoryEmpty, true);
    await Future.delayed(Duration(milliseconds: 50));
    List<bool?> x = await rClient.readDiscreteInputs(DInputs.isMemoryEmpty, 1);
    await Future.delayed(Duration(milliseconds: 50));
    if (x[0] ?? true) {
      if (printable) print("The ids is empty");
      return cards;
    }

    while (!foundDublicates) {
      await Future.delayed(Duration(milliseconds: 50));
      await rClient.writeSingleCoil(Coils.alternateCard, true);
      await Future.delayed(Duration(milliseconds: 50));
      Uint16List registers = await rClient.readInputRegisters(IReg.card, 5);
      await Future.delayed(Duration(milliseconds: 50));
      List data = ModbusCardUtils.unpackCardfromUint16List(registers);

      if (ids.contains(data[1].toString())) {
        foundDublicates = true;
      } else {
        ids.add(data[1].toString());
        cards.add(data);
        if (printable) {
          print(ModbusCardUtils.unpackCardasSrting(registers));
        }
      }
    }
    return cards;
  }

  Future<void> addCard(int apartment, List<int> uid) async {
    var card = ModbusCardUtils.packCard(apartment, uid);
    await rClient.writeMultipleRegisters(HReg.card, card);
    await Future.delayed(mMsgFlushTime);
    await rClient.writeSingleCoil(Coils.addCard, true);
  }

  Future<void> addApartemntToBlacklist(int apartment) async {
    List<int> uid = [0, 0, 0, 0];
    var card = ModbusCardUtils.packCard(apartment, uid);

    await rClient.writeMultipleRegisters(HReg.card, card);
    await Future.delayed(mMsgFlushTime);
    await rClient.writeSingleCoil(Coils.addAptToBlacklist, true);
  }

  Future<void> removeApartmentFromBlacklist(int apartment) async {
    List<int> uid = [0, 0, 0, 0];
    var card = ModbusCardUtils.packCard(apartment, uid);

    await rClient.writeMultipleRegisters(HReg.card, card);
    await Future.delayed(mMsgFlushTime);
    await rClient.writeSingleCoil(Coils.removeAptFromBlacklist, true);
  }

  Future<void> deleteCard(List<int> uid) async {
    var card = ModbusCardUtils.packCard(0, uid);
    await rClient.writeMultipleRegisters(HReg.card, card);
    await Future.delayed(mMsgFlushTime);
    await rClient.writeSingleCoil(Coils.deleteCard, true);
  }

  Future<void> stopFunctioning() async {
    await rClient.writeSingleCoil(Coils.state, false);
  }

  Future<void> startFunctioning() async {
    await rClient.writeSingleCoil(Coils.state, true);
  }

  Future<void> setRelay(bool value) async {
    await rClient.writeSingleCoil(Coils.relaySwitch, value);
  }

  Future<void> setBuzzer(bool value) async {
    await rClient.writeSingleCoil(Coils.buzzerSwitch, value);
  }

  Future<void> writeFromBoard(int apartment) async {
    var card = ModbusCardUtils.packCard(apartment, [0x11, 0x55, 0x22, 0x66]);
    await rClient.writeMultipleRegisters(HReg.card, card);
    await Future.delayed(mMsgFlushTime);
    await rClient.writeSingleCoil(Coils.writeFromBoard, true);
  }

  Future<void> deleteFromBoard() async {
    await rClient.writeSingleCoil(Coils.deleteFromBoard, true);
  }

  Future<void> writePressingTime(int pressingTime) async {
    await rClient.writeSingleRegister(HReg.pressingTime, pressingTime);
  }

  Future<void> debugFromSerial() async {
    await rClient.writeSingleCoil(Coils.debugFlag, true);
  }

  Future<void> resetBoard() async {
    await rClient.writeSingleCoil(Coils.resetFlag, true);
  }

  Future<List<int>> getSlaves(int range) async {
    List<int> ids = [];
    for (var i = 1; i <= range; i++) {
      ids.add(i);
      rClient.setUnitId(i);

      await rClient
          .readDiscreteInputs(DInputs.ack, 1)
          .onError((error, stackTrace) {
        ids.remove(i);
        return [false];
      });
    }
    rClient.setUnitId(mServerID);

    return ids;
  }

  Future<void> writeFileRaw(int fileNumber, Uint8List file) async {
    var u8list = file;
    Uint16List registers = Uint16List((file.length / 2).ceil());
    for (var i = 0; i < file.length; i++) {
      registers.buffer.asByteData().setUint8(i, u8list[i]);
    }

    for (int i = 0; i < (file.length / 2).ceil(); i++) {
      registers[i] =
          ((registers[i] >> 8) & 0x00FF) | (0xFF00 & (registers[i] << 8));
    }

    final chunkSize = 64;
    List<Uint16List> spiltedValues = [];
    for (var i = 0; i < registers.length; i += chunkSize) {
      spiltedValues.add(registers.sublist(i,
          i + chunkSize > registers.length ? registers.length : i + chunkSize));
    }
    print("Splitted file to ${spiltedValues.length} files");
    for (var i = 0; i < spiltedValues.length; i++) {
      print("Sending file $i");
      await rClient.writeFileRecord(fileNumber, i, spiltedValues[i]);
      await Future.delayed(mMsgFlushTime);
    }
  }

  Future<void> writeFileUpdate(Uint8List file) async {
    await rClient.writeSingleCoil(Coils.updateFlag, false);
    await Future.delayed(mMsgFlushTime);
    await writeFileRaw(Files.Update, file);
    await Future.delayed(mMsgFlushTime);
    await rClient.writeSingleCoil(Coils.updateFlag, true);
  }

  Future<void> writeFileConfig(String file) async {
    var u8list = Uint8List.fromList(utf8.encode(file));
    await writeFileRaw(Files.Config, u8list);
  }

  Future<void> writeFileCard(int card, String file) async {
    if (card > 250 || card < 1) return;
    var u8list = Uint8List.fromList(utf8.encode(file));
    await writeFileRaw(card, u8list);
  }
}
