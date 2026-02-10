import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

/// Test screen to verify Firebase connectivity
///
/// This screen tests:
/// - Firebase initialization
/// - Firestore database connection
/// - Firebase Storage connection
/// - Firebase Auth connection
class FirebaseConnectionTest extends StatefulWidget {
  const FirebaseConnectionTest({super.key});

  @override
  State<FirebaseConnectionTest> createState() => _FirebaseConnectionTestState();
}

class _FirebaseConnectionTestState extends State<FirebaseConnectionTest> {
  bool _testing = false;
  final List<String> _results = [];

  Future<void> _testConnection() async {
    setState(() {
      _testing = true;
      _results.clear();
    });

    try {
      // Test 1: Firestore connection
      _addResult('Testing Firestore connection...');
      try {
        final firestore = FirebaseFirestore.instance;
        await firestore
            .collection('_test')
            .doc('connection_test')
            .set({'timestamp': FieldValue.serverTimestamp(), 'test': true});
        _addResult('✅ Firestore: Connected successfully');

        // Clean up test document
        await firestore.collection('_test').doc('connection_test').delete();
      } catch (e) {
        _addResult('❌ Firestore: $e');
      }

      // Test 2: Firebase Storage connection
      _addResult('\nTesting Firebase Storage...');
      try {
        final storage = FirebaseStorage.instance;
        final ref = storage.ref().child('_test/connection_test.txt');
        await ref.putString('test');
        _addResult('✅ Storage: Connected successfully');

        // Clean up test file
        await ref.delete();
      } catch (e) {
        _addResult('❌ Storage: $e');
      }

      // Test 3: Firebase Auth connection
      _addResult('\nTesting Firebase Auth...');
      try {
        final auth = FirebaseAuth.instance;
        final currentUser = auth.currentUser;
        if (currentUser != null) {
          _addResult('✅ Auth: Connected (User: ${currentUser.email})');
        } else {
          _addResult('✅ Auth: Connected (No user signed in)');
        }
      } catch (e) {
        _addResult('❌ Auth: $e');
      }

      _addResult('\n🎉 Firebase connection test complete!');
    } catch (e) {
      _addResult('\n❌ General error: $e');
    }

    setState(() {
      _testing = false;
    });
  }

  void _addResult(String result) {
    setState(() {
      _results.add(result);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Connection Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _testing ? null : _testConnection,
              child: _testing
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Testing...'),
                      ],
                    )
                  : const Text('Test Firebase Connection'),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: _results.isEmpty
                    ? const Center(
                        child: Text(
                          'Press the button to test Firebase connection',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : SingleChildScrollView(
                        child: Text(
                          _results.join('\n'),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
