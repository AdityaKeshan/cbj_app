import 'package:cybear_jinni/application/blinds/blinds_actor/blinds_actor_bloc.dart';
import 'package:cybear_jinni/application/devices/device_watcher/device_watcher_bloc.dart';
import 'package:cybear_jinni/application/lights/lights_actor/lights_actor_bloc.dart';
import 'package:cybear_jinni/application/smart_tv/smart_tv_actor/smart_tv_actor_bloc.dart';
import 'package:cybear_jinni/application/switches/switches_actor/switches_actor_bloc.dart';
import 'package:cybear_jinni/domain/devices/abstract_device/device_entity_abstract.dart';
import 'package:cybear_jinni/domain/devices/generic_blinds_device/generic_blinds_entity.dart';
import 'package:cybear_jinni/domain/devices/generic_boiler_device/generic_boiler_entity.dart';
import 'package:cybear_jinni/domain/devices/generic_light_device/generic_light_entity.dart';
import 'package:cybear_jinni/domain/devices/generic_rgbw_light_device/generic_rgbw_light_entity.dart';
import 'package:cybear_jinni/domain/devices/generic_smart_tv/generic_smart_tv_entity.dart';
import 'package:cybear_jinni/domain/devices/generic_switch_device/generic_switch_entity.dart';
import 'package:cybear_jinni/domain/room/room_entity.dart';
import 'package:cybear_jinni/domain/room/value_objects_room.dart';
import 'package:cybear_jinni/infrastructure/core/gen/cbj_hub_server/protoc_as_dart/cbj_hub_server.pbgrpc.dart';
import 'package:cybear_jinni/injection.dart';
import 'package:cybear_jinni/presentation/core/theme_data.dart';
import 'package:cybear_jinni/presentation/device_full_screen_page/lights/widgets/critical_light_failure_display_widget.dart';
import 'package:cybear_jinni/presentation/home_page/tabs/smart_devices_tab/devices_in_the_room_blocks/blinds_in_the_room.dart';
import 'package:cybear_jinni/presentation/home_page/tabs/smart_devices_tab/devices_in_the_room_blocks/boilers_in_the_room.dart';
import 'package:cybear_jinni/presentation/home_page/tabs/smart_devices_tab/devices_in_the_room_blocks/lights_in_the_room_block.dart';
import 'package:cybear_jinni/presentation/home_page/tabs/smart_devices_tab/devices_in_the_room_blocks/rgbw_lights_in_the_room_block.dart';
import 'package:cybear_jinni/presentation/home_page/tabs/smart_devices_tab/devices_in_the_room_blocks/smart_tv_in_the_room.dart';
import 'package:cybear_jinni/presentation/home_page/tabs/smart_devices_tab/devices_in_the_room_blocks/switches_in_the_room_block.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SmartDevicesByRooms extends StatelessWidget {
  Map<String?, List<DeviceEntityAbstract>> listOfDevicesInDiscoverdRoom({
    required List<RoomEntity?> rooms,
    required List<DeviceEntityAbstract?> devicesList,
  }) {
    final List<DeviceEntityAbstract?> devicesListTemp = List.of(devicesList);

    final Map<String?, List<DeviceEntityAbstract>> tempDevicesByRooms =
        <String, List<DeviceEntityAbstract>>{};

    /// Adding discovered room first so it will be the last in
    /// the list
    for (final RoomEntity? room in rooms) {
      if (room != null &&
          room.uniqueId.getOrCrash() ==
              RoomUniqueId.discoveredRoomId().getOrCrash()) {
        final String roomId = room.uniqueId.getOrCrash();
        tempDevicesByRooms[roomId] = [];

        /// Loops on the devices in the room
        for (final String deviceId in room.roomDevicesId.getOrCrash()) {
          /// Check if app already received the device, it could also
          /// be on the way
          for (final DeviceEntityAbstract? device in devicesListTemp) {
            if (device != null && device.uniqueId.getOrCrash() == deviceId) {
              tempDevicesByRooms[roomId]!.add(device);

              devicesListTemp.remove(device);
              break;
            }
          }
        }
        break;
      }
    }
    return tempDevicesByRooms;
  }

  Map<String?, List<DeviceEntityAbstract>> listOfDevicesInRooms({
    required List<RoomEntity?> rooms,
    required List<DeviceEntityAbstract?> devicesList,
  }) {
    final List<DeviceEntityAbstract?> devicesListTemp = List.of(devicesList);

    final Map<String?, List<DeviceEntityAbstract>> tempDevicesByRooms =
        <String, List<DeviceEntityAbstract>>{};

    /// Loops on the rooms
    for (final RoomEntity? room in rooms) {
      if (room != null &&
          room.uniqueId.getOrCrash() !=
              RoomUniqueId.discoveredRoomId().getOrCrash()) {
        final String roomId = room.uniqueId.getOrCrash();
        tempDevicesByRooms[roomId] = [];

        /// Loops on the devices in the room
        for (final String deviceId in room.roomDevicesId.getOrCrash()) {
          /// Check if app already received the device, it could also
          /// be on the way
          for (final DeviceEntityAbstract? device in devicesListTemp) {
            if (device != null && device.uniqueId.getOrCrash() == deviceId) {
              tempDevicesByRooms[roomId]!.add(device);

              devicesListTemp.remove(device);
              break;
            }
          }
        }
        if (tempDevicesByRooms[roomId]!.isEmpty) {
          tempDevicesByRooms.remove(roomId);
        }
      }
    }

    return tempDevicesByRooms;
  }

  Map<String?, List<DeviceEntityAbstract>>
      listOfDevicesInAllDevicesAndSummaryRooms({
    required List<RoomEntity?> rooms,
    required List<DeviceEntityAbstract?> devicesList,
  }) {
    final Map<String?, List<DeviceEntityAbstract>> tempDevicesByRooms =
        <String, List<DeviceEntityAbstract>>{};

    final RoomEntity allDevicesRoom = RoomEntity.empty().copyWith(
      defaultName: RoomDefaultName('All Devices'),
    );
    final String allDevicesRoomId = allDevicesRoom.uniqueId.getOrCrash();
    tempDevicesByRooms[allDevicesRoomId] = [];

    for (final DeviceEntityAbstract? device in devicesList) {
      if (device != null) {
        allDevicesRoom.addDeviceId(device.uniqueId.getOrCrash());
        tempDevicesByRooms[allDevicesRoomId]!.add(device);
      }
    }
    rooms.add(allDevicesRoom);

    final RoomEntity summaryDevicesRoom = RoomEntity.empty().copyWith(
      defaultName: RoomDefaultName('Summary'),
    );

    final String summaryRoomId = summaryDevicesRoom.uniqueId.getOrCrash();
    tempDevicesByRooms[summaryRoomId] = [];

    for (final DeviceEntityAbstract? device in devicesList) {
      if (device != null && isDeviceShouldBeSownInSummaryRoom(device)) {
        summaryDevicesRoom.addDeviceId(device.uniqueId.getOrCrash());
        tempDevicesByRooms[summaryRoomId]!.add(device);
      }
    }
    rooms.add(summaryDevicesRoom);

    return tempDevicesByRooms;
  }

  bool isDeviceShouldBeSownInSummaryRoom(DeviceEntityAbstract deviceEntity) {
    if (deviceEntity is GenericBlindsDE) {
      /// TODO: Need to check position open and not moving up
      return deviceEntity.blindsSwitchState?.getOrCrash() ==
          DeviceActions.moveUp.toString();
    } else if (deviceEntity is GenericBoilerDE) {
      return deviceEntity.boilerSwitchState?.getOrCrash() ==
          DeviceActions.on.toString();
    } else if (deviceEntity is GenericLightDE) {
      return deviceEntity.lightSwitchState?.getOrCrash() ==
          DeviceActions.on.toString();
    } else if (deviceEntity is GenericRgbwLightDE) {
      return deviceEntity.lightSwitchState?.getOrCrash() ==
          DeviceActions.on.toString();
    } else if (deviceEntity is GenericSmartTvDE) {
      return deviceEntity.smartTvSwitchState?.getOrCrash() ==
          DeviceActions.on.toString();
    } else if (deviceEntity is GenericSwitchDE) {
      return deviceEntity.switchState?.getOrCrash() ==
          DeviceActions.on.toString();
    }
    return false;
  }

  /// RoomId than TypeName than list of devices of this type in
  /// this room
  Map<String, Map<String, List<DeviceEntityAbstract>>>
      mapOfRoomsIdWithListOfDevices({
    required Map<String?, List<DeviceEntityAbstract>> tempDevicesByRooms,
  }) {
    final Map<String, Map<String, List<DeviceEntityAbstract>>>
        tempDevicesByRoomsByType =
        <String, Map<String, List<DeviceEntityAbstract>>>{};

    final Map<String, List<GenericLightDE>> tempDevicesByType =
        <String, List<GenericLightDE>>{};

    tempDevicesByRooms.forEach((k, v) {
      tempDevicesByRoomsByType[k!] = {};
      v.forEach((element) {
        if (tempDevicesByRoomsByType[k]![element.deviceTypes.getOrCrash()] ==
            null) {
          tempDevicesByRoomsByType[k]![element.deviceTypes.getOrCrash()] = [
            element
          ];
        } else {
          tempDevicesByRoomsByType[k]![element.deviceTypes.getOrCrash()]!
              .add(element);
        }
      });
    });
    return tempDevicesByRoomsByType;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DeviceWatcherBloc, DeviceWatcherState>(
      builder: (context, state) {
        return state.map(
          initial: (_) => Container(),
          loadInProgress: (_) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              CircularProgressIndicator(),
              SizedBox(
                height: 30,
              ),
              Text(
                'Searching for CyBear Jinni Hub',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          loadSuccess: (state) {
            if (state.devices.size != 0) {
              final Map<String?, List<DeviceEntityAbstract>>
                  tempDevicesByRooms = <String, List<DeviceEntityAbstract>>{};
              //
              // /// Organized list named tempDevicesByRooms of device by room id
              // for (int i = 0; i < state.devices.size; i++) {
              //   if (state.devices[i] == null) {
              //     continue;
              //   }
              //   final DeviceEntityAbstract tempDevice = state.devices[i]!;
              // }

              final List<DeviceEntityAbstract?> devicesList =
                  state.devices.iter.toList();

              final List<RoomEntity?> roomsList = state.rooms.iter.toList();

              tempDevicesByRooms.addAll(
                listOfDevicesInDiscoverdRoom(
                  rooms: roomsList,
                  devicesList: devicesList,
                ),
              );

              tempDevicesByRooms.addAll(
                listOfDevicesInRooms(
                  rooms: roomsList,
                  devicesList: devicesList,
                ),
              );
              tempDevicesByRooms.addAll(
                listOfDevicesInAllDevicesAndSummaryRooms(
                  rooms: roomsList,
                  devicesList: devicesList,
                ),
              );

              final Map<String, Map<String, List<DeviceEntityAbstract>>>
                  tempDevicesByRoomsByType =
                  <String, Map<String, List<DeviceEntityAbstract>>>{};

              tempDevicesByRoomsByType.addAll(
                mapOfRoomsIdWithListOfDevices(
                  tempDevicesByRooms: tempDevicesByRooms,
                ),
              );

              int gradientColorCounter = 2;

              return SingleChildScrollView(
                reverse: true,
                child: Column(
                  children: [
                    if (tempDevicesByRooms.length == 1)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        alignment: Alignment.center,
                        child: Image.asset(
                          'assets/cbj_logo.png',
                          width: 200.0,
                          fit: BoxFit.fill,
                        ),
                      ),
                    Container(
                      color: Colors.black.withOpacity(0.2),
                      padding: const EdgeInsets.symmetric(horizontal: 50),
                      margin: const EdgeInsets.symmetric(vertical: 20),
                      child: Stack(
                        children: <Widget>[
                          Text(
                            'Rooms',
                            style: TextStyle(
                              fontSize: 35,
                              foreground: Paint()
                                ..style = PaintingStyle.stroke
                                ..strokeWidth = 3
                                ..color = Colors.black.withOpacity(0.2),
                            ),
                          ),
                          Text(
                            'Rooms',
                            style: TextStyle(
                              fontSize: 35,
                              color:
                                  Theme.of(context).textTheme.bodyText1!.color,
                            ),
                          ),
                        ],
                      ),
                    ),

                    /// Builds the rooms
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemBuilder: (context, index) {
                        gradientColorCounter++;

                        if (gradientColorCounter >= gradientColorsList.length) {
                          gradientColorCounter = 3;
                        }

                        Color spacingColor = Colors.transparent;

                        if (index >= roomsList.length - 3) {
                          spacingColor = Colors.black;
                        }

                        List<Color> roomColorGradiant =
                            gradientColorsList[gradientColorCounter];

                        /// Color for Discovered page
                        // TODO: After adding 4 more colors to
                        // gradientColorsList uncomment this section
                        // if (index == 0) {
                        //   roomColorGradiant = gradientColorsList[2];
                        // }

                        /// Color for All Devices page
                        if (index == roomsList.length - 3) {
                          roomColorGradiant = gradientColorsList[1];
                        }

                        /// Color for Summary page
                        else if (index == roomsList.length - 2) {
                          roomColorGradiant = gradientColorsList[0];
                        }

                        final String roomId =
                            tempDevicesByRoomsByType.keys.elementAt(index);

                        final RoomEntity roomEntity = roomsList.firstWhere(
                          (element) => element!.uniqueId.getOrCrash() == roomId,
                        )!;

                        int numberOfDevicesInTheRoom = 0;

                        tempDevicesByRoomsByType[roomId]!.forEach((key, value) {
                          value.forEach((element) {
                            numberOfDevicesInTheRoom++;
                          });
                        });

                        return Container(
                          color: spacingColor,
                          child: Container(
                            margin: const EdgeInsets.only(top: 5),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: roomColorGradiant,
                                begin: Alignment.bottomLeft,
                                end: Alignment.topLeft,
                              ),
                              border: const Border.symmetric(
                                horizontal: BorderSide(width: 0.3),
                              ),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.1),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(top: 12),
                                    alignment: Alignment.topCenter,
                                    child: Text(
                                      roomsList
                                          .firstWhere(
                                            (element) =>
                                                element!.uniqueId
                                                    .getOrCrash() ==
                                                roomId,
                                          )!
                                          .defaultName
                                          .getOrCrash(),
                                      style: TextStyle(
                                        fontSize: 20,
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyText1!
                                            .color,
                                      ),
                                    ),
                                  ),
                                  if (numberOfDevicesInTheRoom == 1)
                                    Text(
                                      '$numberOfDevicesInTheRoom device',
                                      style: const TextStyle(fontSize: 12),
                                    )
                                  else
                                    Text(
                                      '$numberOfDevicesInTheRoom devices',
                                      style: const TextStyle(fontSize: 12),
                                    ),

                                  /// Build the devices in the room by type
                                  GridView.builder(
                                    padding: EdgeInsets.zero,
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        const SliverGridDelegateWithMaxCrossAxisExtent(
                                      maxCrossAxisExtent: 200,
                                      childAspectRatio: 1.4,
                                      crossAxisSpacing: 8,
                                      mainAxisSpacing: 20,
                                    ),
                                    itemCount: tempDevicesByRoomsByType[roomId]!
                                        .keys
                                        .length,
                                    itemBuilder:
                                        (BuildContext ctx, secondIndex) {
                                      final String deviceType =
                                          tempDevicesByRoomsByType[roomId]!
                                              .keys
                                              .elementAt(secondIndex);
                                      if (deviceType ==
                                          DeviceTypes.light.toString()) {
                                        return BlocProvider(
                                          create: (context) =>
                                              getIt<LightsActorBloc>(),
                                          child: LightsInTheRoomBlock
                                              .withAbstractDevice(
                                            roomEntity: roomEntity,
                                            tempDeviceInRoom:
                                                tempDevicesByRoomsByType[
                                                    roomId]![deviceType]!,
                                            tempRoomColorGradiant:
                                                roomColorGradiant,
                                          ),
                                        );
                                      } else if (deviceType ==
                                          DeviceTypes.rgbwLights.toString()) {
                                        return BlocProvider(
                                          create: (context) =>
                                              getIt<LightsActorBloc>(),
                                          child: RgbwLightsInTheRoomBlock
                                              .withAbstractDevice(
                                            roomEntity: roomEntity,
                                            tempDeviceInRoom:
                                                tempDevicesByRoomsByType[
                                                    roomId]![deviceType]!,
                                            tempRoomColorGradiant:
                                                roomColorGradiant,
                                          ),
                                        );
                                      } else if (deviceType ==
                                          DeviceTypes.switch_.toString()) {
                                        return BlocProvider(
                                          create: (context) =>
                                              getIt<SwitchesActorBloc>(),
                                          child: SwitchesInTheRoomBlock
                                              .withAbstractDevice(
                                            roomEntityTemp:
                                                roomsList.firstWhere(
                                              (element) =>
                                                  element!.uniqueId
                                                      .getOrCrash() ==
                                                  roomId,
                                            )!,
                                            tempDeviceInRoom:
                                                tempDevicesByRoomsByType[
                                                    roomId]![deviceType]!,
                                            tempRoomColorGradiant:
                                                roomColorGradiant,
                                          ),
                                        );
                                      } else if (deviceType ==
                                          DeviceTypes.blinds.toString()) {
                                        return BlocProvider(
                                          create: (context) =>
                                              getIt<BlindsActorBloc>(),
                                          child: BlindsInTheRoom
                                              .withAbstractDevice(
                                            roomEntity: roomEntity,
                                            tempDeviceInRoom:
                                                tempDevicesByRoomsByType[
                                                    roomId]![deviceType]!,
                                            temprRoomColorGradiant:
                                                roomColorGradiant,
                                          ),
                                        );
                                      } else if (deviceType ==
                                          DeviceTypes.boiler.toString()) {
                                        //TODO: Boiler should not user Blinds block
                                        return BlocProvider(
                                          create: (context) =>
                                              getIt<BlindsActorBloc>(),
                                          child: BoilersInTheRoom
                                              .withAbstractDevice(
                                            roomEntity: roomEntity,
                                            tempDeviceInRoom:
                                                tempDevicesByRoomsByType[
                                                    roomId]![deviceType]!,
                                            tempRoomColorGradiant:
                                                roomColorGradiant,
                                          ),
                                        );
                                      } else if (deviceType ==
                                          DeviceTypes.smartTV.toString()) {
                                        return BlocProvider(
                                          create: (context) =>
                                              getIt<SmartTvActorBloc>(),
                                          child: SmartTvInTheRoom
                                              .withAbstractDevice(
                                            roomEntity: roomEntity,
                                            tempDeviceInRoom:
                                                tempDevicesByRoomsByType[
                                                    roomId]![deviceType]!,
                                            tempRoomColorGradiant:
                                                roomColorGradiant,
                                          ),
                                        );
                                      }
                                      return Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: const [
                                          CircleAvatar(
                                            child: FaIcon(
                                              FontAwesomeIcons.lowVision,
                                              color: Colors.red,
                                            ),
                                          ),
                                          Text('Not Supported'),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      itemCount: tempDevicesByRoomsByType.keys.length,
                    ),
                  ],
                ),
              );
            } else {
              return GestureDetector(
                onTap: () {
                  Fluttertoast.showToast(
                    msg: 'Add new device by pressing the plus button',
                    toastLength: Toast.LENGTH_LONG,
                    gravity: ToastGravity.CENTER,
                    backgroundColor: Colors.blueGrey,
                    textColor: Theme.of(context).textTheme.bodyText1!.color,
                    fontSize: 16.0,
                  );
                },
                child: SingleChildScrollView(
                  reverse: true,
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 30),
                        alignment: Alignment.center,
                        child: Image.asset(
                          'assets/cbj_logo.png',
                          fit: BoxFit.fitHeight,
                        ),
                      ),
                      Align(
                        alignment: Alignment.topCenter,
                        child: Text(
                          'Devices list is empty',
                          style: TextStyle(
                            fontSize: 30,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          },
          loadFailure: (state) {
            return CriticalLightFailureDisplay(
              failure: state.devicesFailure,
            );
          },
          error: (Error value) {
            return const Text('Error');
          },
        );
      },
    );
  }
}
