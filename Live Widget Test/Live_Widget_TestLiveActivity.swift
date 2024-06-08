//
//  Live_Widget_TestLiveActivity.swift
//  Live Widget Test
//
//  Created by Philipp Smponias on 08.06.24.
//

import ActivityKit
import WidgetKit
import SwiftUI

//TODO: Ideas
// 1.Add 5kg/ 1.25kg to previous weight -> Make it so that you can adjust the weight easily from the home screen
// 2.Timer
// 3.Check Mark(?)
// 4.Show current exercise / set
// 5. Estimated remaining time (based on history)
// DynamicIsland Support is not planed for now. Lock screen has high priority
struct Live_Widget_TestAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct Live_Widget_TestLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: Live_Widget_TestAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
                Spacer()
                Text("Hello World")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension Live_Widget_TestAttributes {
    fileprivate static var preview: Live_Widget_TestAttributes {
        Live_Widget_TestAttributes(name: "World")
    }
}

extension Live_Widget_TestAttributes.ContentState {
    fileprivate static var smiley: Live_Widget_TestAttributes.ContentState {
        Live_Widget_TestAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: Live_Widget_TestAttributes.ContentState {
         Live_Widget_TestAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: Live_Widget_TestAttributes.preview) {
   Live_Widget_TestLiveActivity()
} contentStates: {
    Live_Widget_TestAttributes.ContentState.smiley
    Live_Widget_TestAttributes.ContentState.starEyes
}
