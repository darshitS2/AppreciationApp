// lib/export_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:universal_html/html.dart' as html; // This is for web
import 'package:flutter/foundation.dart' show kIsWeb; // This tells us if we are on the web
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExportService {
  Future<void> exportAppreciationsToCsv() async {
    try {
      // 1. Fetch all users and create a map of UID -> Full Name
      final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
      final userMap = {for (var doc in usersSnapshot.docs) doc.id: doc.data()['fullName'] ?? 'Unknown User'};

      // 2. Fetch all appreciations
      final appreciationsSnapshot = await FirebaseFirestore.instance.collection('appreciations').orderBy('timestamp', descending: true).get();
      
      // 3. Prepare the data for the CSV file
      List<List<dynamic>> rows = [];
      // Add the header row
      rows.add(["Date", "From", "To", "Company Value", "Message"]);

      // Add the data rows
      for (var doc in appreciationsSnapshot.docs) {
        final data = doc.data();
        final timestamp = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
        
        // Use the userMap to get names from UIDs
        final fromName = userMap[data['from_uid']] ?? 'Unknown';
        final toName = userMap[data['to_uid']] ?? 'Unknown';

        rows.add([
          timestamp.toIso8601String(),
          fromName,
          toName,
          data['value'] ?? 'General',
          data['message'] ?? '',
        ]);
      }

      // 4. Convert the data to a CSV string
        String csv = const ListToCsvConverter().convert(rows);

        if (kIsWeb) {
        // WEB EXPORT LOGIC
        final bytes = utf8.encode(csv);
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute("download", "appreciations_export.csv")
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        // MOBILE EXPORT LOGIC (Your existing code)
        final directory = await getTemporaryDirectory();
        final path = "${directory.path}/appreciations_export_${DateTime.now().millisecondsSinceEpoch}.csv";
        final File file = File(path);
        await file.writeAsString(csv);
        final xFile = XFile(path);
        await Share.shareXFiles([xFile], text: 'Appreciation Data Export');
      }

    } catch (e) {
      print("Error exporting to CSV: $e");
    }
  }
}