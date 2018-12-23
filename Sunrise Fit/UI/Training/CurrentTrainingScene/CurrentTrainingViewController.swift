//
//  CurrentTrainingViewController.swift
//  Rhino Fit
//
//  Created by Karim Abou Zeid on 10.02.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import UIKit
import CoreData

class CurrentTrainingViewController: UIViewController {
    
    var training: Training? {
        didSet {
            title = training?.displayTitle
            tableView?.reloadData()
            if timerView != nil {
                updateTimerViewState(animated: false)
            }
        }
    }
    
    @IBOutlet weak var timerView: TimerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self

        navigationItem.rightBarButtonItems?.append(editButtonItem)
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "Training", style: .plain, target: nil, action: nil) // when navigating to other VCs show only a short back button title
        
        timerView.title.text = "Elapsed time"
        timerView.button.setTitle("Start timer", for: .normal)
        timerView.delegate = self
    }

    private var reload = true
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if reload {
            // for now there is no easy way to figure out which cells have changed
            tableView.reloadData()
            updateTimerViewState(animated: false) // training could have been started
            reload = false
        }
    }

    @IBOutlet weak var tableView: UITableView!
    @IBAction func confirmCancelCurrentTraining(_ sender: Any) {
        let alert = UIAlertController(title: nil, message: "The current training will be deleted.", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Cancel Training", style: .destructive) { [weak self] _ in
            self?.performSegue(withIdentifier: "cancel training", sender: self)
        })
        alert.addAction(UIAlertAction(title: "Continue Training", style: .cancel))
        alert.popoverPresentationController?.barButtonItem = sender as? UIBarButtonItem // iPad
        present(alert, animated: true)
    }

    private func updateTimerViewState(animated: Bool) {
        if self.training?.start != nil {
            timerView.showTimer(animated: animated)
        } else {
            timerView.hideTimer(animated: animated)
        }
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let exerciseTableViewController = segue.destination as? ExercisesTableViewController {
            exerciseTableViewController.exercises = EverkineticDataProvider.exercises
            exerciseTableViewController.exerciseSelectionHandler = self
            exerciseTableViewController.accessoryType = .detailButton
            exerciseTableViewController.navigationItem.hidesSearchBarWhenScrolling = false
            exerciseTableViewController.title = "Add Exercise"
        } else if let trainingExerciseViewController = segue.destination as? CurrentTrainingExerciseViewController,
            let indexPath = tableView.indexPathForSelectedRow {
            reload = true // make sure to reload the table view when we come back
            trainingExerciseViewController.trainingExercise = (training!.trainingExercises![indexPath.row] as! TrainingExercise)
        } else if segue.identifier == "cancel training" {
            if training?.managedObjectContext != nil {
                training!.managedObjectContext!.delete(training!)
                AppDelegate.instance.saveContext()
            }
        }
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: animated)
    }
    
    private func createDefaultTrainingSets() -> NSOrderedSet {
        var trainingSets = [TrainingSet]()
        
        if training?.managedObjectContext == nil {
            return NSOrderedSet(array: trainingSets)
        }
        
        for _ in 0...3 {
            let trainingSet = TrainingSet(context: training!.managedObjectContext!)
            // TODO add default reps and weight
            trainingSets.append(trainingSet)
        }
        return NSOrderedSet(array: trainingSets)
    }
}

extension CurrentTrainingViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        if proposedDestinationIndexPath.row == training?.trainingExercises?.count {
            return sourceIndexPath // don't allow to move behind add exercise button
        }
        return (training!.trainingExercises![proposedDestinationIndexPath.row] as! TrainingExercise).isCompleted! ? sourceIndexPath : proposedDestinationIndexPath
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        if indexPath.row == training?.trainingExercises?.count {
            return .none // disable swipe to delete
        }
        return .delete
    }
}

extension CurrentTrainingViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let trainingExercise = training!.trainingExercises![sourceIndexPath.row] as! TrainingExercise
        training!.removeFromTrainingExercises(trainingExercise)
        training!.insertIntoTrainingExercises(trainingExercise, at: destinationIndexPath.row)
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        if (indexPath.row == training?.trainingExercises?.count) {
            return false // don't allow to move the add exercise button
        }
        return !(training!.trainingExercises![indexPath.row] as! TrainingExercise).isCompleted!
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let trainingExercise = training!.trainingExercises![indexPath.row] as! TrainingExercise
            training!.removeFromTrainingExercises(trainingExercise)
            trainingExercise.managedObjectContext?.delete(trainingExercise)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            title = training!.displayTitle
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (training?.trainingExercises?.count ?? 0) + 1 // + 1 for the addExercise row
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == training?.trainingExercises?.count {
            return tableView.dequeueReusableCell(withIdentifier: "addExerciseCell", for: indexPath) as! AddExerciseTableViewCell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "exerciseCell", for: indexPath)
        // TODO
        let trainingExercise = training!.trainingExercises![indexPath.row] as! TrainingExercise
        let completedSets = trainingExercise.numberOfCompletedSets!
        let totalSets = trainingExercise.trainingSets!.count
        cell.textLabel?.text = trainingExercise.exercise?.title
        cell.detailTextLabel?.text = "\(completedSets) of \(totalSets)"
        cell.tintColor = UIColor.lightGray
        if completedSets == totalSets { // completed exercise
            cell.textLabel?.textColor = UIColor.lightGray
            cell.detailTextLabel?.textColor = UIColor.lightGray
            cell.accessoryType = .checkmark
        } else {
            cell.textLabel?.textColor = UIColor.darkText
            cell.detailTextLabel?.textColor = UIColor.darkGray
            cell.accessoryType = .disclosureIndicator
        }
        return cell
    }
}

extension CurrentTrainingViewController: ExerciseSelectionHandler {
    func handleSelection(exercise: Exercise) {
        navigationController?.popToViewController(self, animated: true)
        
        guard let managedObjectContext = training?.managedObjectContext else {
            return
        }
        
        let trainingExercise = TrainingExercise(context: managedObjectContext)
        trainingExercise.exerciseId = Int16(exercise.id)
        trainingExercise.training = training
        trainingExercise.addToTrainingSets(createDefaultTrainingSets())
        
        AppDelegate.instance.saveContext()
        
        let insertedIndex = training!.trainingExercises!.index(of: trainingExercise)
        assert(insertedIndex != NSNotFound, "Just added trainig exercise not found")
        tableView.insertRows(at: [IndexPath(row: insertedIndex, section: 0)], with: .automatic)
        
        title = training?.displayTitle
    }
}

extension CurrentTrainingViewController: TimerViewDelegate {
    func elapsedTime(_ timerView: TimerView) -> TimeInterval {
        return -(self.training?.start?.timeIntervalSinceNow ?? 0.0)
    }
    
    func timerViewButtonPressed(_ timerView: TimerView) {
        if training?.start == nil {
            training?.start = Date()
        }
        updateTimerViewState(animated: true)
    }
}

class AddExerciseTableViewCell: UITableViewCell {
    @IBOutlet weak var addExerciseButton: UIButton!
}
