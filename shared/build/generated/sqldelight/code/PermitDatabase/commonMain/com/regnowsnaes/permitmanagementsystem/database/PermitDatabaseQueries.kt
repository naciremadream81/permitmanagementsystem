package com.regnowsnaes.permitmanagementsystem.database

import app.cash.sqldelight.Query
import app.cash.sqldelight.TransacterImpl
import app.cash.sqldelight.db.QueryResult
import app.cash.sqldelight.db.SqlCursor
import app.cash.sqldelight.db.SqlDriver
import kotlin.Any
import kotlin.Long
import kotlin.String

public class PermitDatabaseQueries(
  driver: SqlDriver,
) : TransacterImpl(driver) {
  public fun <T : Any> getUserById(id: Long, mapper: (
    id: Long,
    email: String,
    firstName: String,
    lastName: String,
    role: String,
    createdAt: String,
    updatedAt: String,
    lastSyncedAt: String?,
  ) -> T): Query<T> = GetUserByIdQuery(id) { cursor ->
    mapper(
      cursor.getLong(0)!!,
      cursor.getString(1)!!,
      cursor.getString(2)!!,
      cursor.getString(3)!!,
      cursor.getString(4)!!,
      cursor.getString(5)!!,
      cursor.getString(6)!!,
      cursor.getString(7)
    )
  }

  public fun getUserById(id: Long): Query<UserEntity> = getUserById(id) { id_, email, firstName,
      lastName, role, createdAt, updatedAt, lastSyncedAt ->
    UserEntity(
      id_,
      email,
      firstName,
      lastName,
      role,
      createdAt,
      updatedAt,
      lastSyncedAt
    )
  }

  public fun <T : Any> getCurrentUser(mapper: (
    id: Long,
    email: String,
    firstName: String,
    lastName: String,
    role: String,
    createdAt: String,
    updatedAt: String,
    lastSyncedAt: String?,
  ) -> T): Query<T> = Query(1_018_047_641, arrayOf("UserEntity"), driver, "PermitDatabase.sq",
      "getCurrentUser",
      "SELECT UserEntity.id, UserEntity.email, UserEntity.firstName, UserEntity.lastName, UserEntity.role, UserEntity.createdAt, UserEntity.updatedAt, UserEntity.lastSyncedAt FROM UserEntity LIMIT 1") {
      cursor ->
    mapper(
      cursor.getLong(0)!!,
      cursor.getString(1)!!,
      cursor.getString(2)!!,
      cursor.getString(3)!!,
      cursor.getString(4)!!,
      cursor.getString(5)!!,
      cursor.getString(6)!!,
      cursor.getString(7)
    )
  }

  public fun getCurrentUser(): Query<UserEntity> = getCurrentUser { id, email, firstName, lastName,
      role, createdAt, updatedAt, lastSyncedAt ->
    UserEntity(
      id,
      email,
      firstName,
      lastName,
      role,
      createdAt,
      updatedAt,
      lastSyncedAt
    )
  }

  public fun <T : Any> getAllCounties(mapper: (
    id: Long,
    name: String,
    state: String,
    createdAt: String,
    updatedAt: String,
    lastSyncedAt: String?,
  ) -> T): Query<T> = Query(218_601_438, arrayOf("CountyEntity"), driver, "PermitDatabase.sq",
      "getAllCounties",
      "SELECT CountyEntity.id, CountyEntity.name, CountyEntity.state, CountyEntity.createdAt, CountyEntity.updatedAt, CountyEntity.lastSyncedAt FROM CountyEntity ORDER BY name") {
      cursor ->
    mapper(
      cursor.getLong(0)!!,
      cursor.getString(1)!!,
      cursor.getString(2)!!,
      cursor.getString(3)!!,
      cursor.getString(4)!!,
      cursor.getString(5)
    )
  }

  public fun getAllCounties(): Query<CountyEntity> = getAllCounties { id, name, state, createdAt,
      updatedAt, lastSyncedAt ->
    CountyEntity(
      id,
      name,
      state,
      createdAt,
      updatedAt,
      lastSyncedAt
    )
  }

  public fun <T : Any> getCountyById(id: Long, mapper: (
    id: Long,
    name: String,
    state: String,
    createdAt: String,
    updatedAt: String,
    lastSyncedAt: String?,
  ) -> T): Query<T> = GetCountyByIdQuery(id) { cursor ->
    mapper(
      cursor.getLong(0)!!,
      cursor.getString(1)!!,
      cursor.getString(2)!!,
      cursor.getString(3)!!,
      cursor.getString(4)!!,
      cursor.getString(5)
    )
  }

  public fun getCountyById(id: Long): Query<CountyEntity> = getCountyById(id) { id_, name, state,
      createdAt, updatedAt, lastSyncedAt ->
    CountyEntity(
      id_,
      name,
      state,
      createdAt,
      updatedAt,
      lastSyncedAt
    )
  }

  public fun <T : Any> getChecklistItemsByCounty(countyId: Long, mapper: (
    id: Long,
    countyId: Long,
    title: String,
    description: String?,
    required: Long,
    orderIndex: Long,
    createdAt: String,
    updatedAt: String,
    lastSyncedAt: String?,
  ) -> T): Query<T> = GetChecklistItemsByCountyQuery(countyId) { cursor ->
    mapper(
      cursor.getLong(0)!!,
      cursor.getLong(1)!!,
      cursor.getString(2)!!,
      cursor.getString(3),
      cursor.getLong(4)!!,
      cursor.getLong(5)!!,
      cursor.getString(6)!!,
      cursor.getString(7)!!,
      cursor.getString(8)
    )
  }

  public fun getChecklistItemsByCounty(countyId: Long): Query<ChecklistItemEntity> =
      getChecklistItemsByCounty(countyId) { id, countyId_, title, description, required, orderIndex,
      createdAt, updatedAt, lastSyncedAt ->
    ChecklistItemEntity(
      id,
      countyId_,
      title,
      description,
      required,
      orderIndex,
      createdAt,
      updatedAt,
      lastSyncedAt
    )
  }

  public fun <T : Any> getAllPermitPackages(mapper: (
    id: Long,
    userId: Long,
    countyId: Long,
    name: String,
    description: String?,
    status: String,
    createdAt: String,
    updatedAt: String,
    lastSyncedAt: String?,
    pendingSync: Long,
  ) -> T): Query<T> = Query(1_689_149_982, arrayOf("PermitPackageEntity"), driver,
      "PermitDatabase.sq", "getAllPermitPackages",
      "SELECT PermitPackageEntity.id, PermitPackageEntity.userId, PermitPackageEntity.countyId, PermitPackageEntity.name, PermitPackageEntity.description, PermitPackageEntity.status, PermitPackageEntity.createdAt, PermitPackageEntity.updatedAt, PermitPackageEntity.lastSyncedAt, PermitPackageEntity.pendingSync FROM PermitPackageEntity ORDER BY createdAt DESC") {
      cursor ->
    mapper(
      cursor.getLong(0)!!,
      cursor.getLong(1)!!,
      cursor.getLong(2)!!,
      cursor.getString(3)!!,
      cursor.getString(4),
      cursor.getString(5)!!,
      cursor.getString(6)!!,
      cursor.getString(7)!!,
      cursor.getString(8),
      cursor.getLong(9)!!
    )
  }

  public fun getAllPermitPackages(): Query<PermitPackageEntity> = getAllPermitPackages { id, userId,
      countyId, name, description, status, createdAt, updatedAt, lastSyncedAt, pendingSync ->
    PermitPackageEntity(
      id,
      userId,
      countyId,
      name,
      description,
      status,
      createdAt,
      updatedAt,
      lastSyncedAt,
      pendingSync
    )
  }

  public fun <T : Any> getPermitPackageById(id: Long, mapper: (
    id: Long,
    userId: Long,
    countyId: Long,
    name: String,
    description: String?,
    status: String,
    createdAt: String,
    updatedAt: String,
    lastSyncedAt: String?,
    pendingSync: Long,
  ) -> T): Query<T> = GetPermitPackageByIdQuery(id) { cursor ->
    mapper(
      cursor.getLong(0)!!,
      cursor.getLong(1)!!,
      cursor.getLong(2)!!,
      cursor.getString(3)!!,
      cursor.getString(4),
      cursor.getString(5)!!,
      cursor.getString(6)!!,
      cursor.getString(7)!!,
      cursor.getString(8),
      cursor.getLong(9)!!
    )
  }

  public fun getPermitPackageById(id: Long): Query<PermitPackageEntity> = getPermitPackageById(id) {
      id_, userId, countyId, name, description, status, createdAt, updatedAt, lastSyncedAt,
      pendingSync ->
    PermitPackageEntity(
      id_,
      userId,
      countyId,
      name,
      description,
      status,
      createdAt,
      updatedAt,
      lastSyncedAt,
      pendingSync
    )
  }

  public fun <T : Any> getPermitPackagesByUser(userId: Long, mapper: (
    id: Long,
    userId: Long,
    countyId: Long,
    name: String,
    description: String?,
    status: String,
    createdAt: String,
    updatedAt: String,
    lastSyncedAt: String?,
    pendingSync: Long,
  ) -> T): Query<T> = GetPermitPackagesByUserQuery(userId) { cursor ->
    mapper(
      cursor.getLong(0)!!,
      cursor.getLong(1)!!,
      cursor.getLong(2)!!,
      cursor.getString(3)!!,
      cursor.getString(4),
      cursor.getString(5)!!,
      cursor.getString(6)!!,
      cursor.getString(7)!!,
      cursor.getString(8),
      cursor.getLong(9)!!
    )
  }

  public fun getPermitPackagesByUser(userId: Long): Query<PermitPackageEntity> =
      getPermitPackagesByUser(userId) { id, userId_, countyId, name, description, status, createdAt,
      updatedAt, lastSyncedAt, pendingSync ->
    PermitPackageEntity(
      id,
      userId_,
      countyId,
      name,
      description,
      status,
      createdAt,
      updatedAt,
      lastSyncedAt,
      pendingSync
    )
  }

  public fun <T : Any> getPendingSyncPackages(mapper: (
    id: Long,
    userId: Long,
    countyId: Long,
    name: String,
    description: String?,
    status: String,
    createdAt: String,
    updatedAt: String,
    lastSyncedAt: String?,
    pendingSync: Long,
  ) -> T): Query<T> = Query(1_853_696_660, arrayOf("PermitPackageEntity"), driver,
      "PermitDatabase.sq", "getPendingSyncPackages",
      "SELECT PermitPackageEntity.id, PermitPackageEntity.userId, PermitPackageEntity.countyId, PermitPackageEntity.name, PermitPackageEntity.description, PermitPackageEntity.status, PermitPackageEntity.createdAt, PermitPackageEntity.updatedAt, PermitPackageEntity.lastSyncedAt, PermitPackageEntity.pendingSync FROM PermitPackageEntity WHERE pendingSync = 1") {
      cursor ->
    mapper(
      cursor.getLong(0)!!,
      cursor.getLong(1)!!,
      cursor.getLong(2)!!,
      cursor.getString(3)!!,
      cursor.getString(4),
      cursor.getString(5)!!,
      cursor.getString(6)!!,
      cursor.getString(7)!!,
      cursor.getString(8),
      cursor.getLong(9)!!
    )
  }

  public fun getPendingSyncPackages(): Query<PermitPackageEntity> = getPendingSyncPackages { id,
      userId, countyId, name, description, status, createdAt, updatedAt, lastSyncedAt,
      pendingSync ->
    PermitPackageEntity(
      id,
      userId,
      countyId,
      name,
      description,
      status,
      createdAt,
      updatedAt,
      lastSyncedAt,
      pendingSync
    )
  }

  public fun <T : Any> getDocumentsByPackage(packageId: Long, mapper: (
    id: Long,
    packageId: Long,
    checklistItemId: Long,
    fileName: String,
    filePath: String,
    mimeType: String,
    fileSize: Long,
    createdAt: String,
    updatedAt: String,
    lastSyncedAt: String?,
    pendingSync: Long,
    localFilePath: String?,
  ) -> T): Query<T> = GetDocumentsByPackageQuery(packageId) { cursor ->
    mapper(
      cursor.getLong(0)!!,
      cursor.getLong(1)!!,
      cursor.getLong(2)!!,
      cursor.getString(3)!!,
      cursor.getString(4)!!,
      cursor.getString(5)!!,
      cursor.getLong(6)!!,
      cursor.getString(7)!!,
      cursor.getString(8)!!,
      cursor.getString(9),
      cursor.getLong(10)!!,
      cursor.getString(11)
    )
  }

  public fun getDocumentsByPackage(packageId: Long): Query<PermitDocumentEntity> =
      getDocumentsByPackage(packageId) { id, packageId_, checklistItemId, fileName, filePath,
      mimeType, fileSize, createdAt, updatedAt, lastSyncedAt, pendingSync, localFilePath ->
    PermitDocumentEntity(
      id,
      packageId_,
      checklistItemId,
      fileName,
      filePath,
      mimeType,
      fileSize,
      createdAt,
      updatedAt,
      lastSyncedAt,
      pendingSync,
      localFilePath
    )
  }

  public fun <T : Any> getDocumentById(id: Long, mapper: (
    id: Long,
    packageId: Long,
    checklistItemId: Long,
    fileName: String,
    filePath: String,
    mimeType: String,
    fileSize: Long,
    createdAt: String,
    updatedAt: String,
    lastSyncedAt: String?,
    pendingSync: Long,
    localFilePath: String?,
  ) -> T): Query<T> = GetDocumentByIdQuery(id) { cursor ->
    mapper(
      cursor.getLong(0)!!,
      cursor.getLong(1)!!,
      cursor.getLong(2)!!,
      cursor.getString(3)!!,
      cursor.getString(4)!!,
      cursor.getString(5)!!,
      cursor.getLong(6)!!,
      cursor.getString(7)!!,
      cursor.getString(8)!!,
      cursor.getString(9),
      cursor.getLong(10)!!,
      cursor.getString(11)
    )
  }

  public fun getDocumentById(id: Long): Query<PermitDocumentEntity> = getDocumentById(id) { id_,
      packageId, checklistItemId, fileName, filePath, mimeType, fileSize, createdAt, updatedAt,
      lastSyncedAt, pendingSync, localFilePath ->
    PermitDocumentEntity(
      id_,
      packageId,
      checklistItemId,
      fileName,
      filePath,
      mimeType,
      fileSize,
      createdAt,
      updatedAt,
      lastSyncedAt,
      pendingSync,
      localFilePath
    )
  }

  public fun <T : Any> getPendingSyncDocuments(mapper: (
    id: Long,
    packageId: Long,
    checklistItemId: Long,
    fileName: String,
    filePath: String,
    mimeType: String,
    fileSize: Long,
    createdAt: String,
    updatedAt: String,
    lastSyncedAt: String?,
    pendingSync: Long,
    localFilePath: String?,
  ) -> T): Query<T> = Query(771_502_577, arrayOf("PermitDocumentEntity"), driver,
      "PermitDatabase.sq", "getPendingSyncDocuments",
      "SELECT PermitDocumentEntity.id, PermitDocumentEntity.packageId, PermitDocumentEntity.checklistItemId, PermitDocumentEntity.fileName, PermitDocumentEntity.filePath, PermitDocumentEntity.mimeType, PermitDocumentEntity.fileSize, PermitDocumentEntity.createdAt, PermitDocumentEntity.updatedAt, PermitDocumentEntity.lastSyncedAt, PermitDocumentEntity.pendingSync, PermitDocumentEntity.localFilePath FROM PermitDocumentEntity WHERE pendingSync = 1") {
      cursor ->
    mapper(
      cursor.getLong(0)!!,
      cursor.getLong(1)!!,
      cursor.getLong(2)!!,
      cursor.getString(3)!!,
      cursor.getString(4)!!,
      cursor.getString(5)!!,
      cursor.getLong(6)!!,
      cursor.getString(7)!!,
      cursor.getString(8)!!,
      cursor.getString(9),
      cursor.getLong(10)!!,
      cursor.getString(11)
    )
  }

  public fun getPendingSyncDocuments(): Query<PermitDocumentEntity> = getPendingSyncDocuments { id,
      packageId, checklistItemId, fileName, filePath, mimeType, fileSize, createdAt, updatedAt,
      lastSyncedAt, pendingSync, localFilePath ->
    PermitDocumentEntity(
      id,
      packageId,
      checklistItemId,
      fileName,
      filePath,
      mimeType,
      fileSize,
      createdAt,
      updatedAt,
      lastSyncedAt,
      pendingSync,
      localFilePath
    )
  }

  public fun <T : Any> getPendingSyncOperations(mapper: (
    id: Long,
    entityType: String,
    entityId: Long,
    operation: String,
    data_: String?,
    createdAt: String,
    retryCount: Long,
    lastAttemptAt: String?,
  ) -> T): Query<T> = Query(-1_034_100_781, arrayOf("SyncQueueEntity"), driver, "PermitDatabase.sq",
      "getPendingSyncOperations",
      "SELECT SyncQueueEntity.id, SyncQueueEntity.entityType, SyncQueueEntity.entityId, SyncQueueEntity.operation, SyncQueueEntity.data, SyncQueueEntity.createdAt, SyncQueueEntity.retryCount, SyncQueueEntity.lastAttemptAt FROM SyncQueueEntity ORDER BY createdAt") {
      cursor ->
    mapper(
      cursor.getLong(0)!!,
      cursor.getString(1)!!,
      cursor.getLong(2)!!,
      cursor.getString(3)!!,
      cursor.getString(4),
      cursor.getString(5)!!,
      cursor.getLong(6)!!,
      cursor.getString(7)
    )
  }

  public fun getPendingSyncOperations(): Query<SyncQueueEntity> = getPendingSyncOperations { id,
      entityType, entityId, operation, data_, createdAt, retryCount, lastAttemptAt ->
    SyncQueueEntity(
      id,
      entityType,
      entityId,
      operation,
      data_,
      createdAt,
      retryCount,
      lastAttemptAt
    )
  }

  public fun <T : Any> getLastSyncTime(mapper: (MAX: String?) -> T): Query<T> = Query(131_342_249,
      arrayOf("CountyEntity", "ChecklistItemEntity", "PermitPackageEntity", "PermitDocumentEntity"),
      driver, "PermitDatabase.sq", "getLastSyncTime", """
  |SELECT MAX(lastSyncedAt) FROM (
  |    SELECT lastSyncedAt FROM CountyEntity
  |    UNION ALL
  |    SELECT lastSyncedAt FROM ChecklistItemEntity
  |    UNION ALL
  |    SELECT lastSyncedAt FROM PermitPackageEntity
  |    UNION ALL
  |    SELECT lastSyncedAt FROM PermitDocumentEntity
  |)
  """.trimMargin()) { cursor ->
    mapper(
      cursor.getString(0)
    )
  }

  public fun getLastSyncTime(): Query<GetLastSyncTime> = getLastSyncTime { MAX ->
    GetLastSyncTime(
      MAX
    )
  }

  public fun insertUser(
    id: Long?,
    email: String,
    firstName: String,
    lastName: String,
    role: String,
    createdAt: String,
    updatedAt: String,
    lastSyncedAt: String?,
  ) {
    driver.execute(-76_449_649, """
        |INSERT OR REPLACE INTO UserEntity (id, email, firstName, lastName, role, createdAt, updatedAt, lastSyncedAt)
        |VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """.trimMargin(), 8) {
          bindLong(0, id)
          bindString(1, email)
          bindString(2, firstName)
          bindString(3, lastName)
          bindString(4, role)
          bindString(5, createdAt)
          bindString(6, updatedAt)
          bindString(7, lastSyncedAt)
        }
    notifyQueries(-76_449_649) { emit ->
      emit("UserEntity")
    }
  }

  public fun deleteAllUsers() {
    driver.execute(793_066_653, """DELETE FROM UserEntity""", 0)
    notifyQueries(793_066_653) { emit ->
      emit("UserEntity")
    }
  }

  public fun insertCounty(
    id: Long?,
    name: String,
    state: String,
    createdAt: String,
    updatedAt: String,
    lastSyncedAt: String?,
  ) {
    driver.execute(-972_210_930, """
        |INSERT OR REPLACE INTO CountyEntity (id, name, state, createdAt, updatedAt, lastSyncedAt)
        |VALUES (?, ?, ?, ?, ?, ?)
        """.trimMargin(), 6) {
          bindLong(0, id)
          bindString(1, name)
          bindString(2, state)
          bindString(3, createdAt)
          bindString(4, updatedAt)
          bindString(5, lastSyncedAt)
        }
    notifyQueries(-972_210_930) { emit ->
      emit("CountyEntity")
    }
  }

  public fun deleteAllCounties() {
    driver.execute(-472_791_885, """DELETE FROM CountyEntity""", 0)
    notifyQueries(-472_791_885) { emit ->
      emit("ChecklistItemEntity")
      emit("CountyEntity")
      emit("PermitPackageEntity")
    }
  }

  public fun insertChecklistItem(
    id: Long?,
    countyId: Long,
    title: String,
    description: String?,
    required: Long,
    orderIndex: Long,
    createdAt: String,
    updatedAt: String,
    lastSyncedAt: String?,
  ) {
    driver.execute(341_839_253, """
        |INSERT OR REPLACE INTO ChecklistItemEntity (id, countyId, title, description, required, orderIndex, createdAt, updatedAt, lastSyncedAt)
        |VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """.trimMargin(), 9) {
          bindLong(0, id)
          bindLong(1, countyId)
          bindString(2, title)
          bindString(3, description)
          bindLong(4, required)
          bindLong(5, orderIndex)
          bindString(6, createdAt)
          bindString(7, updatedAt)
          bindString(8, lastSyncedAt)
        }
    notifyQueries(341_839_253) { emit ->
      emit("ChecklistItemEntity")
    }
  }

  public fun deleteChecklistItemsByCounty(countyId: Long) {
    driver.execute(2_006_825_361, """DELETE FROM ChecklistItemEntity WHERE countyId = ?""", 1) {
          bindLong(0, countyId)
        }
    notifyQueries(2_006_825_361) { emit ->
      emit("ChecklistItemEntity")
      emit("PermitDocumentEntity")
    }
  }

  public fun deleteAllChecklistItems() {
    driver.execute(1_859_200_709, """DELETE FROM ChecklistItemEntity""", 0)
    notifyQueries(1_859_200_709) { emit ->
      emit("ChecklistItemEntity")
      emit("PermitDocumentEntity")
    }
  }

  public fun insertPermitPackage(
    id: Long?,
    userId: Long,
    countyId: Long,
    name: String,
    description: String?,
    status: String,
    createdAt: String,
    updatedAt: String,
    lastSyncedAt: String?,
    pendingSync: Long,
  ) {
    driver.execute(14_357_351, """
        |INSERT OR REPLACE INTO PermitPackageEntity (id, userId, countyId, name, description, status, createdAt, updatedAt, lastSyncedAt, pendingSync)
        |VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """.trimMargin(), 10) {
          bindLong(0, id)
          bindLong(1, userId)
          bindLong(2, countyId)
          bindString(3, name)
          bindString(4, description)
          bindString(5, status)
          bindString(6, createdAt)
          bindString(7, updatedAt)
          bindString(8, lastSyncedAt)
          bindLong(9, pendingSync)
        }
    notifyQueries(14_357_351) { emit ->
      emit("PermitPackageEntity")
    }
  }

  public fun updatePackageStatus(
    status: String,
    updatedAt: String,
    id: Long,
  ) {
    driver.execute(-66_087_036,
        """UPDATE PermitPackageEntity SET status = ?, updatedAt = ?, pendingSync = 1 WHERE id = ?""",
        3) {
          bindString(0, status)
          bindString(1, updatedAt)
          bindLong(2, id)
        }
    notifyQueries(-66_087_036) { emit ->
      emit("PermitPackageEntity")
    }
  }

  public fun markPackageSynced(lastSyncedAt: String?, id: Long) {
    driver.execute(-1_257_519_672,
        """UPDATE PermitPackageEntity SET pendingSync = 0, lastSyncedAt = ? WHERE id = ?""", 2) {
          bindString(0, lastSyncedAt)
          bindLong(1, id)
        }
    notifyQueries(-1_257_519_672) { emit ->
      emit("PermitPackageEntity")
    }
  }

  public fun deleteAllPermitPackages() {
    driver.execute(297_196_339, """DELETE FROM PermitPackageEntity""", 0)
    notifyQueries(297_196_339) { emit ->
      emit("PermitDocumentEntity")
      emit("PermitPackageEntity")
    }
  }

  public fun insertPermitDocument(
    id: Long?,
    packageId: Long,
    checklistItemId: Long,
    fileName: String,
    filePath: String,
    mimeType: String,
    fileSize: Long,
    createdAt: String,
    updatedAt: String,
    lastSyncedAt: String?,
    pendingSync: Long,
    localFilePath: String?,
  ) {
    driver.execute(555_931_162, """
        |INSERT OR REPLACE INTO PermitDocumentEntity (id, packageId, checklistItemId, fileName, filePath, mimeType, fileSize, createdAt, updatedAt, lastSyncedAt, pendingSync, localFilePath)
        |VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """.trimMargin(), 12) {
          bindLong(0, id)
          bindLong(1, packageId)
          bindLong(2, checklistItemId)
          bindString(3, fileName)
          bindString(4, filePath)
          bindString(5, mimeType)
          bindLong(6, fileSize)
          bindString(7, createdAt)
          bindString(8, updatedAt)
          bindString(9, lastSyncedAt)
          bindLong(10, pendingSync)
          bindString(11, localFilePath)
        }
    notifyQueries(555_931_162) { emit ->
      emit("PermitDocumentEntity")
    }
  }

  public fun markDocumentSynced(lastSyncedAt: String?, id: Long) {
    driver.execute(-1_251_389_171,
        """UPDATE PermitDocumentEntity SET pendingSync = 0, lastSyncedAt = ? WHERE id = ?""", 2) {
          bindString(0, lastSyncedAt)
          bindLong(1, id)
        }
    notifyQueries(-1_251_389_171) { emit ->
      emit("PermitDocumentEntity")
    }
  }

  public fun deleteDocument(id: Long) {
    driver.execute(-134_214_447, """DELETE FROM PermitDocumentEntity WHERE id = ?""", 1) {
          bindLong(0, id)
        }
    notifyQueries(-134_214_447) { emit ->
      emit("PermitDocumentEntity")
    }
  }

  public fun deleteAllDocuments() {
    driver.execute(2_114_498_253, """DELETE FROM PermitDocumentEntity""", 0)
    notifyQueries(2_114_498_253) { emit ->
      emit("PermitDocumentEntity")
    }
  }

  public fun insertSyncOperation(
    entityType: String,
    entityId: Long,
    operation: String,
    data_: String?,
    createdAt: String,
    retryCount: Long,
    lastAttemptAt: String?,
  ) {
    driver.execute(1_294_543_048, """
        |INSERT INTO SyncQueueEntity (entityType, entityId, operation, data, createdAt, retryCount, lastAttemptAt)
        |VALUES (?, ?, ?, ?, ?, ?, ?)
        """.trimMargin(), 7) {
          bindString(0, entityType)
          bindLong(1, entityId)
          bindString(2, operation)
          bindString(3, data_)
          bindString(4, createdAt)
          bindLong(5, retryCount)
          bindString(6, lastAttemptAt)
        }
    notifyQueries(1_294_543_048) { emit ->
      emit("SyncQueueEntity")
    }
  }

  public fun updateSyncOperationRetry(
    retryCount: Long,
    lastAttemptAt: String?,
    id: Long,
  ) {
    driver.execute(852_515_024,
        """UPDATE SyncQueueEntity SET retryCount = ?, lastAttemptAt = ? WHERE id = ?""", 3) {
          bindLong(0, retryCount)
          bindString(1, lastAttemptAt)
          bindLong(2, id)
        }
    notifyQueries(852_515_024) { emit ->
      emit("SyncQueueEntity")
    }
  }

  public fun deleteSyncOperation(id: Long) {
    driver.execute(-1_564_000_490, """DELETE FROM SyncQueueEntity WHERE id = ?""", 1) {
          bindLong(0, id)
        }
    notifyQueries(-1_564_000_490) { emit ->
      emit("SyncQueueEntity")
    }
  }

  public fun deleteAllSyncOperations() {
    driver.execute(1_328_247_282, """DELETE FROM SyncQueueEntity""", 0)
    notifyQueries(1_328_247_282) { emit ->
      emit("SyncQueueEntity")
    }
  }

  private inner class GetUserByIdQuery<out T : Any>(
    public val id: Long,
    mapper: (SqlCursor) -> T,
  ) : Query<T>(mapper) {
    override fun addListener(listener: Query.Listener) {
      driver.addListener("UserEntity", listener = listener)
    }

    override fun removeListener(listener: Query.Listener) {
      driver.removeListener("UserEntity", listener = listener)
    }

    override fun <R> execute(mapper: (SqlCursor) -> QueryResult<R>): QueryResult<R> =
        driver.executeQuery(-446_624_088,
        """SELECT UserEntity.id, UserEntity.email, UserEntity.firstName, UserEntity.lastName, UserEntity.role, UserEntity.createdAt, UserEntity.updatedAt, UserEntity.lastSyncedAt FROM UserEntity WHERE id = ?""",
        mapper, 1) {
      bindLong(0, id)
    }

    override fun toString(): String = "PermitDatabase.sq:getUserById"
  }

  private inner class GetCountyByIdQuery<out T : Any>(
    public val id: Long,
    mapper: (SqlCursor) -> T,
  ) : Query<T>(mapper) {
    override fun addListener(listener: Query.Listener) {
      driver.addListener("CountyEntity", listener = listener)
    }

    override fun removeListener(listener: Query.Listener) {
      driver.removeListener("CountyEntity", listener = listener)
    }

    override fun <R> execute(mapper: (SqlCursor) -> QueryResult<R>): QueryResult<R> =
        driver.executeQuery(-1_830_441_497,
        """SELECT CountyEntity.id, CountyEntity.name, CountyEntity.state, CountyEntity.createdAt, CountyEntity.updatedAt, CountyEntity.lastSyncedAt FROM CountyEntity WHERE id = ?""",
        mapper, 1) {
      bindLong(0, id)
    }

    override fun toString(): String = "PermitDatabase.sq:getCountyById"
  }

  private inner class GetChecklistItemsByCountyQuery<out T : Any>(
    public val countyId: Long,
    mapper: (SqlCursor) -> T,
  ) : Query<T>(mapper) {
    override fun addListener(listener: Query.Listener) {
      driver.addListener("ChecklistItemEntity", listener = listener)
    }

    override fun removeListener(listener: Query.Listener) {
      driver.removeListener("ChecklistItemEntity", listener = listener)
    }

    override fun <R> execute(mapper: (SqlCursor) -> QueryResult<R>): QueryResult<R> =
        driver.executeQuery(-1_586_705_018,
        """SELECT ChecklistItemEntity.id, ChecklistItemEntity.countyId, ChecklistItemEntity.title, ChecklistItemEntity.description, ChecklistItemEntity.required, ChecklistItemEntity.orderIndex, ChecklistItemEntity.createdAt, ChecklistItemEntity.updatedAt, ChecklistItemEntity.lastSyncedAt FROM ChecklistItemEntity WHERE countyId = ? ORDER BY orderIndex""",
        mapper, 1) {
      bindLong(0, countyId)
    }

    override fun toString(): String = "PermitDatabase.sq:getChecklistItemsByCounty"
  }

  private inner class GetPermitPackageByIdQuery<out T : Any>(
    public val id: Long,
    mapper: (SqlCursor) -> T,
  ) : Query<T>(mapper) {
    override fun addListener(listener: Query.Listener) {
      driver.addListener("PermitPackageEntity", listener = listener)
    }

    override fun removeListener(listener: Query.Listener) {
      driver.removeListener("PermitPackageEntity", listener = listener)
    }

    override fun <R> execute(mapper: (SqlCursor) -> QueryResult<R>): QueryResult<R> =
        driver.executeQuery(281_714_194,
        """SELECT PermitPackageEntity.id, PermitPackageEntity.userId, PermitPackageEntity.countyId, PermitPackageEntity.name, PermitPackageEntity.description, PermitPackageEntity.status, PermitPackageEntity.createdAt, PermitPackageEntity.updatedAt, PermitPackageEntity.lastSyncedAt, PermitPackageEntity.pendingSync FROM PermitPackageEntity WHERE id = ?""",
        mapper, 1) {
      bindLong(0, id)
    }

    override fun toString(): String = "PermitDatabase.sq:getPermitPackageById"
  }

  private inner class GetPermitPackagesByUserQuery<out T : Any>(
    public val userId: Long,
    mapper: (SqlCursor) -> T,
  ) : Query<T>(mapper) {
    override fun addListener(listener: Query.Listener) {
      driver.addListener("PermitPackageEntity", listener = listener)
    }

    override fun removeListener(listener: Query.Listener) {
      driver.removeListener("PermitPackageEntity", listener = listener)
    }

    override fun <R> execute(mapper: (SqlCursor) -> QueryResult<R>): QueryResult<R> =
        driver.executeQuery(-811_142_923,
        """SELECT PermitPackageEntity.id, PermitPackageEntity.userId, PermitPackageEntity.countyId, PermitPackageEntity.name, PermitPackageEntity.description, PermitPackageEntity.status, PermitPackageEntity.createdAt, PermitPackageEntity.updatedAt, PermitPackageEntity.lastSyncedAt, PermitPackageEntity.pendingSync FROM PermitPackageEntity WHERE userId = ? ORDER BY createdAt DESC""",
        mapper, 1) {
      bindLong(0, userId)
    }

    override fun toString(): String = "PermitDatabase.sq:getPermitPackagesByUser"
  }

  private inner class GetDocumentsByPackageQuery<out T : Any>(
    public val packageId: Long,
    mapper: (SqlCursor) -> T,
  ) : Query<T>(mapper) {
    override fun addListener(listener: Query.Listener) {
      driver.addListener("PermitDocumentEntity", listener = listener)
    }

    override fun removeListener(listener: Query.Listener) {
      driver.removeListener("PermitDocumentEntity", listener = listener)
    }

    override fun <R> execute(mapper: (SqlCursor) -> QueryResult<R>): QueryResult<R> =
        driver.executeQuery(-1_908_489_534,
        """SELECT PermitDocumentEntity.id, PermitDocumentEntity.packageId, PermitDocumentEntity.checklistItemId, PermitDocumentEntity.fileName, PermitDocumentEntity.filePath, PermitDocumentEntity.mimeType, PermitDocumentEntity.fileSize, PermitDocumentEntity.createdAt, PermitDocumentEntity.updatedAt, PermitDocumentEntity.lastSyncedAt, PermitDocumentEntity.pendingSync, PermitDocumentEntity.localFilePath FROM PermitDocumentEntity WHERE packageId = ? ORDER BY createdAt""",
        mapper, 1) {
      bindLong(0, packageId)
    }

    override fun toString(): String = "PermitDatabase.sq:getDocumentsByPackage"
  }

  private inner class GetDocumentByIdQuery<out T : Any>(
    public val id: Long,
    mapper: (SqlCursor) -> T,
  ) : Query<T>(mapper) {
    override fun addListener(listener: Query.Listener) {
      driver.addListener("PermitDocumentEntity", listener = listener)
    }

    override fun removeListener(listener: Query.Listener) {
      driver.removeListener("PermitDocumentEntity", listener = listener)
    }

    override fun <R> execute(mapper: (SqlCursor) -> QueryResult<R>): QueryResult<R> =
        driver.executeQuery(-1_438_671_240,
        """SELECT PermitDocumentEntity.id, PermitDocumentEntity.packageId, PermitDocumentEntity.checklistItemId, PermitDocumentEntity.fileName, PermitDocumentEntity.filePath, PermitDocumentEntity.mimeType, PermitDocumentEntity.fileSize, PermitDocumentEntity.createdAt, PermitDocumentEntity.updatedAt, PermitDocumentEntity.lastSyncedAt, PermitDocumentEntity.pendingSync, PermitDocumentEntity.localFilePath FROM PermitDocumentEntity WHERE id = ?""",
        mapper, 1) {
      bindLong(0, id)
    }

    override fun toString(): String = "PermitDatabase.sq:getDocumentById"
  }
}
