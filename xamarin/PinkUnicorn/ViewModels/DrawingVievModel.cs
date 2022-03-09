using System.Linq;
using Realms;
using Realms.Sync;
using Sharpnado.Presentation.Forms.ViewModels;
using SkiaSharp;
using PinkUnicorn.Models;

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

        private SKColor fillColor;
        public SKColor FillColor { get => fillColor; set => SetAndRaise(ref fillColor, value); }

        public DrawingVievModel(Realm realm)
        {
            this.realm = realm;
            components = realm.All<Component>();
            components.AsRealmCollection().SubscribeForNotifications((sender, changes, error) => RaisePropertyChanged(() => Components));
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
