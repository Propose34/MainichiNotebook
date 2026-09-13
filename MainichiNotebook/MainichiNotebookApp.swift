//
//  MainichiNotebookApp.swift
//  MainichiNotebook
//
//  Created by Propose34 on 4/6/2569 BE.
//

import SwiftUI

@main
struct MainichiNotebookApp: App {
    @StateObject private var studyDataService = StudyDataService()
    @StateObject private var studyUserLibraryService = StudyUserLibraryService()
    @StateObject private var flashcardHistoryService = FlashCardReviewHistoryService()
    @StateObject private var userVocabularyService = UserVocabularyService()
    @StateObject private var srsService = SRSService()
    @StateObject private var writingPracticeProgressService = WritingPracticeProgressService()
    @StateObject private var simpleVocabularyProgressService = SimpleVocabularyProgressService()
    @StateObject private var dailySummaryService = DailySummaryService()
    @StateObject private var userProfileService = UserProfileService()
    @StateObject private var appSettingsService = AppSettingsService()
    @StateObject private var localNotificationService = LocalNotificationService()
    @StateObject private var studyPlanService = StudyPlanService()
    @StateObject private var paperTemplateService = PaperTemplateService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(studyDataService)
                .environmentObject(studyUserLibraryService)
                .environmentObject(flashcardHistoryService)
                .environmentObject(userVocabularyService)
                .environmentObject(srsService)
                .environmentObject(writingPracticeProgressService)
                .environmentObject(simpleVocabularyProgressService)
                .environmentObject(dailySummaryService)
                .environmentObject(userProfileService)
                .environmentObject(appSettingsService)
                .environmentObject(localNotificationService)
                .environmentObject(studyPlanService)
                .environmentObject(paperTemplateService)
                .onAppear {
                    srsService.observeLibrary(studyUserLibraryService)
                }
        }
    }
}
