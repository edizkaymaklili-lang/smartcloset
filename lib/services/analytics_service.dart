import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  FirebaseAnalytics get analytics => _analytics;
  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  // ─── User Events ───
  Future<void> logSignUp(String method) async {
    try {
      await _analytics.logSignUp(signUpMethod: method);
      debugPrint('Analytics: sign_up ($method)');
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  Future<void> logLogin(String method) async {
    try {
      await _analytics.logLogin(loginMethod: method);
      debugPrint('Analytics: login ($method)');
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  Future<void> setUserId(String userId) async {
    try {
      await _analytics.setUserId(id: userId);
      debugPrint('Analytics: user_id set to $userId');
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  Future<void> setUserProperty(String name, String value) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
      debugPrint('Analytics: user_property $name = $value');
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  // ─── Wardrobe Events ───
  Future<void> logAddWardrobeItem(String category) async {
    try {
      await _analytics.logEvent(
        name: 'add_wardrobe_item',
        parameters: {'category': category},
      );
      debugPrint('Analytics: add_wardrobe_item ($category)');
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  Future<void> logDeleteWardrobeItem(String category) async {
    try {
      await _analytics.logEvent(
        name: 'delete_wardrobe_item',
        parameters: {'category': category},
      );
      debugPrint('Analytics: delete_wardrobe_item ($category)');
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  // ─── Style Feed Events ───
  Future<void> logCreatePost() async {
    try {
      await _analytics.logEvent(name: 'create_style_post');
      debugPrint('Analytics: create_style_post');
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  Future<void> logLikePost() async {
    try {
      await _analytics.logEvent(name: 'like_post');
      debugPrint('Analytics: like_post');
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  Future<void> logSavePost() async {
    try {
      await _analytics.logEvent(name: 'save_post');
      debugPrint('Analytics: save_post');
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  Future<void> logSharePost() async {
    try {
      await _analytics.logShare(
        contentType: 'style_post',
        itemId: 'post',
        method: 'share_button',
      );
      debugPrint('Analytics: share_post');
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  Future<void> logFollowUser() async {
    try {
      await _analytics.logEvent(name: 'follow_user');
      debugPrint('Analytics: follow_user');
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  // ─── Search Events ───
  Future<void> logSearch(String searchTerm, String searchType) async {
    try {
      await _analytics.logSearch(
        searchTerm: searchTerm,
        parameters: {'search_type': searchType},
      );
      debugPrint('Analytics: search ($searchType: $searchTerm)');
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  // ─── Recommendation Events ───
  Future<void> logViewRecommendations() async {
    try {
      await _analytics.logEvent(name: 'view_recommendations');
      debugPrint('Analytics: view_recommendations');
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  Future<void> logRequestRecommendation(String occasion) async {
    try {
      await _analytics.logEvent(
        name: 'request_recommendation',
        parameters: {'occasion': occasion},
      );
      debugPrint('Analytics: request_recommendation ($occasion)');
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  // ─── Screen View Events ───
  Future<void> logScreenView(String screenName) async {
    try {
      await _analytics.logScreenView(screenName: screenName);
      debugPrint('Analytics: screen_view ($screenName)');
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  // ─── Settings Events ───
  Future<void> logToggleDarkMode(bool enabled) async {
    try {
      await _analytics.logEvent(
        name: 'toggle_dark_mode',
        parameters: {'enabled': enabled},
      );
      debugPrint('Analytics: toggle_dark_mode ($enabled)');
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  Future<void> logToggleNotifications(bool enabled) async {
    try {
      await _analytics.logEvent(
        name: 'toggle_notifications',
        parameters: {'enabled': enabled},
      );
      debugPrint('Analytics: toggle_notifications ($enabled)');
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }
}
