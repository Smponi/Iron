//
//  StartTrainingView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 19.07.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct StartTrainingView: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @EnvironmentObject var trainingsDataStore: TrainingsDataStore
    
    private var plateImage: some View {
        Image("plate")
            .resizable()
            .padding(48)
            .aspectRatio(contentMode: ContentMode.fit)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if colorScheme == .dark {
                    plateImage.colorInvert()
                } else {
                    plateImage
                }
                    
                Button("Start Training") {
                    precondition(Training.currentTraining(context: self.trainingsDataStore.context) == nil)
                    // create a new training
                    let training = Training(context: self.trainingsDataStore.context)
                    training.isCurrentTraining = true
                    self.trainingsDataStore.context.safeSave()
                }
                .padding()
                .foregroundColor(Color.white)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).foregroundColor(.accentColor))
                .padding()
            }
            .navigationBarTitle("Training")
        }
    }
}

#if DEBUG
struct StartTrainingView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            StartTrainingView()
            
            StartTrainingView()
                .environment(\.colorScheme, .dark)
                
        }
        .environmentObject(mockTrainingsDataStore)
    }
}
#endif
