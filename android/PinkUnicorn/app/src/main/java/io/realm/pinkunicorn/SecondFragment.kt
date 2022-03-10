package io.realm.pinkunicorn

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.Button
import androidx.compose.material.LinearProgressIndicator
import androidx.compose.material.MaterialTheme
import androidx.compose.material.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.inset
import androidx.compose.ui.graphics.drawscope.translate
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.ViewCompositionStrategy
import androidx.compose.ui.unit.dp
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import io.realm.Realm
import io.realm.RealmList
import io.realm.log.RealmLog
import io.realm.pinkunicorn.databinding.FragmentSecondBinding
import io.realm.pinkunicorn.model.Component
import io.realm.pinkunicorn.model.Point
import io.realm.pinkunicorn.model.Shape

val data = listOf(
    Component().apply {
        left = -500.0F
        top = -500.0F
        right = 100F
        bottom = 150F
        fillColor = Color.Yellow
        shape = Shape.CIRCLE
        strokeWidth = 8.0F
        strokeColor = Color.Cyan
    },
    Component().apply {
        left = 0F
        top = 0F
        right = 75F
        bottom = 50F
        fillColor = Color.Red
        shape = Shape.RECTANGLE
        strokeWidth = 4.0F
        strokeColor = Color.Black
    },
    Component().apply {
        left = -50F
        top = -50F
        right = 75F
        bottom = 50F
        fillColor = null
        shape = Shape.PATH
        strokeWidth = 10.0F
        strokeColor = Color.Black
        points = RealmList(Point(-50F, -50F), Point (50F, 0F), Point (75F, 50F))
    },
)

/**
 * A simple [Fragment] subclass as the second destination in the navigation.
 */
class SecondFragment : Fragment() {

    private var _binding: FragmentSecondBinding? = null
    // This property is only valid between onCreateView and onDestroyView.
    private val binding get() = _binding!!

    private lateinit var realm: Realm
    val vm: DrawingBoardViewModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
    }

    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        _binding = FragmentSecondBinding.inflate(inflater, container, false)
        val view = binding.root
        binding.canvas.apply {
            setViewCompositionStrategy(ViewCompositionStrategy.DisposeOnViewTreeLifecycleDestroyed)
            setContent {
                MaterialTheme {
                    Column(verticalArrangement = Arrangement.Bottom) {
                        Box(modifier = Modifier.weight(1f)) {
                            DrawingBoard(vm)
                            CustomLinearProgressBar(vm)
                        }
                        Box(modifier = Modifier
                            .height(64.dp)
                            .fillMaxWidth()
                            .background(color = Color.Cyan)
                            .padding(8.dp)
                        ) {
                            Row(modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceAround,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Button(onClick = { vm.selectShape(Shape.RECTANGLE) }) {
                                    Text(text = "Rectangle")
                                }
                                Button(onClick = { vm.selectShape(Shape.CIRCLE) }) {
                                    Text(text = "Circle")
                                }
                                Button(onClick = { vm.selectShape(Shape.PATH) }) {
                                    Text(text = "Path")
                                }
                            }
                        }
                    }
                }
            }
        }
        return view
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
//        binding.buttonSecond.setOnClickListener {
//            findNavController().navigate(R.id.action_SecondFragment_to_FirstFragment)
//        }
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }

    override fun onDestroy() {
        super.onDestroy()
        realm.close()
    }
}

@Composable
fun DrawingBoard(vm: DrawingBoardViewModel) {
    val verticalScrollState = rememberScrollState(initial = 2000)
    val horizontalScrollState = rememberScrollState(initial = 2000)
    horizontalScrollState.interactionSource

    Box(modifier = Modifier
        .fillMaxSize()
        .verticalScroll(state = verticalScrollState)
        .horizontalScroll(state = horizontalScrollState)
    ) {
        BoardCanvas(vm)
    }
}


