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
    var z: Double = 0
    var points: [Point] = []

    mutating func reset() {
        self.points = []
        self.shape = .unknown
    }
}

struct CanvasView: View {
    @ObservedResults(Component.self, sortDescriptor: SortDescriptor(keyPath: \Component.z, ascending: true)) private var components
    @Environment(\.realm) private var realm

    // Controls
    @State private var bgColor = Color(.sRGB, red: 0.98, green: 0.9, blue: 0.2)
    @State private var strokeWidth: CGFloat = 1.0
    @State private var editMode: ShapeType = .unknown
    @State private var isFillable: Bool = false

    // Editable component
    @State private var currentComponent: ShapeComponent = ShapeComponent()

    // Dragging
    @State private var previousOffset = CGSize.zero
    @State private var offset = CGSize.zero

    // Zooming
    @State private var scale: CGFloat = 1.0

    var body: some View {
        VStack {
            ZStack {
                GeometryReader { geometry in
                    ForEach(components) { component in
                        switch component.shape {
                        case .path:
                            if case let .int(fillColor) = component.fillColor {
                                DrawShape(points: component.points.map { $0 }, offset: offset, scale: scale)
                                    .fill(Color(hex: fillColor))
                            } else {
                                DrawShape(points: component.points.map { $0 }, offset: offset, scale: scale)
                                    .stroke(lineWidth: component.strokeWidth)
                                    .foregroundColor(Color(hex: component.strokeColor.intValue ?? 0))
                            }
                        case .circle:
                            if case let .int(fillColor) = component.fillColor {
                                DrawCircularShape(component: component, offset: offset, scale: scale)
                                    .fill(Color(hex:  fillColor))
                            } else {
                                DrawCircularShape(component: component, offset: offset, scale: scale)
                                    .stroke(lineWidth: component.strokeWidth)
                                    .foregroundColor(Color(hex: component.strokeColor.intValue ?? 0))
                            }
                        case .rectangle:
                            if case let .int(fillColor) = component.fillColor {
                                DrawRectangleShape(component: component, offset: offset, scale: scale)
                                    .fill(Color(hex:  fillColor))
                            } else {
                                DrawRectangleShape(component: component, offset: offset, scale: scale)
                                    .stroke(lineWidth: component.strokeWidth)
                                    .foregroundColor(Color(hex: component.strokeColor.intValue ?? 0))
                            }
                        default: EmptyView()
                        }
                    }
                }
                .scaleEffect(scale)
                Canvas { context, size in
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
                        guard currentComponent.points.count > 1 else { return }
                        let x = currentComponent.points[0].x > currentComponent.points[1].x ? currentComponent.points[1].x : currentComponent.points[0].x
                        let y = currentComponent.points[0].y > currentComponent.points[1].y ? currentComponent.points[1].y : currentComponent.points[0].y
                        let width = currentComponent.points[1].x > currentComponent.points[0].x ? (currentComponent.points[1].x - currentComponent.points[0].x) : (currentComponent.points[0].x - currentComponent.points[1].x)
                        let height = currentComponent.points[1].y > currentComponent.points[0].y ? (currentComponent.points[1].y - currentComponent.points[0].y) : (currentComponent.points[0].y - currentComponent.points[1].y)
                        if let fillColor = currentComponent.fillColor {
                            guard currentComponent.points.count > 1 else { return }
                            context.fill(
                                Path(ellipseIn: CGRect(origin: CGPoint(x: x, y: y), size: CGSize(width: width, height: height))),
                                with: .color(Color(hex: fillColor)))
                        } else {
                            guard currentComponent.points.count > 1 else { return }
                            context.stroke(
                                Path(ellipseIn: CGRect(origin: CGPoint(x: x, y: y), size: CGSize(width: width, height: height))),
                                with: .color(Color(hex: currentComponent.strokeColor)),
                                lineWidth: currentComponent.strokeWidth)
                        }
                    case .rectangle:
                        guard currentComponent.points.count > 1 else { return }
                        let x = currentComponent.points[0].x > currentComponent.points[1].x ? currentComponent.points[1].x : currentComponent.points[0].x
                        let y = currentComponent.points[0].y > currentComponent.points[1].y ? currentComponent.points[1].y : currentComponent.points[0].y
                        let width = currentComponent.points[1].x > currentComponent.points[0].x ? (currentComponent.points[1].x - currentComponent.points[0].x) : (currentComponent.points[0].x - currentComponent.points[1].x)
                        let height = currentComponent.points[1].y > currentComponent.points[0].y ? (currentComponent.points[1].y - currentComponent.points[0].y) : (currentComponent.points[0].y - currentComponent.points[1].y)
                        if let fillColor = currentComponent.fillColor {
                            context.fill(
                                Path(CGRect(origin: CGPoint(x: x, y: y), size: CGSize(width: width, height: height))),
                                with: .color(Color(hex: fillColor)))
                        } else {
                            context.stroke(
                                Path(CGRect(origin: CGPoint(x: x, y: y), size: CGSize(width: width, height: height))),
                                with: .color(Color(hex: currentComponent.strokeColor)),
                                lineWidth: currentComponent.strokeWidth)
                        }
                    default:
                        break
                    }
                }
                .scaleEffect(scale)
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
                                currentComponent.points.append(Point(x: newPoint.x, y: newPoint.y))
                                currentComponent.z = (components.last?.z ?? 0 + 1)
                            } else {
                                if currentComponent.points.count > 1 {
                                    currentComponent.points[1] = Point(x: newPoint.x, y: newPoint.y)
                                } else {
                                    currentComponent.points.append(Point(x: newPoint.x, y: newPoint.y))
                                }
                            }
                        case .path:
                            if value.translation.width + value.translation.height == 0 {
                                currentComponent.shape = editMode
                                currentComponent.strokeColor = bgColor.hexaInt ?? 0
                                currentComponent.strokeWidth = strokeWidth
                                currentComponent.fillColor = isFillable ? bgColor.hexaInt ?? 0 : nil
                                currentComponent.points.append(Point(x: newPoint.x, y: newPoint.y))
                                currentComponent.z = (components.last?.z ?? 0 + 1)
                            } else {
                                currentComponent.points.append(Point(x: newPoint.x, y: newPoint.y))
                            }
                        case .unknown:
                            break
                        }
                    })
                    .onChanged({ gesture in
                        switch editMode {
                        case .unknown:
                            let currentWidth = gesture.translation.width - previousOffset.width
                            let currentHeight = gesture.translation.height - previousOffset.height
                            previousOffset = gesture.translation
                            offset = CGSize(width: offset.width + currentWidth, height: offset.height + currentHeight)
                            updateSubscription(offset: offset)
                        default: break
                        }
                    })
                    .onEnded({ value in
                        switch editMode {
                        case .circle, .rectangle, .path:
                            guard currentComponent.points.count > 1,
                                  currentComponent.points[0].x != currentComponent.points[1].x || currentComponent.points[0].y != currentComponent.points[1].y else {
                                currentComponent.reset()
                                return
                            }
                            currentComponent.left = currentComponent.points.sorted(by: { $0.x < $1.x }).first!.x
                            currentComponent.top = currentComponent.points.sorted(by: { $0.y < $1.y }).first!.y
                            currentComponent.right = currentComponent.points.sorted(by: { $0.x > $1.x }).first!.x
                            currentComponent.bottom = currentComponent.points.sorted(by: { $0.y > $1.y }).first!.y
                            $components.append(Component.make(shapeComponent: currentComponent, offset: offset))
                            currentComponent.reset()
                        case .unknown:
                            previousOffset = .zero
                        }
                    })
            )
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        self.scale = value.magnitude
                    }
            )
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

    func updateSubscription(offset: CGSize) {
        let subs = realm.subscriptions
        if let offsetSubscription = subs.first(named: "offset") {
            subs.write({
                print("-----> New query update left < \(UIScreen.main.bounds.width - offset.width) && right > \((0 - offset.width)) && top < \(UIScreen.main.bounds.height - offset.height) && bottom > \(0 - offset.height)")
                offsetSubscription.update(toType: Component.self) {
                    $0.left < (UIScreen.main.bounds.width - offset.width) && $0.right > (0 - offset.width) && $0.top < (UIScreen.main.bounds.height - offset.height) && $0.bottom > (0 - offset.height)
                }
            }) { error in
                print("Query update completed with error \(String(describing: error))")
            }
        }
    }
}

struct DrawShape: Shape {
    var points: [Point]
    var offset: CGSize
    var scale: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard points.count > 1 else {
            return path
        }

        path.move(to: CGPoint(x: points[0].x + offset.width, y: points[0].y + offset.height))
        for index in 1...(points.count - 1) {
            path.addLine(to: CGPoint(x: points[index].x + offset.width, y: points[index].y + offset.height))
        }
        return path
    }
}

struct DrawCircularShape: Shape {
    var component: Component
    var offset: CGSize
    var scale: CGFloat

    func path(in rect: CGRect) -> Path {
        return Path(ellipseIn: CGRect(origin:  CGPoint(x: component.left + offset.width, y: component.top + offset.height), size: CGSize(width: (component.right - component.left), height: (component.bottom - component.top))))
    }
}

struct DrawRectangleShape: Shape {
    var component: Component
    var offset: CGSize
    var scale: CGFloat

    func path(in rect: CGRect) -> Path {
        return Path(CGRect(origin:  CGPoint(x: component.left + offset.width, y: component.top +  offset.height), size: CGSize(width: (component.right - component.left), height: (component.bottom - component.top))))
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
