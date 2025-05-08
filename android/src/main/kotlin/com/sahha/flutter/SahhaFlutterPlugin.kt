package com.sahha.flutter

import android.content.Context
import androidx.activity.ComponentActivity
import androidx.annotation.NonNull
import com.google.gson.Gson
import com.google.gson.GsonBuilder
import com.google.gson.JsonPrimitive
import com.google.gson.JsonSerializer
import io.flutter.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import sdk.sahha.android.source.Sahha
import sdk.sahha.android.source.SahhaBiomarkerCategory
import sdk.sahha.android.source.SahhaBiomarkerType
import sdk.sahha.android.source.SahhaConverterUtility
import sdk.sahha.android.source.SahhaDemographic
import sdk.sahha.android.source.SahhaEnvironment
import sdk.sahha.android.source.SahhaFramework
import sdk.sahha.android.source.SahhaNotificationConfiguration
import sdk.sahha.android.source.SahhaScoreType
import sdk.sahha.android.source.SahhaSensor
import sdk.sahha.android.source.SahhaSettings
import java.time.ZonedDateTime
import java.util.Date

private const val TAG = "SahhaFlutterPlugin"

/** SahhaFlutterPlugin */
class SahhaFlutterPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {

    enum class SahhaMethod {
        configure,
        isAuthenticated,
        authenticate,
        authenticateToken,
        deauthenticate,
        getProfileToken,
        getDemographic,
        postDemographic,
        getSensorStatus,
        enableSensors,
        getScores,
        getBiomarkers,
        getStats,
        getSamples,
        openAppSettings,
        postSensorData,
    }

    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var flutterActivity: ComponentActivity? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "sahha_flutter")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onDetachedFromActivity() {
        Log.d("Sahha", "onDetachedFromActivity")
        flutterActivity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        Log.d("Sahha", "onReattachedToActivityForConfigChanges")
        onAttachedToActivity(binding)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        val componentActivity = binding.activity as ComponentActivity
        Log.d("Sahha", "onAttachedToActivity")
        flutterActivity = if (componentActivity is ComponentActivity) {
            componentActivity
        } else null
    }

    override fun onDetachedFromActivityForConfigChanges() {
        Log.d("Sahha", "onDetachedFromActivityForConfigChanges")
        onDetachedFromActivity()
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        Log.d("Sahha", call.method)

        when (call.method) {
            SahhaMethod.configure.name -> {
                configure(call, result)
            }

            SahhaMethod.isAuthenticated.name -> {
                isAuthenticated(result)
            }

            SahhaMethod.authenticate.name -> {
                authenticate(call, result)
            }

            SahhaMethod.authenticateToken.name -> {
                authenticateToken(call, result)
            }

            SahhaMethod.deauthenticate.name -> {
                deauthenticate(result)
            }

            SahhaMethod.getProfileToken.name -> {
                getProfileToken(result)
            }

            SahhaMethod.getDemographic.name -> {
                getDemographic(result)
            }

            SahhaMethod.postDemographic.name -> {
                postDemographic(call, result)
            }

            SahhaMethod.getSensorStatus.name -> {
                getSensorStatus(call, result)
            }

            SahhaMethod.enableSensors.name -> {
                enableSensors(call, result)
            }

            SahhaMethod.getScores.name -> {
                getScores(call, result)
            }

            SahhaMethod.getBiomarkers.name -> {
                getBiomarkers(call, result)
            }

            SahhaMethod.getStats.name -> {
                getStats(call, result)
            }

            SahhaMethod.getSamples.name -> {
                getSamples(call, result)
            }

            SahhaMethod.postSensorData.name -> {
                postSensorData()
            }

            SahhaMethod.openAppSettings.name -> {
                openAppSettings()
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    fun configure(@NonNull call: MethodCall, @NonNull result: Result) {
        val environment: String? = call.argument<String>("environment")
        val notificationSettings: HashMap<String, String>? =
            call.argument<HashMap<String, String>>("notificationSettings")

        if (environment == null || notificationSettings == null) {
            Sahha.postError(
                SahhaFramework.flutter,
                "SahhaFlutter.configure() parameters invalid",
                "SahhaFlutterPlugin",
                "configure"
            )
            result.error("Sahha Error", "SahhaFlutter.configure() parameters invalid", null)
            return
        }

        if (flutterActivity == null) {
            result.error("Sahha Error", "flutterActivity was null", null)
            return
        }

        try {
            val settings = SahhaSettings(
                framework = SahhaFramework.flutter,
                environment = SahhaEnvironment.valueOf(environment),
                notificationSettings = SahhaNotificationConfiguration(
                    icon = SahhaConverterUtility
                        .stringToDrawableResource(
                            context,
                            notificationSettings["icon"]
                        ),
                    title = notificationSettings["title"],
                    shortDescription = notificationSettings["shortDescription"]
                )
            )

            // null checked above ^^^
            Sahha.configure(flutterActivity!!, settings) { error, success ->
                if (!success) result.error("Sahha Error", error, null)
                result.success(success)
            }
        } catch (e: Exception) {
            result.error("Sahha Error", e.message, e)
        }
    }

    private fun isAuthenticated(@NonNull result: Result) {
        result.success(Sahha.isAuthenticated)
    }

    private fun authenticate(@NonNull call: MethodCall, @NonNull result: Result) {
        Sahha.postError(SahhaFramework.flutter, "TEST", "SahhaFlutterPlugin", "authenticate")

        val appId: String? = call.argument<String>("appId")
        val appSecret: String? = call.argument<String>("appSecret")
        val externalId: String? = call.argument<String>("externalId")

        if (appId != null && appSecret != null && externalId != null) {
            Sahha.authenticate(appId, appSecret, externalId) { error, success ->
                if (!success) {
                    result.error("Sahha Error", error, null)
                    return@authenticate
                }
                result.success(success)
                return@authenticate
            }
        } else {
            Sahha.postError(
                SahhaFramework.flutter,
                "SahhaFlutter.authenticate() parameters invalid",
                "SahhaFlutterPlugin",
                "authenticate",
                "hidden"
            )
            result.error("Sahha Error", "SahhaFlutter.authenticate() parameters invalid", null)
        }
    }

    private fun authenticateToken(@NonNull call: MethodCall, @NonNull result: Result) {
        val profileToken: String? = call.argument<String>("profileToken")
        val refreshToken: String? = call.argument<String>("refreshToken")
        if (profileToken != null && refreshToken != null) {
            Sahha.authenticate(profileToken, refreshToken) { error, success ->
                if (error != null) {
                    result.error("Sahha Error", error, null)
                } else {
                    result.success(success)
                }
            }
        } else {
            Sahha.postError(
                SahhaFramework.flutter,
                "SahhaFlutter.authenticateToken() parameters invalid",
                "SahhaFlutterPlugin",
                "authenticateToken",
                "hidden"
            )
            result.error("Sahha Error", "SahhaFlutter.authenticateToken() parameters invalid", null)
        }
    }

    private fun deauthenticate(@NonNull result: Result) {
        Sahha.deauthenticate() { error, success ->
            if (error != null) {
                result.error("Sahha Error", error, null)
            } else {
                result.success(success)
            }
        }
    }

    private fun getProfileToken(@NonNull result: Result) {
        result.success(Sahha.profileToken)
    }

    private fun getDemographic(@NonNull result: Result) {
        Sahha.getDemographic() { error, demographic ->
            if (error != null) {
                result.error("Sahha Error", error, null)
            } else if (demographic != null) {
                val gson = Gson()
                val demographicJson: String = gson.toJson(demographic)
                Log.d("Sahha", demographicJson)
                result.success(demographicJson)
            } else {
                result.success(null)
            }
        }
    }

    private fun postDemographic(@NonNull call: MethodCall, @NonNull result: Result) {
        val age: Int? = call.argument<Int>("age")
        val gender: String? = call.argument<String>("gender")
        val country: String? = call.argument<String>("country")
        val birthCountry: String? = call.argument<String>("birthCountry")
        val ethnicity: String? = call.argument<String>("ethnicity")
        val occupation: String? = call.argument<String>("occupation")
        val industry: String? = call.argument<String>("industry")
        val incomeRange: String? = call.argument<String>("incomeRange")
        val education: String? = call.argument<String>("education")
        val relationship: String? = call.argument<String>("relationship")
        val locale: String? = call.argument<String>("locale")
        val livingArrangement: String? = call.argument<String>("livingArrangement")
        val birthDate: String? = call.argument<String>("birthDate")
        var sahhaDemographic = SahhaDemographic(
            age,
            gender,
            country,
            birthCountry,
            ethnicity,
            occupation,
            industry,
            incomeRange,
            education,
            relationship,
            locale,
            livingArrangement,
            birthDate
        )

        Sahha.postDemographic(sahhaDemographic) { error, success ->
            if (error != null) {
                result.error("Sahha Error", error, null)
            } else {
                result.success(success)
            }
        }
    }

    private fun getSensorStatus(@NonNull call: MethodCall, @NonNull result: Result) {
        val sensors: List<String>? = call.argument<List<String>>("sensors")
        var sensorsList: Set<SahhaSensor>? = null

        if (sensors != null) {
            try {
                sensorsList = sensors.map { SahhaSensor.valueOf(it) }.toSet()
            } catch (e: Exception) {
                result.error("Sahha Error", e.message, e)
                return
            }
        } else {
            result.error(
                "Sahha Error",
                "SahhaFlutter.getSensorStatus() sensors parameter must not be null",
                null
            )
            return
        }

        Sahha.getSensorStatus(context, sensorsList) { error, sensorStatus ->
            if (error != null) {
                result.error("Sahha Error", error, null)
            } else {
                result.success(sensorStatus.ordinal)
            }
        }
    }

    private fun enableSensors(@NonNull call: MethodCall, @NonNull result: Result) {
        val sensors: List<String>? = call.argument<List<String>>("sensors")
        var sensorsList: Set<SahhaSensor>? = null

        if (sensors != null) {
            try {
                sensorsList = sensors.map { SahhaSensor.valueOf(it) }.toSet()
            } catch (e: Exception) {
                result.error("Sahha Error", e.message, e)
                return
            }
        } else {
            result.error(
                "Sahha Error",
                "SahhaFlutter.enableSensors() sensors parameter must not be null",
                null
            )
            return
        }

        Sahha.enableSensors(context, sensorsList) { error, sensorStatus ->
            if (error != null) {
                result.error("Sahha Error", error, null)
            } else {
                result.success(sensorStatus.ordinal)
            }
        }
    }

    @Deprecated(
        message = "postSensorData is only supported on iOS",
        level = DeprecationLevel.WARNING
    )
    private fun postSensorData() {
        Log.w(TAG, "postSensorData is only supported on iOS")
    }

    private fun openAppSettings() {
        Sahha.openAppSettings(context);
    }

    private fun getScores(@NonNull call: MethodCall, @NonNull result: Result) {
        val codeBody = call.arguments?.toString()

        val types = call.argument<List<String>>("types")
        if (types != null) {
            Log.d("Sahha", "types $types")
        } else {
            Sahha.postError(
                SahhaFramework.flutter,
                "SahhaFlutter.getScores() score types missing",
                "SahhaFlutterPlugin",
                "getScores",
                codeBody
            )
            Log.d("Sahha", "types missing")
        }

        val startDateTime: Long? = call.argument<Long>("startDateTime")
        if (startDateTime != null) {
            Log.d("Sahha", "startDateTime $startDateTime")
        } else {
            Sahha.postError(
                SahhaFramework.flutter,
                "SahhaFlutter.getScores() startDateTime missing",
                "SahhaFlutterPlugin",
                "getScores",
                codeBody
            )
            Log.d("Sahha", "startDateTime missing")
        }

        val endDateTime: Long? = call.argument<Long>("endDateTime")
        if (endDateTime != null) {
            Log.d("Sahha", "endDateTime $endDateTime")
        } else {
            Sahha.postError(
                SahhaFramework.flutter,
                "SahhaFlutter.getScores() endDateTime missing",
                "SahhaFlutterPlugin",
                "getScores",
                codeBody
            )
            Log.d("Sahha", "endDateTime missing")
        }

        if (startDateTime != null && endDateTime != null && types != null) {
            val sahhaScoreTypes = types.map { SahhaScoreType.valueOf(it) }.toSet()
            Sahha.getScores(
                sahhaScoreTypes,
                Pair(Date(startDateTime), Date(endDateTime)),
            ) { error, value ->
                if (error != null) {
                    result.error("Sahha Error", error, null)
                } else if (value != null) {
                    result.success(value)
                } else {
                    Sahha.postError(
                        SahhaFramework.flutter,
                        "SahhaFlutter.getScores() scores missing",
                        "SahhaFlutterPlugin",
                        "getScores",
                        codeBody
                    )
                    result.error("Sahha Error", "Sahha scores not available", null)
                }
            }
        } else {
            Sahha.postError(
                SahhaFramework.flutter,
                "SahhaFlutter.getScores() parameters invalid",
                "SahhaFlutterPlugin",
                "getScores",
                codeBody
            )
            result.error(
                "Sahha Error",
                "SahhaFlutter.getScores() parameters invalid",
                null
            )
        }
    }

    private fun getBiomarkers(@NonNull call: MethodCall, @NonNull result: Result) {
        val codeBody = call.arguments?.toString()
        val categories = call.argument<List<String>>("categories")
        if (categories != null) {
            Log.d("Sahha", "categories $categories")
        } else {
            Sahha.postError(
                SahhaFramework.flutter,
                "SahhaFlutter.getBiomarkers() biomarker categories missing",
                "SahhaFlutterPlugin",
                "getBiomarkers",
                codeBody
            )
            Log.d("Sahha", "categories missing")
        }

        val types = call.argument<List<String>>("types")
        if (types != null) {
            Log.d("Sahha", "types $types")
        } else {
            Sahha.postError(
                SahhaFramework.flutter,
                "SahhaFlutter.getBiomarkers() biomarker types missing",
                "SahhaFlutterPlugin",
                "getBiomarkers",
                codeBody
            )
            Log.d("Sahha", "types missing")
        }

        val startDateTime: Long? = call.argument<Long>("startDateTime")
        if (startDateTime != null) {
            Log.d("Sahha", "startDateTime $startDateTime")
        } else {
            Sahha.postError(
                SahhaFramework.flutter,
                "SahhaFlutter.getBiomarkers() startDateTime missing",
                "SahhaFlutterPlugin",
                "getBiomarkers",
                codeBody
            )
            Log.d("Sahha", "startDateTime missing")
        }

        val endDateTime: Long? = call.argument<Long>("endDateTime")
        if (endDateTime != null) {
            Log.d("Sahha", "endDateTime $endDateTime")
        } else {
            Sahha.postError(
                SahhaFramework.flutter,
                "SahhaFlutter.getBiomarkers() endDateTime missing",
                "SahhaFlutterPlugin",
                "getBiomarkers",
                codeBody
            )
            Log.d("Sahha", "endDateTime missing")
        }

        if (startDateTime != null && endDateTime != null && categories != null && types != null) {
            val biomarkerCategories = categories.map { SahhaBiomarkerCategory.valueOf(it) }.toSet()
            val biomarkerTypes = types.map { SahhaBiomarkerType.valueOf(it) }.toSet()
            Sahha.getBiomarkers(
                biomarkerCategories,
                biomarkerTypes,
                Pair(Date(startDateTime), Date(endDateTime)),
            ) { error, value ->
                if (error != null) {
                    result.error("Sahha Error", error, null)
                } else if (value != null) {
                    result.success(value)
                } else {
                    Sahha.postError(
                        SahhaFramework.flutter,
                        "SahhaFlutter.getBiomarkers() scores missing",
                        "SahhaFlutterPlugin",
                        "getBiomarkers",
                        codeBody
                    )
                    result.error("Sahha Error", "Sahha biomarkers not available", null)
                }
            }
        } else {
            Sahha.postError(
                SahhaFramework.flutter,
                "SahhaFlutter.getBiomarkers() parameters invalid",
                "SahhaFlutterPlugin",
                "getBiomarkers",
                codeBody
            )
            result.error(
                "Sahha Error",
                "SahhaFlutter.getBiomarkers() parameters invalid",
                null
            )
        }
    }

    private fun getStats(@NonNull call: MethodCall, @NonNull result: Result) {
        val codeBody = call.arguments?.toString()
        val sensor: String? = call.argument<String>("sensor")
        if (sensor != null) {
            Log.d("Sahha", "sensor $sensor")
        } else {
            Sahha.postError(
                SahhaFramework.flutter,
                "SahhaFlutter.getStats() sensor missing",
                "SahhaFlutterPlugin",
                "getStats",
                codeBody
            )
            Log.d("Sahha", "sensor missing")
        }

        val startDateTime: Long? = call.argument<Long>("startDateTime")
        if (startDateTime != null) {
            Log.d("Sahha", "startDateTime $startDateTime")
        } else {
            Sahha.postError(
                SahhaFramework.flutter,
                "SahhaFlutter.getStats() startDateTime missing",
                "SahhaFlutterPlugin",
                "getStats",
                codeBody
            )
            Log.d("Sahha", "startDateTime missing")
        }

        val endDateTime: Long? = call.argument<Long>("endDateTime")
        if (endDateTime != null) {
            Log.d("Sahha", "endDatTime $endDateTime")
        } else {
            Sahha.postError(
                SahhaFramework.flutter,
                "SahhaFlutter.getStats() endDateTime missing",
                "SahhaFlutterPlugin",
                "getStats",
                codeBody
            )
            Log.d("Sahha", "endDateTime missing")
        }

        if (sensor != null && startDateTime != null && endDateTime != null) {
            Sahha.getStats(
                SahhaSensor.valueOf(sensor),
                Pair(Date(startDateTime), Date(endDateTime)),
            ) { error, stats ->
                if (error != null) {
                    result.error("Sahha Error", error, null)
                } else if (stats != null) {
                    val gson = GsonBuilder().apply {
                        registerTypeAdapter(
                            ZonedDateTime::class.java,
                            JsonSerializer<ZonedDateTime> { src, _, _ ->
                                JsonPrimitive(src.toString())
                            }
                        )
                    }.create()
                    val statsJson = gson.toJson(stats)
                    result.success(statsJson);
                } else {
                    Sahha.postError(
                        SahhaFramework.flutter,
                        "SahhaFlutter.getStats() stats missing",
                        "SahhaFlutterPlugin",
                        "getStats",
                        codeBody
                    )
                    result.error("Sahha Error", "Sahha stats not available", null)
                }
            }
        } else {
            Sahha.postError(
                SahhaFramework.flutter,
                "SahhaFlutter.getStats() parameters invalid",
                "SahhaFlutterPlugin",
                "getStats",
                codeBody
            )
            result.error(
                "Sahha Error",
                "SahhaFlutter.getStats() parameters invalid",
                null
            )
        }
    }

    private fun getSamples(@NonNull call: MethodCall, @NonNull result: Result) {
        val codeBody = call.arguments?.toString()
        val sensor: String? = call.argument<String>("sensor")
        if (sensor != null) {
            Log.d("Sahha", "sensor $sensor")
        } else {
            Sahha.postError(
                SahhaFramework.flutter,
                "SahhaFlutter.getSamples() sensor missing",
                "SahhaFlutterPlugin",
                "getSamples",
                codeBody
            )
            Log.d("Sahha", "sensor missing")
        }

        val startDateTime: Long? = call.argument<Long>("startDateTime")
        if (startDateTime != null) {
            Log.d("Sahha", "startDate $startDateTime")
        } else {
            Sahha.postError(
                SahhaFramework.flutter,
                "SahhaFlutter.getSamples() startDateTime missing",
                "SahhaFlutterPlugin",
                "getStats",
                codeBody
            )
            Log.d("Sahha", "startDateTime missing")
        }

        val endDateTime: Long? = call.argument<Long>("endDateTime")
        if (endDateTime != null) {
            Log.d("Sahha", "endDateTime $endDateTime")
        } else {
            Sahha.postError(
                SahhaFramework.flutter,
                "SahhaFlutter.getSamples() endDateTime missing",
                "SahhaFlutterPlugin",
                "getSamples",
                codeBody
            )
            Log.d("Sahha", "endDateTime missing")
        }

        if (sensor != null && startDateTime != null && endDateTime != null) {
            Sahha.getSamples(
                SahhaSensor.valueOf(sensor),
                Pair(Date(startDateTime), Date(endDateTime)),
            ) { error, samples ->
                if (error != null) {
                    result.error("Sahha Error", error, null)
                } else if (samples != null) {
                    val gson = GsonBuilder().apply {
                        registerTypeAdapter(
                            ZonedDateTime::class.java,
                            JsonSerializer<ZonedDateTime> { src, _, _ ->
                                JsonPrimitive(src.toString())
                            }
                        )
                    }.create()
                    val samplesJson = gson.toJson(samples)
                    result.success(samplesJson);
                } else {
                    Sahha.postError(
                        SahhaFramework.flutter,
                        "SahhaFlutter.getSamples() stats missing",
                        "SahhaFlutterPlugin",
                        "getSamples",
                        codeBody
                    )
                    result.error("Sahha Error", "Sahha samples not available", null)
                }
            }
        } else {
            Sahha.postError(
                SahhaFramework.flutter,
                "SahhaFlutter.getSamples() parameters invalid",
                "SahhaFlutterPlugin",
                "getSamples",
                codeBody
            )
            result.error(
                "Sahha Error",
                "SahhaFlutter.getSamples() parameters invalid",
                null
            )
        }
    }

}
