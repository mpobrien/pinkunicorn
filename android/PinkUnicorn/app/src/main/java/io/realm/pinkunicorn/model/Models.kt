package io.realm.pinkunicorn.model

import androidx.compose.ui.graphics.Color
import io.realm.RealmAny
import io.realm.RealmList
import io.realm.RealmObject
import io.realm.annotations.PrimaryKey
import io.realm.annotations.RealmClass
import io.realm.annotations.RealmField
import io.realm.annotations.Required
import org.bson.types.ObjectId
import java.lang.Math.floor

enum class Shape {
    CIRCLE, PATH, RECTANGLE, UNKNOWN
}

@RealmClass(embedded = true)
open class Point(): RealmObject() {

    @RealmField("x") private var _x: Double = 0.0
    @RealmField("y") private var _y: Double = 0.0

    constructor(x: Float, y: Float): this() {
        this.x = x
        this.y = y
    }

    var x: Float
        get() = _x.toFloat()
        set(value) { _x = value.toDouble() }

    var y: Float
        get() = _y.toFloat()
        set(value) { _y = value.toDouble() }
}

open class Component: RealmObject {

    // MongoDB types
    @PrimaryKey
    @Required
    private var _id: ObjectId = ObjectId()
    @RealmField("top") private var _top: Double = 0.0
    @RealmField("left") private var _left: Double = 0.0
    @RealmField("right") private var _right: Double = 0.0
    @RealmField("bottom") private var _bottom: Double = 0.0
    @RealmField("z") private var _z: Double = 0.0
    @Required
    @RealmField("shape") private var _shape: String = ""
    @RealmField("strokeWidth") private var _strokeWidth: Double = 0.0
    @RealmField("strokeColor") private var _strokeColor: RealmAny = RealmAny.nullValue()
    @RealmField("fillColor") private var _fillColor: RealmAny = RealmAny.nullValue()
    var points: RealmList<Point> = RealmList()

    // Public types that hides conversion between MongoDB types and Compose types
    var top: Float
        get() = _top.toFloat()
        set(value) { _top = value.toDouble() }

    var left: Float
        get() = _left.toFloat()
        set(value) { _left = value.toDouble() }

    var right: Float
        get() = _right.toFloat()
        set(value) { _right = value.toDouble() }

    var bottom: Float
        get() = _bottom.toFloat()
        set(value) { _bottom = value.toDouble() }

    var z: Float
        get() = _z.toFloat()
        set(value) { _z = value.toDouble() }

    var shape: Shape
        get() = Shape.values().find { _shape.equals(it.name, ignoreCase = true) } ?: Shape.UNKNOWN
        set(value) {
            _shape = value.name.lowercase()
        }

    var strokeWidth: Float
        get() = _strokeWidth.toFloat()
        set(value) { _strokeWidth = value.toDouble() }

    var strokeColor: Color
        get() {
            return when(_strokeColor.type) {
                RealmAny.Type.INTEGER -> convertRgbToArgb(_strokeColor.asInteger())
                RealmAny.Type.STRING -> {
                    var color = _strokeColor.asString()
                    if (!color.startsWith("#")) color = "#$color"
                    Color(android.graphics.Color.parseColor(color))
                }
                else -> Color.Transparent
            }
        }
        set(value) {
            val color = RealmAny.valueOf(value.toRgb())
            _strokeColor = color
        }

    var fillColor: Color?
        get() {
            val c = _fillColor
            return when(c.type) {
                RealmAny.Type.INTEGER -> convertRgbToArgb(c.asInteger())
                RealmAny.Type.STRING -> {
                    var color = c.asString()
                    if (!color.startsWith("#")) color = "#$color"
                    Color(android.graphics.Color.parseColor(color))
                }
                else -> null
            }
        }
        set(value) {
            _fillColor = if (value == null) {
                RealmAny.nullValue()
            } else {
                val cValue = value.toRgb()
                val color = RealmAny.valueOf(cValue)
                color
            }
        }

    constructor() : super()

    private fun convertRgbToArgb(rgbColor: Int): Color {
        val red: Int = rgbColor shr 16 and 0xFF
        val green: Int = rgbColor shr 8 and 0xFF
        val blue: Int = rgbColor and 0xFF
        return Color(red, green, blue)
    }

    private fun floatToInt(f: Float): Int {
        val v: Float = if (f >= 1.0f) 255f else f * 256.0F
        return kotlin.math.floor(v).toInt()
    }

    private fun Color.toRgb(): Int {
        var rgb = floatToInt(this.red)
        rgb = ((rgb shl 8) + floatToInt(this.green))
        rgb = ((rgb shl 8) + floatToInt(this.blue))
        return rgb
    }

    override fun toString(): String {
        return "Component(points=$points, top=$top, left=$left, right=$right, bottom=$bottom, z=$z, shape=$shape, strokeWidth=$strokeWidth, strokeColor=$strokeColor, fillColor=$fillColor)"
    }

    fun printBoundingBox(): String {
        return "$shape[$left, $top, $right, $bottom]"
    }

}
