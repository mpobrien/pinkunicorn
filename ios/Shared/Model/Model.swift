import RealmSwift
import CoreGraphics

class Component: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var _id: ObjectId = ObjectId.generate()
    @Persisted var shape: ShapeType
    @Persisted var strokeColor: AnyRealmValue
    @Persisted var strokeWidth: Double
    @Persisted var fillColor: AnyRealmValue
    @Persisted var top: Double
    @Persisted var right: Double
    @Persisted var bottom: Double
    @Persisted var left: Double
    @Persisted var z: Double
    @Persisted var points: List<Point>

    static func make(shapeComponent: ShapeComponent, offset: CGSize) -> Component {
        let component = Component()
        component.shape = shapeComponent.shape
        component.strokeColor = .int(shapeComponent.strokeColor)
        component.strokeWidth = shapeComponent.strokeWidth
        component.fillColor = shapeComponent.fillColor != nil ? .int(shapeComponent.fillColor!) : .none
        component.top = shapeComponent.top - offset.height
        component.right = shapeComponent.right - offset.width
        component.bottom = shapeComponent.bottom - offset.height
        component.left = shapeComponent.left - offset.width
        component.z = shapeComponent.z
        shapeComponent.points.forEach { point in
            component.points.append(Point(x: point.x - offset.width, y: point.y - offset.height))
        }
        return component
    }
}

class Point: EmbeddedObject {
    @Persisted var x: Double
    @Persisted var y: Double
    
    convenience init(x: Double,
                     y: Double) {
        self.init()
        self.x = x
        self.y = y
    }
}

enum ShapeType: String, PersistableEnum {
    case circle
    case rectangle
    case path
    case unknown
}
