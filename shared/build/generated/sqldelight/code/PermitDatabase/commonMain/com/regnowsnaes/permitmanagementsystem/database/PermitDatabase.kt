package com.regnowsnaes.permitmanagementsystem.database

import app.cash.sqldelight.Transacter
import app.cash.sqldelight.db.QueryResult
import app.cash.sqldelight.db.SqlDriver
import app.cash.sqldelight.db.SqlSchema
import com.regnowsnaes.permitmanagementsystem.database.shared.newInstance
import com.regnowsnaes.permitmanagementsystem.database.shared.schema
import kotlin.Unit

public interface PermitDatabase : Transacter {
  public val permitDatabaseQueries: PermitDatabaseQueries

  public companion object {
    public val Schema: SqlSchema<QueryResult.Value<Unit>>
      get() = PermitDatabase::class.schema

    public operator fun invoke(driver: SqlDriver): PermitDatabase =
        PermitDatabase::class.newInstance(driver)
  }
}
