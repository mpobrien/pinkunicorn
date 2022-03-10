using System;
using Realms;
using SkiaSharp;
using SkiaSharp.Views.Forms;
using Xamarin.Forms;
using PinkUnicorn.Models;
using System.Linq;
using PinkUnicorn.ViewModels;
using System.Collections.Generic;
using Xamarin.CommunityToolkit.Extensions;
using System.Threading.Tasks;

namespace PinkUnicorn
{
    public partial class DrawingPage : ContentPage
    {
        SKMatrix matrix = SKMatrix.Identity;

        public DrawingPage(DrawingVievModel vievModel)
        {
            InitializeComponent();

            ViewModel = vievModel;
            ViewModel.PropertyChanged += (s, e) => RefreshCanvas(); // a bit rude
        }

        private DrawingVievModel viewModel;

        public DrawingVievModel ViewModel
        {
            get => viewModel; set
            {
                viewModel = value;
                BindingContext = viewModel;
            }
        }

        readonly SKPaint dotted = new()
        {
            Color = SKColors.Black,
            Style = SKPaintStyle.Stroke,
            PathEffect = SKPathEffect.CreateDash(new float[] { 10, 30 }, 20),
            StrokeCap = SKStrokeCap.Round,
            StrokeWidth = 4
        };

        readonly SKPaint solid = new()
        {
            Color = SKColors.Black,
            Style = SKPaintStyle.Stroke,
            StrokeCap = SKStrokeCap.Round,
            StrokeWidth = 4
        };

        void DrawComponent(SKCanvas canvas, Component c)
        {
            var strokeColor = c.StrokeColor;
            if (strokeColor.Alpha == 0) strokeColor = strokeColor.WithAlpha(255);
            var strokePaint = new SKPaint { Color = strokeColor, StrokeWidth = (float)c.StrokeWidth, IsAntialias = true, IsStroke = true };

            var box = new SKRect
            {
                Location = c.TopLeft,
                Size = c.Size
            };

            switch (c.Shape)
            {
                case Shape.Circle:
                    canvas.DrawOval(box, strokePaint);
                    break;
                case Shape.Line:
                    canvas.DrawLine(c.TopLeft, c.BottomRight, strokePaint);
                    break;
                case Shape.Path:
                    var path = new SKPath();
                    path.AddPoly(c.Points.ToArray(), close: c.FillColor != null);
                    canvas.DrawPath(path, strokePaint);
                    break;
                case Shape.Rectangle:
                    canvas.DrawRect(box, strokePaint);
                    break;
            }
        }

        Component next = null;
        void OnCanvasViewPaintSurface(object sender, SKPaintSurfaceEventArgs args)
        {
            var info = args.Info;
            var surface = args.Surface;
            var canvas = surface.Canvas;

            canvas.Clear();
            canvas.SetMatrix(matrix);
            var bounds = canvas.LocalClipBounds;
            ViewModel.UpdateSubscription(bounds);
            canvas.DrawLine(bounds.Left, 400, bounds.Right, 400, dotted); // 400 is the magic number :-)

            foreach (var c in ViewModel.Components)
            {
                DrawComponent(canvas, c);
            }

            if (traced != null)
            {
                if (traced.PointCount == 1)
                {
                    canvas.DrawPoint(traced.LastPoint, solid);
                }
                else if (traced.PointCount > 1)
                {
                    var path = traced; // if Shape.Path
                    var shape = ViewModel.Shape;
                    if (shape != Shape.Path)
                    {
                        path = new SKPath();
                        path.MoveTo(traced.Points[0]);
                        path.LineTo(traced.LastPoint);
                    }
                    var box = path.Bounds;

                    var strokeWidth = ViewModel.StrokeWidth;
                    next = new Component
                    {
                        Shape = shape,
                        StrokeWidth = strokeWidth,
                        StrokeColor = ViewModel.StrokeColor,
                        FillColor = ViewModel.FillColor,
                        Top = box.Top,
                        Bottom = box.Bottom,
                        Left = box.Left,
                        Right = box.Right,
                    };
                    if (shape == Shape.Path) {
                        next.Points = path.Points;
                    }

                    DrawComponent(canvas, next);

                    // Add bounding box overlay for current draw op
                    var scale = canvas.TotalMatrix.ScaleX; // = ScaleY
                    var paint = solid.Clone(); // dotted PathEffect looks odd under scaling, so use solid for now
                    paint.StrokeWidth /= scale;
                    box.Inflate(strokeWidth / 2, strokeWidth / 2);
                    canvas.DrawRect(box, paint);
                }
            }
        }

