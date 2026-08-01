# Gson — R8 full mode merusak TypeToken generic signature.
# Tanpa ini, seluruh jalur persistensi flutter_local_notifications
# melempar "Missing type parameter" di release build saja.
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keep public class * implements java.lang.reflect.Type

# flutter_local_notifications
-keep class com.dexterous.** { *; }
