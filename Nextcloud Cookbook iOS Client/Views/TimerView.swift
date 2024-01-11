//
//  TimerView.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 11.01.24.
//

import Foundation
import SwiftUI
import Combine
import AVFoundation
import UserNotifications


struct TimerView: View {
    @ObservedObject var timer: RecipeTimer
    
    var body: some View {
        HStack {
            Gauge(value: timer.timeTotal - timer.timeElapsed, in: 0...timer.timeTotal) {
                Text("Cooking time")
            } currentValueLabel: {
                Button {
                    if timer.isRunning {
                        timer.pause()
                    } else {
                        timer.start()
                    }
                } label: {
                    if timer.isRunning {
                        Image(systemName: "pause.fill")
                    } else {
                        Image(systemName: "play.fill")
                    }
                }
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .animation(.easeInOut, value: timer.timeElapsed)
            .tint(timer.isRunning ? .green : .nextcloudBlue)
            .foregroundStyle(timer.isRunning ? Color.green : Color.nextcloudBlue)
            
            VStack(alignment: .leading) {
                Text("Cooking")
                Text(timer.duration.toTimerText())
            }
            .padding(.horizontal)
            
            Button {
                timer.cancel()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(timer.isRunning ? Color.nextcloudBlue : Color.secondary)
            }
        }
        .bold()
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 20)
                .foregroundStyle(.ultraThickMaterial)
        }
    }
}



class RecipeTimer: ObservableObject {
    var timeTotal: Double
    @Published var duration: DurationComponents
    private var startDate: Date?
    private var pauseDate: Date?
    @Published var timeElapsed: Double = 0
    @Published var isRunning: Bool = false
    @Published var timerExpired: Bool = false
    private var timer: Timer.TimerPublisher?
    private var timerCancellable: Cancellable?
    var audioPlayer: AVAudioPlayer?

    init(duration: DurationComponents) {
        self.duration = duration
        self.timeTotal = duration.toSeconds()
    }
    
    func start() {
        self.isRunning = true
        if startDate == nil {
            startDate = Date()
        } else if let pauseDate = pauseDate {
            // Adjust start date based on the pause duration
            let pauseDuration = Date().timeIntervalSince(pauseDate)
            startDate = startDate?.addingTimeInterval(pauseDuration)
        }
        requestNotificationPermissions()
        scheduleTimerNotification(timeInterval: timeTotal)
        // Prepare audio session
        setupAudioSession()
        prepareAudioPlayer(with: "alarm_sound_0")
        
        self.timer = Timer.publish(every: 1, on: .main, in: .common)
        self.timerCancellable = self.timer?.autoconnect().sink { [weak self] _ in
            DispatchQueue.main.async {
                if let self = self, let startTime = self.startDate {
                    let elapsed = Date().timeIntervalSince(startTime)
                    if elapsed < self.timeTotal {
                        self.timeElapsed = elapsed
                        self.duration.fromSeconds(Int(self.timeTotal - self.timeElapsed))
                    } else {
                        self.timerExpired = true
                        self.timeElapsed = self.timeTotal
                        self.duration.fromSeconds(Int(self.timeTotal - self.timeElapsed))
                        self.pause()
                        
                        self.startAlarm()
                    }
                }
            }
        }
    }
    
    func pause() {
        self.isRunning = false
        pauseDate = Date()
        self.timerCancellable?.cancel()
        self.timerCancellable = nil
        self.timer = nil
    }
    
    func resume() {
        self.isRunning = true
        start()
    }
    
    func cancel() {
        self.isRunning = false
        self.timerCancellable?.cancel()
        self.timerCancellable = nil
        self.timer = nil
        self.timeElapsed = 0
        self.startDate = nil
        self.pauseDate = nil
        self.duration.fromSeconds(Int(timeTotal))
    }
}

extension RecipeTimer {
    func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session category. Error: \(error)")
        }
    }
    
    func prepareAudioPlayer(with soundName: String) {
        if let soundURL = Bundle.main.url(forResource: "alarm_sound_0", withExtension: "mp3") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.prepareToPlay()
                audioPlayer?.numberOfLoops = -1 // Loop indefinitely
            } catch {
                print("Error loading sound file: \(error)")
            }
        }
    }
    
    func postNotification() {
        NotificationCenter.default.post(name: Notification.Name("AlarmNotification"), object: nil)
    }

    func startAlarm() {
        audioPlayer?.play()
        postNotification()
    }

    func stopAlarm() {
        audioPlayer?.stop()
        try? AVAudioSession.sharedInstance().setActive(false)
    }
    
    // ===================================== ALTERNATIVE
    
    func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted.")
            } else if let error = error {
                print("Notification permission denied because: \(error.localizedDescription).")
            }
        }
    }
    
    func scheduleTimerNotification(timeInterval: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = "Timer Finished"
        content.body = "Your timer is up!"
        content.sound = UNNotificationSound.default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)

        let request = UNNotificationRequest(identifier: "timerNotification", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
}
