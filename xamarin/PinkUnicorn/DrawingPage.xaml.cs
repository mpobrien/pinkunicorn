using System;
using Realms;
using SkiaSharp;
using SkiaSharp.Views.Forms;
using Xamarin.Forms;
using PinkUnicorn.Models;
using System.Linq;
using PinkUnicorn.ViewModels;

namespace PinkUnicorn
{
    public partial class DrawingPage : ContentPage
    {
        float scale = 1.0f;
        SKPoint offset = SKPoint.Empty;

        public DrawingPage(DrawingVievModel vievModel)
        {
            InitializeComponent();

            ViewModel = vievModel;
            ViewModel.PropertyChanged += (s, e) => RefreshCanvas(); // a bit rude
        }

        public DrawingVievModel ViewModel { get; }

        void OnCanvasViewPaintSurface(object sender, SKPaintSurfaceEventArgs args)
        {
            var info = args.Info;
            var surface = args.Surface;
            var canvas = surface.Canvas;

            canvas.Clear();
            canvas.Scale(scale);
            canvas.Translate(EffectiveOffset);
            ViewModel.UpdateSubscription(canvas.LocalClipBounds);

            foreach (var c in ViewModel.Components)
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
        }

        void RefreshCanvas()
        {            
            canvasView.InvalidateSurface();
        }

        void PinchGestureRecognizer_PinchUpdated(object sender, PinchGestureUpdatedEventArgs e)
        {
            //Console.WriteLine(e);
            scale *= (float)e.Scale;
            RefreshCanvas();
        }

        void TapGestureRecognizer_Tapped(object sender, EventArgs e)
        {
            //Console.WriteLine(e);
            scale = 1.0f;
            offset = SKPoint.Empty;
            RefreshCanvas();
        }

        SKPoint panOffset = SKPoint.Empty;
        void PanGestureRecognizer_PanUpdated(object sender, PanUpdatedEventArgs e)
        {
            //Console.WriteLine(e);
            switch (e.StatusType)
            {
                case GestureStatus.Running:
                    panOffset.X = (float)e.TotalX;
                    panOffset.Y = (float)e.TotalY;
                    break;
                case GestureStatus.Completed:
                    offset += panOffset;
                    panOffset = SKPoint.Empty;
                    break;
                case GestureStatus.Canceled:
                    panOffset = SKPoint.Empty;
                    break;
            }
            RefreshCanvas();
        }

        SKPoint EffectiveOffset => offset + panOffset;

        void canvasView_Touch(object sender, SKTouchEventArgs e)
        {
            //Console.WriteLine(e);
            switch (e.ActionType)
            {
                case SKTouchAction.Pressed:
                case SKTouchAction.Moved:
                case SKTouchAction.Released:
                    break;
            }
            e.Handled = true;
        }
    }
}
