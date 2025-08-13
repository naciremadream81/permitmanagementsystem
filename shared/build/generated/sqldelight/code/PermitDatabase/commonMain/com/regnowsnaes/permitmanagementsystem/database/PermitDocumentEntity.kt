package com.regnowsnaes.permitmanagementsystem.database

import kotlin.Long
import kotlin.String

public data class PermitDocumentEntity(
  public val id: Long,
  public val packageId: Long,
  public val checklistItemId: Long,
  public val fileName: String,
  public val filePath: String,
  public val mimeType: String,
  public val fileSize: Long,
  public val createdAt: String,
  public val updatedAt: String,
  public val lastSyncedAt: String?,
  public val pendingSync: Long,
  public val localFilePath: String?,
)
