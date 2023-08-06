import 'dart:io';

import 'package:ruva_esb_client/ruva_esb_client.dart';

void main() async {
  var rClient = RuvaModbusClient(ipAddress: "192.168.4.22", port: 502, serverID: 1, timeout: Duration(seconds: 5)); // Create Modbus Client
  rClient.setServer(1); // Set Server id if not defines
  await rClient.connect(); // connect to client
  // await rClient.resetBoard();
  // await rClient.addCard(15, [0xff,0x20,0x15,0x1c])
  // await rClient.deleteCard([0xff,0x20,0x15,0x1c]);
  // await rClient.stopFunctioning();
  // await rClient.startFunctioning();
  // print(await rClient.getSlaves(5)); // in range 5 slaves ids
  // await rClient.setRelay(true);
  // await Future.delayed(Duration(seconds: 1));
  // await rClient.setRelay(false);
  // await rClient.setBuzzer(false);
  // await rClient.writeFromBoard(55);
  // await rClient.deleteFromBoard();
  print(await rClient.printCards());
  // await rClient.writePressingTime(5000);
  // await rClient.addApartemntToBlacklist(45);
  // await rClient.removeApartmentFromBlacklist(55);

  //////////////////////////////////////////////
  ///UPDATE FIRMWARE ON AIR
  // var input = await File(
  //         "D:\\Dev\\Ruva\\ruva_smart_elevator\\V1\\Software\\ESB\\.pio\\build\\esp12e\\firmware.bin")
  //     .readAsBytes();
  // await rClient.writeFileUpdate(input);

  ////////////////////////////////
  ///UPDATE CONFIG ON AIR
  // var input = await File("D:\\Dev\\Ruva\\ruva_smart_elevator\\V1\\Software\\ESB\\data\\config.json").readAsString();
  // await rClient.writeFileConfig(input);

  ///////////////////////////////////////////
  ///UPDATE CARDS ON AIR
  // var input = await File("D:\\Dev\\Ruva\\ruva_smart_elevator\\V1\\Software\\ESB\\data\\cards\\23.json").readAsString();
  // await rClient.writeFileCard(23,input);
  // await rClient.debugFromSerial(); // to Print the stack and heap size to serial

  await rClient.close();
}
