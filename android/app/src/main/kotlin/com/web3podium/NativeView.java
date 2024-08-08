package com.web3podium;

import android.content.Context;
import android.graphics.Color;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.platform.PlatformView;
import java.util.Map;

// Set up message channel


import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.embedding.engine.dart.DartExecutor.DartEntrypoint;
import io.flutter.plugin.common.BasicMessageChannel;
import io.flutter.plugin.common.BasicMessageChannel.MessageHandler;
import io.flutter.plugin.common.BasicMessageChannel.Reply;
import io.flutter.plugin.common.StringCodec;

class NativeView implements PlatformView, BasicMessageChannel.MessageHandler {
    @NonNull private final TextView textView;
    @NonNull private static final String CHANNEL = "increment";
    private BasicMessageChannel basicMessageChannel;

    NativeView(@NonNull Context context, BinaryMessenger messenger, int id, @Nullable Map<String, Object> creationParams) {
        textView = new TextView(context);
        textView.setTextSize(60);
        textView.setBackgroundColor(Color.rgb(255, 255, 255));
        textView.setText("Rendered on a native Android view (id: " + id + ")" + creationParams.get("counting"));
        basicMessageChannel = new BasicMessageChannel(messenger, CHANNEL, StringCodec.INSTANCE);
        basicMessageChannel.setMessageHandler(this);
        textView.setOnClickListener(
                new View.OnClickListener(){

                    @Override
                    public void onClick(View view) {
                        basicMessageChannel.send("basic_text_click");
                        Toast.makeText(context, "Basic click native toast", Toast.LENGTH_SHORT).show();
                    }
                }
        );
    }

    @NonNull
    @Override
    public View getView() {
        return textView;
    }

    @Override
    public void dispose() {} // Free the message handler

    @Override
    public void onMessage(@Nullable Object message, @NonNull Reply reply) {
        if(message != null){
            textView.setText(message.toString());
            basicMessageChannel.send("basic_set_text_done!");
        }
    }
}
