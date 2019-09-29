//
//  MuscleGroupSectionedExercisesView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 04.07.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct MuscleGroupSectionedExercisesView : View {
    var exerciseMuscleGroups: [[Exercise]]
    
    var body: some View {
        List {
            ForEach(exerciseMuscleGroups, id: \.first?.muscleGroup) { exercises in
                Section(header: Text(exercises.first?.muscleGroup.uppercased() ?? "")) {
                    ForEach(exercises, id: \.id) { exercise in
                        NavigationLink(exercise.title, destination: ExerciseDetailView(exercise: exercise))
                    }
                }
            }
        }
    }
}

#if DEBUG
struct MuscleGroupSectionedExercisesView_Previews : PreviewProvider {
    static var previews: some View {
        MuscleGroupSectionedExercisesView(exerciseMuscleGroups: ExerciseStore.splitIntoMuscleGroups(exercises: ExerciseStore.shared.exercises))
            .environmentObject(SettingsStore.mockMetric)
            .environment(\.managedObjectContext, mockManagedObjectContext)
    }
}
#endif
