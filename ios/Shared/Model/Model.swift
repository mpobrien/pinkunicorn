import RealmSwift

class Component: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var _id: ObjectId = ObjectId.generate()
    @Persisted var shape: ShapeType
    @Persisted var strokeColor: Int
    @Persisted var strokeWidth: Double
    @Persisted var fillColor: Int?
    @Persisted var top: Double
    @Persisted var right: Double
    @Persisted var bottom: Double
    @Persisted var left: Double
    @Persisted var z: Double
    @Persisted var points: List<Point>

    static func make(shapeComponent: ShapeComponent) -> Component {
        let component = Component()
        component.shape = shapeComponent.shape
        component.strokeColor = shapeComponent.strokeColor
        component.strokeWidth = shapeComponent.strokeWidth
        component.fillColor = shapeComponent.fillColor
        component.top = shapeComponent.top
        component.right = shapeComponent.right
        component.bottom = shapeComponent.bottom
        component.left = shapeComponent.left
        component.z = shapeComponent.z
        component.points.append(objectsIn: shapeComponent.points)
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
