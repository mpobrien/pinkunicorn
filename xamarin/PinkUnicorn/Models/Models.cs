using System;
using System.Collections.Generic;
using System.Linq;
using MongoDB.Bson;
using Realms;
using SkiaSharp;

namespace PinkUnicorn.Models
{
    public enum Shape { Circle, Line, Path, Rectangle, Triangle }

    public class Point : EmbeddedObject
    {
        [MapTo("x")]
        public double X { get; set; }

        [MapTo("y")]
        public double Y { get; set; }
    }

    public class Board : RealmObject
    {
        [PrimaryKey]
        [MapTo("_id")]
        public ObjectId Id { get; set; } = ObjectId.GenerateNewId();

        public Owner Owner { get; set; }

        public string Title { get; set; }

        public ISet<Component> Drawing { get; }
    }

    public class Component : RealmObject
    {
        [PrimaryKey]
        [MapTo("_id")]
        public ObjectId Id { get; set; } = ObjectId.GenerateNewId();

        [MapTo("left")]
        public double Left { get; set; }

        [MapTo("top")]
        public double Top { get; set; }

        [MapTo("right")]
        public double Right { get; set; }

        [MapTo("bottom")]
        public double Bottom { get; set; }

        public double Width => Right - Left;

        public double Height => Bottom - Top;

        public SKPoint TopLeft => new SKPoint((float)Left, (float)Top);

        public SKPoint BottomRight => new SKPoint((float)Right, (float)Bottom);

        public SKSize Size => new SKSize((float)Width, (float)Height);

        [MapTo("points")]
        private IList<Point> _Points { get; }

        public IEnumerable<SKPoint> Points
        {
            get => _Points.Select((p) => new SKPoint((float)p.X, (float)p.Y));
            set
            {
                _Points.Clear();
                foreach (var p in value)
                {
                    var converted = new Point { X = p.X, Y = p.Y };
                    _Points.Add(converted);
                }
            }
        }

        [MapTo("z")]
        public double Z { get; set; }

        [MapTo("shape")]
        [Required]
        private string _Shape { get; set; }

        public Shape Shape
        {
            get
            {
                Shape shape;
                if (Enum.TryParse(_Shape, true, out shape)) return shape;
                return Shape.Rectangle;
            }
            set => _Shape = value.ToString().ToLower();
        }

        [MapTo("strokeColor")]
        private RealmValue _StrokeColor { get; set; }

        public SKColor StrokeColor
        {
            get => _StrokeColor.Type == RealmValueType.Int ? new((uint)_StrokeColor.AsInt32()) : SKColor.Parse(_StrokeColor.AsString());
            set => _StrokeColor = (int)(uint)value;
        }

        [MapTo("strokeWidth")]
        public double StrokeWidth { get; set; }

        [MapTo("fillColor")]
        private RealmValue _FillColor { get; set; } = RealmValue.Null;

        public SKColor? FillColor
        {
            get => _FillColor.Type == RealmValueType.Null ? null : _FillColor.Type == RealmValueType.Int ? new((uint)_FillColor.AsInt32()) : SKColor.Parse(_FillColor.AsString());
            set => _FillColor = (int?)(uint?)value;
        }
    }

    public class Owner : RealmObject
    {
        [PrimaryKey]
        [MapTo("_id")]
        public ObjectId Id { get; set; } = ObjectId.GenerateNewId();

        [MapTo("name")]
        public string Name { get; set; }
    }
}
