package com.regnowsnaes.permitmanagementsystem.routes

import com.regnowsnaes.permitmanagementsystem.database.ChecklistItems
import com.regnowsnaes.permitmanagementsystem.database.Counties
import com.regnowsnaes.permitmanagementsystem.models.ChecklistItem
import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.request.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import kotlinx.serialization.Serializable
import org.jetbrains.exposed.sql.*
import org.jetbrains.exposed.sql.SqlExpressionBuilder.eq
import org.jetbrains.exposed.sql.transactions.transaction
import java.time.LocalDateTime

@Serializable
data class CreateChecklistItemRequest(
    val title: String,
    val description: String,
    val required: Boolean = true,
    val orderIndex: Int? = null
)

@Serializable
data class UpdateChecklistItemRequest(
    val title: String? = null,
    val description: String? = null,
    val required: Boolean? = null,
    val orderIndex: Int? = null
)

fun Application.configureChecklistRoutes() {
    routing {
        
        // Get all checklist items for a county
        get("/counties/{countyId}/checklist") {
            val countyId = call.parameters["countyId"]?.toIntOrNull()
            if (countyId == null) {
                call.respond(HttpStatusCode.BadRequest, mapOf("error" to "Invalid county ID"))
                return@get
            }

            try {
                val checklistItems = transaction {
                    // Verify county exists
                    val countyExists = Counties.select { Counties.id eq countyId }.count() > 0
                    if (!countyExists) {
                        return@transaction null
                    }

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

                if (checklistItems == null) {
                    call.respond(HttpStatusCode.NotFound, mapOf("error" to "County not found"))
                } else {
                    call.respond(HttpStatusCode.OK, checklistItems)
                }
            } catch (e: Exception) {
                call.application.log.error("Error fetching checklist items", e)
                call.respond(HttpStatusCode.InternalServerError, mapOf("error" to "Failed to fetch checklist items"))
            }
        }

        // Add a new checklist item to a county
        post("/counties/{countyId}/checklist") {
            val countyId = call.parameters["countyId"]?.toIntOrNull()
            if (countyId == null) {
                call.respond(HttpStatusCode.BadRequest, mapOf("error" to "Invalid county ID"))
                return@post
            }

            try {
                val request = call.receive<CreateChecklistItemRequest>()
                
                val newItem = transaction {
                    // Verify county exists
                    val countyExists = Counties.select { Counties.id eq countyId }.count() > 0
                    if (!countyExists) {
                        return@transaction null
                    }

                    // Get the next order index if not provided
                    val nextOrderIndex = request.orderIndex ?: run {
                        val maxOrder = ChecklistItems.select { ChecklistItems.countyId eq countyId }
                            .maxByOrNull { it[ChecklistItems.orderIndex] }
                            ?.get(ChecklistItems.orderIndex) ?: 0
                        maxOrder + 1
                    }

                    // Insert the new checklist item
                    val insertedId = ChecklistItems.insertAndGetId {
                        it[ChecklistItems.countyId] = countyId
                        it[title] = request.title
                        it[description] = request.description
                        it[required] = request.required
                        it[orderIndex] = nextOrderIndex
                        it[createdAt] = LocalDateTime.now()
                        it[updatedAt] = LocalDateTime.now()
                    }

                    // Return the created item
                    ChecklistItems.select { ChecklistItems.id eq insertedId }
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
                        }.first()
                }

                if (newItem == null) {
                    call.respond(HttpStatusCode.NotFound, mapOf("error" to "County not found"))
                } else {
                    call.respond(HttpStatusCode.Created, newItem)
                }
            } catch (e: Exception) {
                call.application.log.error("Error creating checklist item", e)
                call.respond(HttpStatusCode.InternalServerError, mapOf("error" to "Failed to create checklist item"))
            }
        }

        // Update a checklist item
        put("/counties/{countyId}/checklist/{itemId}") {
            val countyId = call.parameters["countyId"]?.toIntOrNull()
            val itemId = call.parameters["itemId"]?.toIntOrNull()
            
            if (countyId == null || itemId == null) {
                call.respond(HttpStatusCode.BadRequest, mapOf("error" to "Invalid county ID or item ID"))
                return@put
            }

            try {
                val request = call.receive<UpdateChecklistItemRequest>()
                
                val updatedItem = transaction {
                    // Verify the item exists and belongs to the county
                    val existingItem = ChecklistItems.select { 
                        (ChecklistItems.id eq itemId) and (ChecklistItems.countyId eq countyId) 
                    }.singleOrNull()
                    
                    if (existingItem == null) {
                        return@transaction null
                    }

                    // Update the item
                    ChecklistItems.update({ ChecklistItems.id eq itemId }) {
                        request.title?.let { title -> it[ChecklistItems.title] = title }
                        request.description?.let { description -> it[ChecklistItems.description] = description }
                        request.required?.let { required -> it[ChecklistItems.required] = required }
                        request.orderIndex?.let { orderIndex -> it[ChecklistItems.orderIndex] = orderIndex }
                        it[updatedAt] = LocalDateTime.now()
                    }

                    // Return the updated item
                    ChecklistItems.select { ChecklistItems.id eq itemId }
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
                        }.first()
                }

                if (updatedItem == null) {
                    call.respond(HttpStatusCode.NotFound, mapOf("error" to "Checklist item not found"))
                } else {
                    call.respond(HttpStatusCode.OK, updatedItem)
                }
            } catch (e: Exception) {
                call.application.log.error("Error updating checklist item", e)
                call.respond(HttpStatusCode.InternalServerError, mapOf("error" to "Failed to update checklist item"))
            }
        }

        // Delete a checklist item
        delete("/counties/{countyId}/checklist/{itemId}") {
            val countyId = call.parameters["countyId"]?.toIntOrNull()
            val itemId = call.parameters["itemId"]?.toIntOrNull()
            
            if (countyId == null || itemId == null) {
                call.respond(HttpStatusCode.BadRequest, mapOf("error" to "Invalid county ID or item ID"))
                return@delete
            }

            try {
                val deleted = transaction {
                    // Verify the item exists and belongs to the county
                    val existingItem = ChecklistItems.select { 
                        (ChecklistItems.id eq itemId) and (ChecklistItems.countyId eq countyId) 
                    }.singleOrNull()
                    
                    if (existingItem == null) {
                        return@transaction false
                    }

                    // Delete the item
                    ChecklistItems.deleteWhere { ChecklistItems.id eq itemId } > 0
                }

                if (deleted) {
                    call.respond(HttpStatusCode.OK, mapOf("message" to "Checklist item deleted successfully"))
                } else {
                    call.respond(HttpStatusCode.NotFound, mapOf("error" to "Checklist item not found"))
                }
            } catch (e: Exception) {
                call.application.log.error("Error deleting checklist item", e)
                call.respond(HttpStatusCode.InternalServerError, mapOf("error" to "Failed to delete checklist item"))
            }
        }

        // Reorder checklist items
        put("/counties/{countyId}/checklist/reorder") {
            val countyId = call.parameters["countyId"]?.toIntOrNull()
            if (countyId == null) {
                call.respond(HttpStatusCode.BadRequest, mapOf("error" to "Invalid county ID"))
                return@put
            }

            try {
                @Serializable
                data class ReorderRequest(val itemIds: List<Int>)
                
                val request = call.receive<ReorderRequest>()
                
                val success = transaction {
                    // Verify all items belong to the county
                    val existingItems = ChecklistItems.select { ChecklistItems.countyId eq countyId }
                        .map { it[ChecklistItems.id].value }
                        .toSet()
                    
                    if (!existingItems.containsAll(request.itemIds)) {
                        return@transaction false
                    }

                    // Update order indices
                    request.itemIds.forEachIndexed { index, itemId ->
                        ChecklistItems.update({ ChecklistItems.id eq itemId }) {
                            it[orderIndex] = index + 1
                            it[updatedAt] = LocalDateTime.now()
                        }
                    }
                    
                    true
                }

                if (success) {
                    call.respond(HttpStatusCode.OK, mapOf("message" to "Checklist items reordered successfully"))
                } else {
                    call.respond(HttpStatusCode.BadRequest, mapOf("error" to "Invalid item IDs"))
                }
            } catch (e: Exception) {
                call.application.log.error("Error reordering checklist items", e)
                call.respond(HttpStatusCode.InternalServerError, mapOf("error" to "Failed to reorder checklist items"))
            }
        }
    }
}
