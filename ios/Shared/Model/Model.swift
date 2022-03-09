import RealmSwift

class Component: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var _id: ObjectId
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
}

class Point: EmbeddedObject {
    @Persisted var x: Double
    @Persisted var y: Double
}

enum ShapeType: String, PersistableEnum {
    case circle
    case rectangle
    case path
    case unknown
}
