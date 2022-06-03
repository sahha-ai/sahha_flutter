package com.sahha.flutter

import android.app.Activity
import android.app.ActivityManager
import android.app.Application
import android.content.Context
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.annotation.NonNull
import com.google.gson.Gson
import io.flutter.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.android.FlutterFragmentActivity;
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import sdk.sahha.android.source.*
import java.util.*

/** SahhaFlutterPlugin */
class SahhaFlutterPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {

  enum class SahhaMethod {
    configure,
    authenticate,
    getDemographic,
    postDemographic,
    getSensorStatus,
    enableSensor,
    postSensorData,
    analyze,
    openAppSettings
  }

  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel: MethodChannel
  private lateinit var context: Context
  private var flutterActivity: Activity? = null

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
    Log.d("Sahha", "onAttachedToActivity")
    flutterActivity = binding.activity
  }

  override fun onDetachedFromActivityForConfigChanges() {
    Log.d("Sahha", "onDetachedFromActivityForConfigChanges")
    onDetachedFromActivity()
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    Log.d("Sahha", "method")

    when (call.method) {
      SahhaMethod.configure.name -> {configure(call, result)}
      SahhaMethod.authenticate.name -> {authenticate(call, result)}
      SahhaMethod.getDemographic.name -> {getDemographic(call, result)}
      SahhaMethod.postDemographic.name -> {postDemographic(call, result)}
      SahhaMethod.getSensorStatus.name -> {getSensorStatus(call, result)}
      SahhaMethod.enableSensor.name -> {enableSensor(call, result)}
      SahhaMethod.postSensorData.name -> {postSensorData(call, result)}
      SahhaMethod.analyze.name -> {analyze(call, result)}
      SahhaMethod.openAppSettings.name -> {openAppSettings(call, result)}
      else -> { result.notImplemented() }
    }
  }

  fun configure(@NonNull call: MethodCall, @NonNull result: Result) {

    val environment: String? = call.argument<String>("environment")
    val sensors: List<String>? = call.argument<List<String>>("sensors")
    var postSensorDataManually: Boolean? = call.argument<Boolean>("postSensorDataManually")

    if (environment == null || sensors == null || postSensorDataManually == null) {
      result.error("Sahha Error", "SahhaFlutter.configure() parameters are not valid", null)
      return
    }

    var sahhaEnvironment: SahhaEnvironment
    try {
      sahhaEnvironment = SahhaEnvironment.valueOf(environment)
    } catch (e: IllegalArgumentException) {
      result.error(
        "Sahha Error",
        "SahhaFlutter.configure() environment parameter is not valid",
        null
      )
      return
    }

    var sahhaSensors: MutableSet<SahhaSensor> = mutableSetOf()
    try {
      sensors.forEach {
        var sensor = SahhaSensor.valueOf(it)
        sahhaSensors.add(sensor)
      }
    } catch (e: IllegalArgumentException) {
      result.error("Sahha Error", "SahhaFlutter.configure() sensor parameter is not valid", null)
      return
    }

    var sahhaSettings = SahhaSettings(
      sahhaEnvironment,
      SahhaFramework.flutter,
      sahhaSensors,
      postSensorDataManually
    )

    try {
      var app = flutterActivity?.application
      if (app != null) {
        Log.d("Sahha", "Application is OK")
        Sahha.configure(app, sahhaSettings)
        result.success(true)
      } else {
        Log.e("Sahha", "Application is null")
      }
    } catch (e: IllegalArgumentException) {
      Log.e("Sahha", e.message ?: "Activity error")
      result.error("Sahha Error", "SahhaFlutter.configure() Android activity is not valid", null)
    }
  }

  private fun authenticate(@NonNull call: MethodCall, @NonNull result: Result) {
    val profileToken: String? = call.argument<String>("profileToken")
    val refreshToken: String? = call.argument<String>("refreshToken")
    if (profileToken == null || refreshToken == null) {
      result.error("Sahha Error", "SahhaFlutter.authenticate() parameters are not valid", null)
      return
    }
    Sahha.authenticate(profileToken, refreshToken) { error, success ->
      if (error != null) {
        result.error("Sahha Error", error, null)
      } else {
        result.success(success)
      }
    }
  }

  private fun getDemographic(@NonNull call: MethodCall, @NonNull result: Result) {
    Sahha.getDemographic() { error, demographic ->
      if (error != null) {
        result.error("Sahha Error", error, null)
      } else if (demographic != null) {
        val gson = Gson()
        val demographicJson: String = gson.toJson(demographic)
        Log.d("Sahha", demographicJson)
        result.success(demographicJson)
      } else {
        result.error("Sahha Error", "Sahha Demographic not available", null)
      }
    }
  }

  private fun postDemographic(@NonNull call: MethodCall, @NonNull result: Result) {
    val age: Int? = call.argument<Int>("age")
    val gender: String? = call.argument<String>("gender")
    val country: String? = call.argument<String>("country")
    val birthCountry: String? = call.argument<String>("birthCountry")

    var demographic = SahhaDemographic(age, gender, country, birthCountry)
    Sahha.postDemographic(demographic) { error, success ->
      if (error != null) {
        result.error("Sahha Error", error, null)
      } else {
        result.success(success)
      }
    }
  }

  private fun getSensorStatus(@NonNull call: MethodCall, @NonNull result: Result) {

    var sensorName: String? = call.argument<String>("sensor")

    if (sensorName == null) {
      result.error("Sahha Error", "SahhaFlutter sensor parameter is missing", null)
      return
    }
    try {
      var sahhaSensor = SahhaSensor.valueOf(sensorName)
      Sahha.getSensorStatus(context, sahhaSensor) { error, sensorStatus ->
        if (error != null) {
          result.error("Sahha Error", error, null)
        } else {
          result.success(sensorStatus.ordinal)
        }
      }
    } catch (e: IllegalArgumentException) {
      result.error("Sahha Error", "SahhaFlutter sensor parameter is not valid", null)
    }
  }

  private fun enableSensor(@NonNull call: MethodCall, @NonNull result: Result) {

    var sensorName: String? = call.argument<String>("sensor")

    if (sensorName == null) {
      result.error("Sahha Error", "SahhaFlutter sensor parameter is missing", null)
      return
    }
    try {
      var sahhaSensor = SahhaSensor.valueOf(sensorName)
      Sahha.enableSensor(context, sahhaSensor) { error, sensorStatus ->
        if (error != null) {
          result.error("Sahha Error", error, null)
        } else {
          result.success(sensorStatus.ordinal)
        }
      }
    } catch (e: IllegalArgumentException) {
      result.error("Sahha Error", "SahhaFlutter sensor parameter is not valid", null)
    }
  }

  private fun postSensorData(@NonNull call: MethodCall, @NonNull result: Result) {

    val sensors: List<String>? = call.argument<List<String>>("sensors")
    var sahhaSensors: MutableSet<SahhaSensor>?
    if (sensors == null) {
      Sahha.postSensorData { error, success ->
        if (error != null) {
          result.error("Sahha Error", error, null)
        } else {
          result.success(success)
        }
      }
    } else {
      sahhaSensors = mutableSetOf()
      try {
        sensors.forEach {
          var sensor = SahhaSensor.valueOf(it)
          sahhaSensors.add(sensor)
        }
      } catch (e: IllegalArgumentException) {
        result.error("Sahha Error", "SahhaFlutter.postSensorData() sensor parameter is not valid", null)
        return
      }

      Sahha.postSensorData(sahhaSensors) { error, success ->
        if (error != null) {
          result.error("Sahha Error", error, null)
        } else {
          result.success(success)
        }
      }
    }
  }

  private fun analyze(@NonNull call: MethodCall, @NonNull result: Result) {

    val startDate: Long? = call.argument<Long>("startDate")
    if (startDate != null) {
      Log.d("Sahha", "startDate $startDate")
    } else {
      Log.d("Sahha", "startDate missing")
    }

    val endDate: Long? = call.argument<Long>("endDate")
    if (endDate != null) {
      Log.d("Sahha", "endDate $endDate")
    } else {
      Log.d("Sahha", "endDate missing")
    }

    if (startDate != null && endDate != null) {
      Sahha.analyze(Pair(Date(startDate), Date(endDate))) { error, value ->
        if (error != null) {
          result.error("Sahha Error", error, null)
        } else if (value != null) {
          result.success(value)
        } else {
          result.error("Sahha Error", "Sahha Analyzation not available", null)
        }
      }
    } else {
      Sahha.analyze() { error, value ->
        if (error != null) {
          result.error("Sahha Error", error, null)
        } else if (value != null) {
          result.success(value)
        } else {
          result.error("Sahha Error", "Sahha Analyzation not available", null)
        }
      }
    }
  }

  private fun openAppSettings(@NonNull call: MethodCall, @NonNull result: Result) {
    Sahha.openAppSettings(context);
  }

}
