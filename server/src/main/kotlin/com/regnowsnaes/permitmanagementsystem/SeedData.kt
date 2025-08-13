package com.regnowsnaes.permitmanagementsystem

import com.regnowsnaes.permitmanagementsystem.database.DatabaseConfig
import com.regnowsnaes.permitmanagementsystem.database.*
import org.jetbrains.exposed.sql.*
import org.jetbrains.exposed.sql.transactions.transaction
import java.time.LocalDateTime

fun main() {
    // Initialize database
    DatabaseConfig.init()
    
    // Add additional test data
    addTestData()
    
    println("✅ Seed data added successfully!")
}

private fun addTestData() {
    transaction {
        // Add more counties
        val riversideCountyId = Counties.insertAndGetId {
            it[name] = "Riverside County"
            it[state] = "CA"
            it[createdAt] = LocalDateTime.now()
            it[updatedAt] = LocalDateTime.now()
        }
        
        val sanDiegoCountyId = Counties.insertAndGetId {
            it[name] = "San Diego County"
            it[state] = "CA"
            it[createdAt] = LocalDateTime.now()
            it[updatedAt] = LocalDateTime.now()
        }
        
        // Add checklist items for Riverside County
        ChecklistItems.insert {
            it[countyId] = riversideCountyId
            it[title] = "Site Plan"
            it[description] = "Upload site plan drawing showing property boundaries, building locations, and setbacks"
            it[required] = true
            it[orderIndex] = 1
            it[createdAt] = LocalDateTime.now()
            it[updatedAt] = LocalDateTime.now()
        }
        
        ChecklistItems.insert {
            it[countyId] = riversideCountyId
            it[title] = "Building Plans"
            it[description] = "Upload architectural drawings and building plans"
            it[required] = true
            it[orderIndex] = 2
            it[createdAt] = LocalDateTime.now()
            it[updatedAt] = LocalDateTime.now()
        }
        
        ChecklistItems.insert {
            it[countyId] = riversideCountyId
            it[title] = "Structural Calculations"
            it[description] = "Upload structural engineering calculations and analysis"
            it[required] = true
            it[orderIndex] = 3
            it[createdAt] = LocalDateTime.now()
            it[updatedAt] = LocalDateTime.now()
        }
        
        // Add checklist items for San Diego County
        ChecklistItems.insert {
            it[countyId] = sanDiegoCountyId
            it[title] = "Site Plan"
            it[description] = "Upload site plan drawing showing property boundaries, building locations, and setbacks"
            it[required] = true
            it[orderIndex] = 1
            it[createdAt] = LocalDateTime.now()
            it[updatedAt] = LocalDateTime.now()
        }
        
        ChecklistItems.insert {
            it[countyId] = sanDiegoCountyId
            it[title] = "Building Plans"
            it[description] = "Upload architectural drawings and building plans"
            it[required] = true
            it[orderIndex] = 2
            it[createdAt] = LocalDateTime.now()
            it[updatedAt] = LocalDateTime.now()
        }
        
        ChecklistItems.insert {
            it[countyId] = sanDiegoCountyId
            it[title] = "Energy Calculations"
            it[description] = "Upload energy compliance calculations and documentation"
            it[required] = false
            it[orderIndex] = 3
            it[createdAt] = LocalDateTime.now()
            it[updatedAt] = LocalDateTime.now()
        }
        
        ChecklistItems.insert {
            it[countyId] = sanDiegoCountyId
            it[title] = "Fire Safety Plans"
            it[description] = "Upload fire safety and emergency exit plans"
            it[required] = true
            it[orderIndex] = 4
            it[createdAt] = LocalDateTime.now()
            it[updatedAt] = LocalDateTime.now()
        }
        
        println("Added Riverside County and San Diego County with their checklist items")
    }
} 