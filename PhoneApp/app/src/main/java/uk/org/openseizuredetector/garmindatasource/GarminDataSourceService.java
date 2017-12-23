package uk.org.openseizuredetector.garmindatasource;

import android.app.Notification;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.os.IBinder;
import android.util.Log;

import com.garmin.android.connectiq.ConnectIQ;
import com.garmin.android.connectiq.IQApp;
import com.garmin.android.connectiq.IQDevice;
import com.garmin.android.connectiq.exception.InvalidStateException;
import com.garmin.android.connectiq.exception.ServiceUnavailableException;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public class GarminDataSourceService extends Service {
    private String TAG = "GarminDataSourceService";
    Context mContext;
    ConnectIQ connectIQ;
    IQApp mIqApp;
    IQDevice mIqDevice;
    private NotificationManager mNM;
    private int NOTIFICATION_ID = 0;

    public GarminDataSourceService() {
        Log.v(TAG,"GarminDataSourceService()");
    }

    @Override
    public IBinder onBind(Intent intent) {
        // TODO: Return the communication channel to the service.
        throw new UnsupportedOperationException("Not yet implemented");
    }

    @Override
    public void onCreate() {
        super.onCreate();
        mContext = getApplicationContext();
        Log.v(TAG,"onCreate()");
        initComms();
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        Log.v(TAG,"onStartCommand()");
        showNotification();
        return super.onStartCommand(intent, flags, startId);
    }

    @Override
    public void onDestroy() {
        Log.v(TAG,"onDestroy()");
        closeComms();
        cancelNotification();
        super.onDestroy();
    }

    @Override
    public boolean onUnbind(Intent intent) {
        return super.onUnbind(intent);
    }

    @Override
    public void onRebind(Intent intent) {
        super.onRebind(intent);
    }


    private void initComms() {
        Log.v(TAG,"initComms()");
        final ConnectIQ connectIQ = ConnectIQ.getInstance(mContext, ConnectIQ.IQConnectType.WIRELESS);
        connectIQ.initialize(mContext, true, new ConnectIQ.ConnectIQListener() {
            // Called when the SDK has been successfully initialized
            @Override
            public void onSdkReady() {
                Log.v(TAG, "onSdkReady()");
                ////////////////////////////////////////
                // Get a list of the connected devices
                List<IQDevice> deviceList = null;
                try {
                    deviceList = connectIQ.getConnectedDevices();
                } catch (ServiceUnavailableException e) {
                    Log.e(TAG, "ConnectIQ Service Unavailable Exception - " + e.getLocalizedMessage());
                } catch (InvalidStateException e) {
                    Log.e(TAG, "ConnectIQ Invalid State Exception - " + e.getLocalizedMessage());
                }

                if (deviceList != null && deviceList.size() > 0) {
                    final IQDevice device = deviceList.get(0);
                    mIqDevice = device;
                    Log.v(TAG, "Device Connected - working with " + device.getFriendlyName() +
                            ": " + device.toString());
                    //////////////////////////////////////
                    // Register to receive status updates
                    try {
                        connectIQ.registerForDeviceEvents(device, new ConnectIQ.IQDeviceEventListener() {
                            @Override
                            public void onDeviceStatusChanged(IQDevice device, IQDevice.IQDeviceStatus newStatus) {
                                Log.v(TAG, "onDeviceStatusChanged() - new status = " + newStatus.name());
                                // FIXME - DO SOMETHING ABOUT NEW STATUS
                            }
                        });
                    } catch (InvalidStateException e) {
                        Log.e(TAG, "ConnectIQ Invalid State Exception - " + e.getLocalizedMessage());

                    }
                    ///////////////////////////////////////////////////
                    // Check the OpenSeizureDetector App is Installed
                    try {
                        connectIQ.getApplicationInfo("a863c9aa-d62d-477d-a478-c35d99297ea3", device,
                                new ConnectIQ.IQApplicationInfoListener() {
                                    @Override
                                    public void onApplicationInfoReceived(IQApp iqApp) {
                                        Log.v(TAG, "onApplicationInforRecevied() - iqApp = " + iqApp.toString() +
                                                " :" + iqApp.getDisplayName() + ", status=" + iqApp.getStatus());
                                        if (iqApp.getStatus() == IQApp.IQAppStatus.INSTALLED) {
                                            Log.v(TAG, "success - App is installed! - starting it");
                                            mIqApp = iqApp;
                                            ////////////////////////////////
                                            // tell the watch app to start
                                            try {
                                                connectIQ.openApplication(device, iqApp, new ConnectIQ.IQOpenApplicationListener() {
                                                    @Override
                                                    public void onOpenApplicationResponse(IQDevice device, IQApp app, ConnectIQ.IQOpenApplicationStatus status) {
                                                        Log.v(TAG, "onOpenApplicationResponse()");
                                                        //////////////////////////////////////////////////////
                                                        // Register to receive messages from our application
                                                        try {
                                                            Log.v(TAG, "registering for application events");
                                                            connectIQ.registerForAppEvents(device, mIqApp, iqApplicationEventListener);
                                                        } catch (InvalidStateException e) {
                                                            Log.e(TAG, "Invalid State Exception " + e.toString());
                                                        }
                                                    }
                                                });
                                            } catch (ServiceUnavailableException e) {
                                                Log.e(TAG,"ServiceUnavailable Exception - "+e.toString());
                                            } catch (InvalidStateException e) {
                                                Log.e(TAG,"InvalidState Exception - "+e.toString());
                                            }
                                        }
                                    }

                                    @Override
                                    public void onApplicationNotInstalled(String s) {
                                        Log.v(TAG, "onApplicationNotInstalled() - s=" + s);
                                    }
                                });
                    } catch (InvalidStateException e) {
                        Log.e(TAG, "ConnectIQ Invalid State Exception - " + e.getLocalizedMessage());
                    } catch (ServiceUnavailableException e) {
                        Log.e(TAG, "ConnectIQ ServiceUnavailable Exception - " + e.getLocalizedMessage());
                    }
                } else {
                    Log.e(TAG, "NO CONNECTED DEVICES");
                }
                Log.v(TAG,"initComms() Exiting");
                // Do any post initialization setup.
            }

            @Override
            public void onInitializeError(ConnectIQ.IQSdkErrorStatus status) {
                Log.v(TAG, "onInitializeError() - status = " + status.name());

            }

            @Override
            public void onSdkShutDown() {
                Log.v(TAG, "onSdkShutdown()");
            }
        });

    }

    private void closeComms() {
        Log.v(TAG, "closeComms");
        if ((mIqDevice != null) && (mIqApp != null)) {
            try {
                connectIQ.unregisterForApplicationEvents(mIqDevice, mIqApp);
            } catch (Exception e) {
                Log.e(TAG, "closeComms - exception " + e.toString());
            }
        } else {
            Log.e(TAG, "closeComms - something is already null so doing nothing"
            );
        }
    }

    private ConnectIQ.IQApplicationEventListener iqApplicationEventListener = new ConnectIQ.IQApplicationEventListener() {
        @Override
        public void onMessageReceived(IQDevice device, IQApp app,
                List<Object> messageData,
                ConnectIQ.IQMessageStatus status) {
            Log.v(TAG, "onMessageReceived()");

            // First inspect the status to make sure this
            // was a SUCCESS.  If not then the status will indicate why there
            // was an issue receiving the message from the Connect IQ application.
            if (status == ConnectIQ.IQMessageStatus.SUCCESS) {
                Log.v(TAG, "Message Received " + messageData.get(0).toString());
                Intent intent = new Intent();
                intent.setAction("uk.org.openseizuredetector.SdDataReceived");
                intent.putExtra("data",messageData.get(0).toString());
                sendBroadcast(intent);

                // Send a message back
                List<Object> outMsg = new ArrayList<Object>(Arrays.asList("hello pi", "3.14159"));
                try {
                    connectIQ.sendMessage(device, app, outMsg, sendMessageListener);
                } catch (InvalidStateException e) {
                    Log.e(TAG,"onMessageReceived - invalidStateException "+e.toString());
                } catch (ServiceUnavailableException e) {
                    Log.e(TAG,"onMessageReceived - ServiceUnavailableException "+e.toString());
                } catch (Exception e) {
                    Log.e(TAG,"onMessageReceived - Exception "+e.toString());
                    e.printStackTrace();
                }
            } else {
                Log.w(TAG, "Invalid Message Received");
            }
        }
    };

    private ConnectIQ.IQSendMessageListener sendMessageListener = new ConnectIQ.IQSendMessageListener() {
        @Override
        public void onMessageStatus(IQDevice iqDevice, IQApp iqApp, ConnectIQ.IQMessageStatus iqMessageStatus) {
            Log.v(TAG,"onMessageStatus() - " + iqMessageStatus.name());
        }
    };

    /**
     * Show a notification while this service is running.
     */
    private void showNotification() {
        Log.v(TAG, "showNotification()");
        int iconId;
        iconId = R.drawable.star_of_life_24x24;
        Intent i = new Intent(getApplicationContext(), MainActivity.class);
        i.setFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT);
        PendingIntent contentIntent =
                PendingIntent.getActivity(this,
                        0, i, PendingIntent.FLAG_UPDATE_CURRENT);
        Notification.Builder builder = new Notification.Builder(this);
        Notification notification = builder.setContentIntent(contentIntent)
                .setSmallIcon(iconId)
                .setTicker("OpenSeizureDetector")
                .setAutoCancel(false)
                .setContentTitle("OpenSeizureDetector")
                .setContentText("Garmin Data Source")
                .build();

        mNM = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
        mNM.notify(NOTIFICATION_ID, notification);
    }

    private void cancelNotification() {
        // Cancel the notification.
        Log.v(TAG, "cancelNotification(): cancelling notification");
        mNM.cancel(NOTIFICATION_ID);
    }

    // Show the main activity on the user's screen.
    private void showMainActivity() {
        Log.v(TAG, "showMainActivity(): Showing Main Activity");
        Intent i = new Intent(getApplicationContext(), MainActivity.class);
        i.setFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT | Intent.FLAG_ACTIVITY_NEW_TASK);
        this.startActivity(i);
    }


}
