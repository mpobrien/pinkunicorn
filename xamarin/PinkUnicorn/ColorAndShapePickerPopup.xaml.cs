using PinkUnicorn.ViewModels;
using Xamarin.CommunityToolkit.UI.Views;
using Xamarin.Forms;

namespace PinkUnicorn
{
    public partial class ColorAndShapePickerPopup : Popup
    {
        public ColorAndShapePickerPopup(View anchor, DrawingVievModel viewModel)
        {
            InitializeComponent();
            Anchor = anchor;
            BindingContext = viewModel;
        }
    }
}
