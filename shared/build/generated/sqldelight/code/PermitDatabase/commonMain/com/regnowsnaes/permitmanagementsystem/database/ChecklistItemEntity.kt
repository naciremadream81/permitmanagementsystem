package com.regnowsnaes.permitmanagementsystem.database

import kotlin.Long
import kotlin.String

public data class ChecklistItemEntity(
  public val id: Long,
  public val countyId: Long,
  public val title: String,
  public val description: String?,
  public val required: Long,
  public val orderIndex: Long,
  public val createdAt: String,
  public val updatedAt: String,
  public val lastSyncedAt: String?,
)
