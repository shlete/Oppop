# 광고 SDK가 쓰는 WorkManager의 Room DB 구현을 R8이 지우면 앱이 켜지자마자 꺼진다.
-keep class * extends androidx.room.RoomDatabase { <init>(); }
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
