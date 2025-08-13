package com.regnowsnaes.permitmanagementsystem.database

import com.zaxxer.hikari.HikariConfig
import com.zaxxer.hikari.HikariDataSource
import org.jetbrains.exposed.sql.*
import org.jetbrains.exposed.sql.transactions.transaction
import java.time.LocalDateTime
import javax.sql.DataSource

object DatabaseConfig {
    private lateinit var dataSource: DataSource
    
    fun init() {
        // Get database configuration from environment
        val databaseUrl = System.getenv("DATABASE_URL") 
            ?: throw IllegalStateException("DATABASE_URL environment variable is required")
        val dbUser = System.getenv("DB_USER") 
            ?: throw IllegalStateException("DB_USER environment variable is required")
        val dbPassword = System.getenv("DB_PASSWORD") 
            ?: throw IllegalStateException("DB_PASSWORD environment variable is required")
        
        // Configure HikariCP connection pool
        val config = HikariConfig().apply {
            jdbcUrl = databaseUrl
            username = dbUser
            password = dbPassword
            driverClassName = "org.postgresql.Driver"
            
            // Connection pool settings
            maximumPoolSize = System.getenv("DB_POOL_SIZE")?.toIntOrNull() ?: 10
            minimumIdle = 2
            connectionTimeout = System.getenv("DB_CONNECTION_TIMEOUT")?.toLongOrNull() ?: 30000
            idleTimeout = 600000 // 10 minutes
            maxLifetime = 1800000 // 30 minutes
            leakDetectionThreshold = 60000 // 1 minute
            
            // Connection validation
            connectionTestQuery = "SELECT 1"
            validationTimeout = 5000
            
            // Pool name for monitoring
            poolName = "PermitManagementPool"
            
            // Additional PostgreSQL optimizations
            addDataSourceProperty("cachePrepStmts", "true")
            addDataSourceProperty("prepStmtCacheSize", "250")
            addDataSourceProperty("prepStmtCacheSqlLimit", "2048")
            addDataSourceProperty("useServerPrepStmts", "true")
            addDataSourceProperty("useLocalSessionState", "true")
            addDataSourceProperty("rewriteBatchedStatements", "true")
            addDataSourceProperty("cacheResultSetMetadata", "true")
            addDataSourceProperty("cacheServerConfiguration", "true")
            addDataSourceProperty("elideSetAutoCommits", "true")
            addDataSourceProperty("maintainTimeStats", "false")
        }
        
        try {
            dataSource = HikariDataSource(config)
            
            // Connect to database using Exposed
            val database = Database.connect(dataSource)
            
            // Test connection
            transaction(database) {
                exec("SELECT 1") { rs ->
                    if (rs.next()) {
                        println("✅ Database connection test successful")
                    }
                }
            }
            
            // Create tables
            transaction(database) {
                SchemaUtils.create(
                    Users,
                    Counties,
                    ChecklistItems,
                    PermitPackages,
                    PermitDocuments
                    // Advanced admin tables temporarily disabled
                    // AdminUsers,
                    // AdminSessions,
                    // AdminAuditLog,
                    // DocumentUploads
                )
                println("✅ Database tables created/verified")
            }
            
            // Seed initial data if tables are empty
            seedInitialData()
            
        } catch (e: Exception) {
            println("❌ Database initialization failed: ${e.message}")
            throw e
        }
    }
    
    fun getDataSource(): DataSource = dataSource
    
    fun healthCheck(): Boolean {
        return try {
            transaction {
                exec("SELECT 1") { rs -> rs.next() }
            }
            true
        } catch (e: Exception) {
            println("Database health check failed: ${e.message}")
            false
        }
    }
    
