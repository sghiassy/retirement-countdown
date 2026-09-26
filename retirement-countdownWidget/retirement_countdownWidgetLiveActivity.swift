//
//  retirement_countdownWidgetLiveActivity.swift
//  retirement-countdownWidget
//
//  Created by Shaheen Ghiassy on 9/26/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct retirement_countdownWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct retirement_countdownWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: retirement_countdownWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
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

extension retirement_countdownWidgetAttributes {
    fileprivate static var preview: retirement_countdownWidgetAttributes {
        retirement_countdownWidgetAttributes(name: "World")
    }
}

extension retirement_countdownWidgetAttributes.ContentState {
    fileprivate static var smiley: retirement_countdownWidgetAttributes.ContentState {
        retirement_countdownWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: retirement_countdownWidgetAttributes.ContentState {
         retirement_countdownWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: retirement_countdownWidgetAttributes.preview) {
   retirement_countdownWidgetLiveActivity()
} contentStates: {
    retirement_countdownWidgetAttributes.ContentState.smiley
    retirement_countdownWidgetAttributes.ContentState.starEyes
}
