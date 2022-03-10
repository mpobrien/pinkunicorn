import SwiftUI
import RealmSwift

struct ShapeComponent {
    var shape: ShapeType = .unknown
    var strokeColor: Int = 0
    var strokeWidth: Double = 0.0
    var fillColor: Int?
    var top: Double = 0.0
    var right: Double = 0.0
    var bottom: Double = 0.0
    var left: Double = 0.0
    var z: Double = 0.0
    var points: [Point] = []

    mutating func reset() {
        self.left = 0.0
        self.right = 0.0
        self.top = 0.0
        self.bottom = 0.0
        self.points = []
        self.shape = .unknown
    }
}

struct CanvasView: View {
    @ObservedResults(Component.self) var components

    @State private var bgColor = Color(.sRGB, red: 0.98, green: 0.9, blue: 0.2)
    @State private var strokeWidth: CGFloat = 1.0
    @State private var editMode: ShapeType = .unknown
    @State private var isFillable: Bool = false
    @State private var currentComponent: ShapeComponent = ShapeComponent()

    var body: some View {
        VStack {
            ZStack {
                GeometryReader { geometry in
                    ForEach(components) { component in
                        switch component.shape {
                        case .path:
                            if let fillColor = component.fillColor {
                                DrawShape(points: component.points.map { $0 })
                                    .fill(Color(hex: fillColor))
                            } else {
                                DrawShape(points: component.points.map { $0 })
                                    .stroke(lineWidth: component.strokeWidth)
                                    .foregroundColor(Color(hex: component.strokeColor))
                            }
                        case .circle:
                            if let fillColor = component.fillColor {
                                DrawCircularShape(component: component)
                                    .fill(Color(hex: fillColor))
                            } else {
                                DrawCircularShape(component: component)
                                    .stroke(lineWidth: component.strokeWidth)
                                    .foregroundColor(Color(hex: component.strokeColor))
                            }
                        case .rectangle:
                            if let fillColor = component.fillColor {
                                DrawRectangleShape(component: component)
                                    .fill(Color(hex: fillColor))
                            } else {
                                DrawRectangleShape(component: component)
                                    .stroke(lineWidth: component.strokeWidth)
                                    .foregroundColor(Color(hex: component.strokeColor))
                            }
                        default: EmptyView()
                        }
                    }
                }
                Canvas { context, size in
                    print("Drawing")
                    switch currentComponent.shape {
                    case .path:
                        guard currentComponent.points.count > 1 else { return }
                        context.stroke(
                            Path() { path in
                                path.move(to: CGPoint(x: currentComponent.points[0].x, y: currentComponent.points[0].y))
                                (1...(currentComponent.points.count - 1)).forEach { index in
                                    path.addLine(to: CGPoint(x: currentComponent.points[index].x, y: currentComponent.points[index].y))
                                }
                            },
                            with: .color(Color(hex: currentComponent.strokeColor)),
                            lineWidth: currentComponent.strokeWidth)
                    case .circle:
                        if let fillColor = currentComponent.fillColor {
                            context.fill(
                                Path(ellipseIn: CGRect(origin: CGPoint(x: currentComponent.left, y: currentComponent.top), size: CGSize(width: currentComponent.right - currentComponent.left, height: currentComponent.bottom - currentComponent.top))),
                                with: .color(Color(hex: fillColor)))
                        } else {
                            context.stroke(
                                Path(ellipseIn: CGRect(origin: CGPoint(x: currentComponent.left, y: currentComponent.top), size: CGSize(width: currentComponent.right - currentComponent.left, height: currentComponent.bottom - currentComponent.top))),
                                with: .color(Color(hex: currentComponent.strokeColor)),
                                lineWidth: currentComponent.strokeWidth)
                        }
                    case .rectangle:
                        if let fillColor = currentComponent.fillColor {
                            context.fill(
                                Path(CGRect(origin: CGPoint(x: currentComponent.left, y: currentComponent.top), size: CGSize(width: currentComponent.right - currentComponent.left, height: currentComponent.bottom - currentComponent.top))),
                                with: .color(Color(hex: fillColor)))
                        } else {
                            context.stroke(
                                Path(CGRect(origin: CGPoint(x: currentComponent.left, y: currentComponent.top), size: CGSize(width: currentComponent.right - currentComponent.left, height: currentComponent.bottom - currentComponent.top))),
                                with: .color(Color(hex: currentComponent.strokeColor)),
                                lineWidth: currentComponent.strokeWidth)
                        }
                    default:
                        break
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .local)
                        .onChanged({ value in
                            let newPoint = value.location
                            switch editMode {
                            case .circle, .rectangle:
                                if value.translation.width + value.translation.height == 0 {
                                    currentComponent.shape = editMode
                                    currentComponent.strokeColor = bgColor.hexaInt ?? 0
                                    currentComponent.strokeWidth = strokeWidth
                                    currentComponent.fillColor = isFillable ? bgColor.hexaInt ?? 0 : nil
                                    currentComponent.left = newPoint.x
                                    currentComponent.top = newPoint.y
                                    currentComponent.right = newPoint.x
                                    currentComponent.bottom = newPoint.y
                                } else {
                                    currentComponent.right = newPoint.x
                                    currentComponent.bottom = newPoint.y
                                }
                            case .path:
                                if value.translation.width + value.translation.height == 0 {
                                    currentComponent.shape = editMode
                                    currentComponent.strokeColor = bgColor.hexaInt ?? 0
                                    currentComponent.strokeWidth = strokeWidth
                                    currentComponent.fillColor = isFillable ? bgColor.hexaInt ?? 0 : nil
                                    currentComponent.points.append(Point(x: newPoint.x, y: newPoint.y))
                                } else {
                                    currentComponent.points.append(Point(x: newPoint.x, y: newPoint.y))
                                }
                            case .unknown:
                                break
                            }

                        })
                        .onEnded({ value in
                            let newPoint = value.location
                            guard newPoint.x != currentComponent.left && newPoint.y != currentComponent.right else {
                                currentComponent.reset()
                                return
                            }
                            $components.append(Component.make(shapeComponent: currentComponent))
                            currentComponent.reset()
                        })
                    )

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
                Slider(value: $strokeWidth, in: 1...10,
                       minimumValueLabel: Text(""),
                       maximumValueLabel: Text("\(Int(strokeWidth))").font(.system(size: 16))) {}
                .frame(width: 150)
                Toggle("Fill", isOn: $isFillable)
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
    init(hex: Int) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1.0
        )
    }

    var uiColor: UIColor { .init(self) }
    typealias RGBA = (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)
    var rgba: RGBA? {
        var (r, g, b, a): RGBA = (0, 0, 0, 0)
        return uiColor.getRed(&r, green: &g, blue: &b, alpha: &a) ? (r, g, b, a) : nil
    }
    var hexaInt: Int? {
        guard let (red, green, blue, _) = rgba else { return nil }
        let hexString = String(format: "%02x%02x%02x",
                               Int(red * 255),
                               Int(green * 255),
                               Int(blue * 255))
        return Int(UInt64(hexString, radix: 16) ?? 0)
    }
}

extension Shape {
    func fill<Fill: ShapeStyle, Stroke: ShapeStyle>(_ fillStyle: Fill, strokeBorder strokeStyle: Stroke, lineWidth: CGFloat = 1) -> some View {
        self
            .stroke(strokeStyle, lineWidth: lineWidth)
            .background(self.fill(fillStyle))
    }
}