    fun getConnectionPoolStats(): Map<String, Any> {
        return if (::dataSource.isInitialized && dataSource is HikariDataSource) {
            val hikariDataSource = dataSource as HikariDataSource
            val poolMXBean = hikariDataSource.hikariPoolMXBean
            
            mapOf(
                "active_connections" to poolMXBean.activeConnections,
                "idle_connections" to poolMXBean.idleConnections,
                "total_connections" to poolMXBean.totalConnections,
                "threads_awaiting_connection" to poolMXBean.threadsAwaitingConnection,
                "pool_name" to (hikariDataSource.poolName ?: "unknown")
            )
        } else {
            mapOf("status" to "not_initialized")
        }
    }
    
    private fun seedInitialData() {
        transaction {
            // Only seed if counties table is empty
            if (Counties.selectAll().count() == 0L) {
                println("🌱 Seeding database with Florida counties and building department checklists...")
                
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

                // Miami-Dade County Checklist (12 items)
                val miamiDadeItems = listOf(
                    "Building Permit Application" to "Complete and submit building permit application with all required information",
                    "Architectural Plans" to "Submit complete architectural drawings stamped by a Florida-licensed architect",
                    "Structural Plans" to "Submit structural engineering plans stamped by a Florida-licensed structural engineer",
                    "Hurricane Impact Analysis" to "Provide hurricane impact analysis and wind load calculations per Florida Building Code",
                    "Flood Zone Compliance" to "Submit flood zone determination and compliance documentation if applicable",
                    "Site Survey" to "Provide current property survey showing existing conditions and proposed improvements",
                    "Zoning Compliance" to "Demonstrate compliance with Miami-Dade County zoning requirements",
                    "Environmental Review" to "Submit environmental impact assessment if required",
                    "Fire Department Review" to "Obtain fire department review and approval for commercial projects",
                    "Utilities Coordination" to "Coordinate with utility companies for service connections and relocations",
                    "Traffic Impact Study" to "Submit traffic impact analysis for projects generating significant traffic",
                    "Final Inspection Checklist" to "Complete all required inspections before certificate of occupancy"
                )

                miamiDadeItems.forEachIndexed { index, (title, description) ->
                    ChecklistItems.insert {
                        it[countyId] = miamiDadeId
                        it[this.title] = title
                        it[this.description] = description
                        it[required] = true
                        it[orderIndex] = index + 1
                        it[createdAt] = now
                        it[updatedAt] = now
                    }
                }

                // Broward County Checklist (10 items)
                val browardItems = listOf(
                    "Property Survey" to "Submit current property survey certified by a Florida-licensed surveyor",
                    "Construction Documents" to "Provide complete construction documents including plans and specifications",
                    "Structural Analysis" to "Submit structural analysis and calculations by licensed engineer",
                    "Fire Safety Plan" to "Develop and submit fire safety and evacuation plans",
                    "Stormwater Management" to "Submit stormwater management plan and drainage calculations",
                    "Building Code Compliance" to "Demonstrate compliance with Florida Building Code requirements",
                    "Accessibility Review" to "Ensure ADA compliance for all public and commercial buildings",
                    "Energy Code Compliance" to "Submit energy efficiency calculations and compliance documentation",
                    "Impact Fee Assessment" to "Calculate and pay required impact fees for new construction",
                    "Certificate of Occupancy" to "Schedule final inspections and obtain certificate of occupancy"
                )

                browardItems.forEachIndexed { index, (title, description) ->
                    ChecklistItems.insert {
                        it[countyId] = browardId
                        it[this.title] = title
                        it[this.description] = description
                        it[required] = true
                        it[orderIndex] = index + 1
                        it[createdAt] = now
                        it[updatedAt] = now
                    }
                }

                // Palm Beach County Checklist (8 items)
                val palmBeachItems = listOf(
                    "Zoning Compliance Review" to "Verify compliance with Palm Beach County zoning ordinances",
                    "Environmental Permits" to "Obtain required environmental permits and clearances",
                    "Coastal Construction" to "Submit coastal construction control line permits if applicable",
                    "Tree Preservation" to "Submit tree survey and preservation plan as required",
                    "Drainage Plan" to "Provide site drainage plan and stormwater calculations",
                    "Building Plans Review" to "Submit building plans for county review and approval",
                    "Impact Studies" to "Complete required traffic and utility impact studies",
                    "Final Approvals" to "Obtain all final approvals and certificates before occupancy"
                )

                palmBeachItems.forEachIndexed { index, (title, description) ->
                    ChecklistItems.insert {
                        it[countyId] = palmBeachId
                        it[this.title] = title
                        it[this.description] = description
                        it[required] = true
                        it[orderIndex] = index + 1
                        it[createdAt] = now
                        it[updatedAt] = now
                    }
                }

                // Orange County Checklist (8 items)
                val orangeItems = listOf(
                    "Site Development Plan" to "Submit site development plan showing all improvements and utilities",
                    "Building Plan Review" to "Provide architectural and engineering plans for county review",
                    "Utilities Review" to "Coordinate with utility providers for service availability and connections",
                    "Transportation Review" to "Submit transportation impact analysis for applicable projects",
                    "Environmental Review" to "Complete environmental review and obtain necessary permits",
                    "Fire Safety Review" to "Obtain fire department review and approval of safety systems",
                    "Code Compliance" to "Demonstrate compliance with Orange County building codes",
                    "Occupancy Permit" to "Schedule inspections and obtain certificate of occupancy"
                )

                orangeItems.forEachIndexed { index, (title, description) ->
                    ChecklistItems.insert {
                        it[countyId] = orangeId
                        it[this.title] = title
                        it[this.description] = description
                        it[required] = true
                        it[orderIndex] = index + 1
                        it[createdAt] = now
                        it[updatedAt] = now
                    }
                }

                // Hillsborough County Checklist (7 items)
                val hillsboroughItems = listOf(
                    "Development Review" to "Submit development plans for county review and approval",
                    "Building Permit" to "Apply for and obtain building permit before construction",
                    "Flood Compliance" to "Verify flood zone compliance and obtain required certifications",
                    "Utility Coordination" to "Coordinate with Tampa Electric and other utilities",
                    "Transportation Impact" to "Submit transportation impact study if required",
                    "Environmental Clearance" to "Obtain environmental clearances and permits",
                    "Final Inspection" to "Complete all inspections and obtain certificate of occupancy"
                )

                hillsboroughItems.forEachIndexed { index, (title, description) ->
                    ChecklistItems.insert {
                        it[countyId] = hillsboroughId
                        it[this.title] = title
                        it[this.description] = description
                        it[required] = true
                        it[orderIndex] = index + 1
                        it[createdAt] = now
                        it[updatedAt] = now
                    }
                }

                // Pinellas County Checklist (7 items)
                val pinellasItems = listOf(
                    "Coastal Compliance" to "Ensure compliance with coastal construction requirements",
                    "Building Code Review" to "Submit plans for building code compliance review",
                    "Environmental Review" to "Complete environmental impact assessment",
                    "Stormwater Management" to "Submit stormwater management and drainage plans",
                    "Utility Services" to "Coordinate utility services and connections",
                    "Safety Inspections" to "Schedule and complete all required safety inspections",
                    "Occupancy Certificate" to "Obtain certificate of occupancy after final approvals"
                )

                pinellasItems.forEachIndexed { index, (title, description) ->
                    ChecklistItems.insert {
                        it[countyId] = pinellasId
                        it[this.title] = title
                        it[this.description] = description
                        it[required] = true
                        it[orderIndex] = index + 1
                        it[createdAt] = now
                        it[updatedAt] = now
                    }
                }

                val totalItems = miamiDadeItems.size + browardItems.size + palmBeachItems.size + 
                               orangeItems.size + hillsboroughItems.size + pinellasItems.size
                println("✅ Successfully seeded database with $totalItems checklist items across 6 Florida counties")
            } else {
                println("✅ Database already contains seed data")
            }
        }
    }
} 