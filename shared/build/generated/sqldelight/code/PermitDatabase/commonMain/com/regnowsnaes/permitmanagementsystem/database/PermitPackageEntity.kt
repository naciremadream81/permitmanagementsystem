package com.regnowsnaes.permitmanagementsystem.database

import kotlin.Long
import kotlin.String

public data class PermitPackageEntity(
  public val id: Long,
  public val userId: Long,
  public val countyId: Long,
  public val name: String,
  public val description: String?,
  public val status: String,
  public val createdAt: String,
  public val updatedAt: String,
  public val lastSyncedAt: String?,
  public val pendingSync: Long,
)