        void RefreshCanvas()
        {
            canvasView.InvalidateSurface();
        }

        private SKPath? traced;
        void HandleUserDraw(SKPoint point, bool commitIfSelected)
        {
            // Single-finger?
            if (touchDictionary.Count == 1)
            {
                // Invert the matrix
                if (matrix.TryInvert(out SKMatrix inverseMatrix))
                {
                    var transformedPoint = inverseMatrix.MapPoint(point);

                    if (traced != null && commitIfSelected)
                    {
                        if (traced.Bounds.Contains(transformedPoint))
                        {
                            ViewModel.Commit(next);
                        }
                        traced = null;
                    }
                    else
                    {
                        traced ??= new SKPath();
                        if (traced.IsEmpty)
                        {
                            traced.MoveTo(transformedPoint);
                        }
                        else
                        {
                            traced.LineTo(transformedPoint);
                        }
                    }
                    canvasView.InvalidateSurface();
                }
            }
            else
            {
                traced = null; // cancel
            }
        }

        // Touch information
        Dictionary<long, SKPoint> touchDictionary = new();
        void canvasView_Touch(object sender, SKTouchEventArgs e)
        {
            e.Handled = true;
            Console.WriteLine(e);
            var point = e.Location;

            switch (e.ActionType)
            {
                case SKTouchAction.Pressed:
                    if (!touchDictionary.ContainsKey(e.Id))
                    {
                        touchDictionary.Add(e.Id, point);
                    }
                    HandleUserDraw(point, true);
                    break;

                case SKTouchAction.Moved:
                    if (touchDictionary.ContainsKey(e.Id))
                    {
                        HandleUserDraw(point, false);

                        // Double-finger rotate, scale, and drag
                        if (touchDictionary.Count >= 2)
                        {
                            // Copy two dictionary keys into array
                            long[] keys = new long[touchDictionary.Count];
                            touchDictionary.Keys.CopyTo(keys, 0);

                            // Find index non-moving (pivot) finger
                            int pivotIndex = (keys[0] == e.Id) ? 1 : 0;

                            // Get the three points in the transform
                            var pivotPoint = touchDictionary[keys[pivotIndex]];
                            var prevPoint = touchDictionary[e.Id];
                            var newPoint = point;

                            // Calculate two vectors
                            var oldVector = prevPoint - pivotPoint;
                            var newVector = newPoint - pivotPoint;

                            // Find angles from pivot point to touch points
                            var oldAngle = (float)Math.Atan2(oldVector.Y, oldVector.X);
                            var newAngle = (float)Math.Atan2(newVector.Y, newVector.X);

                            // Calculate rotation matrix
                            var angle = newAngle - oldAngle;
                            var rotationMatrix = SKMatrix.CreateRotation(angle, pivotPoint.X, pivotPoint.Y);

                            // Effectively rotate the old vector
                            var magnitudeRatio = Magnitude(oldVector) / Magnitude(newVector);
                            oldVector.X = magnitudeRatio * newVector.X;
                            oldVector.Y = magnitudeRatio * newVector.Y;

                            // Isotropic scaling!
                            var scale = Magnitude(newVector) / Magnitude(oldVector);

                            if (!float.IsNaN(scale) && !float.IsInfinity(scale))
                            {
                                // Combine matrices
                                var scaleMatrix = SKMatrix.CreateScale(scale, scale, pivotPoint.X, pivotPoint.Y);
                                SKMatrix.PostConcat(ref rotationMatrix, scaleMatrix);
                                SKMatrix.PostConcat(ref matrix, rotationMatrix);
                                canvasView.InvalidateSurface();
                            }
                        }

                        // Store the new point in the dictionary
                        touchDictionary[e.Id] = point;
                    }
                    break;

                case SKTouchAction.Cancelled:
                case SKTouchAction.Exited:
                case SKTouchAction.Released:
                    if (touchDictionary.ContainsKey(e.Id))
                    {
                        touchDictionary.Remove(e.Id);
                    }
                    break;
            }
        }

        float Magnitude(SKPoint point)
        {
            return (float)Math.Sqrt(Math.Pow(point.X, 2) + Math.Pow(point.Y, 2));
        }

        void Button_Clicked(object sender, EventArgs e)
        {
            Application.Current.MainPage.Navigation.ShowPopup(new ColorPickerPopup(showColorPickers, ViewModel));
        }
    }
}
