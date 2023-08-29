#!/bin/bash
#
# Better readability for `ip route monitor`
#
# Instead of something like:
# > 2607:6003:2307::/48 via 2a0f:XXXX::10 dev ur proto bird src 2a05:xxxx::96 metric 32 pref medium
# > 2a0a:6040:e6ff::/48 via 2a0f:XXXX::10 dev ur proto bird src 2a05:xxxx::96 metric 32 pref medium
# > 2602:fc23:151::/48 via 2a0e:XXXX::1 dev ruda proto bird src 2a05:xxxx::96 metric 32 pref medium
# > 2a06:a001:a108::/48 via 2a0f:XXXX::10 dev ur proto bird src 2a05:xxxx::96 metric 32 pref medium
# > 2404:f4c0:8868::/48 via 2a0f:XXXX::10 dev ur proto bird src 2a05:xxxx::96 metric 32 pref medium
# > 2804:16b8::/32 via 2a0e:XXXX::1 dev ruda proto bird src 2a05:xxxx::96 metric 32 pref medium
# > 2804:20fc:1b00::/48 via 2a0e:XXXX::1 dev netassist proto bird src 2a05:xxxx::96 metric 32 pref medium
# > 2404:f4c0:8868::/48 via 2a0e:XXXX::1 dev ruda proto bird src 2a05:xxxx::96 metric 32 pref medium
#
# Displays something like this:
# -     ruda    2804:858:b000::/36
# -     ruda    2804:858:c000::/36
# -     ruda    2804:858:d000::/36
# -     ruda    2804:858:e000::/36
# -     ruda    2804:858:f000::/36
# +     ruda    2a13:df80:8000::/38
# +       ur    2605:9cc0:c03::/48
# +       ur    2806:250:25::/48
# +       ur    2806:250:26::/48
# + netassist   2804:20fc:1b00::/48
#

ip monitor route | awk -W interactive '{if($1=="Deleted"){ printf("- %10s\t%s\n", $6, $2)}else{printf("+ %10s\t%s\n", $5, $1)}}'
# optionally:
#| ts '%Y-%m-%d %H:%M:%.S'
