//
//  TimerBannerView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 14.08.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct TimerBannerView: View {
    @EnvironmentObject var restTimerStore: RestTimerStore
    
    @ObservedObject var training: Training

    @ObservedObject private var refresher = Refresher()
    
    @State private var activeSheet: SheetType?

    private enum SheetType: Identifiable {
        case restTimer
        case editTime
        
        var id: Self { self }
    }

    private let trainingTimerDurationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
    
    private var closeSheetButton: some View {
        Button("Close") {
            self.activeSheet = nil
        }
    }
    
    private var editTimeSheet: some View {
        VStack(spacing: 0) {
            SheetBar(title: "Workout Duration", leading: closeSheetButton, trailing: EmptyView()).padding()
            Divider()
            EditCurrentTrainingTimeView(training: training)
        }
    }
    
    private var restTimerSheet: some View {
        VStack(spacing: 0) {
            SheetBar(title: "Rest Timer", leading: closeSheetButton, trailing: EmptyView()).padding()
            Spacer()
            RestTimerView().environmentObject(self.restTimerStore)
            Spacer()
        }
    }
    
    var body: some View {
        HStack {
            Button(action: {
                self.activeSheet = .editTime
            }) {
                HStack {
                    Image(systemName: "clock")
                    Text(trainingTimerDurationFormatter.string(from: training.safeDuration) ?? "")
                        .font(Font.body.monospacedDigit())
                }
                .padding()
            }

            Spacer()

            Button(action: {
                self.activeSheet = .restTimer
            }) {
                HStack {
                    Image(systemName: "timer")
                    restTimerStore.restTimerRemainingTime.map({
                        Text(restTimerDurationFormatter.string(from: $0.rounded(.up)) ?? "")
                            .font(Font.body.monospacedDigit())
                    })
                }
                .padding()
            }
        }
        .background(VisualEffectView(effect: UIBlurEffect(style: .systemMaterial)))
        .sheet(item: $activeSheet) { sheet in
            if sheet == .editTime {
                self.editTimeSheet
            } else if sheet == .restTimer {
                self.restTimerSheet
            }
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in self.refresher.refresh() }
    }
}

#if DEBUG
struct TimerBannerView_Previews: PreviewProvider {
    static var previews: some View {
        if restTimerStore.restTimerRemainingTime == nil {
            restTimerStore.restTimerStart = Date()
            restTimerStore.restTimerDuration = 10
        }
        return TimerBannerView(training: mockCurrentTraining)
            .environmentObject(restTimerStore)
    }
}
#endif
