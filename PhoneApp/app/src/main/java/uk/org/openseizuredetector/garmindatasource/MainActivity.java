package uk.org.openseizuredetector.garmindatasource;

import android.app.Activity;
import android.app.ActivityManager;
import android.app.PendingIntent;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.os.Handler;
import android.util.Log;
import android.widget.CompoundButton;
import android.widget.TextView;
import android.widget.ToggleButton;

import com.garmin.android.connectiq.ConnectIQ;
import com.garmin.android.connectiq.ConnectIQ.IQConnectType;
import com.garmin.android.connectiq.IQApp;
import com.garmin.android.connectiq.IQDevice;
import com.garmin.android.connectiq.exception.InvalidStateException;
import com.garmin.android.connectiq.exception.ServiceUnavailableException;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Timer;
import java.util.TimerTask;

import static com.garmin.android.connectiq.IQApp.IQAppStatus.INSTALLED;

public class MainActivity extends Activity {
    private String TAG = "MainActivity";
    private Context mContext;
    private Timer mUiTimer;
    private Handler mHandler = new Handler();   // used to update ui from mUiTimer

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        mContext = this;
        setContentView(R.layout.activity_main);
    }

    @Override
    protected void onDestroy() {
        Log.v(TAG,"onDestroy()");
        //closeComms();
        //cancelNotification();
        super.onDestroy();
    }

    @Override
    protected void onStart() {
        super.onStart();
        Log.v(TAG,"onStart()");
        if (isMyServiceRunning(GarminDataSourceService.class)) {
            startServer();
        } else {
            Log.v(TAG,"Service already running so not starting it");
        }

        // start timer to refresh user interface every second.
        mUiTimer = new Timer();
        mUiTimer.schedule(new TimerTask() {
            @Override
            public void run() {
                mHandler.post(updateUiRunnable);
                //updateServerStatus();
            }
        }, 0, 1000);

        ToggleButton tb = (ToggleButton) findViewById(R.id.toggleButton);
        tb.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
            public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
                if (isChecked) {
                    startServer();
                } else {
                    stopServer();
                }
            }
        });
    }

    @Override
    protected void onStop() {
        super.onStop();
        Log.v(TAG,"onStop()");
        mUiTimer.cancel();
    }


    private void startServer() {
        Intent i;
        ComponentName c;
        i = new Intent(mContext, GarminDataSourceService.class);
        i.setData(Uri.parse("Start"));
        c = mContext.startService(i);
        if (c == null) { Log.e(TAG, "failed to start with "+i); }
        else {
            Log.v(TAG,"Started server ok");
        }
    }

    public void stopServer() {
        Log.v(TAG, "stopping Server...");
        // then send an Intent to stop the service.
        Intent i;
        i = new Intent(mContext, GarminDataSourceService.class);
        i.setData(Uri.parse("Stop"));
        mContext.stopService(i);
    }



    // From https://stackoverflow.com/questions/600207/how-to-check-if-a-service-is-running-on-android
    private boolean isMyServiceRunning(Class<?> serviceClass) {
        ActivityManager manager = (ActivityManager) getSystemService(Context.ACTIVITY_SERVICE);
        for (ActivityManager.RunningServiceInfo service : manager.getRunningServices(Integer.MAX_VALUE)) {
            if (serviceClass.getName().equals(service.service.getClassName())) {
                return true;
            }
        }
        return false;
    }
    /*
    * serverStatusRunnable - called by updateServerStatus - updates the
    * user interface to reflect the current status received from the server.
    * If everything is ok, we close this activity and open the main user interface
    * activity.
    */
    final Runnable updateUiRunnable = new Runnable() {
        public void run() {
            Boolean allOk = true;
            TextView tv;
            ToggleButton tb;

            // Service Running
            tv = (TextView) findViewById(R.id.textview1);
            tb = (ToggleButton)findViewById(R.id.toggleButton);
            if (isMyServiceRunning(GarminDataSourceService.class)) {
                tv.setText("GarminDataSource Service Running OK");
                tb.setChecked(true );
            } else {
                tv.setText("*** GarminDataSource NOT RUNNING ***");
                tb.setChecked(false);
            }

        }
    };
}