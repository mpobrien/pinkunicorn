import SwiftUI
import RealmSwift

struct CanvasView: View {
    @ObservedResults(Component.self) var components

    @State private var bgColor =
            Color(.sRGB, red: 0.98, green: 0.9, blue: 0.2)
    @State private var editMode: ShapeType = .unknown

    var body: some View {
        VStack {
            ZStack {
                GeometryReader { geometry in
                    ForEach(components) { component in
                        switch component.shape {
                        case .path:
                            DrawShape(points: component.points.map { $0 })
                                .stroke(lineWidth: component.strokeWidth)
                                .foregroundColor(Color(rgbInt: component.strokeColor))
                        case .circle:
                            DrawCircularShape(component: component)
                                .stroke(lineWidth: component.strokeWidth)
                                .foregroundColor(Color(rgbInt: component.strokeColor))
                        case .rectangle:
                            DrawRectangleShape(component: component)
                                .stroke(lineWidth: component.strokeWidth)
                                .foregroundColor(Color(rgbInt: component.strokeColor))
                        default: EmptyView()
                        }
                    }
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                Spacer()
                Button {
                    if editMode == .circle {
                        editMode = .unknown
                    } else {
                        editMode = .circle
                    }
                } label: {
                    if self.editMode == .circle {
                        Image(systemName: "circle.fill")
                    } else {
                        Image(systemName: "circle")
                    }
                }
                .controlSize(.large)
                Button {
                    if editMode == .rectangle {
                        editMode = .unknown
                    } else {
                        editMode = .rectangle
                    }
                } label: {
                    if self.editMode == .rectangle {
                        Image(systemName: "rectangle.fill")
                    } else {
                        Image(systemName: "rectangle")
                    }
                }
                .controlSize(.large)
                Button {
                    if editMode == .path {
                        editMode = .unknown
                    } else {
                        editMode = .path
                    }
                } label: {
                    if self.editMode == .path {
                        Image(systemName: "scribble.variable")
                    } else {
                        Image(systemName: "scribble")
                    }
                }
                .controlSize(.large)
                ColorPicker("", selection: $bgColor)
                Spacer()
            }
        }
    }

}

struct DrawShape: Shape {
    var points: [Point]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard points.count > 1 else {
            return path
        }

        path.move(to: CGPoint(x: points[0].x, y: points[0].y))
        for index in 1...(points.count - 1) {
            path.addLine(to: CGPoint(x: points[index].x, y: points[index].y))
        }
        return path
    }
}

struct DrawCircularShape: Shape {
    var component: Component

    func path(in rect: CGRect) -> Path {
        return Path(ellipseIn: CGRect(origin:  CGPoint(x: component.left, y: component.top), size: CGSize(width: component.right - component.left, height: component.bottom - component.top)))
    }
}

struct DrawRectangleShape: Shape {
    var component: Component

    func path(in rect: CGRect) -> Path {
        return Path(CGRect(origin:  CGPoint(x: component.left, y: component.top), size: CGSize(width: component.right - component.left, height: component.bottom - component.top)))
    }
}

struct Footer: View {
   var body: some View {
        HStack {
            if let user = app.currentUser {
                Text("Logged In as: \(app.currentUser!.id)")
                Button("Logout") {
                    Task {
                        do {
                            try await user.logOut()
                        } catch {
                        }
                    }
                }
            }
            Spacer()
        }
    }
}

extension Color {
    init(rgbInt: Int) {
        var hexString = String(rgbInt)
        if hexString.count < 2 {
            hexString = "0" + hexString
        }
        var hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        if (hex.hasPrefix("#")) {
            hex.remove(at: hex.startIndex)
        }

        if ((hex.count) != 6) {
            self = .gray
        }

        var rgbValue:UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgbValue)

        self = Color(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0)
    }
}
