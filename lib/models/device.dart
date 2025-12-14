import 'package:equatable/equatable.dart';

enum DeviceType { mobile, tablet, desktop, web }

enum DeviceStatus { online, offline, syncing }

class ConnectedDevice extends Equatable {
  final String id;
  final String name;
  final DeviceType type;
  final DeviceStatus status;
  final String? ipAddress;
  final DateTime connectedAt;
  final bool isHost;

  const ConnectedDevice({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    this.ipAddress,
    required this.connectedAt,
    this.isHost = false,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        status,
        ipAddress,
        connectedAt,
        isHost,
      ];

  ConnectedDevice copyWith({
    String? id,
    String? name,
    DeviceType? type,
    DeviceStatus? status,
    String? ipAddress,
    DateTime? connectedAt,
    bool? isHost,
  }) {
    return ConnectedDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      status: status ?? this.status,
      ipAddress: ipAddress ?? this.ipAddress,
      connectedAt: connectedAt ?? this.connectedAt,
      isHost: isHost ?? this.isHost,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.toString(),
      'status': status.toString(),
      'ipAddress': ipAddress,
      'connectedAt': connectedAt.toIso8601String(),
      'isHost': isHost,
    };
  }

  factory ConnectedDevice.fromJson(Map<String, dynamic> json) {
    return ConnectedDevice(
      id: json['id'] as String,
      name: json['name'] as String,
      type: DeviceType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => DeviceType.mobile,
      ),
      status: DeviceStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => DeviceStatus.offline,
      ),
      ipAddress: json['ipAddress'] as String?,
      connectedAt: DateTime.parse(json['connectedAt'] as String),
      isHost: json['isHost'] as bool? ?? false,
    );
  }

  String get deviceIcon {
    switch (type) {
      case DeviceType.mobile:
        return '📱';
      case DeviceType.tablet:
        return '📲';
      case DeviceType.desktop:
        return '💻';
      case DeviceType.web:
        return '🌐';
    }
  }
}
