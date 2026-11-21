package ir.soundify.soundify

import android.os.Build
import com.ryanheise.audioservice.AudioServiceFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : AudioServiceFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "ir.soundify/security")
            .setMethodCallHandler { call, result ->
                if (call.method != "check") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val paths = listOf("/system/app/Superuser.apk", "/sbin/su", "/system/bin/su",
                    "/system/xbin/su", "/data/local/xbin/su", "/data/local/bin/su",
                    "/system/bin/.ext/.su", "/sbin/.magisk", "/data/adb/magisk")
                val indicators = paths.filter { File(it).exists() }.toMutableList()
                if (Build.TAGS?.contains("test-keys") == true) indicators.add("test-keys")
                val emulator = Build.FINGERPRINT.startsWith("generic") ||
                    Build.FINGERPRINT.contains("emulator", true) ||
                    Build.FINGERPRINT.contains("vbox", true) ||
                    Build.MODEL.contains("Emulator", true) || Build.MODEL.contains("sdk_gphone", true) ||
                    Build.HARDWARE in listOf("goldfish", "ranchu", "vbox86") ||
                    (Build.BRAND.startsWith("generic") && Build.DEVICE.startsWith("generic")) ||
                    Build.PRODUCT.contains("sdk", true)
                result.success(mapOf("rooted" to indicators.isNotEmpty(), "emulator" to emulator,
                    "indicators" to indicators, "model" to "${Build.MANUFACTURER} ${Build.MODEL}",
                    "android" to Build.VERSION.RELEASE, "sdk" to Build.VERSION.SDK_INT))
            }
    }
}
