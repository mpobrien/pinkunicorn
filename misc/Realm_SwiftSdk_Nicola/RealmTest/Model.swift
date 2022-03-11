//
//  Model.swift
//  RealmTest
//
//  Created by nicola cabiddu on 09/03/2022.
//

import Foundation
import RealmSwift

class Component: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var shape: ShapeType = .unknown
    @Persisted var strokeColor: AnyRealmValue
    @Persisted var strokeWidth: Double
    @Persisted var fillColor: AnyRealmValue
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
