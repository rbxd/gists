package main

import (
    "github.com/bradfitz/gomemcache/memcache"
    "encoding/json"
    "time"
    "log"
    "os"
    "os/exec"
    "bytes"
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


// TODO get this from runtime configuration
func init() {
    pingEndpoints = []netHost {
        netHost {
            SymName: "Вхід 1",
            Hostname: "ord.tuxedo-in.ts.net",
        },
        netHost {
            SymName: "Вхід 2",
            Hostname: "dfw.tuxedo-in.ts.net",
        },
    }
}

func allUp(status []endpointStatus) bool {
    for i:=0; i<len(status); i++ {
        if status[i].Up == false {
            return false
        }
    }

    return true
}

func allDown(status []endpointStatus) bool {
    for i:=0; i<len(status); i++ {
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


func main() {
    // TODO get server address, key name from configuration
    mc := memcache.New("127.0.0.1:11211")
    mcKey := "123ping"
    var mcExpiry int32 = 720

    l := log.New(os.Stdout, "[Pinger.go] ", log.Lmsgprefix | log.LstdFlags)

    // TODO get initial status from memcached
    //      from the previous runs
    var systemStatus apiResponse

    for {
        var pingStatus = make([]endpointStatus, len(pingEndpoints))

        for i:=0; i<len(pingEndpoints); i++ {
            var stdout, stderr bytes.Buffer

            cmd := exec.Command("ping", "-c 1", "-W 1", pingEndpoints[i].Hostname)
	          cmd.Stdout = &stdout
            cmd.Stderr = &stderr

            err := cmd.Run()

            up := true

            if err != nil {
                // Should be put in DEBUG log:
                //l.Printf("Error during execution: ", err)
                //l.Printf("STDOUT: ", stdout.String())
                //l.Printf("STDERR: ", stderr.String())
                up = false
            }

            pingStatus[i] = endpointStatus{
                SymName: pingEndpoints[i].SymName,
                Up: up,
            }
        }

        // DEBUG
        //l.Printf("PING STATUS: ", pingStatus)

        lightStatus := getStatus(pingStatus)

        // TODO handle empty systemStatus - silently set it to the current status
        if lightStatus != systemStatus.Lights {
            l.Printf("Change of status. From: '%s' to: '%s'", systemStatus.Lights, lightStatus)

            systemStatus = apiResponse{
                Lights:     lightStatus,
                Time:       time.Now().Unix(),
                Since:      time.Now().Unix(),
                Endpoints:  pingStatus,
            }
        } else {
            systemStatus.Time = time.Now().Unix()
        } // TODO handle corner case: status remains "partial", but the endpoints status changed

        // DEBUG
        //l.Printf("SYSTEM STATUS: ", systemStatus)

        storeVal, _ := json.Marshal(systemStatus)
        mc.Set(&memcache.Item{Key: mcKey, Value: storeVal, Expiration: mcExpiry})

        // TODO get interval from configuration
        time.Sleep(20 * time.Second)
    }
}
