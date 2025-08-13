package com.regnowsnaes.permitmanagementsystem.database

import com.regnowsnaes.permitmanagementsystem.models.*
import org.jetbrains.exposed.sql.*
import org.jetbrains.exposed.sql.transactions.transaction
import java.time.LocalDateTime

object DatabaseSeeder {
    fun seedDatabase() {
        transaction {
            // Check if data already exists
            if (Counties.selectAll().count() > 0) {
                println("Database already seeded, skipping...")
                return@transaction
            }

            println("Seeding database with Florida counties and building department checklists...")

            val now = LocalDateTime.now()

            // Insert Florida Counties
            val miamiDadeId = Counties.insertAndGetId {
                it[name] = "Miami-Dade County"
                it[state] = "FL"
                it[createdAt] = now
                it[updatedAt] = now
            }

            val browardId = Counties.insertAndGetId {
                it[name] = "Broward County"
                it[state] = "FL"
                it[createdAt] = now
                it[updatedAt] = now
            }

            val palmBeachId = Counties.insertAndGetId {
                it[name] = "Palm Beach County"
                it[state] = "FL"
                it[createdAt] = now
                it[updatedAt] = now
            }

            val orangeId = Counties.insertAndGetId {
                it[name] = "Orange County"
                it[state] = "FL"
                it[createdAt] = now
                it[updatedAt] = now
            }

            val hillsboroughId = Counties.insertAndGetId {
                it[name] = "Hillsborough County"
                it[state] = "FL"
                it[createdAt] = now
                it[updatedAt] = now
            }

            val pinellasId = Counties.insertAndGetId {
                it[name] = "Pinellas County"
                it[state] = "FL"
                it[createdAt] = now
                it[updatedAt] = now
            }

            // Miami-Dade County Building Department Checklist
            val miamiDadeChecklist = listOf(
                ChecklistItemData("Building Permit Application", "Complete Miami-Dade County building permit application form", true, 1),
                ChecklistItemData("Site Plan", "Detailed site plan showing property boundaries, setbacks, and building location", true, 2),
                ChecklistItemData("Architectural Plans", "Complete architectural drawings stamped by Florida licensed architect", true, 3),
                ChecklistItemData("Structural Plans", "Structural drawings and calculations stamped by Florida licensed engineer", true, 4),
                ChecklistItemData("Electrical Plans", "Electrical plans and load calculations", true, 5),
                ChecklistItemData("Plumbing Plans", "Plumbing plans and fixture schedules", true, 6),
                ChecklistItemData("Mechanical Plans", "HVAC plans and load calculations", true, 7),
                ChecklistItemData("Energy Code Compliance", "Florida Energy Code compliance documentation", true, 8),
                ChecklistItemData("Hurricane Impact Analysis", "Wind load analysis and hurricane impact documentation", true, 9),
                ChecklistItemData("Flood Zone Compliance", "FEMA flood zone documentation and elevation certificates", false, 10),
                ChecklistItemData("Environmental Review", "Environmental impact assessment if required", false, 11),
                ChecklistItemData("Traffic Impact Study", "Traffic analysis for large developments", false, 12)
            )

            // Broward County Building Department Checklist
            val browardChecklist = listOf(
                ChecklistItemData("Permit Application", "Broward County building permit application", true, 1),
                ChecklistItemData("Property Survey", "Current property survey by Florida licensed surveyor", true, 2),
                ChecklistItemData("Construction Documents", "Complete construction documents stamped by licensed professionals", true, 3),
                ChecklistItemData("Structural Analysis", "Structural engineering analysis for wind and seismic loads", true, 4),
                ChecklistItemData("Fire Safety Plan", "Fire safety and egress plans", true, 5),
                ChecklistItemData("Accessibility Compliance", "ADA compliance documentation", true, 6),
                ChecklistItemData("Stormwater Management", "Stormwater management and drainage plans", true, 7),
                ChecklistItemData("Landscape Plans", "Landscape and tree preservation plans", false, 8),
                ChecklistItemData("Parking Analysis", "Parking requirement analysis and layout", false, 9),
                ChecklistItemData("Utility Coordination", "Utility company coordination letters", false, 10)
            )

            // Palm Beach County Building Department Checklist
            val palmBeachChecklist = listOf(
                ChecklistItemData("Building Application", "Palm Beach County building permit application", true, 1),
                ChecklistItemData("Zoning Compliance", "Zoning compliance verification letter", true, 2),
                ChecklistItemData("Construction Plans", "Complete construction plans by licensed professionals", true, 3),
                ChecklistItemData("Engineering Reports", "Structural and civil engineering reports", true, 4),
                ChecklistItemData("Environmental Permits", "Environmental resource permits if applicable", true, 5),
                ChecklistItemData("Coastal Construction", "Coastal construction control line permits if applicable", false, 6),
                ChecklistItemData("Tree Removal Permits", "Tree removal and replacement permits", false, 7),
                ChecklistItemData("Historic Preservation", "Historic preservation review if in historic district", false, 8)
            )

            // Orange County (Orlando) Building Department Checklist
            val orangeChecklist = listOf(
                ChecklistItemData("Permit Application", "Orange County building permit application", true, 1),
                ChecklistItemData("Site Development", "Site development plans and engineering", true, 2),
                ChecklistItemData("Building Plans", "Architectural and engineering plans", true, 3),
                ChecklistItemData("Code Compliance", "Florida Building Code compliance documentation", true, 4),
                ChecklistItemData("Fire Department Review", "Fire department plan review and approval", true, 5),
                ChecklistItemData("Utilities Review", "Public utilities review and approval", true, 6),
                ChecklistItemData("Transportation Review", "Transportation impact analysis", false, 7),
                ChecklistItemData("Wetlands Delineation", "Wetlands survey and delineation if applicable", false, 8)
            )

            // Hillsborough County (Tampa) Building Department Checklist
            val hillsboroughChecklist = listOf(
                ChecklistItemData("Building Permit", "Hillsborough County building permit application", true, 1),
                ChecklistItemData("Development Review", "Development review committee approval", true, 2),
                ChecklistItemData("Construction Documents", "Complete stamped construction documents", true, 3),
                ChecklistItemData("Structural Review", "Structural engineering review for Florida conditions", true, 4),
                ChecklistItemData("Flood Compliance", "Flood zone compliance and elevation requirements", true, 5),
                ChecklistItemData("Concurrency Review", "Transportation and utility concurrency review", false, 6),
                ChecklistItemData("Landscaping Plans", "Landscape architecture plans and tree survey", false, 7)
            )

            // Pinellas County Building Department Checklist
            val pinellasChecklist = listOf(
                ChecklistItemData("Permit Application", "Pinellas County building permit application", true, 1),
                ChecklistItemData("Site Plan Review", "Site plan review and approval", true, 2),
                ChecklistItemData("Building Code Review", "Florida Building Code plan review", true, 3),
                ChecklistItemData("Structural Plans", "Structural plans for hurricane wind loads", true, 4),
                ChecklistItemData("Coastal Compliance", "Coastal high hazard area compliance", true, 5),
                ChecklistItemData("Environmental Review", "Environmental development review", false, 6),
                ChecklistItemData("Archaeological Survey", "Archaeological survey if in sensitive area", false, 7)
            )

            // Insert checklist items for each county
            insertChecklistItems(miamiDadeId.value, miamiDadeChecklist, now)
            insertChecklistItems(browardId.value, browardChecklist, now)
            insertChecklistItems(palmBeachId.value, palmBeachChecklist, now)
            insertChecklistItems(orangeId.value, orangeChecklist, now)
            insertChecklistItems(hillsboroughId.value, hillsboroughChecklist, now)
            insertChecklistItems(pinellasId.value, pinellasChecklist, now)

            println("Database seeded successfully with ${Counties.selectAll().count()} Florida counties")
            println("Total checklist items: ${ChecklistItems.selectAll().count()}")
        }
    }

    private fun insertChecklistItems(countyId: Int, items: List<ChecklistItemData>, timestamp: LocalDateTime) {
        items.forEach { item ->
            ChecklistItems.insert {
                it[ChecklistItems.countyId] = countyId
                it[title] = item.title
                it[description] = item.description
                it[required] = item.required
                it[orderIndex] = item.orderIndex
                it[createdAt] = timestamp
                it[updatedAt] = timestamp
            }
        }
    }

    private data class ChecklistItemData(
        val title: String,
        val description: String,
        val required: Boolean,
        val orderIndex: Int
    )
}
