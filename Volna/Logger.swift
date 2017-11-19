//
//  Logger.swift
//  Volna
//
//  Created by Artem Malyshev on 8/13/17.
//  Copyright © 2017 Artem Malyshev. All rights reserved.
//

import Foundation
import FirebaseAnalytics

class Logger {
    
    class func logAppleReviewPresented(numberOfTimes: Int32) {
        Analytics.logEvent("apple_review_presented", parameters: [
            "name": "Apple Review Presented" as NSObject,
            "full_text": "Apple Review Attempt Presented and the app was opened \(numberOfTimes) times" as NSObject
            ])
    }
    
    class func logReviewPresented(numberOfTimes: Int32) {
        Analytics.logEvent("review_presented", parameters: [
            "name": "Review Presented" as NSObject,
            "full_text": "Review Presented and the app was opened \(numberOfTimes) times" as NSObject
            ])
    }
    
    class func logAcceptedReview() {
        Analytics.logEvent("review_accepted", parameters: [
            "name": "Review Accepted" as NSObject,
            "full_text": "Review request accepted and user sent to app store" as NSObject
            ])
    }
    
	class func logRequestLater() {
        Analytics.logEvent("review_later", parameters: [
            "name": "Review Later" as NSObject,
            "full_text": "User pressed review later" as NSObject
            ])
    }
    
    class func logRequestNever() {
        Analytics.logEvent("review_never", parameters: [
            "name": "Review Never" as NSObject,
            "full_text": "User requested to never review app" as NSObject
            ])
    }
    
    class func logDuplicatStationsHappened(_ position: Int, predicate: String) {
        Analytics.logEvent("duplicate_stations", parameters: [
            "name": "Duplicate Stations" as NSObject,
            "full_text": "duplicate station in position" as NSObject,
            "position": position as NSObject,
            "favourite": predicate as NSObject
            ])
    }
    
    class func logCouldNotFindDuplicates(_ position: Int, array: [Int16], predicate: String) {
        Analytics.logEvent("error_duplicates_finder", parameters: [
            "name": "Error Duplicates Finder" as NSObject,
            "full_text": "Missing station \(position) but could not find duplicates in \(array)" as NSObject,
            "position": position as NSObject,
            "favourite": predicate as NSObject,
            "array": array as NSObject
            ])
    }
    
    class func logMetadata(_ string: String) {
        Analytics.logEvent("metadata", parameters: [
            "name": "Metadata received" as NSObject,
            "full_text": "Metadata string \(string) passed to parser" as NSObject,
            "string": string as NSObject
            ])
    }
    
    class func logMetadataError(_ string: String, error: Error) {
        Analytics.logEvent("metadata_error", parameters: [
            "name": "Metadata parse errors" as NSObject,
            "full_text": "Metadata string \(string) could not be parsed, error: \(error.localizedDescription)" as NSObject,
            "string": string as NSObject,
            "error": error as NSObject,
            "error description": error.localizedDescription as NSObject
            ])
    }
    
    class func logStationClicked(_ station: String) {
        Analytics.logEvent("station_clicked", parameters: [
            "name": "\(station)" as NSObject,
            "full_text": "Station Clicked" as NSObject,
            ])
    }
}
