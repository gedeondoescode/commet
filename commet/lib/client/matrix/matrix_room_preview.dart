import 'package:commet/client/matrix/matrix_peer.dart';
import 'package:commet/client/room_preview.dart';
import 'package:flutter/widgets.dart';
import 'package:matrix/matrix.dart';

class MatrixSpaceRoomChunkPreview implements RoomPreview {
  SpaceRoomsChunk chunk;
  Client matrixClient;
  @override
  ImageProvider? avatar;

  @override
  String get displayName => chunk.name ?? chunk.canonicalAlias ?? roomId;

  @override
  String get roomId => chunk.roomId;

  @override
  String? get topic => chunk.topic;

  @override
  late RoomPreviewType type;

  MatrixSpaceRoomChunkPreview(this.chunk, this.matrixClient) {
    avatar = chunk.avatarUrl != null
        ? NetworkImage(chunk.avatarUrl!
            .getThumbnail(matrixClient, width: 60, height: 60)
            .toString())
        : null;

    if (chunk.roomType == "m.space") {
      type = RoomPreviewType.space;
    } else {
      type = RoomPreviewType.room;
    }
  }

  @override
  Color get color => MatrixPeer.hashColor(roomId);
}
