package com.regnowsnaes.permitmanagementsystem.database

import kotlin.Long
import kotlin.String

public data class SyncQueueEntity(
  public val id: Long,
  public val entityType: String,
  public val entityId: Long,
  public val operation: String,
  public val data_: String?,
  public val createdAt: String,
  public val retryCount: Long,
  public val lastAttemptAt: String?,
)
