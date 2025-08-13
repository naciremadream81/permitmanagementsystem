package com.regnowsnaes.permitmanagementsystem.services

import com.regnowsnaes.permitmanagementsystem.database.*
import com.regnowsnaes.permitmanagementsystem.models.*
import org.jetbrains.exposed.sql.*
import org.jetbrains.exposed.sql.SqlExpressionBuilder.eq
import org.jetbrains.exposed.sql.transactions.transaction
import java.time.LocalDateTime

object PermitService {
    
    // County operations
    fun getAllCounties(): List<County> {
        return transaction {
            Counties.selectAll().map { row ->
                County(
                    id = row[Counties.id].value,
                    name = row[Counties.name],
                    state = row[Counties.state],
                    createdAt = row[Counties.createdAt],
                    updatedAt = row[Counties.updatedAt]
                )
            }
        }
    }
    
    fun getCountyById(countyId: Int): County? {
        return transaction {
            Counties.select { Counties.id eq countyId }.singleOrNull()?.let { row ->
                County(
                    id = row[Counties.id].value,
                    name = row[Counties.name],
                    state = row[Counties.state],
                    createdAt = row[Counties.createdAt],
                    updatedAt = row[Counties.updatedAt]
                )
            }
        }
    }
    
    // Checklist operations
    fun getChecklistByCountyId(countyId: Int): List<ChecklistItem> {
        return transaction {
            ChecklistItems.select { ChecklistItems.countyId eq countyId }
                .orderBy(ChecklistItems.orderIndex to SortOrder.ASC)
                .map { row ->
                    ChecklistItem(
                        id = row[ChecklistItems.id].value,
                        countyId = row[ChecklistItems.countyId].value,
                        title = row[ChecklistItems.title],
                        description = row[ChecklistItems.description],
                        required = row[ChecklistItems.required],
                        orderIndex = row[ChecklistItems.orderIndex],
                        createdAt = row[ChecklistItems.createdAt],
                        updatedAt = row[ChecklistItems.updatedAt]
                    )
                }
        }
    }
    
    // Permit package operations
    fun createPermitPackage(
        userId: Int, 
        countyId: Int, 
        name: String, 
        description: String?,
        customerName: String? = null,
        customerEmail: String? = null,
        customerPhone: String? = null,
        customerCompany: String? = null,
        customerLicense: String? = null,
        siteAddress: String? = null,
        siteCity: String? = null,
        siteState: String? = null,
        siteZip: String? = null,
        siteCounty: String? = null
    ): PermitPackage {
        return transaction {
            val packageId = PermitPackages.insertAndGetId {
                it[PermitPackages.userId] = userId
                it[PermitPackages.countyId] = countyId
                it[PermitPackages.name] = name
                it[PermitPackages.description] = description
                it[PermitPackages.status] = "draft"
                
                // Customer Information
                it[PermitPackages.customerName] = customerName
                it[PermitPackages.customerEmail] = customerEmail
                it[PermitPackages.customerPhone] = customerPhone
                it[PermitPackages.customerCompany] = customerCompany
                it[PermitPackages.customerLicense] = customerLicense
                
                // Site Information
                it[PermitPackages.siteAddress] = siteAddress
                it[PermitPackages.siteCity] = siteCity
                it[PermitPackages.siteState] = siteState
                it[PermitPackages.siteZip] = siteZip
                it[PermitPackages.siteCounty] = siteCounty
                
                it[PermitPackages.createdAt] = LocalDateTime.now()
                it[PermitPackages.updatedAt] = LocalDateTime.now()
            }
            
            PermitPackage(
                id = packageId.value,
                userId = userId,
                countyId = countyId,
                name = name,
                description = description,
                status = "draft",
                customerName = customerName,
                customerEmail = customerEmail,
                customerPhone = customerPhone,
                customerCompany = customerCompany,
                customerLicense = customerLicense,
                siteAddress = siteAddress,
                siteCity = siteCity,
                siteState = siteState,
                siteZip = siteZip,
                siteCounty = siteCounty,
                createdAt = LocalDateTime.now(),
                updatedAt = LocalDateTime.now()
            )
        }
    }

    fun getPermitPackagesByUserId(userId: Int): List<PermitPackage> {
        return transaction {
            PermitPackages.select { PermitPackages.userId eq userId }
                .orderBy(PermitPackages.createdAt to SortOrder.DESC)
                .map { row ->
                    PermitPackage(
                        id = row[PermitPackages.id].value,
                        userId = row[PermitPackages.userId].value,
                        countyId = row[PermitPackages.countyId].value,
                        name = row[PermitPackages.name],
                        description = row[PermitPackages.description],
                        status = row[PermitPackages.status],
                        customerName = row[PermitPackages.customerName],
                        customerEmail = row[PermitPackages.customerEmail],
                        customerPhone = row[PermitPackages.customerPhone],
                        customerCompany = row[PermitPackages.customerCompany],
                        customerLicense = row[PermitPackages.customerLicense],
                        siteAddress = row[PermitPackages.siteAddress],
                        siteCity = row[PermitPackages.siteCity],
                        siteState = row[PermitPackages.siteState],
                        siteZip = row[PermitPackages.siteZip],
                        siteCounty = row[PermitPackages.siteCounty],
                        createdAt = row[PermitPackages.createdAt],
                        updatedAt = row[PermitPackages.updatedAt]
                    )
                }
        }
    }

    fun getPermitPackageById(packageId: Int, userId: Int): PermitPackage? {
        return transaction {
            PermitPackages.select { 
                (PermitPackages.id eq packageId) and (PermitPackages.userId eq userId) 
            }.singleOrNull()?.let { row ->
                PermitPackage(
                    id = row[PermitPackages.id].value,
                    userId = row[PermitPackages.userId].value,
                    countyId = row[PermitPackages.countyId].value,
                    name = row[PermitPackages.name],
                    description = row[PermitPackages.description],
                    status = row[PermitPackages.status],
                    customerName = row[PermitPackages.customerName],
                    customerEmail = row[PermitPackages.customerEmail],
                    customerPhone = row[PermitPackages.customerPhone],
                    customerCompany = row[PermitPackages.customerCompany],
                    customerLicense = row[PermitPackages.customerLicense],
                    siteAddress = row[PermitPackages.siteAddress],
                    siteCity = row[PermitPackages.siteCity],
                    siteState = row[PermitPackages.siteState],
                    siteZip = row[PermitPackages.siteZip],
                    siteCounty = row[PermitPackages.siteCounty],
                    createdAt = row[PermitPackages.createdAt],
                    updatedAt = row[PermitPackages.updatedAt]
                )
            }
        }
    }

    fun updatePermitPackageStatus(packageId: Int, userId: Int, status: String): PermitPackage? {
        return transaction {
            val updatedRows = PermitPackages.update({ 
                (PermitPackages.id eq packageId) and (PermitPackages.userId eq userId) 
            }) {
                it[PermitPackages.status] = status
                it[PermitPackages.updatedAt] = LocalDateTime.now()
            }
            
            if (updatedRows > 0) {
                getPermitPackageById(packageId, userId)
            } else {
                null
            }
        }
    }

    fun deletePermitPackage(packageId: Int, userId: Int): Boolean {
        return transaction {
            val deletedRows = PermitPackages.deleteWhere { 
                (PermitPackages.id eq packageId) and (PermitPackages.userId eq userId) 
            }
            deletedRows > 0
        }
    }
} 