package com.regnowsnaes.permitmanagementsystem.database

import android.content.Context

actual object DatabaseProvider {
    private var context: Context? = null
    
    fun initialize(context: Context) {
        this.context = context.applicationContext
    }
    
    actual fun getDatabaseDriverFactory(): DatabaseDriverFactory {
        val ctx = context ?: throw IllegalStateException("DatabaseProvider not initialized. Call initialize(context) first.")
        return DatabaseDriverFactory(ctx)
    }
}
