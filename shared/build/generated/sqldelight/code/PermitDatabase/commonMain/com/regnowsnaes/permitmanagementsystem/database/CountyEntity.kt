package com.regnowsnaes.permitmanagementsystem.database

import kotlin.Long
import kotlin.String

public data class CountyEntity(
  public val id: Long,
  public val name: String,
  public val state: String,
  public val createdAt: String,
  public val updatedAt: String,
  public val lastSyncedAt: String?,
)
