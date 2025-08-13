package com.regnowsnaes.permitmanagementsystem.database

import org.jetbrains.exposed.dao.id.IntIdTable
import org.jetbrains.exposed.sql.*
import org.jetbrains.exposed.sql.javatime.datetime

object Users : IntIdTable("users") {
    val email = varchar("email", 255).uniqueIndex()
    val password = varchar("password", 255)
    val firstName = varchar("first_name", 100)
    val lastName = varchar("last_name", 100)
    val role = varchar("role", 50).default("user")
    val createdAt = datetime("created_at")
    val updatedAt = datetime("updated_at")
}

object Counties : IntIdTable("counties") {
    val name = varchar("name", 100)
    val state = varchar("state", 2)
    val createdAt = datetime("created_at")
    val updatedAt = datetime("updated_at")
}

object ChecklistItems : IntIdTable("checklist_items") {
    val countyId = reference("county_id", Counties)
    val title = varchar("title", 255)
    val description = text("description")
    val required = bool("required").default(true)
    val orderIndex = integer("order_index")
    val createdAt = datetime("created_at")
    val updatedAt = datetime("updated_at")
}

object PermitPackages : IntIdTable("permit_packages") {
    val userId = reference("user_id", Users)
    val countyId = reference("county_id", Counties)
    val name = varchar("name", 255)
    val description = text("description").nullable()
    val status = varchar("status", 50).default("draft")
    val customerName = varchar("customer_name", 255).nullable()
    val customerEmail = varchar("customer_email", 255).nullable()
    val customerPhone = varchar("customer_phone", 50).nullable()
    val customerCompany = varchar("customer_company", 255).nullable()
    val customerLicense = varchar("customer_license", 100).nullable()
    val siteAddress = varchar("site_address", 500).nullable()
    val siteCity = varchar("site_city", 100).nullable()
    val siteState = varchar("site_state", 2).nullable()
    val siteZip = varchar("site_zip", 20).nullable()
    val siteCounty = varchar("site_county", 100).nullable()
    val createdAt = datetime("created_at")
    val updatedAt = datetime("updated_at")
}

object PermitDocuments : IntIdTable("permit_documents") {
    val packageId = reference("package_id", PermitPackages)
    val checklistItemId = reference("checklist_item_id", ChecklistItems)
    val fileName = varchar("file_name", 255)
    val fileUrl = varchar("file_url", 500)
    val fileSize = integer("file_size")
    val mimeType = varchar("mime_type", 100)
    val documentType = varchar("document_type", 50).default("general")
    val version = varchar("version", 20).default("1.0")
    val isApproved = bool("is_approved").default(false)
    val approvalDate = datetime("approval_date").nullable()
    val approvedBy = reference("approved_by", Users).nullable()
    val rejectionReason = text("rejection_reason").nullable()
    val uploadedAt = datetime("uploaded_at")
} 