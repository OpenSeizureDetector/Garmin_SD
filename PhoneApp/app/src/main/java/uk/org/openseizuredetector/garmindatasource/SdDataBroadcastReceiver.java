package uk.org.openseizuredetector.garmindatasource;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

public class SdDataBroadcastReceiver extends BroadcastReceiver {
    private String TAG = "SdDataBroadcastReceiver";

    @Override
    public void onReceive(Context context, Intent intent) {
        Log.v(TAG,"onReceive()");
        String jsonStr = intent.getStringExtra("data");
        Log.v(TAG,"data="+jsonStr);
    }
}
