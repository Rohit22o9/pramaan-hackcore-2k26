import 'package:flutter/material.dart';

class PendingSyncItem {
  final String id;
  final String title;
  final String type;
  final String timestamp;
  final String sizeKb;
  String status; // PENDING, SYNCING, SYNCED, FAILED

  PendingSyncItem({
    required this.id,
    required this.title,
    required this.type,
    required this.timestamp,
    required this.sizeKb,
    this.status = 'PENDING',
  });
}

class SyncProvider extends ChangeNotifier {
  bool _isOnline = true;
  bool _isSyncing = false;
  final List<PendingSyncItem> _syncQueue = [
    PendingSyncItem(
      id: 'Q-01',
      title: 'Voice Note: Foliar Nitrogen Application',
      type: 'VOICE_AUDIO',
      timestamp: 'Today, 08:30 AM',
      sizeKb: '420 KB',
      status: 'PENDING',
    ),
    PendingSyncItem(
      id: 'Q-02',
      title: 'Crop Photo: Lower Canopy Leaf Cluster',
      type: 'HIGH_RES_IMAGE',
      timestamp: 'Today, 08:32 AM',
      sizeKb: '2.1 MB',
      status: 'PENDING',
    ),
  ];

  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  List<PendingSyncItem> get syncQueue => _syncQueue;
  int get pendingCount => _syncQueue.where((i) => i.status == 'PENDING').length;

  void toggleNetwork(bool online) {
    _isOnline = online;
    notifyListeners();
  }

  Future<void> syncAll() async {
    if (!_isOnline) return;
    _isSyncing = true;
    notifyListeners();

    for (var item in _syncQueue) {
      item.status = 'SYNCING';
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 700));
      item.status = 'SYNCED';
    }

    _isSyncing = false;
    notifyListeners();
  }

  void clearSynced() {
    _syncQueue.removeWhere((i) => i.status == 'SYNCED');
    notifyListeners();
  }
}
