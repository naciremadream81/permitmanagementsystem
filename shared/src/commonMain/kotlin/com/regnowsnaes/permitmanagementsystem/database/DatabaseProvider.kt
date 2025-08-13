package com.regnowsnaes.permitmanagementsystem.database

expect object DatabaseProvider {
    fun getDatabaseDriverFactory(): DatabaseDriverFactory
}
