package com.regnowsnaes.permitmanagementsystem.services

import at.favre.lib.crypto.bcrypt.BCrypt
import com.regnowsnaes.permitmanagementsystem.database.Users
import com.regnowsnaes.permitmanagementsystem.models.User
import com.auth0.jwt.JWT
import com.auth0.jwt.algorithms.Algorithm
import com.auth0.jwt.exceptions.JWTVerificationException
import org.jetbrains.exposed.sql.*
import org.jetbrains.exposed.sql.SqlExpressionBuilder.eq
import org.jetbrains.exposed.sql.transactions.transaction
import java.time.LocalDateTime
import java.util.*

object AuthService {
    private val jwtSecret = System.getenv("JWT_SECRET") ?: "your-secret-key-change-in-production"
    private val algorithm = Algorithm.HMAC256(jwtSecret)
    
    fun register(email: String, password: String, firstName: String, lastName: String): User {
        return transaction {
            // Check if user already exists
            val existingUser = Users.select { Users.email eq email }.singleOrNull()
            if (existingUser != null) {
                throw IllegalArgumentException("User with this email already exists")
            }
            
            // Hash password
            val hashedPassword = BCrypt.withDefaults().hashToString(12, password.toCharArray())
            
            // Create user
            val userId = Users.insertAndGetId {
                it[Users.email] = email
                it[Users.password] = hashedPassword
                it[Users.firstName] = firstName
                it[Users.lastName] = lastName
                it[Users.role] = "user"
                it[Users.createdAt] = LocalDateTime.now()
                it[Users.updatedAt] = LocalDateTime.now()
            }
            
            // Return user without password
            User(
                id = userId.value,
                email = email,
                firstName = firstName,
                lastName = lastName,
                role = "user",
                createdAt = LocalDateTime.now(),
                updatedAt = LocalDateTime.now()
            )
        }
    }
    
    fun login(email: String, password: String): User {
        return transaction {
            val userRow = Users.select { Users.email eq email }.singleOrNull()
                ?: throw IllegalArgumentException("Invalid email or password")
            
            val hashedPassword = userRow[Users.password]
            val passwordVerified = BCrypt.verifyer().verify(password.toCharArray(), hashedPassword)
            
            if (!passwordVerified.verified) {
                throw IllegalArgumentException("Invalid email or password")
            }
            
            User(
                id = userRow[Users.id].value,
                email = userRow[Users.email],
                firstName = userRow[Users.firstName],
                lastName = userRow[Users.lastName],
                role = userRow[Users.role],
                createdAt = userRow[Users.createdAt],
                updatedAt = userRow[Users.updatedAt]
            )
        }
    }
    
    fun generateToken(user: User): String {
        return JWT.create()
            .withSubject(user.id.toString())
            .withClaim("userId", user.id)
            .withClaim("email", user.email)
            .withClaim("firstName", user.firstName)
            .withClaim("lastName", user.lastName)
            .withClaim("role", user.role)
            .withIssuedAt(Date())
            .withExpiresAt(Date(System.currentTimeMillis() + 24 * 60 * 60 * 1000)) // 24 hours
            .sign(algorithm)
    }
    
    fun validateToken(token: String): User? {
        return try {
            val verifier = JWT.require(algorithm).build()
            val decodedJWT = verifier.verify(token)
            
            val userId = decodedJWT.getClaim("userId").asInt()
            val email = decodedJWT.getClaim("email").asString()
            val firstName = decodedJWT.getClaim("firstName").asString()
            val lastName = decodedJWT.getClaim("lastName").asString()
            val role = decodedJWT.getClaim("role").asString() ?: "user"
            
            User(
                id = userId,
                email = email,
                firstName = firstName,
                lastName = lastName,
                role = role
            )
        } catch (e: JWTVerificationException) {
            null
        }
    }
    
    fun getUserById(userId: Int): User? {
        return transaction {
            val userRow = Users.select { Users.id eq userId }.singleOrNull()
            userRow?.let {
                User(
                    id = it[Users.id].value,
                    email = it[Users.email],
                    firstName = it[Users.firstName],
                    lastName = it[Users.lastName],
                    role = it[Users.role],
                    createdAt = it[Users.createdAt],
                    updatedAt = it[Users.updatedAt]
                )
            }
        }
    }
    
    fun updateUserRole(userId: Int, newRole: String): User? {
        return transaction {
            val updated = Users.update({ Users.id eq userId }) {
                it[role] = newRole
                it[updatedAt] = LocalDateTime.now()
            }
            
            if (updated > 0) {
                getUserById(userId)
            } else {
                null
            }
        }
    }
    
    fun isAdmin(user: User): Boolean {
        return user.role == "admin"
    }
    
    fun getAllUsers(): List<User> {
        return transaction {
            Users.selectAll().map { row ->
                User(
                    id = row[Users.id].value,
                    email = row[Users.email],
                    firstName = row[Users.firstName],
                    lastName = row[Users.lastName],
                    role = row[Users.role],
                    createdAt = row[Users.createdAt],
                    updatedAt = row[Users.updatedAt]
                )
            }
        }
    }
    
    fun deleteUser(userId: Int): Boolean {
        return transaction {
            val deleted = Users.deleteWhere { Users.id eq userId }
            deleted > 0
        }
    }
}
