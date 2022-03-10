using PinkUnicorn.ViewModels;
using Xamarin.CommunityToolkit.UI.Views;
using Xamarin.Forms;

namespace PinkUnicorn
{
    public partial class ColorPickerPopup : Popup
    {
        public ColorPickerPopup(View anchor, DrawingVievModel viewModel)
        {
            InitializeComponent();
            Size = new Size(300, 150);
            Anchor = anchor;
            BindingContext = viewModel;
        }
    }
}
