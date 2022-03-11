using System;
using System.Globalization;
using SkiaSharp;
using SkiaSharp.Views.Forms;
using Xamarin.Forms;

namespace PinkUnicorn
{
    public class SKColorToFormsColor : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            return ((SKColor?)value)?.ToFormsColor();
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            return ((Color?)value)?.ToSKColor();
        }
    }
}