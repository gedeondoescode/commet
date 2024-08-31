import 'dart:async';

import 'package:commet/config/layout_config.dart';
import 'package:commet/ui/atoms/scaled_safe_area.dart';
import 'package:commet/ui/organisms/chat/chat.dart';
import 'package:commet/ui/organisms/room_event_search/room_event_search_widget.dart';
import 'package:commet/ui/organisms/room_members_list/room_members_list.dart';
import 'package:commet/ui/organisms/room_quick_access_menu/room_quick_access_menu_mobile.dart';
import 'package:commet/ui/pages/main/main_page.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/atoms/tile.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

enum _SidePanelState {
  defaultView,
  thread,
  search,
}

class RoomSidePanel extends StatefulWidget {
  const RoomSidePanel({required this.state, super.key});

  final MainPageState state;

  @override
  State<RoomSidePanel> createState() => _RoomSidePanelState();
}

class _RoomSidePanelState extends State<RoomSidePanel> {
  String? _currentThreadId;
  String? get currentThreadId => _currentThreadId;

  _SidePanelState state = _SidePanelState.defaultView;

  late List<StreamSubscription> subs;

  @override
  void initState() {
    subs = [
      EventBus.openThread.stream.listen(onOpenThreadSignal),
      EventBus.closeThread.stream.listen(onCloseThreadSignal),
      EventBus.startSearch.stream.listen(onStartSearch),
    ];
    super.initState();
  }

  @override
  void dispose() {
    for (var sub in subs) {
      sub.cancel();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool showBackButton = state == _SidePanelState.thread;

    Widget result = Stack(
      alignment: Alignment.topRight,
      children: [
        buildPanelContent(context),
        if (showBackButton)
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: tiamat.CircleButton(
                  icon: Icons.close,
                  radius: 24,
                  onPressed: () => setState(() {
                        state = _SidePanelState.defaultView;
                      })),
            ),
          ),
      ],
    );

    if (state == _SidePanelState.thread) {
      result = Flexible(child: result);
    }

    return Material(
      color: Colors.transparent,
      child: result,
    );
  }

  Widget buildPanelContent(BuildContext context) {
    switch (state) {
      case _SidePanelState.defaultView:
        return buildDefaultView();
      case _SidePanelState.thread:
        return buildThread();
      case _SidePanelState.search:
        return buildSearch();
    }
  }

  void onOpenThreadSignal((String, String, String) event) {
    var clientId = event.$1;
    var roomId = event.$2;
    var threadId = event.$3;

    EventBus.openRoom.add((roomId, clientId));

    setState(() {
      _currentThreadId = threadId;
      state = _SidePanelState.thread;
    });
  }

  void onCloseThreadSignal(void event) {
    setState(() {
      _currentThreadId = null;
      state = _SidePanelState.defaultView;
    });
  }

  Widget buildDefaultView() {
    return Column(
      children: [
        if (Layout.mobile)
          RoomQuickAccessMenuViewMobile(
            room: widget.state.currentRoom!,
          ),
        Flexible(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: SizedBox(
                width: Layout.desktop ? 200 : null,
                child: RoomMembersListWidget(widget.state.currentRoom!)),
          ),
        ),
      ],
    );
  }

  Widget buildThread() {
    return Flexible(
      child: Tile(
        caulkPadLeft: true,
        caulkClipTopLeft: true,
        caulkClipBottomLeft: true,
        caulkPadBottom: true,
        child: Stack(
          children: [
            Chat(
              widget.state.currentRoom!,
              threadId: currentThreadId,
              key: ValueKey(
                  "room-timeline-key-${widget.state.currentRoom!.localId}_thread_$currentThreadId"),
            ),
            ScaledSafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: tiamat.CircleButton(
                    icon: Icons.close,
                    radius: 24,
                    onPressed: () => EventBus.closeThread.add(null),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSearch() {
    return SizedBox(
        width: Layout.desktop ? 300 : null,
        child: RoomEventSearchWidget(
          room: widget.state.currentRoom!,
          onEventClicked: (eventId) {
            EventBus.jumpToEvent.add(eventId);
            EventBus.focusTimeline.add(null);
          },
          close: () => setState(() {
            state = _SidePanelState.defaultView;
          }),
        ));
  }

  void onStartSearch(void event) {
    setState(() {
      state = _SidePanelState.search;
    });
  }
}