//
//  Widget_1LiveActivity.swift
//  Widget 1
//
//  Created by Alex Polan on 5/13/25.


import ActivityKit
import WidgetKit
import SwiftUI

struct Widget_1Attributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        
        var value: Int
    }

    
    var name: String
}

struct Widget_1LiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: Widget_1Attributes.self) { context in
            
            VStack {
                Text("Hello")
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
                    Text("Bottom")
                    
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T")
            } minimal: {
                Text("Min")
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension Widget_1Attributes {
    fileprivate static var preview: Widget_1Attributes {
        Widget_1Attributes(name: "World")
    }
}

extension Widget_1Attributes.ContentState {
    fileprivate static var smiley: Widget_1Attributes.ContentState {
        Widget_1Attributes.ContentState(value: 1)
     }
     
     fileprivate static var starEyes: Widget_1Attributes.ContentState {
         Widget_1Attributes.ContentState(value: 2)
     }
}

#Preview("Notification", as: .content, using: Widget_1Attributes.preview) {
   Widget_1LiveActivity()
} contentStates: {
    Widget_1Attributes.ContentState.smiley
    Widget_1Attributes.ContentState.starEyes
}
