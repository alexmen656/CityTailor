//
//  Widget_2LiveActivity.swift
//  Widget 2
//
//  Created by Alex Polan on 5/14/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct Widget_2Attributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        
        var emoji: String
    }

    
    var name: String
}

struct Widget_2LiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: Widget_2Attributes.self) { context in
            
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                
                
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    
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

extension Widget_2Attributes {
    fileprivate static var preview: Widget_2Attributes {
        Widget_2Attributes(name: "World")
    }
}

extension Widget_2Attributes.ContentState {
    fileprivate static var smiley: Widget_2Attributes.ContentState {
        Widget_2Attributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: Widget_2Attributes.ContentState {
         Widget_2Attributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: Widget_2Attributes.preview) {
   Widget_2LiveActivity()
} contentStates: {
    Widget_2Attributes.ContentState.smiley
    Widget_2Attributes.ContentState.starEyes
}
