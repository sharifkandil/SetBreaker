//
//  ContentView.swift
//  SetBreaker
//
//  Created by sharif.kandil  on 15/12/2024.
//

import SwiftUI
import WebKit

// Add at the top level, after imports
class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
}

// Add social media enum
enum SocialMedia: String, CaseIterable {
    case instagram = "Instagram"
    case tiktok = "TikTok"
    
    var url: String {
        switch self {
        case .instagram: return "https://www.instagram.com"
        case .tiktok: return "https://www.tiktok.com"
        }
    }
}

// Basic WebView that worked before
struct SocialMediaWebView: UIViewRepresentable {
    let url: String
    var onScroll: () -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.scrollView.delegate = context.coordinator
        if let url = URL(string: url) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    class Coordinator: NSObject, UIScrollViewDelegate {
        var parent: SocialMediaWebView
        private var lastContentOffset: CGFloat = 0
        private var isScrolling = false
        
        init(_ parent: SocialMediaWebView) {
            self.parent = parent
        }
        
        func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
            isScrolling = true
            lastContentOffset = scrollView.contentOffset.y
        }
        
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            guard isScrolling else { return }
            let currentOffset = scrollView.contentOffset.y
            let difference = abs(currentOffset - lastContentOffset)
            
            if difference > 20 {
                parent.onScroll()
                isScrolling = false
            }
        }
        
        func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
            isScrolling = false
        }
    }
}

struct SettingsView: View {
    @AppStorage("restPeriod") private var restPeriod: Int = 60
    @AppStorage("autoStartTimer") private var autoStartTimer: Bool = true
    @AppStorage("startOnScroll") private var startOnScroll: Bool = false
    @AppStorage("selectedSocialMedia") private var selectedSocialMedia: SocialMedia = .instagram
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Social Media")) {
                    Picker("Platform", selection: $selectedSocialMedia.animation()) {
                        ForEach(SocialMedia.allCases, id: \.self) { platform in
                            Text(platform.rawValue).tag(platform)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedSocialMedia) { _ in
                        HapticManager.shared.impact(style: .light)
                    }
                }
                
                Section(header: Text("Timer Settings")) {
                    Stepper(value: $restPeriod, in: 15...300, step: 15) {
                        HStack {
                            Text("Rest Period")
                            Spacer()
                            Text("\(restPeriod) seconds")
                                .foregroundColor(.gray)
                        }
                    }
                    .onChange(of: restPeriod) { _ in
                        HapticManager.shared.impact(style: .light)
                    }
                    
                    Toggle("Auto-start Timer", isOn: $autoStartTimer)
                        .tint(.blue)
                        .onChange(of: autoStartTimer) { _ in
                            HapticManager.shared.impact(style: .light)
                        }
                    
                    Toggle("Start on Scroll", isOn: $startOnScroll)
                        .tint(.blue)
                        .onChange(of: startOnScroll) { _ in
                            HapticManager.shared.impact(style: .light)
                        }
                }
                
                Section(header: Text("About")) {
                    Text("SetBreaker helps you maintain your workout rhythm by timing your rest periods while browsing social media.")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}

struct ContentView: View {
    @AppStorage("restPeriod") private var restPeriod: Int = 60
    @AppStorage("autoStartTimer") private var autoStartTimer: Bool = true
    @AppStorage("startOnScroll") private var startOnScroll: Bool = false
    @AppStorage("selectedSocialMedia") private var selectedSocialMedia: SocialMedia = .instagram
    @State private var timeRemaining: Int = 60
    @State private var timer: Timer?
    @State private var isTimerRunning = false
    @State private var showingTimerEndAlert = false
    @State private var isContentBlocked = false
    @State private var showingSettings = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 20) {
                // Timer Display
                Text(timeString(from: timeRemaining))
                    .font(.system(size: 38, weight: .bold))
                    .foregroundColor(timeRemaining < 10 ? .red : .primary)
                    .frame(width: 120, alignment: .leading)
                
                // Timer Controls
                HStack(spacing: 12) {
                    Button(action: startTimer) {
                        Text(isTimerRunning ? "Pause" : "Start")
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(isTimerRunning ? .red : .green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    
                    Button(action: resetTimer) {
                        Text("Reset")
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                
                Spacer()
                
                // Settings Button
                Button(action: { showingSettings = true }) {
                    Image(systemName: "gear")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
            
            // Social Media Feed
            SocialMediaWebView(
                url: selectedSocialMedia.url,
                onScroll: handleScroll
            )
            .id(selectedSocialMedia) // Force view refresh when platform changes
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .disabled(isContentBlocked)
            .overlay(
                isContentBlocked ?
                Color.black.opacity(0.5)
                    .overlay(
                        Text("Time to start your next set!")
                            .foregroundColor(.white)
                            .font(.headline)
                    )
                : nil
            )
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .alert("Rest Period Complete!", isPresented: $showingTimerEndAlert) {
            Button("Start Next Set") {
                resetTimer()
                isContentBlocked = false
            }
            Button("Extend Rest", role: .cancel) {
                timeRemaining = restPeriod
                startTimer()
            }
        } message: {
            Text("Time to start your next set!")
        }
        .onAppear {
            timeRemaining = restPeriod
            if autoStartTimer {
                startTimer()
            }
        }
    }
    
    private func handleScroll() {
        if startOnScroll && !isTimerRunning && !isContentBlocked {
            timeRemaining = restPeriod
            HapticManager.shared.impact(style: .soft) // Gentle feedback when starting on scroll
            startTimer()
        }
    }
    
    private func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
    
    private func startTimer() {
        HapticManager.shared.impact(style: .medium)
        
        if isTimerRunning {
            timer?.invalidate()
            isTimerRunning = false
        } else {
            isTimerRunning = true
            timer = Timer(timeInterval: 1, repeats: true) { _ in
                DispatchQueue.main.async {
                    if timeRemaining > 0 {
                        timeRemaining -= 1
                        if timeRemaining <= 10 {
                            HapticManager.shared.impact(style: .rigid)
                        }
                    } else {
                        timer?.invalidate()
                        isTimerRunning = false
                        showingTimerEndAlert = true
                        isContentBlocked = true
                        HapticManager.shared.notification(type: .warning)
                    }
                }
            }
            RunLoop.main.add(timer!, forMode: .common)
        }
    }
    
    private func resetTimer() {
        HapticManager.shared.impact(style: .light) // Light feedback for reset
        timer?.invalidate()
        timeRemaining = restPeriod
        isTimerRunning = false
        isContentBlocked = false
        if autoStartTimer {
            startTimer()
        }
    }
}

#Preview {
    ContentView()
}
