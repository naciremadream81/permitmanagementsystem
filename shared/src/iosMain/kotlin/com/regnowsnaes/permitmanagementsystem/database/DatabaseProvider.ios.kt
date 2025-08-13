package com.regnowsnaes.permitmanagementsystem.database

actual object DatabaseProvider {
    actual fun getDatabaseDriverFactory(): DatabaseDriverFactory {
        return DatabaseDriverFactory()
    }
}
