## Flutter wrapper
-keep class androidx.lifecycle.** { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-dontwarn io.flutter.embedding.**

-keep class com.builttoroam.devicecalendar.** { *; }
-keep class org.xmlpull.v1.** { *;}
-dontwarn org.xmlpull.v1.**

-keepclassmembers class * implements javax.net.ssl.SSLSocketFactory { 
	private javax.net.ssl.SSLSocketFactory delegate; 
}

## Flutter WebRTC
-keep class com.cloudwebrtc.webrtc.** { *; }
-keep class org.webrtc.** { *; } 