@Composable
fun BoardCanvas(vm: DrawingBoardViewModel) {
    val debug = true
    val canvasWidth = 2000.dp
    val canvasHeight = 2000.dp
    val items by vm.observeDrawings().collectAsState(initial = listOf())
    Canvas(
        modifier = Modifier
            .size(canvasHeight, canvasWidth)
            .pointerInput(Unit) {
                detectTapGestures { offset: Offset ->
                    // Map back from Canvas coordinates to our "world" coordinates
                    vm.canvasTapped(
                        Offset(
                            (offset.x.toDp() - canvasWidth/2).value,
                            (offset.y.toDp() - canvasHeight/2).value
                        )
                    )
                }
            }
    ) {
        // Debug lines
        if (debug) {
            drawLine(
                start = Offset(x = this.size.width, y = 0f),
                end = Offset(x = 0f, y = this.size.height),
                color = Color.Blue
            )
            drawLine(
                start = Offset(x = 0f, y = 0f),
                end = Offset(x = this.size.width, y = this.size.height),
                color = Color.Blue
            )
        }

        // Draw "forbidden" area
        inset(left = 0f, top = 0f, right = 0f, bottom = 400.dp.toPx()) {
            drawRect(color = Color.LightGray.copy(alpha = 0.5f), size = this.size)
        }

        // Move (0,0) to center of drawing
        translate(left = (canvasWidth / 2).toPx(), top = (canvasHeight / 2).toPx()) {
            items.forEach { comp: Component ->
                // Define bounding box for each component
                )
                try {
                    inset(
                        left = comp.left.dp.toPx(),
                        top = comp.top.dp.toPx(),
                        right = (canvasWidth - comp.right.dp).toPx(),
                        bottom = (canvasHeight - comp.bottom.dp).toPx()
                    ) {
                        val stroke = Stroke(
                            width = comp.strokeWidth.dp.toPx(),
                            join = StrokeJoin.Bevel,
                            cap = StrokeCap.Round
                        )
                        when (comp.shape) {
                            Shape.CIRCLE -> { drawCircle(this, comp, stroke) }
                            Shape.PATH -> {
                                // Reset inset as the Points array uses the original coordinates
                                inset(left = -comp.left.dp.toPx(), top = -comp.top.dp.toPx(), right = -(canvasWidth - comp.right.dp).toPx(), bottom = -(canvasHeight - comp.bottom.dp).toPx()) {
                                    drawPath(this, comp, stroke)
                                }
                            }
                            Shape.RECTANGLE -> { drawRectangle(this, comp, stroke) }
                            Shape.UNKNOWN -> {
                                drawRect(color = Color.Black, size = this.size)
                            }
                        }
                    }
                } catch (e: Exception) {
                    // Some components seem to break invariants
                    RealmLog.error(comp.toString())
                    RealmLog.error(e.toString())
                }
            }
        }
    }
}

fun drawRectangle(scope: DrawScope, comp: Component, stroke: Stroke) {
    comp.fillColor?.let { fillColor ->
        scope.drawRect(color = fillColor, size = scope.size)
    }
    scope.drawRect(
        color = comp.strokeColor,
        size = scope.size,
        style = stroke
    )
}

fun drawPath(scope: DrawScope, comp: Component, stroke: Stroke) {
    scope.apply {
        drawPath(
            path = Path().apply {
                comp.points.forEachIndexed { i, point ->
                    if (i == 0) {
                        moveTo(point.x.dp.toPx(), point.y.dp.toPx())
                    } else {
                        lineTo(point.x.dp.toPx(), point.y.dp.toPx())
                    }
                }
            },
            color = comp.strokeColor,
            style = stroke
        )
    }
}

fun drawCircle(scope: DrawScope, comp: Component, stroke: Stroke) {
    comp.fillColor?.let { fillColor ->
        scope.drawOval(color = fillColor)
    }
    scope.drawOval(
        color = comp.strokeColor,
        size = scope.size,
        style = stroke
    )
}

@Composable
private fun CustomLinearProgressBar(vm: DrawingBoardViewModel) {
    val loadingState by vm.observeLoading().collectAsState(initial = false)
    AnimatedVisibility(
        visible = loadingState != Hidden,
        enter = fadeIn(),
        exit = fadeOut()
    ) {
        Column(modifier = Modifier.fillMaxWidth()) {
            LinearProgressIndicator(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(8.dp),
                backgroundColor = Color.LightGray.copy(alpha = 0.5F),
                color = if (loadingState == Error) Color.Magenta else Color.Green,
            )
        }
    }
}
