using System;
using System.IO;
using System.Threading.Tasks;
using Realms;
using Realms.Exceptions.Sync;
using Realms.Schema;
using Realms.Sync;
using Xamarin.Forms;
using Xamarin.Forms.Xaml;
using Realms.Logging;

namespace PinkUnicorn
{
    public partial class App : Application
    {
        public static Realms.Sync.App RealmApp;

        public App()
        {
            InitializeComponent();
            MainPage = new MainPage();
        }

        protected async override void OnStart()
        {
            try
            {
                Logger.LogLevel = LogLevel.All;
                Logger.Default = Logger.Function(message =>
                {
                    Console.WriteLine(message);
                });

                const string appId = "pink-unicorn-bvzgq";
                var appConfiguration = new AppConfiguration(appId) { };
                RealmApp = Realms.Sync.App.Create(appConfiguration);
                while (RealmApp.CurrentUser == null)
                {
                    await RealmApp.LogInAsync(Credentials.Anonymous());
                }

                var config = new FlexibleSyncConfiguration(RealmApp.CurrentUser)
                {
                    Schema = new[] {
                        typeof(PinkUnicorn.Models.Component),
                        typeof(PinkUnicorn.Models.Point)
                    }
                };
                var realm = await Realm.GetInstanceAsync(config);

                realm.Subscriptions.Update(() =>
                {
                    var viewPort = realm.All<PinkUnicorn.Models.Component>();
                    realm.Subscriptions.Add(viewPort, new SubscriptionOptions { Name = "viewPort", UpdateExisting = true });
                });

                try
                {
                    await realm.Subscriptions.WaitForSynchronizationAsync();
                }
                catch (SubscriptionException ex)
                {
                    Console.WriteLine($@"The subscription set's state is Error and synchronization is paused:  {ex.Message}");
                }

                /*
                var navPage = RealmApp.CurrentUser == null ?
                    new NavigationPage(new LoginPage()) :
                    new NavigationPage(new TaskPage());
                */
                var navPage = new DrawingPage(realm);
                NavigationPage.SetHasBackButton(navPage, false);
                MainPage = navPage;
            }
            catch (Exception e)
            {
                // A NullReferenceException occurs if:
                // 1. the config file does not exist, or
                // 2. the config does not contain an "appId" or "baseUrl" element.

                // If the appId value is incorrect, we handle that
                // exception in the Login page.

                throw e;
            }
        }

        protected override void OnSleep()
        {
        }

        protected override void OnResume()
        {
        }
    }
}
