//
//  PinnedChart.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 20.07.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation

struct PinnedChart: Hashable {
    let exerciseId: Int
    let measurementType: WorkoutExerciseChartDataGenerator.MeasurementType
}
