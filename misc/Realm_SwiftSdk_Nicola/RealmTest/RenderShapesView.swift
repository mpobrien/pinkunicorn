//
//  RenderView.swift
//  RealmTest
//
//  Created by nicola cabiddu on 09/03/2022.
//

import SwiftUI
import RealmSwift

struct CircleShape : Shape {
    var component : Component
    func path(in rect : CGRect) -> Path {
        return Path(ellipseIn: CGRect(origin:  CGPoint(x: component.left, y: component.top), size: CGSize(width: component.right - component.left, height: component.bottom - component.top)))
    }
}

struct RectangleShape : Shape {
    var component : Component
    func path(in rect : CGRect) -> Path {
        return Path(CGRect(origin:  CGPoint(x: component.left, y: component.top), size: CGSize(width: component.right - component.left, height: component.bottom - component.top)))
    }
}

struct GenericShape : Shape {
    var points: [Point]
    func path(in rect : CGRect) -> Path {
        if points.count <= 1 {
            return Path()
        }
            
        var path = Path()
        path.move(to: CGPoint(x: points[0].x, y: points[0].y))
        for index in 1...(points.count - 1) {
            path.addLine(to: CGPoint(x: points[index].x, y: points[index].y))
        }
        return path
    }
}

struct RgbColor {
    static func toColor(argb : Int) -> SwiftUI.Color {
        let red   = Double((argb & 0x00FF0000) >> 16) / 255
        let green = Double((argb & 0x0000FF00) >> 8) / 255
        let blue  = Double((argb & 0x000000FF)) / 255
        return SwiftUI.Color(CGColor(red: red, green: green, blue: blue, alpha: 1.0))
    }
}

struct RenderShapesView: View {
    
    @ObservedResults(Component.self) var components

    @State private var bgColor = Color(.sRGB, red: 1.0, green: 1.0, blue: 1.0)
    @State private var editMode: ShapeType = .unknown
    
    var body: some View {
        VStack {
            ZStack {
                GeometryReader { geometry in
                    ForEach(components) { component in
                        
//                        if let fillColor = component.fillColor {
//                            CircleShape(component: component).fill(RgbColor.toColor(argb: fillColor))
//                        } else {
//                            CircleShape(component: component).stroke(lineWidth: component.strokeWidth)
//                                .foregroundColor(RgbColor.toColor(argb: component.strokeColor))
//                        }
                        
                        
                        switch component.shape {
                        case .circle:
                            
                            if case let .int(fillColor) = component.fillColor {
                                CircleShape(component: component).fill(RgbColor.toColor(argb: fillColor))
                            } else {
                                CircleShape(component: component)
                                    .stroke(lineWidth: component.strokeWidth)
                                    .foregroundColor(RgbColor.toColor(argb: component.strokeColor.intValue ?? 0))
                            }
                            
                        case .rectangle:
                            
                            if case let .int(fillColor) = component.fillColor {
                                RectangleShape(component: component).fill(RgbColor.toColor(argb: fillColor))
                            } else {
                                RectangleShape(component: component).stroke(lineWidth: component.strokeWidth)
                                    .foregroundColor(RgbColor.toColor(argb: component.strokeColor.intValue ?? 0))
                            }
                            
                        case .path:
                            
                            if case let .int(fillColor) = component.fillColor {
                                GenericShape(points: component.points.map{$0}).fill(RgbColor.toColor(argb: fillColor))
                            } else {
                                GenericShape(points: component.points.map{$0}).stroke(lineWidth: component.strokeWidth)
                                    .foregroundColor(RgbColor.toColor(argb: component.strokeColor.intValue ?? 0))
                            }
                            
                        default: EmptyView()
                        }
                    }
                }
            }
        }.toolbar {
            ToolbarItem(placement: ToolbarItemPlacement.bottomBar) {
                Button(action: {
                    
                }) { Image(systemName: "circle") }
            }
            ToolbarItem(placement: ToolbarItemPlacement.bottomBar) {
                Button(action: {
                    
                }) { Image(systemName: "rectangle") }
            }
            ToolbarItem(placement: ToolbarItemPlacement.bottomBar) {
                Button(action: {
                    
                }) { Image(systemName: "shape") }
            }
        }
    }
}
