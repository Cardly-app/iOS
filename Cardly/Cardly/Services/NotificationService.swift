//
//  NotificationService.swift
//  Cardly
//
//  Local "time to review" reminder. A single daily repeating notification at a
//  fixed hour; the user toggles it on/off. No server / push setup needed.
//

import Foundation
import UserNotifications

enum NotificationService {
    private static let reviewID = "cardly.daily-review"
    static let reminderHour = 19   // 7 PM

    /// Ask for permission. Returns true if granted.
    @discardableResult
    static func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        default:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        }
    }

    /// Schedule (or replace) the daily review reminder.
    static func scheduleDailyReview() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [reviewID])

        let content = UNMutableNotificationContent()
        content.title = "복습할 시간이에요"
        content.body = "오늘 복습할 카드를 확인해보세요 📚"
        content.sound = .default

        var when = DateComponents()
        when.hour = reminderHour
        when.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: when, repeats: true)
        center.add(UNNotificationRequest(identifier: reviewID, content: content, trigger: trigger))
    }

    static func cancelDailyReview() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reviewID])
    }

    /// Apply the user's preference: request permission + schedule, or cancel.
    /// Returns the effective on-state (off if permission was denied).
    @discardableResult
    static func apply(enabled: Bool) async -> Bool {
        guard enabled else { cancelDailyReview(); return false }
        guard await requestAuthorization() else { return false }
        scheduleDailyReview()
        return true
    }
}
