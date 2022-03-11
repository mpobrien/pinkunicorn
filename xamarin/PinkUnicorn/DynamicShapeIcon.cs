using System;
using System.Windows.Input;
using PinkUnicorn.Models;
using SkiaSharp;
using SkiaSharp.Views.Forms;
using Xamarin.Forms;

namespace PinkUnicorn
{
    public class DynamicShapeIcon : SKCanvasView
    {
        private static void InvalidateSurfaceOnChange(BindableObject bindable, object oldValue, object newValue)
        {
            var control = (DynamicShapeIcon)bindable;

            // Avoid unnecessary invalidation
            if (oldValue != newValue)
                control.InvalidateSurface();
        }

        public static readonly BindableProperty ShapeProperty =
            BindableProperty.Create(propertyName: nameof(Shape),
                returnType: typeof(Shape),
                declaringType: typeof(DynamicShapeIcon),
                defaultValue: Shape.Circle,
                validateValue: (_, value) => value != null,
                propertyChanged: InvalidateSurfaceOnChange);

        public Shape Shape
        {
            get => (Shape)GetValue(ShapeProperty);
            set => SetValue(ShapeProperty, value);
        }

        public static readonly BindableProperty StrokeColorProperty =
                    BindableProperty.Create(propertyName: nameof(StrokeColor),
                        returnType: typeof(SKColor),
                        declaringType: typeof(DynamicShapeIcon),
                        defaultValue: SKColors.Gray,
                        validateValue: (_, value) => value != null,
                        propertyChanged: InvalidateSurfaceOnChange);

        public SKColor StrokeColor
        {
            get => (SKColor)GetValue(StrokeColorProperty);
            set => SetValue(StrokeColorProperty, value);
        }

        public static readonly BindableProperty StrokeWidthProperty =
                    BindableProperty.Create(propertyName: nameof(StrokeWidth),
                        returnType: typeof(float),
                        declaringType: typeof(DynamicShapeIcon),
                        defaultValue: 1.0f,
                        validateValue: (_, value) => value != null,
                        propertyChanged: InvalidateSurfaceOnChange);

        public float StrokeWidth
        {
            get => (float)GetValue(StrokeWidthProperty);
            set => SetValue(StrokeWidthProperty, value);
        }

        public static readonly BindableProperty FillColorProperty =
                    BindableProperty.Create(propertyName: nameof(FillColor),
                        returnType: typeof(SKColor),
                        declaringType: typeof(DynamicShapeIcon),
                        defaultValue: SKColors.Transparent,
                        validateValue: (_, value) => value != null,
                        propertyChanged: InvalidateSurfaceOnChange);

        // Ugly hack.. Xamarin.Forms bindings don't like nullable types
        public SKColor? FillColor
        {
            get
            {
                var fillColor = (SKColor)GetValue(FillColorProperty);
                return fillColor == SKColors.Transparent ? null : fillColor;
            }
            set => SetValue(FillColorProperty, value ?? SKColors.Transparent);
        }

        public static readonly BindableProperty TouchCommandProperty =
            BindableProperty.Create(nameof(TouchCommand),
                typeof(ICommand),
                typeof(DynamicShapeIcon),
                null);

        public ICommand TouchCommand
        {
            get => (ICommand)GetValue(TouchCommandProperty);
            set => SetValue(TouchCommandProperty, value);
        }

        public event EventHandler Touched;

        // This gets called when the button is pressed
        private void InvokeTouch()
        {
            Touched?.Invoke(this, EventArgs.Empty);
            TouchCommand?.Execute(null);
        }

        protected override void OnTouch(SKTouchEventArgs e)
        {
            if (e.ActionType == SKTouchAction.Entered
                || e.ActionType == SKTouchAction.Pressed
                || e.ActionType == SKTouchAction.Moved)
            {
                InvokeTouch();
                InvalidateSurface();
            }
            e.Handled = true;
        }

        protected override void OnPaintSurface(SKPaintSurfaceEventArgs e)
        {
            var canvas = e.Surface.Canvas;
            var size = e.Info.Size;

            var strokeWidth = StrokeWidth / 300 * size.Width; // Hack.. this assumes StrokeWidth go from 0-100.. and somewhat assume size is square

            var strokeColor = StrokeColor;
            if (strokeColor != SKColors.Transparent && strokeColor.Alpha == 0) strokeColor = strokeColor.WithAlpha(255);
            var strokePaint = new SKPaint { Color = strokeColor, StrokeWidth = strokeWidth, IsAntialias = true, IsStroke = true };

            var fillColor = FillColor ?? SKColors.Transparent;
            if (fillColor != SKColors.Transparent && fillColor.Alpha == 0) fillColor = fillColor.WithAlpha(255);
            var fillPaint = new SKPaint { Color = fillColor, IsStroke = false };

            var box = new SKRect
            {
                Location = SKPoint.Empty,
                Size = size
            };

            box.Inflate(-strokeWidth / 2, -strokeWidth / 2);

            canvas.Clear();
            foreach (var paint in new[] { fillPaint, strokePaint })
            {
                switch (Shape)
                {
                    case Shape.Circle:
                        canvas.DrawOval(box, paint);
                        break;
                    case Shape.Line:
                    case Shape.Path:
                        canvas.DrawLine(SKPoint.Empty, size.ToPointI(), paint);
                        break;
                    case Shape.Rectangle:
                        canvas.DrawRect(box, paint);
                        break;
                }
            }
        }
    }
}

