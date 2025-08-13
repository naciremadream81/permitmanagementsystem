package com.regnowsnaes.permitmanagementsystem.database

import kotlin.Long
import kotlin.String

public data class UserEntity(
  public val id: Long,
  public val email: String,
  public val firstName: String,
  public val lastName: String,
  public val role: String,
  public val createdAt: String,
  public val updatedAt: String,
  public val lastSyncedAt: String?,
)
