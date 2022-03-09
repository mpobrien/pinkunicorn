using System.Linq;
using Realms;
using Sharpnado.Presentation.Forms.ViewModels;
using SkiaSharp;
using PinkUnicorn.Models;

namespace PinkUnicorn.ViewModels
{
    public class DrawingVievModel : Bindable
    {
        Realm realm;

        private IQueryable<Component> components;
        public IQueryable<Component> Components { get => components; }

        private float scale;
        public float Scale { get => scale; set => SetAndRaise(ref scale, value); }

        public SKPoint Offset { get; set; }
        public SKPoint PanOffset { get; set; }

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
    }
}
