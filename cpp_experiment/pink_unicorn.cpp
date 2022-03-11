#include <iostream>
#include <map>
#include <filesystem>
#include <chrono>

#include <realm/object-store/object_schema.hpp>
#include <realm/object-store/object.hpp>
#include <realm/object-store/property.hpp>
#include <realm/object-store/thread_safe_reference.hpp>

#include <realm/object-store/sync/app.hpp>
#include <realm/object-store/sync/sync_manager.hpp>
#include <realm/object-store/sync/sync_user.hpp>
#include <realm/object-store/sync/async_open_task.hpp>
#include <realm/object-store/sync/generic_network_transport.hpp>
#include <realm/sync/subscriptions.hpp>

#include <curl/curl.h>


using namespace std::chrono_literals;
using namespace realm;
using namespace realm::app;

constexpr auto s_app_id = "pink-unicorn-bvzgq";

static std::unique_ptr<util::Logger> defaultSyncLogger(util::Logger::Level level)
{
    struct SyncLogger : public util::RootLogger
    {
        void do_log(Level, const std::string& message) override
        {
            std::cout<<"[LOGGER][SYNC]: " + message<<std::endl;
        }
    };
    
    auto logger = std::make_unique<SyncLogger>();
    logger->set_level_threshold(level);
    return std::move(logger);
}

static size_t curl_write_cb(char* ptr, size_t size, size_t nmemb, std::string* response)
{
    REALM_ASSERT(response);
    size_t realsize = size * nmemb;
    response->append(ptr, realsize);
    return realsize;
}

static size_t curl_header_cb(char* buffer, size_t size, size_t nitems, std::map<std::string, std::string>* response_headers)
{
    //copied from c++ sdk
    REALM_ASSERT(response_headers);
    std::string combined(buffer, size * nitems);
        
    if (auto pos = combined.find(':'); pos != std::string::npos) {
        std::string key = combined.substr(0, pos);
        std::string value = combined.substr(pos + 1);
        while (value.size() > 0 && value[0] == ' ') {
            value = value.substr(1);
        }
        while (value.size() > 0 && (value[value.size() - 1] == '\r' || value[value.size() - 1] == '\n')) {
            value = value.substr(0, value.size() - 1);
        }
        response_headers->insert({key, value});
    }
    else {
        if (combined.size() > 5 && combined.substr(0, 5) != "HTTP/") { // ignore for now HTTP/1.1 ...
            std::cerr << "test transport skipping header: " << combined << std::endl;
        }
    }
    return nitems * size;
}

static app::Response do_curl_request(const Request& request) {
    
    //hook all the curl stuff in order to make a request
    
    auto curl = curl_easy_init();
    if (!curl) {
        return app::Response{500, -1};
    }
    
    struct curl_slist* list = nullptr;
    auto curl_cleanup = util::ScopeExit([&]() noexcept {
        curl_easy_cleanup(curl);
        curl_slist_free_all(list);
    });
    
    std::string response;
    std::map<std::string, std::string> response_headers;
    
    curl_easy_setopt(curl, CURLOPT_URL, request.url.c_str());
    
    if (request.method == app::HttpMethod::post) {
        curl_easy_setopt(curl, CURLOPT_POSTFIELDS, request.body.c_str());
    }
    else if (request.method == app::HttpMethod::put) {
        curl_easy_setopt(curl, CURLOPT_CUSTOMREQUEST, "PUT");
        curl_easy_setopt(curl, CURLOPT_POSTFIELDS, request.body.c_str());
    }
    else if (request.method == app::HttpMethod::patch) {
        curl_easy_setopt(curl, CURLOPT_CUSTOMREQUEST, "PATCH");
        curl_easy_setopt(curl, CURLOPT_POSTFIELDS, request.body.c_str());
    }
    else if (request.method == app::HttpMethod::del) {
        curl_easy_setopt(curl, CURLOPT_CUSTOMREQUEST, "DELETE");
        curl_easy_setopt(curl, CURLOPT_POSTFIELDS, request.body.c_str());
    }
    else if (request.method == app::HttpMethod::patch) {
        curl_easy_setopt(curl, CURLOPT_CUSTOMREQUEST, "PATCH");
        curl_easy_setopt(curl, CURLOPT_POSTFIELDS, request.body.c_str());
    }
    
    curl_easy_setopt(curl, CURLOPT_TIMEOUT, request.timeout_ms);
    
    for (auto header : request.headers) {
        auto header_str = util::format("%1: %2", header.first, header.second);
        list = curl_slist_append(list, header_str.c_str());
    }
    
    curl_easy_setopt(curl, CURLOPT_HTTPHEADER, list);
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, curl_write_cb);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, &response);
    curl_easy_setopt(curl, CURLOPT_HEADERFUNCTION, curl_header_cb);
    curl_easy_setopt(curl, CURLOPT_HEADERDATA, &response_headers);
    
    auto response_code = curl_easy_perform(curl);
    if (response_code != CURLE_OK) {
        fprintf(stderr, "curl_easy_perform() failed when sending request to '%s' with body '%s': %s\n",
                request.url.c_str(), request.body.c_str(), curl_easy_strerror(response_code));
    }
    int http_code = 0;
    curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &http_code);
    return {
        http_code,
        0, // binding_response_code
        std::move(response_headers),
        std::move(response),
    };
}

