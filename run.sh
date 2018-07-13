#!/bin/bash

/etc/init.d/cups start || exit 1
/etc/init.d/papercut start || exit 1
sleep 30
/etc/init.d/papercut-web-print start || exit 1
/etc/init.d/papercut-event-monitor start || exit 1
/etc/init.d/pc-mobility-print start || exit 1
sleep 10000d
