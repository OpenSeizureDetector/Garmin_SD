package uk.org.openseizuredetector.garmindatasource;

import android.app.Activity;
import android.content.Context;
import android.os.Bundle;
import android.util.Log;

import com.garmin.android.connectiq.ConnectIQ;
import com.garmin.android.connectiq.ConnectIQ.IQConnectType;
import com.garmin.android.connectiq.IQApp;
import com.garmin.android.connectiq.IQDevice;
import com.garmin.android.connectiq.exception.InvalidStateException;
import com.garmin.android.connectiq.exception.ServiceUnavailableException;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import static com.garmin.android.connectiq.IQApp.IQAppStatus.INSTALLED;

public class MainActivity extends Activity {
    private String TAG = "MainActivity";
    Context mContext;
    ConnectIQ connectIQ;
    IQApp mIqApp;
    IQDevice mIqDevice;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        mContext = getApplicationContext();
        initComms();
    }

    @Override
    protected void onDestroy() {
        closeComms();
        super.onDestroy();
    }


    private void initComms() {
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
                                            Log.v(TAG, "success - App is installed!");
                                            mIqApp = iqApp;
                                            ////////////////////////////////
                                            // tell the watch app to start
                                            try {
                                                connectIQ.openApplication(device, iqApp, new ConnectIQ.IQOpenApplicationListener() {
                                                    @Override
                                                    public void onOpenApplicationResponse(IQDevice device, IQApp app, ConnectIQ.IQOpenApplicationStatus status) {
                                                        //////////////////////////////////////////////////////
                                                        // Register to receive messages from our application
                                                        try {
                                                            connectIQ.registerForAppEvents(device, mIqApp, new ConnectIQ.IQApplicationEventListener() {

                                                                @Override
                                                                public void onMessageReceived(IQDevice device, IQApp app,
                                                                                              List<Object> messageData,
                                                                                              ConnectIQ.IQMessageStatus status) {
                                                                    // First inspect the status to make sure this
                                                                    // was a SUCCESS.  If not then the status will indicate why there
                                                                    // was an issue receiving the message from the Connect IQ application.
                                                                    if (status == ConnectIQ.IQMessageStatus.SUCCESS) {
                                                                        Log.v(TAG, "Message Received " + messageData.toString());
                                                                        List<Object> outMsg = new ArrayList<Object>(Arrays.asList("hello pi", "3.14159"));
                                                                        try {
                                                                            connectIQ.sendMessage(device, app, outMsg, sendMessageListener);
                                                                        } catch (InvalidStateException e) {
                                                                            Log.e(TAG,"onMessageReceived - invalidStateException "+e.toString());
                                                                        } catch (ServiceUnavailableException e) {
                                                                            Log.e(TAG,"onMessageReceived - ServiceUnavailableException "+e.toString());
                                                                        }
                                                                    } else {
                                                                        Log.w(TAG, "Invalid Message Received");
                                                                    }
                                                                }
                                                            });
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
            } catch (InvalidStateException e) {
                Log.e(TAG, "closeComms - invalidstateexception " + e.toString());
            }
        } else {
            Log.e(TAG, "closeComms - something is already null so doing nothing"
            );
        }
    }


    private ConnectIQ.IQSendMessageListener sendMessageListener = new ConnectIQ.IQSendMessageListener() {
        @Override
        public void onMessageStatus(IQDevice iqDevice, IQApp iqApp, ConnectIQ.IQMessageStatus iqMessageStatus) {
            Log.v(TAG,"onMessageStatus() - " + iqMessageStatus.name());
        }
    };
}