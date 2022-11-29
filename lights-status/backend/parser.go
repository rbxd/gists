package main

import (
    "github.com/bradfitz/gomemcache/memcache"
    "encoding/json"
    "time"
    "os"
    "log"
)

type netHost struct {
    SymName   string
    Hostname  string
}

var pingEndpoints []netHost

type endpointStatus struct {
    SymName   string   `json:"name"`
    Up        bool     `json:"up"`
}

type apiResponse struct {
    // could be one of "on", "off", "partial", "unknown"
    Lights    string                  `json:"lights"`
    Time      int64                   `json:"time"`
    Since     int64                   `json:"since"`
    Endpoints []endpointStatus        `json:"endpoints"`
}

func getStatusMemcache(mc *memcache.Client, key string) (*apiResponse, error) {
    systemStatus := new(apiResponse)

    mcVal, err := mc.Get(key)
    if err != nil {
      return nil, err
    }

    err = json.Unmarshal(mcVal.Value, &systemStatus)
    if err != nil {
        return nil, err
    }

    return systemStatus, nil
}


func main() {
    // TODO get server address, key name from configuration
    mc := memcache.New("127.0.0.1:11211")
    mcKey := "zl34:lights"

    l := log.New(os.Stdout, "[Pinger.go] ", log.Lmsgprefix | log.LstdFlags)

    // get initial status from memcached
    //      from the previous runs
    systemStatus, err := getStatusMemcache(mc, mcKey)

    if err != nil || systemStatus == nil {
        l.Printf("Did not get system Status from mc: ", err)
        systemStatus = new(apiResponse)
    } else {
        l.Printf("Loaded status:")
        l.Printf("\tLights:\t'%s'", systemStatus.Lights)
        l.Printf("\tSince:\t%d (%d seconds ago)", systemStatus.Since, time.Now().Unix()-systemStatus.Since)
        l.Printf("\tPosted:\t%d (%d seconds ago)", systemStatus.Time, time.Now().Unix()-systemStatus.Time)
    }

    // DEBUG
    l.Printf("SYSTEM STATUS: ", systemStatus)
}
