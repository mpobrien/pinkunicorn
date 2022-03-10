package io.realm.pinkunicorn

import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.lifecycle.ViewModel
import io.realm.Realm
import io.realm.kotlin.toFlow
import io.realm.kotlin.where
import io.realm.log.RealmLog
import io.realm.mongodb.sync.MutableSubscriptionSet
import io.realm.mongodb.sync.Subscription
import io.realm.mongodb.sync.SubscriptionSet
import io.realm.mongodb.sync.SyncConfiguration
import io.realm.pinkunicorn.model.Component
import io.realm.pinkunicorn.model.Point
import io.realm.pinkunicorn.model.Shape
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.flowOf
import kotlin.random.Random

sealed interface LoadingState
object Hidden : LoadingState
object Loading: LoadingState
object Error : LoadingState

class DrawingBoardViewModel : ViewModel() {

    private val realm: Realm
    private var selectedShape: Shape? = null
    private var _mutableLoadingState = MutableStateFlow<LoadingState>(Hidden)

    init {
        val config = SyncConfiguration.Builder(UnicornApplication.APP.currentUser())
            .initialSubscriptions { realm: Realm, subscriptions: MutableSubscriptionSet ->
                subscriptions.addOrUpdate(Subscription.create(realm.where<Component>()))
            }
            .build()
        // Local Realm for debugging
        // val config = Realm.getDefaultConfiguration()
        realm = Realm.getInstance(config)
        realm.subscriptions.waitForSynchronizationAsync(object: SubscriptionSet.StateChangeCallback {
            override fun onStateChange(subscriptions: SubscriptionSet) {
                _mutableLoadingState.value = Hidden
            }

            override fun onError(e: Throwable) {
                RealmLog.error(e.toString())
                _mutableLoadingState.value = Error
            }
        })
    }

    fun observeDrawings(): Flow<List<Component>> {
        return realm.where<Component>().findAllAsync().toFlow()
    }

    fun observeLoading(): Flow<LoadingState> {
        return _mutableLoadingState.asStateFlow()
    }

    fun selectShape(shape: Shape) {
        selectedShape = shape
    }

    private fun getRandomStrokeColor(): Color = listOf(Color.Black, Color.Red, Color.Green, Color.Blue).random()

    private fun getRandomStrokeWidth(): Float = Random.nextInt(10).toFloat()

    private fun getRandomFillColor(): Color? = Color(
            red = Random.nextInt(256),
            green = Random.nextInt(256),
            blue = Random.nextInt(256),
            alpha = Random.nextInt(256)
        )

    private fun setRandomSize(component: Component, offset: Offset): Component {
        val width = Random.nextInt(200)
        val height = Random.nextInt(200)
        return component.apply {
            left = offset.x - width/2
            right = offset.x + width/2
            top = offset.y - height/2
            bottom = offset.y + height/2
        }
    }

    // Requires that left, top, right and bottom are set
    private fun createRandomPath(component: Component) {
        // Create a triangle
        component.points.apply {
            add(Point(component.left, component.bottom))
            add(Point(component.left + (component.right - component.left)/2, component.top))
            add(Point(component.right, component.bottom))
            add(Point(component.left, component.bottom))
        }
    }

    fun canvasTapped(offset: Offset) {
        selectedShape?.let { shape ->
            val component = createRandomComponent(shape, offset)
            RealmLog.error("Offset: $offset, obj: $component")
            realm.executeTransactionAsync { bgRealm ->
                bgRealm.insert(component)
            }
        }
    }

    private fun createRandomComponent(shape: Shape, offset: Offset): Component {
        val comp = when(shape) {
            Shape.CIRCLE -> {
                Component().apply {
                    fillColor = getRandomFillColor()
                    this.shape = Shape.CIRCLE
                    strokeWidth = getRandomStrokeWidth()
                    strokeColor = getRandomStrokeColor()
                }
            }
            Shape.PATH -> {
                Component().apply {
                    fillColor = null
                    this.shape = Shape.PATH
                    strokeWidth = getRandomStrokeWidth()
                    strokeColor = getRandomStrokeColor()
                }
            }
            Shape.RECTANGLE -> {
                Component().apply {
                    fillColor = getRandomFillColor()
                    this.shape = Shape.RECTANGLE
                    strokeWidth = getRandomStrokeWidth()
                    strokeColor = getRandomStrokeColor()
                }
            }
            Shape.UNKNOWN -> TODO()
        }

        setRandomSize(comp, offset)
        if (comp.shape == Shape.PATH) {
            createRandomPath(comp)
        }
        return comp
    }
}