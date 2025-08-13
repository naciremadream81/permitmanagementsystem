package com.regnowsnaes.permitmanagementsystem.database.shared

import app.cash.sqldelight.TransacterImpl
import app.cash.sqldelight.db.AfterVersion
import app.cash.sqldelight.db.QueryResult
import app.cash.sqldelight.db.SqlDriver
import app.cash.sqldelight.db.SqlSchema
import com.regnowsnaes.permitmanagementsystem.database.PermitDatabase
import com.regnowsnaes.permitmanagementsystem.database.PermitDatabaseQueries
import kotlin.Long
import kotlin.Unit
import kotlin.reflect.KClass

internal val KClass<PermitDatabase>.schema: SqlSchema<QueryResult.Value<Unit>>
  get() = PermitDatabaseImpl.Schema

internal fun KClass<PermitDatabase>.newInstance(driver: SqlDriver): PermitDatabase =
    PermitDatabaseImpl(driver)

private class PermitDatabaseImpl(
  driver: SqlDriver,
) : TransacterImpl(driver), PermitDatabase {
  override val permitDatabaseQueries: PermitDatabaseQueries = PermitDatabaseQueries(driver)

  public object Schema : SqlSchema<QueryResult.Value<Unit>> {
    override val version: Long
      get() = 1

    override fun create(driver: SqlDriver): QueryResult.Value<Unit> {
      driver.execute(null, """
          |CREATE TABLE IF NOT EXISTS UserEntity (
          |    id INTEGER PRIMARY KEY,
          |    email TEXT NOT NULL UNIQUE,
          |    firstName TEXT NOT NULL,
          |    lastName TEXT NOT NULL,
          |    role TEXT NOT NULL DEFAULT 'user',
          |    createdAt TEXT NOT NULL,
          |    updatedAt TEXT NOT NULL,
          |    lastSyncedAt TEXT
          |)
          """.trimMargin(), 0)
      driver.execute(null, """
          |CREATE TABLE IF NOT EXISTS CountyEntity (
          |    id INTEGER PRIMARY KEY,
          |    name TEXT NOT NULL,
          |    state TEXT NOT NULL,
          |    createdAt TEXT NOT NULL,
          |    updatedAt TEXT NOT NULL,
          |    lastSyncedAt TEXT
          |)
          """.trimMargin(), 0)
      driver.execute(null, """
          |CREATE TABLE IF NOT EXISTS ChecklistItemEntity (
          |    id INTEGER PRIMARY KEY,
          |    countyId INTEGER NOT NULL,
          |    title TEXT NOT NULL,
          |    description TEXT,
          |    required INTEGER NOT NULL DEFAULT 1,
          |    orderIndex INTEGER NOT NULL DEFAULT 0,
          |    createdAt TEXT NOT NULL,
          |    updatedAt TEXT NOT NULL,
          |    lastSyncedAt TEXT,
          |    FOREIGN KEY (countyId) REFERENCES CountyEntity(id) ON DELETE CASCADE
          |)
          """.trimMargin(), 0)
      driver.execute(null, """
          |CREATE TABLE IF NOT EXISTS PermitPackageEntity (
          |    id INTEGER PRIMARY KEY,
          |    userId INTEGER NOT NULL,
          |    countyId INTEGER NOT NULL,
          |    name TEXT NOT NULL,
          |    description TEXT,
          |    status TEXT NOT NULL DEFAULT 'draft',
          |    createdAt TEXT NOT NULL,
          |    updatedAt TEXT NOT NULL,
          |    lastSyncedAt TEXT,
          |    pendingSync INTEGER NOT NULL DEFAULT 0,
          |    FOREIGN KEY (countyId) REFERENCES CountyEntity(id) ON DELETE CASCADE
          |)
          """.trimMargin(), 0)
      driver.execute(null, """
          |CREATE TABLE IF NOT EXISTS PermitDocumentEntity (
          |    id INTEGER PRIMARY KEY,
          |    packageId INTEGER NOT NULL,
          |    checklistItemId INTEGER NOT NULL,
          |    fileName TEXT NOT NULL,
          |    filePath TEXT NOT NULL,
          |    mimeType TEXT NOT NULL,
          |    fileSize INTEGER NOT NULL DEFAULT 0,
          |    createdAt TEXT NOT NULL,
          |    updatedAt TEXT NOT NULL,
          |    lastSyncedAt TEXT,
          |    pendingSync INTEGER NOT NULL DEFAULT 0,
          |    localFilePath TEXT,
          |    FOREIGN KEY (packageId) REFERENCES PermitPackageEntity(id) ON DELETE CASCADE,
          |    FOREIGN KEY (checklistItemId) REFERENCES ChecklistItemEntity(id) ON DELETE CASCADE
          |)
          """.trimMargin(), 0)
      driver.execute(null, """
          |CREATE TABLE IF NOT EXISTS SyncQueueEntity (
          |    id INTEGER PRIMARY KEY AUTOINCREMENT,
          |    entityType TEXT NOT NULL,
          |    entityId INTEGER NOT NULL,
          |    operation TEXT NOT NULL, -- 'CREATE', 'UPDATE', 'DELETE'
          |    data TEXT, -- JSON data for the operation
          |    createdAt TEXT NOT NULL,
          |    retryCount INTEGER NOT NULL DEFAULT 0,
          |    lastAttemptAt TEXT
          |)
          """.trimMargin(), 0)
      return QueryResult.Unit
    }

    override fun migrate(
      driver: SqlDriver,
      oldVersion: Long,
      newVersion: Long,
      vararg callbacks: AfterVersion,
    ): QueryResult.Value<Unit> = QueryResult.Unit
  }
}
