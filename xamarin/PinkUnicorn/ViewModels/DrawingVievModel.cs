using System.Linq;
using Realms;
using Realms.Sync;
using Sharpnado.Presentation.Forms.ViewModels;
using SkiaSharp;
using PinkUnicorn.Models;
using System.Collections.Generic;
using System;

namespace PinkUnicorn.ViewModels
{
    public class DrawingVievModel : Bindable
    {
        private Realm realm;

        private IQueryable<Component> components;
        public IQueryable<Component> Components { get => components; }

        private SKColor strokeColor;
        public SKColor StrokeColor { get => strokeColor; set => SetAndRaise(ref strokeColor, value); }

        private float strokeWidth;
        public float StrokeWidth { get => strokeWidth; set => SetAndRaise(ref strokeWidth, value); }

        private SKColor? fillColor = null;
        public SKColor? FillColor { get => EnableFill ? fillColor : null; set => SetAndRaise(ref fillColor, value); }

        private bool enableFill;
        public bool EnableFill
        {
            get => enableFill; set
            {
                if (SetAndRaise(ref enableFill, value))
                {
                    RaisePropertyChanged(() => FillColor);
                }
            }
        }

        private Shape shape;
        public Shape Shape { get => shape; set => SetAndRaise(ref shape, value); }

        public IEnumerable<Shape> SupportedShapes => new[] { Shape.Circle, Shape.Path, Shape.Rectangle };

        private readonly List<IDisposable> subscriptions = new();

        public DrawingVievModel(Realm realm)
        {
            // Set defaults
            StrokeColor = SKColors.DarkGray;
            StrokeWidth = 1;
            FillColor = null;
            EnableFill = false;
            Shape = SupportedShapes.First();

            this.realm = realm;
            components = realm.All<Component>().OrderBy(c => c.Z).ThenBy(c => c.Id); // deterministic ordering

            subscriptions.AddRange(new[] {
                components.AsRealmCollection().SubscribeForNotifications((sender, changes, error) => RaisePropertyChanged(() => Components)),
/*
                // Clean bad components as we see them..
                components.Filter("left > right").AsRealmCollection().SubscribeForNotifications((sender, changes, error) => {

                    foreach (var c in sender) // snapshotted
                    {
                        var oldLeft = c.Left;
                        c.Left = c.Right;
                        c.Right = oldLeft;
                    }
                }),
                components.Filter("top > bottom").AsRealmCollection().SubscribeForNotifications((sender, changes, error) => {
                    foreach (var c in sender) // snapshotted
                    {
                        var oldTop = c.Top;
                        c.Top = c.Bottom;
                        c.Bottom = oldTop;
                    }
                }),
*/
            });
        }

        public void Commit(Component component)
        {
            realm.Write(() => realm.Add(component));
        }

        public void UpdateSubscription(SKRect viewPort)
        {
            var query = realm.All<Component>().Filter("left < $0 AND right > $1 AND top < $2 AND bottom > $3", viewPort.Right, viewPort.Left, viewPort.Bottom, viewPort.Top);
            realm.Subscriptions.Update(
                () => realm.Subscriptions.Add(
                    query,
                    new SubscriptionOptions { Name = "viewPort", UpdateExisting = true }));
        }
    }
}
