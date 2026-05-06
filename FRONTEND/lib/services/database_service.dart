import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as dev;

class DatabaseService {
  static const String scansBox = 'scans';
  static const String patientsBox = 'patients';
  static const String appointmentsBox = 'appointments';
  static const String syncQueueBox = 'sync_queue';

  static Future<void> init() async {
    final boxes = [scansBox, patientsBox, appointmentsBox, syncQueueBox];
    
    for (final boxName in boxes) {
      try {
        await Hive.openBox(boxName);
      } catch (e) {
        dev.log("Error opening Hive box '$boxName': $e. Attempting to repair by deleting box.");
        try {
          await Hive.deleteBoxFromDisk(boxName);
          await Hive.openBox(boxName);
        } catch (deleteError) {
          dev.log("Critical error repairing box '$boxName': $deleteError");
        }
      }
    }
    
    // Start background sync listener
    _initSyncListener();
  }

  // --- Generic Save to Local & Sync Queue ---
  
  static Future<void> saveLocal(String boxName, String id, Map<String, dynamic> data) async {
    final box = Hive.box(boxName);
    await box.put(id, data);
    
    // Add to sync queue if we want to ensure it gets to Firestore
    await _addToSyncQueue(boxName, id, data);
  }

  static Future<void> _addToSyncQueue(String collection, String id, Map<String, dynamic> data) async {
    final box = Hive.box(syncQueueBox);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    await box.put('$collection-$id-$timestamp', {
      'collection': collection,
      'documentId': id,
      'data': data,
      'queuedAt': timestamp,
    });
    
    // Attempt immediate sync
    syncPendingData();
  }

  // --- Real-time Sync Logic ---

  static void _initSyncListener() {
     Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.isNotEmpty && results.first != ConnectivityResult.none) {
        dev.log("Network restored. Syncing pending data...");
        syncPendingData();
      }
    });
  }

  static Future<void> syncPendingData() async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.isEmpty || connectivity.first == ConnectivityResult.none) return;

    final box = Hive.box(syncQueueBox);
    if (box.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final keys = box.keys.toList();
    for (var key in keys) {
      final rawEntry = box.get(key);
      if (rawEntry == null) continue;
      
      final entry = Map<String, dynamic>.from(rawEntry);
      final collection = entry['collection'];
      final docId = entry['documentId'];
      final rawData = entry['data'];
      if (rawData == null) continue;
      
      final data = Map<String, dynamic>.from(rawData);

      try {
        // Correctly route to Firestore based on collection type
        // This assumes a standard structure where scans/appointments are subcollections of clinics
        // or top level collections depending on implementation.
        
        // For this app, patients/scans/appointments are usually scoped.
        // We'll use a dynamic strategy or hardcoded routes.
        
        if (collection == scansBox) {
          // Scans usually go into clinics/{clinicId}/scans/{scanId}
          // We need the clinicId here. If it's missing from data, we'd need to fetch it.
          final clinicId = data['clinicId'];
          if (clinicId != null) {
            await FirebaseFirestore.instance
              .collection('clinics')
              .doc(clinicId)
              .collection('scans')
              .doc(docId)
              .set(data, SetOptions(merge: true));
          }
        } else if (collection == appointmentsBox) {
           final clinicId = data['clinicId'];
           if (clinicId != null) {
            await FirebaseFirestore.instance
              .collection('clinics')
              .doc(clinicId)
              .collection('appointments')
              .doc(docId)
              .set(data, SetOptions(merge: true));
          }
        } else if (collection == patientsBox) {
           final clinicId = data['clinicId'];
           if (clinicId != null) {
             await FirebaseFirestore.instance
              .collection('clinics')
              .doc(clinicId)
              .collection('patients')
              .doc(docId)
              .set(data, SetOptions(merge: true));
           }
        }

        // Remove from queue on success
        await box.delete(key);
        dev.log("Synced $collection ($docId) successfully.");
      } catch (e) {
        dev.log("Sync error for $key: $e");
        // Keep in queue to retry later
      }
    }
  }

  // --- Read Methods (Local First) ---

  static List<Map<String, dynamic>> getAllLocal(String boxName) {
    final box = Hive.box(boxName);
    return box.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Map<String, dynamic>? getLocal(String boxName, String id) {
    final box = Hive.box(boxName);
    final data = box.get(id);
    return data != null ? Map<String, dynamic>.from(data) : null;
  }
}
