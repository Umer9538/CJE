import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Diagnostic helper to check Firebase connectivity and show errors
class DiagnosticHelper {
  static bool _diagnosticShown = false;

  /// Run diagnostics and show results in a dialog
  static Future<void> runDiagnostics(BuildContext context) async {
    if (_diagnosticShown) return;
    _diagnosticShown = true;

    final results = <String, DiagnosticResult>{};

    // Check Firebase Auth
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        results['Authentication'] = DiagnosticResult(
          success: true,
          message: 'Logged in as: ${user.email}\nUID: ${user.uid}',
        );
      } else {
        results['Authentication'] = DiagnosticResult(
          success: false,
          message: 'No user logged in',
        );
      }
    } catch (e) {
      results['Authentication'] = DiagnosticResult(
        success: false,
        message: 'Error: $e',
      );
    }

    // Check Firestore read
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('schools')
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 10));
      results['Firestore Read'] = DiagnosticResult(
        success: true,
        message: 'Read successful (${snapshot.docs.length} docs)',
      );
    } catch (e) {
      results['Firestore Read'] = DiagnosticResult(
        success: false,
        message: 'Error: $e',
      );
    }

    // Check Firestore write (to a test collection)
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final testDoc = FirebaseFirestore.instance
            .collection('_diagnostics')
            .doc(user.uid);
        await testDoc.set({
          'timestamp': FieldValue.serverTimestamp(),
          'test': true,
        }).timeout(const Duration(seconds: 10));
        await testDoc.delete(); // Clean up
        results['Firestore Write'] = DiagnosticResult(
          success: true,
          message: 'Write successful',
        );
      } else {
        results['Firestore Write'] = DiagnosticResult(
          success: false,
          message: 'Cannot test - no user logged in',
        );
      }
    } catch (e) {
      results['Firestore Write'] = DiagnosticResult(
        success: false,
        message: 'Error: $e',
      );
    }

    // Check user document
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get()
            .timeout(const Duration(seconds: 10));
        if (userDoc.exists) {
          final data = userDoc.data()!;
          results['User Profile'] = DiagnosticResult(
            success: true,
            message: 'Role: ${data['role']}\nStatus: ${data['status']}\nCity: ${data['city'] ?? 'null'}',
          );
        } else {
          results['User Profile'] = DiagnosticResult(
            success: false,
            message: 'User document not found in Firestore',
          );
        }
      }
    } catch (e) {
      results['User Profile'] = DiagnosticResult(
        success: false,
        message: 'Error: $e',
      );
    }

    // Show results dialog
    if (context.mounted) {
      _showDiagnosticDialog(context, results);
    }
  }

  static void _showDiagnosticDialog(
    BuildContext context,
    Map<String, DiagnosticResult> results,
  ) {
    final allSuccess = results.values.every((r) => r.success);
    final resultText = results.entries
        .map((e) => '${e.value.success ? "✓" : "✗"} ${e.key}:\n${e.value.message}')
        .join('\n\n');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              allSuccess ? Icons.check_circle : Icons.error,
              color: allSuccess ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(
              'Diagnostic Results',
              style: TextStyle(
                color: allSuccess ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!allSuccess)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    'Some checks failed. This may explain why creating content is not working.',
                    style: TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),
              SelectableText(
                resultText,
                style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: resultText));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard')),
              );
            },
            child: const Text('Copy'),
          ),
          TextButton(
            onPressed: () {
              _diagnosticShown = false; // Allow running again
              Navigator.pop(context);
              runDiagnostics(context);
            },
            child: const Text('Re-run'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Reset the diagnostic shown flag (for testing)
  static void reset() {
    _diagnosticShown = false;
  }
}

class DiagnosticResult {
  final bool success;
  final String message;

  DiagnosticResult({required this.success, required this.message});
}
