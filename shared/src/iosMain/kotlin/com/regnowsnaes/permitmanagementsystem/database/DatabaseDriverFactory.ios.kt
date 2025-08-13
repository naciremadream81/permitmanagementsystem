package com.regnowsnaes.permitmanagementsystem.database

import app.cash.sqldelight.db.SqlDriver
import app.cash.sqldelight.driver.native.NativeSqliteDriver

actual class DatabaseDriverFactory {
    actual fun createDriver(): SqlDriver {
        return NativeSqliteDriver(PermitDatabase.Schema, "permit_database.db")
    }
}
