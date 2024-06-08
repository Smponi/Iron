//
//  Live_Widget_TestBundle.swift
//  Live Widget Test
//
//  Created by Philipp Smponias on 08.06.24.
//  Copyright © 2024 Karim Abou Zeid Software. All rights reserved.
//

import WidgetKit
import SwiftUI

@main
struct Live_Widget_TestBundle: WidgetBundle {
    var body: some Widget {
        Live_Widget_Test()
        Live_Widget_TestLiveActivity()
    }
}
