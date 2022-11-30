package main

import (
	"bytes"
	"encoding/json"
	"github.com/bradfitz/gomemcache/memcache"
	"log"
	"os"
	"os/exec"
	"time"
)

type netHost struct {
	SymName  string
	Hostname string
}

var pingEndpoints []netHost

type endpointStatus struct {
	SymName string `json:"name"`
	Up      bool   `json:"up"`
}

type apiResponse struct {
	// could be one of "on", "off", "partial", "unknown"
	Lights    string           `json:"lights"`
	Time      int64            `json:"time"`
	Since     int64            `json:"since"`
	Endpoints []endpointStatus `json:"endpoints"`
}

// TODO get this from runtime configuration
func init() {
	pingEndpoints = []netHost{
		netHost{
			SymName:  "Вхід 1",
			Hostname: "ord.tuxedo-in.ts.net",
		},
	}
}

func allUp(status []endpointStatus) bool {
	for i := 0; i < len(status); i++ {
		if status[i].Up == false {
			return false
		}
	}

	return true
}

func allDown(status []endpointStatus) bool {
	for i := 0; i < len(status); i++ {
		if status[i].Up == true {
			return false
		}
	}

	return true
}

func getStatus(status []endpointStatus) string {
	if allUp(status) {
		return "on"
	} else if allDown(status) {
		return "off"
	} else {
		return "partial"
	}

	return "unknown"
}

// load status from memcache
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
	mcKey := "zl34_ping"
	var mcExpiry int32 = 720

	l := log.New(os.Stdout, "[Pinger.go] ", log.Lmsgprefix|log.LstdFlags)

	// get initial status from memcached
	//      from the previous runs
	systemStatus, err := getStatusMemcache(mc, mcKey)

	if err != nil || systemStatus == nil {
		l.Printf("Did not get system status from memcache: ", err)
		systemStatus = new(apiResponse)
	} else {
		// DEBUG
		l.Printf("Loaded status from memcached('%s'):", mcKey)
		l.Printf("\tLights:\t'%s'", systemStatus.Lights)
		l.Printf("\tSince:\t%d (%d seconds ago)", systemStatus.Since, time.Now().Unix()-systemStatus.Since)
		l.Printf("\tPosted:\t%d (%d seconds ago)", systemStatus.Time, time.Now().Unix()-systemStatus.Time)
		l.Printf("FULL STATUS: ", systemStatus)
	}

	for {
		var pingStatus = make([]endpointStatus, len(pingEndpoints))

		for i := 0; i < len(pingEndpoints); i++ {
			var stdout, stderr bytes.Buffer
			up := true

			cmd := exec.Command("ping", "-c 1", "-W 1", pingEndpoints[i].Hostname)
			cmd.Stdout = &stdout
			cmd.Stderr = &stderr

			err := cmd.Run()
			if err != nil {
				// Should be put in DEBUG log:
				//l.Printf("Error during execution: ", err)
				//l.Printf("STDOUT: ", stdout.String())
				//l.Printf("STDERR: ", stderr.String())
				up = false
			}

			pingStatus[i] = endpointStatus{
				SymName: pingEndpoints[i].SymName,
				Up:      up,
			}
		}

		lightStatus := getStatus(pingStatus)

		// TODO handle empty systemStatus - silently set it to the current status
		if lightStatus != systemStatus.Lights {
			l.Printf("Change of status. From: '%s' to: '%s' after %d sec", systemStatus.Lights, lightStatus, time.Now().Unix()-systemStatus.Since)

			systemStatus = &apiResponse{
				Lights:    lightStatus,
				Time:      time.Now().Unix(),
				Since:     time.Now().Unix(),
				Endpoints: pingStatus,
			}
		} else {
			systemStatus.Time = time.Now().Unix()
			systemStatus.Endpoints = pingStatus
		}

		// DEBUG
		//l.Printf("SYSTEM STATUS: ", systemStatus)

		storeVal, _ := json.Marshal(systemStatus)
		mc.Set(&memcache.Item{Key: mcKey, Value: storeVal, Expiration: mcExpiry})

		// TODO get interval from configuration
		time.Sleep(20 * time.Second)
	}
}
