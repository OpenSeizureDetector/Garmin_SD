//
// Copyright 2016 by Garmin Ltd. or its subsidiaries.
// Subject to Garmin SDK License Agreement and Wearables
// Application Developer Agreement.
//

using Toybox.WatchUi as Ui;

class AccelMagDelegate extends Ui.BehaviorDelegate {
    var parentView;

    function initialize(view) {
        BehaviorDelegate.initialize();
        parentView = view;
    }

    function onSelect() {
        parentView.kickBall();
    }
}