package io.realm.pinkunicorn

import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.lifecycle.ViewModel
import io.realm.Realm
import io.realm.kotlin.toFlow
import io.realm.kotlin.where
import io.realm.log.RealmLog
import io.realm.mongodb.sync.Subscription
import io.realm.mongodb.sync.SubscriptionSet
import io.realm.mongodb.sync.SyncConfiguration
import io.realm.pinkunicorn.model.Component
import io.realm.pinkunicorn.model.Point
import io.realm.pinkunicorn.model.Shape
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.forEach
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.onEach
import kotlin.random.Random

sealed interface LoadingState
object Hidden : LoadingState
object Loading: LoadingState
object Error : LoadingState

data class ViewPort(val width: Float, val height: Float)

data class BoundingBox(val left: Float, val top: Float, val right: Float, val bottom: Float) {
    fun toComponent(): Component {
        return Component().also {
            it.shape = Shape.RECTANGLE
            it.left = left
            it.top = top
            it.right = right
            it.bottom = bottom
            it.strokeColor = Color.Transparent
            it.strokeWidth = 0F
            it.fillColor = Color.Cyan.copy(alpha = 0.10F)
        }
    }
}

class DrawingBoardViewModel : ViewModel() {

    private var subscriptions: SubscriptionSet
    private var verticalScrollPosition: Float = 0F
    private var horizontalScrollPosition: Float = 0F
    private var viewport: ViewPort = ViewPort(0F, 0F)
    private var canvasSize: ViewPort = ViewPort(0F, 0F)
    private val realm: Realm
    private var selectedShape: Shape? = null
    private var _mutableLoadingState = MutableStateFlow<LoadingState>(Hidden)
    private var _mutableLoadingAreas = MutableStateFlow<List<BoundingBox>>(emptyList())

    init {
        val config = SyncConfiguration.Builder(UnicornApplication.APP.currentUser())
//            .initialSubscriptions { realm: Realm, subscriptions: MutableSubscriptionSet ->
//                subscriptions.addOrUpdate(Subscription.create(realm.where<Component>()))
//            }
            .build()
        realm = Realm.getInstance(config)
        subscriptions = realm.subscriptions
    }

    fun observeDrawings(): Flow<List<Component>> {
        return realm.where<Component>().findAllAsync().toFlow()
            .onEach {
                it.forEach { comp ->
                    RealmLog.error(comp.printBoundingBox())
                }
            }
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
            alpha = 0xFF
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

    fun setCanvasSize(size: ViewPort) {
        this.canvasSize = size
    }

    fun setViewportSize(width: Float, height: Float, verticalScroll: Float, horizontalScroll: Float) {
        this.viewport = ViewPort(width, height)
        this.verticalScrollPosition = verticalScroll
        this.horizontalScrollPosition = horizontalScroll
        updateLoadedAreas(viewport, verticalScroll, horizontalScroll)
    }

    // After a scroll update, run a maintainance over Subscriptions
    // We only want the last to subscriptions to be active
    private fun updateLoadedAreas(
        viewport: ViewPort,
        verticalScrollPosition: Float,
        horizontalScrollPosition: Float
    ) {
        subscriptions.update { subscriptions ->
                // Sort by creation data and then remove all subscription above the limit of 9
                // (Since we are going to add 1, so total limit is 10)
                val sortedSubs = subscriptions.sortedBy { it.createdAt }
                for (i in 10 until sortedSubs.size ) {
                    subscriptions.remove(sortedSubs[i])
                }

                // Calculate bounding box based on viewport size and current scroll positions
                val left = horizontalScrollPosition - canvasSize.width/2
                val right = left + viewport.width
                val top = verticalScrollPosition - canvasSize.height/2
                val bottom = top + viewport.height

                RealmLog.error("Subscription: Area[$left,$top,$right,$bottom]")
                Realm.getInstance(realm.configuration).use { realm ->
                    val sub = Subscription.create(
                        "Area[$left,$top,$right,$bottom]",
                        realm.where<Component>().rawPredicate("left < $0 AND right > $1 AND top < $2 AND bottom > $3", right, left, bottom, top)
                    )
                    subscriptions.addOrUpdate(sub)
                }
                RealmLog.error("Subscriptions: ${subscriptions.size()}")
                subscriptions.forEach {
                    RealmLog.error(it.query)
                }

                // Find the bounding boxes for all current subscriptions
                _mutableLoadingAreas.value = subscriptions
                    .map { it.name!!.substringAfter("[").substringBefore("]") }
                    .map {
                        val parts: List<String> = it.split(",")
                        BoundingBox(
                            left = parts[0].toFloat(),
                            top = parts[1].toFloat(),
                            right = parts[2].toFloat(),
                            bottom = parts[3].toFloat()
                        )
                    }
            }

        // Annoying that this must be tied to updates
        _mutableLoadingState.value = Loading
        subscriptions.waitForSynchronizationAsync(object: SubscriptionSet.StateChangeCallback {
            override fun onStateChange(subscriptions: SubscriptionSet) {
                RealmLog.error("Finished downloading: ${subscriptions.state}")
                _mutableLoadingState.value = Hidden
            }

            override fun onError(e: Throwable) {
                RealmLog.error(e.toString())
                _mutableLoadingState.value = Error
            }
        })

//        realm.subscriptions.updateAsync(object: SubscriptionSet.UpdateAsyncCallback {
//            override fun update(subscriptions: MutableSubscriptionSet) {
//                // Sort by creation data and then remove all subscription above the limit of 9
//                // (Since we are going to add 1, so total limit is 10)
//                val sortedSubs = subscriptions.sortedBy { it.createdAt }
//                for (i in 10 until sortedSubs.size ) {
//                    subscriptions.remove(sortedSubs[i])
//                }
//
//                // Calculate bounding box based on viewport size and current scroll positions
//                // For debugging add a padding of 20
//                val left = horizontalScrollPosition
//                val right = left + viewport.width
//                val top = verticalScrollPosition
//                val bottom = top + viewport.height
//
//                Realm.getInstance(realm.configuration).use { realm ->
//                    val sub = Subscription.create(
//                        "Area[$left,$top,$right,$bottom]",
//                        realm.where<Component>().rawPredicate("left < $0 AND right > $1 AND top < $2 AND bottom > $3", right, left, bottom, top)
//                    )
//                    subscriptions.addOrUpdate(sub)
//                }
//
//                // Find the bounding boxes for all current subscriptions
//                _mutableLoadingAreas.value = subscriptions
//                    .map { it.name!!.substringAfter("[").substringBefore("]") }
//                    .map {
//                        val parts: List<String> = it.split(",")
//                        BoundingBox(
//                            left = parts[0].toFloat(),
//                            top = parts[0].toFloat(),
//                            right = parts[0].toFloat(),
//                            bottom = parts[0].toFloat()
//                        )
//                    }
//            }
//
//            override fun onSuccess(subscriptions: SubscriptionSet) {
////                TODO("Not yet implemented")
//            }
//
//            override fun onError(exception: Throwable) {
//                RealmLog.error(exception.toString())
//            }
//        })
    }

    fun updateVerticalScrollPosition(value: Float) {
        this.verticalScrollPosition = value
        updateLoadedAreas(viewport, verticalScrollPosition, horizontalScrollPosition)
    }

    fun updateHorizontalScrollPosition(value: Float) {
        this.horizontalScrollPosition = value
        updateLoadedAreas(viewport, verticalScrollPosition, horizontalScrollPosition)
    }

    fun observeLoadedAreas(): Flow<List<BoundingBox>> {
        return _mutableLoadingAreas
    }
}