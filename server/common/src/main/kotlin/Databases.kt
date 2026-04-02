package io.ktor.chat

import io.r2dbc.spi.ConnectionFactories
import io.r2dbc.spi.ConnectionFactoryOptions
import io.r2dbc.spi.IsolationLevel
import io.r2dbc.spi.Option
import io.ktor.server.config.property
import io.ktor.server.plugins.di.*
import io.ktor.server.application.*                            // ✅ missing
import kotlinx.serialization.Serializable                              // ✅ missing
import org.jetbrains.exposed.v1.r2dbc.SchemaUtils                       // ✅ missing
import org.jetbrains.exposed.v1.r2dbc.R2dbcDatabase
import org.jetbrains.exposed.v1.r2dbc.R2dbcDatabaseConfig
import org.jetbrains.exposed.v1.r2dbc.transactions.suspendTransaction  // ✅ missing
import java.nio.file.Paths                                             // ✅ missing
import java.time.Duration
import kotlin.io.path.exists

fun Application.database() {
    val mode = if (Paths.get("build.gradle.kts").exists().not()) "test" else "main"
    val config = property<DatabaseConfig>("database.$mode")

    log.info("Using database mode: $mode")
    log.info("Using database url: ${config.url}")

    val connectionFactory = if (mode == "test") {
        // H2 in-memory for local/test
        val options = ConnectionFactoryOptions.builder()
            .option(ConnectionFactoryOptions.DRIVER, "h2")
            .option(ConnectionFactoryOptions.PROTOCOL, "mem")
            .option(ConnectionFactoryOptions.DATABASE, "test")
            .option(Option.valueOf("DB_CLOSE_DELAY"), "-1")
            .build()
        ConnectionFactories.get(options)
    } else {
        // PostgreSQL for production (Render internal)
        val options = ConnectionFactoryOptions.builder()
            .option(ConnectionFactoryOptions.DRIVER, "postgresql")
            .option(ConnectionFactoryOptions.HOST, config.url)
            .option(ConnectionFactoryOptions.PORT, 5432)
            .option(ConnectionFactoryOptions.DATABASE, "db_ktor_chat")
            .option(ConnectionFactoryOptions.USER, config.user)
            .option(ConnectionFactoryOptions.PASSWORD, config.password)
            .option(ConnectionFactoryOptions.CONNECT_TIMEOUT, Duration.ofSeconds(60))
            .build()
        ConnectionFactories.get(options)

        
    }

    val db = R2dbcDatabase.connect(
        connectionFactory = connectionFactory,
        databaseConfig = R2dbcDatabaseConfig {
            defaultMaxAttempts = 3
            defaultR2dbcIsolationLevel = IsolationLevel.READ_COMMITTED
        }
    )

    dependencies {
        provide<R2dbcDatabase> {
            db.also {
                suspendTransaction(db) {
                    SchemaUtils.create(Users, Rooms, Messages, Members)
                }
            }
        }
    }
}

@Serializable
data class DatabaseConfig(
    val url: String,
    val user: String,
    val driver: String,
    val password: String
)
