package com.mob.secverify_example;


import android.os.Bundle;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;


import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterActivity {
  // 通过Mob console申请获得
  private static final String MOB_APPKEY = "moba6b6c6d6";
  private static final String MOB_APPSECRET = "b89d2427a3bc7ad1aea1e1e8c1d36bf3";

  @Override
  protected void onCreate(@Nullable Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
  }

  @Override
  public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
    GeneratedPluginRegistrant.registerWith(flutterEngine);
    super.configureFlutterEngine(flutterEngine);
  }
}

