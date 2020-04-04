//
//  StartWorkoutView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 19.07.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import CoreData
import WorkoutDataKit
import os.log

struct StartWorkoutView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    
    @State private var quote = Quotes.quotes.randomElement()
    
    @State private var selectedWorkoutPlan: WorkoutPlan?
    
    @State private var offsetsToDelete: IndexSet?
    
    @FetchRequest(fetchRequest: StartWorkoutView.fetchRequest) var workoutPlans

    static var fetchRequest: NSFetchRequest<WorkoutPlan> {
        let request: NSFetchRequest<WorkoutPlan> = WorkoutPlan.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WorkoutPlan.title, ascending: false)]
        return request
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    StartEmptyWorkoutCell()
                }
                
                ForEach(workoutPlans) { workoutPlan in
                    Section {
                        WorkoutPlanCell(workoutPlan: workoutPlan, selectedWorkoutPlan: self.$selectedWorkoutPlan)
                        WorkoutPlanRoutines(workoutPlan: workoutPlan)
                            .deleteDisabled(true)
                    }
                }
                .onDelete { offsets in
                    if self.needsConfirmBeforeDelete(offsets: offsets) {
                        self.offsetsToDelete = offsets
                    } else {
                        self.deleteAt(offsets: offsets)
                    }
                }
                
                Section {
                    Button(action: {
                        self.createWorkoutPlan()
                    }) {
                        HStack {
                            Image(systemName: "plus")
                            Text("Create Workout Plan")
                        }
                    }
                }
            }
            .listStyle(GroupedListStyle())
            .navigationBarTitle("Workout")
            .actionSheet(item: $offsetsToDelete) { offsets in
                ActionSheet(title: Text("This cannot be undone."), buttons: [
                    .destructive(Text("Delete Workout Plan"), action: {
                        self.deleteAt(offsets: offsets)
                    }),
                    .cancel()
                ])
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func createWorkoutPlan() {
        assert(self.selectedWorkoutPlan == nil)
        selectedWorkoutPlan = WorkoutPlan.create(context: managedObjectContext)
        managedObjectContext.saveOrCrash()
    }
    
    /// Resturns `true` if at least one workout plan has workout routines
    private func needsConfirmBeforeDelete(offsets: IndexSet) -> Bool {
        for index in offsets {
            if workoutPlans[index].workoutRoutines?.count ?? 0 != 0 {
                return true
            }
        }
        return false
    }
    
    private func deleteAt(offsets: IndexSet) {
        let workoutPlans = self.workoutPlans
        for i in offsets {
            self.managedObjectContext.delete(workoutPlans[i])
        }
        self.managedObjectContext.saveOrCrash()
    }
}

private struct StartEmptyWorkoutCell: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    @EnvironmentObject var settingsStore: SettingsStore
    
    let quote: Quote? = Quotes.quotes[4]
    
    private var plateImage: some View {
        Image(settingsStore.weightUnit == .imperial ? "plate_lbs" : "plate_kg")
            .resizable()
            .aspectRatio(contentMode: ContentMode.fit)
            .frame(maxWidth: 100)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Group {
                if colorScheme == .dark {
                    plateImage.colorInvert()
                } else {
                    plateImage
                }
            }
            
            quote.map {
                Text($0.displayText)
                     .multilineTextAlignment(.center)
                     .foregroundColor(.secondary)
            }
            
            Button(action: {
                Workout.create(context: self.managedObjectContext).startOrCrash()
            }) {
                HStack {
                    Spacer()
                    Text("Start Workout")
                    Spacer()
                }
                .padding()
                .foregroundColor(.accentColor)
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).foregroundColor(Color(.systemFill)))
            }.buttonStyle(BorderlessButtonStyle())
        }
        .padding(.top, 8)
        .padding(.bottom, 8)
    }
}

private struct WorkoutPlanCell: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    
    @ObservedObject var workoutPlan: WorkoutPlan
    @Binding var selectedWorkoutPlan: WorkoutPlan?
    
    var body: some View {
        NavigationLink(destination: WorkoutPlanView(workoutPlan: workoutPlan), tag: workoutPlan, selection: $selectedWorkoutPlan) {
            VStack(alignment: .leading) {
                Text(workoutPlan.displayTitle).font(.headline)
            }
            .contextMenu {
                Button(action: {
                    _ = self.workoutPlan.duplicate(context: self.managedObjectContext)
                    self.managedObjectContext.saveOrCrash()
                }) {
                    Text("Duplicate")
                    Image(systemName: "doc.on.doc")
                }
                Button(action: {
                    self.managedObjectContext.delete(self.workoutPlan)
                    self.managedObjectContext.saveOrCrash()
                }) {
                    Text("Delete")
                    Image(systemName: "trash")
                }
            }
        }
    }
}

private struct WorkoutPlanRoutines: View {
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var exerciseStore: ExerciseStore
    
    @Environment(\.managedObjectContext) var managedObjectContext
    
    @ObservedObject var workoutPlan: WorkoutPlan
    
    private var workoutRoutines: [WorkoutRoutine] {
        workoutPlan.workoutRoutines?.array as? [WorkoutRoutine] ?? []
    }
    
    var body: some View {
        ForEach(workoutRoutines) { workoutRoutine in
            Button(action: {
                workoutRoutine.createWorkout(context: self.managedObjectContext).startOrCrash()
            }) {
                VStack(alignment: .leading) {
                    Text(workoutRoutine.displayTitle).italic()
                    Text(workoutRoutine.subtitle(in: self.exerciseStore.exercises))
                        .lineLimit(1)
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
        }
    }
}

#if DEBUG
struct StartWorkoutView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            StartWorkoutView()
            
            StartWorkoutView()
                .environment(\.colorScheme, .dark)
            
            StartWorkoutView()
                .previewDevice(.init("iPhone SE"))
            
            StartWorkoutView()
                .previewDevice(.init("iPhone 11 Pro Max"))
        }
        .mockEnvironment(weightUnit: .metric, isPro: true)
    }
}
#endif
