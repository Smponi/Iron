//
//  ExerciseHistoryView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 06.07.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import CoreData

struct ExerciseHistoryView : View {
    @Environment(\.managedObjectContext) var managedObjectContext

    var exercise: Exercise
//    @ObservedObject private var observableFetchRequest = ObservableFetchRequest<TrainingExercise>()
    
//    private func fetch() {
//        observableFetchRequest.fetch(fetchRequest: TrainingExercise.historyFetchRequest(of: exercise.id, until: nil), managedObjectContext: managedObjectContext)
//    }

    private var history: [TrainingExercise] {
//        observableFetchRequest.fetchedResults
        (try? managedObjectContext.fetch(TrainingExercise.historyFetchRequest(of: exercise.id, until: nil))) ?? []
    }
    
    private func trainingSets(for trainingExercise: TrainingExercise) -> [TrainingSet] {
        trainingExercise.trainingSets?.array as! [TrainingSet]
    }
    
    private func indexedTrainingSets(for trainingExercise: TrainingExercise) -> [(Int, TrainingSet)] {
        trainingSets(for: trainingExercise).enumerated().map { ($0 + 1, $1) }
    }
    
    var body: some View {
        List {
            ForEach(history, id: \.objectID) { trainingExercise in
                Section(header: Text(Training.dateFormatter.string(from: trainingExercise.training?.start, fallback: "Unknown date"))) {
                    ForEach(self.indexedTrainingSets(for: trainingExercise), id: \.1.objectID) { index, trainingSet in
                        TrainingSetCell(trainingSet: trainingSet, index: index, colorMode: .activated)
                    }
                }
            }
        }
        .listStyle(GroupedListStyle())
//        .onAppear(perform: fetch)
    }
}

#if DEBUG
struct ExerciseHistoryView_Previews : PreviewProvider {
    static var previews: some View {
        ExerciseHistoryView(exercise: EverkineticDataProvider.findExercise(id: 42)!)
            .environmentObject(mockSettingsStoreMetric)
            .environment(\.managedObjectContext, mockManagedObjectContext)
    }
}
#endif
