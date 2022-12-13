#!/bin/bash

sudo killall -SIGUSR1 collectd

RRD1="/var/lib/collectd/rrd/ord/sensors-k10temp-pci-00c3/temperature-temp1.rrd"
PNG24H="/var/www/social.kyiv.ua/zl34/lights-24h.png"
PNG7D="/var/www/social.kyiv.ua/zl34/lights-7d.png"
PNG30D="/var/www/social.kyiv.ua/zl34/lights-30d.png"

TZ="Europe/Kiev" /usr/bin/rrdtool graph $PNG24H \
  --width=600 \
  --height=200 \
  --end now \
  --start end-24h \
  --y-grid none \
  --x-grid MINUTE:10:HOUR:1:HOUR:1:0:%H \
  --title "Power outages - 24 hours" \
    DEF:lights=$RRD1:value:AVERAGE \
    CDEF:lightson=lights,UN,UNKN,INF,IF \
    CDEF:lightsoff=lights,UN,INF,UNKN,IF \
    AREA:lightson#9af042dd:svitlo \
    AREA:lightsoff#9c2424dd:blackout

TZ="Europe/Kiev" /usr/bin/rrdtool graph $PNG7D \
  --width=600 \
  --height=200 \
  --end now \
  --start end-7d \
  --y-grid none \
  --title "Power outages - 7 days" \
    DEF:lights=$RRD1:value:AVERAGE \
    CDEF:lightson=lights,UN,UNKN,INF,IF \
    CDEF:lightsoff=lights,UN,INF,UNKN,IF \
    AREA:lightson#9af042dd:svitlo \
    AREA:lightsoff#9c2424dd:blackout

TZ="Europe/Kiev" /usr/bin/rrdtool graph $PNG30D \
  --width=600 \
  --height=200 \
  --end now \
  --start end-30d \
  --y-grid none \
  --title "Power outages - 30 days" \
    DEF:lights=$RRD1:value:AVERAGE \
    CDEF:lightson=lights,UN,UNKN,INF,IF \
    CDEF:lightsoff=lights,UN,INF,UNKN,IF \
    AREA:lightson#9af042dd:svitlo \
    AREA:lightsoff#9c2424dd:blackout

