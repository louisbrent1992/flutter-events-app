import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Types of credits
enum CreditType { eventImport, aiPlan }

/// Service for managing user credits
class CreditsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user's credits document reference
  DocumentReference? get _userCreditsRef {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('credits')
        .doc('balance');
  }

  /// Initialize credits for a new user
  Future<void> initializeCredits() async {
    if (_userCreditsRef == null) return;

    try {
      await _userCreditsRef!.set({
        'eventImports': 0,
        'aiPlans': 0,
        'totalEventImports': 0,
        'totalAiPlans': 0,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error initializing credits: $e');
      }
      rethrow;
    }
  }

  /// Get current credit balance
  Future<Map<String, int>> getCreditBalance() async {
    if (_userCreditsRef == null) {
      return {'eventImports': 0, 'aiPlans': 0};
    }

    try {
      final doc = await _userCreditsRef!.get();
      if (!doc.exists) {
        await initializeCredits();
        return {'eventImports': 0, 'aiPlans': 0};
      }

      final data = doc.data() as Map<String, dynamic>;
      return {
        'eventImports': data['eventImports'] ?? 0,
        'aiPlans': data['aiPlans'] ?? 0,
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting credit balance: $e');
      }
      return {'eventImports': 0, 'aiPlans': 0};
    }
  }

  /// Add credits
  Future<void> addCredits({
    int eventImports = 0,
    int aiPlans = 0,
    String? reason,
  }) async {
    if (_userCreditsRef == null) return;

    try {
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(_userCreditsRef!);

        int currentImports = 0;
        int currentAiPlans = 0;
        int totalImports = 0;
        int totalAiPlans = 0;

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          currentImports = data['eventImports'] ?? 0;
          currentAiPlans = data['aiPlans'] ?? 0;
          totalImports = data['totalEventImports'] ?? 0;
          totalAiPlans = data['totalAiPlans'] ?? 0;
        }

        transaction.set(_userCreditsRef!, {
          'eventImports': currentImports + eventImports,
          'aiPlans': currentAiPlans + aiPlans,
          'totalEventImports': totalImports + eventImports,
          'totalAiPlans': totalAiPlans + aiPlans,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Log the transaction
        if (reason != null) {
          await _logCreditTransaction(
            transaction: transaction,
            eventImports: eventImports,
            aiPlans: aiPlans,
            reason: reason,
            isAddition: true,
          );
        }
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error adding credits: $e');
      }
      rethrow;
    }
  }

  /// Use credits (deduct)
  Future<bool> useCredits({
    required CreditType type,
    int amount = 1,
    String? reason,
  }) async {
    if (_userCreditsRef == null) return false;

    try {
      bool success = false;

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(_userCreditsRef!);

        if (!doc.exists) {
          await initializeCredits();
          throw Exception('Insufficient credits');
        }

        final data = doc.data() as Map<String, dynamic>;

        final String fieldName = type == CreditType.eventImport ? 'eventImports' : 'aiPlans';

        final int currentBalance = data[fieldName] ?? 0;

        if (currentBalance < amount) {
          throw Exception(
            'Insufficient credits: need $amount, have $currentBalance',
          );
        }

        transaction.update(_userCreditsRef!, {
          fieldName: currentBalance - amount,
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        // Log the transaction
        await _logCreditTransaction(
          transaction: transaction,
          eventImports: type == CreditType.eventImport ? amount : 0,
          aiPlans: type == CreditType.aiPlan ? amount : 0,
          reason: reason ?? 'Credit used',
          isAddition: false,
        );

        success = true;
      });

      return success;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error using credits: $e');
      }
      return false;
    }
  }

  /// Check if user has enough credits
  Future<bool> hasEnoughCredits({
    required CreditType type,
    int amount = 1,
  }) async {
    final balance = await getCreditBalance();
    final fieldName =
        type == CreditType.eventImport ? 'eventImports' : 'aiPlans';

    return (balance[fieldName] ?? 0) >= amount;
  }

  /// Get credit history
  Future<List<Map<String, dynamic>>> getCreditHistory({int limit = 50}) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];

    try {
      final querySnapshot =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('credits')
              .doc('transactions')
              .collection('history')
              .orderBy('timestamp', descending: true)
              .limit(limit)
              .get();

      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting credit history: $e');
      }
      return [];
    }
  }

  /// Log credit transaction
  Future<void> _logCreditTransaction({
    required Transaction transaction,
    required int eventImports,
    required int aiPlans,
    required String reason,
    required bool isAddition,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final transactionRef =
        _firestore
            .collection('users')
            .doc(userId)
            .collection('credits')
            .doc('transactions')
            .collection('history')
            .doc();

    transaction.set(transactionRef, {
      'eventImports': eventImports,
      'aiPlans': aiPlans,
      'reason': reason,
      'type': isAddition ? 'addition' : 'deduction',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Grant monthly subscription credits
  Future<void> grantMonthlySubscriptionCredits({
    required int importCredits,
    required int planCredits,
  }) async {
    await addCredits(
      eventImports: importCredits,
      aiPlans: planCredits,
      reason: 'Monthly subscription renewal',
    );
  }

  /// Handle subscription renewal
  Future<void> handleSubscriptionRenewal({
    required String subscriptionId,
    required int importCredits,
    required int planCredits,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      // Check last renewal date
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final data = userDoc.data();

      if (data != null && data.containsKey('lastSubscriptionRenewal')) {
        final lastRenewal =
            (data['lastSubscriptionRenewal'] as Timestamp).toDate();
        final now = DateTime.now();

        // If less than 25 days since last renewal, don't grant credits yet
        if (now.difference(lastRenewal).inDays < 25) {
          return;
        }
      }

      // Grant credits
      await addCredits(
        eventImports: importCredits,
        aiPlans: planCredits,
        reason: 'Subscription renewal: $subscriptionId',
      );

      // Update last renewal date
      await _firestore.collection('users').doc(userId).update({
        'lastSubscriptionRenewal': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error handling subscription renewal: $e');
      }
      rethrow;
    }
  }
}