class CurlNetworkTransport : public GenericNetworkTransport {
public:
    
    void send_request_to_server( Request&& request,
                                util::UniqueFunction<void(const Response&)>&& completionBlock) override
    {
        completionBlock(do_curl_request(request));
    }
};


static std::mutex s_data_mutex;
static std::condition_variable s_data_cv;

int main(int argc, char** argv) {
    
    curl_global_init(CURL_GLOBAL_ALL);
    
    //Config SyncClient
    SyncClientConfig sync_client_config;
    bool should_encrypt = !getenv("REALM_DISABLE_METADATA_ENCRYPTION");
    sync_client_config.logger_factory = defaultSyncLogger;
    if(!should_encrypt) {
        sync_client_config.metadata_mode = SyncManager::MetadataMode::NoEncryption;
    } else {
        sync_client_config.metadata_mode = SyncManager::MetadataMode::Encryption;
    }
    sync_client_config.base_file_path = std::filesystem::current_path();
    sync_client_config.user_agent_application_info = s_app_id;
    sync_client_config.user_agent_binding_info = "pink_unicorn/0.1";
    //sync_client_config.log_level = util::Logger::Level::all;
    
    auto sync_client = app::App::get_shared_app(app::App::Config{
        .app_id = s_app_id,
        .transport = std::make_shared<CurlNetworkTransport>(),
        .platform = "pink",
        .platform_version = "?",
        .sdk_version = "0.1"
    }, sync_client_config);
    
    std::shared_ptr<AppError> loginError = nullptr;
    std::shared_ptr<SyncUser> syncUserInfo = nullptr;
    auto onLoginCompletation = [&](std::shared_ptr<SyncUser> syncUser,
                                   util::Optional<AppError> error)->void
    {
        if(error) {
            loginError = std::make_shared<AppError>(error.value());
        } else {
            syncUserInfo = syncUser;
        }
        s_data_cv.notify_one();
    };
    
    //Do Login for Sync
    sync_client->log_in_with_credentials(app::AppCredentials::anonymous(), onLoginCompletation);
    
    {
        std::unique_lock<std::mutex> lk(s_data_mutex);
        s_data_cv.wait(lk, [&]{return syncUserInfo || loginError;});
    }
    
    if(loginError) {
        std::cout << loginError->message << std::endl;
        return -1;
    }
    
    REALM_ASSERT(syncUserInfo);
    std::cout << "Login status = " << (int)syncUserInfo->state() << std::endl;
    
    std::shared_ptr<SyncConfig> flex_sync_config = std::make_shared<SyncConfig>(syncUserInfo, SyncConfig::FLXSyncEnabled{});
    flex_sync_config->error_handler = [](std::shared_ptr<SyncSession> session, SyncError error) {
        {
            std::lock_guard<std::mutex> l{s_data_mutex};
            std::cerr<<"[LOGGER][SYNC][ERROR]: "<<error.message<<std::endl;
        }
        
    };
    const auto realm_path = syncUserInfo->sync_manager()->path_for_realm(*flex_sync_config, {"Shapes"});
    //flex_sync_config->client_resync_mode = realm::ClientResyncMode::Manual;
    //flex_sync_config->stop_policy = realm::SyncSessionStopPolicy::AfterChangesUploaded;
    
    auto componenet_schema = realm::Schema{
        {
            "Component", {
                {"_id", PropertyType::Int, Property::IsPrimary{true}},
                {"shape", PropertyType::String},
                {"strokeColor", PropertyType::Mixed | PropertyType::Nullable},
                {"strokeWidth",PropertyType::Double},
                {"fillColor", PropertyType::Mixed | PropertyType::Nullable},
                {"top", PropertyType::Double},
                {"right", PropertyType::Double},
                {"bottom", PropertyType::Double},
                {"left", PropertyType::Double},
                {"z", PropertyType::Double},
                {"points", PropertyType::Array}
            }
        },
    };
    
    Realm::Config realm_config {
        .path = realm_path,
        .sync_config = flex_sync_config,
        //.schema =componenet_schema,
        //.schema_version = 0
    };
    
    bool ready = false;
    auto async = Realm::get_synchronized_realm(realm_config);
    auto callback = [&](ThreadSafeReference ref, std::exception_ptr) {
        ready = true;
        s_data_cv.notify_one();
    };
    async->start(callback);
    
    {
        std::unique_lock<std::mutex> lk(s_data_mutex);
        s_data_cv.wait(lk, [&]{return ready;});
    }

    std::cout << "Realm has been synced" << std::endl;
     
    curl_global_cleanup();
    
    return 0;
}
