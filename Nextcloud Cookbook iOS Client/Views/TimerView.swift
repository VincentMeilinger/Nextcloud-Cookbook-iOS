//
//  TimerView.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 11.01.24.
//

import Foundation
import SwiftUI
import Combine


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
    private var timer: Timer.TimerPublisher?
    private var timerCancellable: Cancellable?

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

        self.timer = Timer.publish(every: 1, on: .main, in: .common)
        self.timerCancellable = self.timer?.autoconnect().sink { [weak self] _ in
            DispatchQueue.main.async {
                if let self = self, let startTime = self.startDate {
                    let elapsed = Date().timeIntervalSince(startTime)
                    if elapsed < self.timeTotal {
                        self.timeElapsed = elapsed
                        self.duration.fromSeconds(Int(self.timeTotal - self.timeElapsed))
                    } else {
                        self.timeElapsed = self.timeTotal
                        self.duration.fromSeconds(Int(self.timeTotal - self.timeElapsed))
                        self.pause()
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
