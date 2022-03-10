package io.realm.pinkunicorn

import android.app.Application
import android.content.Context
import io.realm.Realm
import io.realm.log.LogLevel
import io.realm.log.RealmLog
import io.realm.mongodb.App

class UnicornApplication: Application() {

    companion object {
        lateinit var APP: App
        lateinit var APP_CONTEXT: Context
    }

    override fun onCreate() {
        super.onCreate()
        Realm.init(this)
        RealmLog.setLevel(LogLevel.DEBUG)
        APP = App("pink-unicorn-bvzgq")
        APP_CONTEXT = this
    }
}