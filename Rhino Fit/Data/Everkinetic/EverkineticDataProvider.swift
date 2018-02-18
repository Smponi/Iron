//
//  EverkineticDataProvider.swift
//  Rhino Fit
//
//  Created by Karim Abou Zeid on 22.01.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import Foundation

class EverkineticDataProvider {
    static let exercises = loadExercises()
    static let exercisesGrouped = splitIntoMuscleGroups(exercises: loadExercises())
    
    static func findExercise(id: Int) -> Exercise? {
        if let foundExercise = exercises.first(where: { (exercise) -> Bool in
            return exercise.id == id
        }) {
            return foundExercise
        }
        return nil
    }
    
    private static func loadExercises() -> [Exercise] {
        let jsonUrl = Bundle.main.bundleURL.appendingPathComponent("everkinetic-data").appendingPathComponent("exercises.json")
        if let jsonString = try? String(contentsOf: jsonUrl) {
            return EverkineticParser.parse(jsonString: jsonString).sorted(by: { (a, b) -> Bool in
                a.title < b.title
            })
        }
        return []
    }

    static func splitIntoMuscleGroups(exercises: [Exercise]) -> [[Exercise]] {
        var groups: [[Exercise]] = []
        var nextIndex = 0
        let exercises = exercises.sorted { (a, b) -> Bool in
            a.muscleGroup < b.muscleGroup
        }
        while (exercises.count > nextIndex) {
            let groupName = exercises[nextIndex].muscleGroup
            var muscleGroup = exercises.filter({ (exercise) -> Bool in
                exercise.muscleGroup == groupName
            })
            
            nextIndex = exercises.index(where: { (exercise) -> Bool in
                exercise.id == muscleGroup.last!.id
            })! + 1
            
            // do this after nextIndex is set
            muscleGroup = muscleGroup.sorted(by: { (a, b) -> Bool in
                a.title < b.title
            })
            groups.append(muscleGroup)
        }
        return groups
    }
    
}
