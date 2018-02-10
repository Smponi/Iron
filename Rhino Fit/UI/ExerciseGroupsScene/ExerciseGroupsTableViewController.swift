//
//  ExerciseGroupsTableViewController.swift
//  Rhino Fit
//
//  Created by Karim Abou Zeid on 22.01.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import UIKit

class ExerciseGroupsTableViewController: UITableViewController, ExerciseDetailPresenter {
    


    var exercisesGrouped = EverkineticDataProvider.loadExercisesGrouped()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let exerciseTableViewController = UIStoryboard(name: "Exercises", bundle: nil).instantiateViewController(withIdentifier: "ExerciseTableViewController") as! ExercisesTableViewController
        exerciseTableViewController.exercises = exercisesGrouped.flatMap{$0}
        exerciseTableViewController.exerciseDetailPresenter = self
        navigationItem.searchController = UISearchController(searchResultsController: exerciseTableViewController)
        navigationItem.searchController?.obscuresBackgroundDuringPresentation = false
        navigationItem.searchController?.searchResultsUpdater = exerciseTableViewController
        
        definesPresentationContext = true // prevents black screen when switching tabs while searching
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 1 : exercisesGrouped.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "exerciseGroup", for: indexPath)
        
        if indexPath.section == 0 {
            cell.textLabel?.text = "All"
            cell.detailTextLabel?.text = countString(count: exercisesGrouped.flatMap{$0}.count)
        } else {
            cell.textLabel?.text = exercisesGrouped[indexPath.row][0].muscleGroup.capitalized
            cell.detailTextLabel?.text = countString(count: exercisesGrouped[indexPath.row].count)
        }

        return cell
    }
    
    private func countString(count: Int) -> String {
        return "(\(count))"
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if let exerciseTableViewController = segue.destination as? ExercisesTableViewController,
            let indexPath = tableView.indexPathForSelectedRow {
            if indexPath.section == 0 { // All
                exerciseTableViewController.exercises = exercisesGrouped.flatMap{$0}
                exerciseTableViewController.title = "All"
            } else {
                let exercises = exercisesGrouped[indexPath.row]
                exerciseTableViewController.exercises = exercises
                exerciseTableViewController.title = exercises.first?.muscleGroup.capitalized
            }
        }
        
        if let exerciseDetailViewController = segue.destination as? ExerciseDetailViewController {
            exerciseDetailViewController.exercise = exerciseToPresent
        }
    }

    private var exerciseToPresent: Exercise?
    func presentExerciseDetail(exercise: Exercise) {
        exerciseToPresent = exercise
        performSegue(withIdentifier: "ShowExerciseDetail", sender: self)
    }

}
