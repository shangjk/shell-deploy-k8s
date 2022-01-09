#!/bin/bash
#Auth: Jack
#Date: 2021/9/12
#Version: 1.0
#Description: create grafana dashboard

ZONE=$1
datasource=datasource_$1
mkdir -p $DIR/data/json &> /dev/null
cat > $DIR/data/json/grafana-datasource.json <<EOF
{
  "name":"$datasource",
  "type":"prometheus",
  "access":"proxy",
  "url":"http://prometheus-${ZONE}.jiake.shang:20080/prometheus",
  "password":"",
  "user":"",
  "database":"",
  "basicAuth":false,
  "basicAuthUser":"",
  "basicAuthPassword":"",
  "withCredentials":false,
  "isDefault":false,
  "jsonData":{
      "httpMethod":"GET"
  },
  "readOnly":false
}
EOF

cat > $DIR/data/json/grafana-dashboard.json << EOF
{
  "dashboard": {
    "annotations": {
      "list": [
        {
          "builtIn": 1,
          "datasource": "-- Grafana --",
          "enable": true,
          "hide": true,
          "iconColor": "rgba(0, 211, 255, 1)",
          "name": "Annotations & Alerts",
          "target": {
            "limit": 100,
            "matchAny": false,
            "tags": [],
            "type": "dashboard"
          },
          "type": "dashboard"
        }
      ]
    },
    "editable": true,
    "gnetId": null,
    "graphTooltip": 0,
    "id": null,
    "links": [],
    "panels": [
      {
        "collapsed": false,
        "datasource": "$datasource",
        "gridPos": {
          "h": 1,
          "w": 24,
          "x": 0,
          "y": 0
        },
        "id": 47,
        "panels": [],
        "title": "容器集群资源",
        "type": "row"
      },
      {
        "datasource": "$datasource",
        "description": "",
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "thresholds"
            },
            "decimals": 1,
            "mappings": [],
            "max": 100,
            "min": 0,
            "noValue": "N/A",
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {
                  "color": "green",
                  "value": null
                },
                {
                  "color": "yellow",
                  "value": 65
                },
                {
                  "color": "red",
                  "value": 85
                }
              ]
            },
            "unit": "percent"
          },
          "overrides": []
        },
        "gridPos": {
          "h": 4,
          "w": 3,
          "x": 0,
          "y": 1
        },
        "id": 4,
        "options": {
          "reduceOptions": {
            "calcs": [
              "lastNotNull"
            ],
            "fields": "",
            "values": false
          },
          "showThresholdLabels": false,
          "showThresholdMarkers": true,
          "text": {}
        },
        "pluginVersion": "8.1.3",
        "targets": [
          {
            "exemplar": true,
            "expr": "sum(kube_pod_container_resource_requests{resource=\"cpu\"}) / sum(kube_node_status_allocatable{resource=\"cpu\"}) * 100",
            "instant": false,
            "interval": "",
            "intervalFactor": 1,
            "legendFormat": "",
            "refId": "A"
          }
        ],
        "title": "Cluster CPU request",
        "transparent": true,
        "type": "gauge"
      },
      {
        "datasource": "$datasource",
        "description": "",
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "thresholds"
            },
            "decimals": 1,
            "mappings": [],
            "max": 100,
            "min": 0,
            "noValue": "N/A",
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {
                  "color": "green",
                  "value": null
                },
                {
                  "color": "yellow",
                  "value": 65
                },
                {
                  "color": "red",
                  "value": 90
                }
              ]
            },
            "unit": "percent"
          },
          "overrides": []
        },
        "gridPos": {
          "h": 4,
          "w": 3,
          "x": 3,
          "y": 1
        },
        "id": 6,
        "options": {
          "reduceOptions": {
            "calcs": [
              "lastNotNull"
            ],
            "fields": "",
            "values": false
          },
          "showThresholdLabels": false,
          "showThresholdMarkers": true,
          "text": {}
        },
        "pluginVersion": "8.1.3",
        "targets": [
          {
            "exemplar": true,
            "expr": "sum(rate(container_cpu_usage_seconds_total{id=\"/\"}[1m])) / sum(machine_cpu_cores{}) * 100",
            "instant": false,
            "interval": "30s",
            "intervalFactor": 1,
            "legendFormat": "",
            "refId": "A"
          }
        ],
        "title": "Cluster CPU Usage",
        "transparent": true,
        "type": "gauge"
      },
      {
        "datasource": "$datasource",
        "description": "",
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "thresholds"
            },
            "decimals": 1,
            "mappings": [],
            "max": 100,
            "min": 0,
            "noValue": "N/A",
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {
                  "color": "green",
                  "value": null
                },
                {
                  "color": "yellow",
                  "value": 80
                },
                {
                  "color": "red",
                  "value": 90
                }
              ]
            },
            "unit": "percent"
          },
          "overrides": []
        },
        "gridPos": {
          "h": 4,
          "w": 3,
          "x": 6,
          "y": 1
        },
        "id": 8,
        "options": {
          "reduceOptions": {
            "calcs": [
              "lastNotNull"
            ],
            "fields": "",
            "values": false
          },
          "showThresholdLabels": false,
          "showThresholdMarkers": true,
          "text": {}
        },
        "pluginVersion": "8.1.3",
        "repeat": null,
        "targets": [
          {
            "exemplar": true,
            "expr": "sum(kube_pod_container_resource_requests{resource=\"memory\"}) / sum(kube_node_status_allocatable{resource=\"memory\"}) * 100",
            "instant": false,
            "interval": "",
            "intervalFactor": 1,
            "legendFormat": "",
            "refId": "A"
          }
        ],
        "title": "Cluster Mem Request",
        "transparent": true,
        "type": "gauge"
      },
      {
        "datasource": "$datasource",
        "description": "",
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "thresholds"
            },
            "decimals": 1,
            "mappings": [],
            "max": 100,
            "min": 0,
            "noValue": "N/A",
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {
                  "color": "green",
                  "value": null
                },
                {
                  "color": "yellow",
                  "value": 70
                },
                {
                  "color": "red",
                  "value": 90
                }
              ]
            },
            "unit": "percent"
          },
          "overrides": []
        },
        "gridPos": {
          "h": 4,
          "w": 3,
          "x": 9,
          "y": 1
        },
        "id": 9,
        "options": {
          "reduceOptions": {
            "calcs": [
              "lastNotNull"
            ],
            "fields": "",
            "values": false
          },
          "showThresholdLabels": false,
          "showThresholdMarkers": true,
          "text": {}
        },
        "pluginVersion": "8.1.3",
        "targets": [
          {
            "exemplar": true,
            "expr": "sum(container_memory_working_set_bytes{id=\"/\"}) / sum(machine_memory_bytes{}) * 100",
            "instant": false,
            "interval": "",
            "intervalFactor": 1,
            "legendFormat": "",
            "refId": "A"
          }
        ],
        "title": "Cluster Mem Usage",
        "transparent": true,
        "type": "gauge"
      },
      {
        "datasource": "$datasource",
        "description": "",
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "thresholds"
            },
            "decimals": 1,
            "mappings": [],
            "max": 100,
            "min": 0,
            "noValue": "N/A",
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {
                  "color": "green",
                  "value": null
                },
                {
                  "color": "yellow",
                  "value": 70
                },
                {
                  "color": "red",
                  "value": 90
                }
              ]
            },
            "unit": "percent"
          },
          "overrides": []
        },
        "gridPos": {
          "h": 4,
          "w": 3,
          "x": 12,
          "y": 1
        },
        "id": 10,
        "options": {
          "reduceOptions": {
            "calcs": [
              "lastNotNull"
            ],
            "fields": "",
            "values": false
          },
          "showThresholdLabels": false,
          "showThresholdMarkers": true,
          "text": {}
        },
        "pluginVersion": "8.1.3",
        "targets": [
          {
            "exemplar": true,
            "expr": "sum(container_fs_usage_bytes{device=~\"^/dev/.*$\",id=\"/\"}) / sum(container_fs_limit_bytes{device=~\"^/dev/.*$\",id=\"/\"}) * 100",
            "instant": false,
            "interval": "",
            "intervalFactor": 1,
            "legendFormat": "",
            "refId": "A"
          }
        ],
        "title": "Cluster Filesystem Usage",
        "transparent": true,
        "type": "gauge"
      },
      {
        "datasource": "$datasource",
        "description": "",
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "thresholds"
            },
            "decimals": 2,
            "mappings": [],
            "max": 1,
            "min": 0,
            "noValue": "N/A",
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {
                  "color": "green",
                  "value": null
                },
                {
                  "color": "yellow",
                  "value": 0.8
                },
                {
                  "color": "red",
                  "value": 0.9
                }
              ]
            },
            "unit": "percentunit"
          },
          "overrides": []
        },
        "gridPos": {
          "h": 4,
          "w": 3,
          "x": 15,
          "y": 1
        },
        "id": 11,
        "options": {
          "reduceOptions": {
            "calcs": [
              "lastNotNull"
            ],
            "fields": "",
            "values": false
          },
          "showThresholdLabels": false,
          "showThresholdMarkers": true,
          "text": {}
        },
        "pluginVersion": "8.1.3",
        "targets": [
          {
            "exemplar": true,
            "expr": "max(avg(1 - rate(node_cpu_seconds_total{mode=\"idle\"}[1m])) by (instance))",
            "instant": false,
            "interval": "",
            "intervalFactor": 2,
            "legendFormat": "",
            "refId": "A"
          }
        ],
        "title": "Node中最高CPU使用率",
        "transparent": true,
        "type": "gauge"
      },
      {
        "datasource": "$datasource",
        "description": "",
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "thresholds"
            },
            "decimals": 2,
            "mappings": [],
            "max": 1,
            "min": 0,
            "noValue": "N/A",
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {
                  "color": "green",
                  "value": null
                },
                {
                  "color": "yellow",
                  "value": 0.8
                },
                {
                  "color": "red",
                  "value": 0.9
                }
              ]
            },
            "unit": "percentunit"
          },
          "overrides": []
        },
        "gridPos": {
          "h": 4,
          "w": 3,
          "x": 18,
          "y": 1
        },
        "id": 12,
        "options": {
          "reduceOptions": {
            "calcs": [
              "lastNotNull"
            ],
            "fields": "",
            "values": false
          },
          "showThresholdLabels": false,
          "showThresholdMarkers": true,
          "text": {}
        },
        "pluginVersion": "8.1.3",
        "targets": [
          {
            "exemplar": true,
            "expr": "max(1 - node_memory_MemAvailable_bytes/node_memory_MemTotal_bytes)",
            "instant": false,
            "interval": "",
            "intervalFactor": 2,
            "legendFormat": "",
            "refId": "A"
          }
        ],
        "title": "Node中最高Mem使用率",
        "transparent": true,
        "type": "gauge"
      },
      {
        "datasource": "$datasource",
        "description": "",
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "thresholds"
            },
            "decimals": 2,
            "mappings": [],
            "max": 1,
            "min": 0,
            "noValue": "N/A",
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {
                  "color": "green",
                  "value": null
                },
                {
                  "color": "yellow",
                  "value": 0.8
                },
                {
                  "color": "red",
                  "value": 0.9
                }
              ]
            },
            "unit": "percentunit"
          },
          "overrides": []
        },
        "gridPos": {
          "h": 4,
          "w": 3,
          "x": 21,
          "y": 1
        },
        "id": 13,
        "options": {
          "reduceOptions": {
            "calcs": [
              "lastNotNull"
            ],
            "fields": "",
            "values": false
          },
          "showThresholdLabels": false,
          "showThresholdMarkers": true,
          "text": {}
        },
        "pluginVersion": "8.1.3",
        "targets": [
          {
            "exemplar": true,
            "expr": "max(1-(node_filesystem_avail_bytes{mountpoint!~\".*(serviceaccount|proc|sys|boot).*\"} / node_filesystem_size_bytes{mountpoint!~\".*(serviceaccount|proc|sys|boot).*\"}))",
            "instant": false,
            "interval": "",
            "intervalFactor": 2,
            "legendFormat": "",
            "refId": "A"
          }
        ],
        "title": "Node中最高磁盘使用率",
        "transparent": true,
        "type": "gauge"
      },
      {
        "datasource": "$datasource",
        "gridPos": {
          "h": 1,
          "w": 24,
          "x": 0,
          "y": 5
        },
        "id": 45,
        "title": "Ingress请求状态统计",
        "type": "row"
      },
      {
        "datasource": "$datasource",
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "thresholds"
            },
            "decimals": 0,
            "mappings": [
              {
                "options": {
                  "null": {
                    "index": 0,
                    "text": "N/A"
                  }
                },
                "type": "value"
              }
            ],
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {
                  "color": "green",
                  "value": null
                }
              ]
            },
            "unit": "none"
          },
          "overrides": []
        },
        "gridPos": {
          "h": 3,
          "w": 6,
          "x": 0,
          "y": 6
        },
        "id": 34,
        "options": {
          "colorMode": "value",
          "graphMode": "area",
          "justifyMode": "auto",
          "orientation": "auto",
          "reduceOptions": {
            "calcs": [
              "lastNotNull"
            ],
            "fields": "",
            "values": false
          },
          "text": {},
          "textMode": "auto"
        },
        "pluginVersion": "8.1.3",
        "targets": [
          {
            "exemplar": true,
            "expr": "sum(increase(nginx_ingress_controller_requests{controller_class!='default'}[2m]) / 2)",
            "interval": "",
            "intervalFactor": 2,
            "legendFormat": "RPM",
            "refId": "A"
          }
        ],
        "title": "Ingress Request 总量",
        "type": "stat"
      },
      {
        "datasource": "$datasource",
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "thresholds"
            },
            "decimals": 0,
            "mappings": [
              {
                "options": {
                  "null": {
                    "index": 0,
                    "text": "N/A"
                  }
                },
                "type": "value"
              }
            ],
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {
                  "color": "green",
                  "value": null
                }
              ]
            },
            "unit": "none"
          },
          "overrides": []
        },
        "gridPos": {
          "h": 3,
          "w": 6,
          "x": 6,
          "y": 6
        },
        "id": 35,
        "options": {
          "colorMode": "value",
          "graphMode": "area",
          "justifyMode": "auto",
          "orientation": "auto",
          "reduceOptions": {
            "calcs": [
              "lastNotNull"
            ],
            "fields": "",
            "values": false
          },
          "text": {},
          "textMode": "auto"
        },
        "pluginVersion": "8.1.3",
        "targets": [
          {
            "exemplar": true,
            "expr": "sum(increase(nginx_ingress_controller_requests{controller_class=~\"${ZONE}\"}[2m]) / 2)",
            "interval": "",
            "intervalFactor": 2,
            "legendFormat": "RPM",
            "refId": "A"
          }
        ],
        "title": "Zone ${ZONE} 请求量",
        "type": "stat"
      },
      {
        "datasource": "$datasource",
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "thresholds"
            },
            "decimals": 0,
            "mappings": [
              {
                "options": {
                  "null": {
                    "index": 0,
                    "text": "N/A"
                  }
                },
                "type": "value"
              }
            ],
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {
                  "color": "green",
                  "value": null
                }
              ]
            },
            "unit": "none"
          },
          "overrides": []
        },
        "gridPos": {
          "h": 3,
          "w": 6,
          "x": 12,
          "y": 6
        },
        "id": 50,
        "options": {
          "colorMode": "value",
          "graphMode": "area",
          "justifyMode": "auto",
          "orientation": "auto",
          "reduceOptions": {
            "calcs": [
              "lastNotNull"
            ],
            "fields": "",
            "values": false
          },
          "text": {},
          "textMode": "auto"
        },
        "pluginVersion": "8.1.3",
        "targets": [
          {
            "exemplar": true,
            "expr": "sum(increase(nginx_ingress_controller_requests{namespace='monitoring',service='prometheus'}[2m]) / 2)",
            "interval": "",
            "intervalFactor": 2,
            "legendFormat": "RPM",
            "refId": "A"
          }
        ],
        "title": "Namespace monitoring 请求量",
        "type": "stat"
      },
      {
        "datasource": "$datasource",
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "palette-classic"
            },
            "custom": {
              "axisLabel": "",
              "axisPlacement": "auto",
              "barAlignment": 0,
              "drawStyle": "line",
              "fillOpacity": 0,
              "gradientMode": "none",
              "hideFrom": {
                "legend": false,
                "tooltip": false,
                "viz": false
              },
              "lineInterpolation": "linear",
              "lineStyle": {
                "fill": "solid"
              },
              "lineWidth": 2,
              "pointSize": 5,
              "scaleDistribution": {
                "type": "linear"
              },
              "showPoints": "never",
              "spanNulls": true,
              "stacking": {
                "group": "A",
                "mode": "none"
              },
              "thresholdsStyle": {
                "mode": "off"
              }
            },
            "mappings": [
              {
                "options": {
                  "null": {
                    "index": 0,
                    "text": "N/A"
                  }
                },
                "type": "value"
              }
            ],
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {
                  "color": "green",
                  "value": null
                }
              ]
            },
            "unit": "none"
          },
          "overrides": []
        },
        "gridPos": {
          "h": 3,
          "w": 6,
          "x": 18,
          "y": 6
        },
        "id": 36,
        "options": {
          "legend": {
            "calcs": [
              "count"
            ],
            "displayMode": "table",
            "placement": "right"
          },
          "tooltip": {
            "mode": "single"
          }
        },
        "pluginVersion": "8.1.3",
        "targets": [
          {
            "exemplar": true,
            "expr": "topk(10, ceil((sum(delta(nginx_ingress_controller_bytes_sent_count{controller_class!='default',ingress!='jobadapter'}[2m]) > 0) by (controller_class,host,ingress)) / 2))",
            "instant": false,
            "interval": "10s",
            "intervalFactor": 1,
            "legendFormat": "{{controller_class}} -- {{host}}/{{ingress}}",
            "refId": "A"
          }
        ],
        "title": "[Ingress] Request TOP10 (opm)",
        "type": "timeseries"
      },
      {
        "cacheTimeout": null,
        "datasource": "$datasource",
        "description": "",
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "thresholds"
            },
            "decimals": 0,
            "mappings": [
              {
                "options": {
                  "match": "null",
                  "result": {
                    "text": "N/A"
                  }
                },
                "type": "special"
              }
            ],
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {
                  "color": "green",
                  "value": null
                }
              ]
            },
            "unit": "short"
          },
          "overrides": []
        },
        "gridPos": {
          "h": 3,
          "w": 6,
          "x": 0,
          "y": 9
        },
        "id": 52,
        "interval": null,
        "links": [],
        "maxDataPoints": 100,
        "options": {
          "colorMode": "value",
          "graphMode": "area",
          "justifyMode": "auto",
          "orientation": "horizontal",
          "reduceOptions": {
            "calcs": [
              "lastNotNull"
            ],
            "fields": "",
            "values": false
          },
          "text": {},
          "textMode": "auto"
        },
        "pluginVersion": "8.1.3",
        "targets": [
          {
            "exemplar": true,
            "expr": "sum(increase(nginx_ingress_controller_requests{status=~'(1|2).*',controller_class=~\"${ZONE}\",controller_pod!=''}[3m])) or vector(0)",
            "format": "time_series",
            "interval": "2m",
            "intervalFactor": 1,
            "legendFormat": "",
            "refId": "A"
          }
        ],
        "title": "HTTP 1/2xx (2m)",
        "transparent": true,
        "type": "stat"
      },
      {
        "cacheTimeout": null,
        "datasource": "$datasource",
        "description": "",
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "thresholds"
            },
            "decimals": 0,
            "mappings": [
              {
                "options": {
                  "match": "null",
                  "result": {
                    "text": "N/A"
                  }
                },
                "type": "special"
              }
            ],
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {
                  "color": "green",
                  "value": null
                }
              ]
            },
            "unit": "short"
          },
          "overrides": []
        },
        "gridPos": {
          "h": 3,
          "w": 6,
          "x": 6,
          "y": 9
        },
        "id": 54,
        "interval": null,
        "links": [],
        "maxDataPoints": 100,
        "options": {
          "colorMode": "value",
          "graphMode": "area",
          "justifyMode": "auto",
          "orientation": "horizontal",
          "reduceOptions": {
            "calcs": [
              "lastNotNull"
            ],
            "fields": "",
            "values": false
          },
          "text": {},
          "textMode": "auto"
        },
        "pluginVersion": "8.1.3",
        "targets": [
          {
            "exemplar": true,
            "expr": "sum(increase(nginx_ingress_controller_requests{status=~'(3).*',controller_class=~\"${ZONE}\",controller_pod!=''}[2m])) or vector(0)",
            "format": "time_series",
            "interval": "2m",
            "intervalFactor": 1,
            "legendFormat": "",
            "refId": "A"
          }
        ],
        "title": "HTTP 3xx (2m)",
        "transparent": true,
        "type": "stat"
      },
      {
        "cacheTimeout": null,
        "datasource": "$datasource",
        "description": "",
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "thresholds"
            },
            "decimals": 0,
            "mappings": [
              {
                "options": {
                  "match": "null",
                  "result": {
                    "text": "N/A"
                  }
                },
                "type": "special"
              }
            ],
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {
                  "color": "dark-yellow",
                  "value": null
                }
              ]
            },
            "unit": "short"
          },
          "overrides": []
        },
        "gridPos": {
          "h": 3,
          "w": 6,
          "x": 12,
          "y": 9
        },
        "id": 56,
        "interval": null,
        "links": [],
        "maxDataPoints": 100,
        "options": {
          "colorMode": "value",
          "graphMode": "area",
          "justifyMode": "auto",
          "orientation": "horizontal",
          "reduceOptions": {
            "calcs": [
              "lastNotNull"
            ],
            "fields": "",
            "values": false
          },
          "text": {},
          "textMode": "auto"
        },
        "pluginVersion": "8.1.3",
        "targets": [
          {
            "exemplar": true,
            "expr": "sum(increase(nginx_ingress_controller_requests{status=~'4.*',controller_class=~\"${ZONE}\",controller_pod!=''}[2m]))  or vector(0)",
            "format": "time_series",
            "interval": "2m",
            "intervalFactor": 1,
            "legendFormat": "",
            "refId": "A"
          }
        ],
        "title": "HTTP 4xx (2m)",
        "transparent": true,
        "type": "stat"
      },
      {
        "cacheTimeout": null,
        "datasource": "$datasource",
        "description": "",
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "thresholds"
            },
            "decimals": 0,
            "mappings": [
              {
                "options": {
                  "match": "null",
                  "result": {
                    "text": "N/A"
                  }
                },
                "type": "special"
              }
            ],
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {
                  "color": "dark-red",
                  "value": null
                }
              ]
            },
            "unit": "short"
          },
          "overrides": []
        },
        "gridPos": {
          "h": 3,
          "w": 6,
          "x": 18,
          "y": 9
        },
        "id": 58,
        "interval": null,
        "links": [],
        "maxDataPoints": 100,
        "options": {
          "colorMode": "value",
          "graphMode": "area",
          "justifyMode": "auto",
          "orientation": "horizontal",
          "reduceOptions": {
            "calcs": [
              "lastNotNull"
            ],
            "fields": "",
            "values": false
          },
          "text": {},
          "textMode": "auto"
        },
        "pluginVersion": "8.1.3",
        "targets": [
          {
            "exemplar": true,
            "expr": "sum(increase(nginx_ingress_controller_requests{status=~'5.*',controller_class=~\"${ZONE}\",controller_pod!=''}[2m])) or vector(0)",
            "format": "time_series",
            "interval": "2m",
            "intervalFactor": 1,
            "legendFormat": "",
            "refId": "A"
          }
        ],
        "title": "HTTP 5xx (2m)",
        "transparent": true,
        "type": "stat"
      },
      {
        "datasource": "$datasource",
        "gridPos": {
          "h": 1,
          "w": 24,
          "x": 0,
          "y": 12
        },
        "id": 43,
        "title": "集群内部资源状态",
        "type": "row"
      },
      {
        "datasource": "$datasource",
        "description": "",
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "palette-classic"
            },
            "custom": {
              "axisLabel": "",
              "axisPlacement": "auto",
              "barAlignment": 0,
              "drawStyle": "line",
              "fillOpacity": 0,
              "gradientMode": "none",
              "hideFrom": {
                "legend": false,
                "tooltip": false,
                "viz": false
              },
              "lineInterpolation": "linear",
              "lineStyle": {
                "fill": "solid"
              },
              "lineWidth": 1,
              "pointSize": 5,
              "scaleDistribution": {
                "type": "linear"
              },
              "showPoints": "never",
              "spanNulls": true,
              "stacking": {
                "group": "A",
                "mode": "none"
              },
              "thresholdsStyle": {
                "mode": "off"
              }
            },
            "mappings": [],
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {
                  "color": "green",
                  "value": null
                }
              ]
            },
            "unit": "none"
          },
          "overrides": [
            {
              "matcher": {
                "id": "byName",
                "options": "monitoring"
              },
              "properties": [
                {
                  "id": "color",
                  "value": {
                    "fixedColor": "purple",
                    "mode": "fixed"
                  }
                }
              ]
            }
          ]
        },
        "gridPos": {
          "h": 5,
          "w": 8,
          "x": 0,
          "y": 13
        },
        "id": 30,
        "options": {
          "legend": {
            "calcs": [
              "lastNotNull"
            ],
            "displayMode": "table",
            "placement": "right"
          },
          "tooltip": {
            "mode": "single"
          }
        },
        "targets": [
          {
            "exemplar": true,
            "expr": "sum(kube_deployment_status_replicas_unavailable{}) by (namespace)",
            "interval": "",
            "legendFormat": "{{namespace}}",
            "refId": "A"
          }
        ],
        "title": "Deployment Unavailable",
        "type": "timeseries"
      },
      {
        "datasource": "$datasource",
        "description": "",
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "palette-classic"
            },
            "custom": {
              "axisLabel": "",
              "axisPlacement": "auto",
              "barAlignment": 0,
              "drawStyle": "line",
              "fillOpacity": 0,
              "gradientMode": "none",
              "hideFrom": {
                "legend": false,
                "tooltip": false,
                "viz": false
              },
              "lineInterpolation": "linear",
              "lineStyle": {
                "fill": "solid"
              },
              "lineWidth": 1,
              "pointSize": 5,
              "scaleDistribution": {
                "type": "linear"
              },
              "showPoints": "never",
              "spanNulls": true,
              "stacking": {
                "group": "A",
                "mode": "none"
              },
              "thresholdsStyle": {
                "mode": "off"
              }
            },
            "mappings": [],
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {
                  "color": "green",
                  "value": null
                }
              ]
            },
            "unit": "none"
          },
          "overrides": [
            {
              "matcher": {
                "id": "byName",
                "options": "monitoring"
              },
              "properties": [
                {
                  "id": "color",
                  "value": {
                    "fixedColor": "purple",
                    "mode": "fixed"
                  }
                }
              ]
            }
          ]
        },
        "gridPos": {
          "h": 5,
          "w": 8,
          "x": 8,
          "y": 13
        },
        "id": 31,
        "options": {
          "legend": {
            "calcs": [
              "lastNotNull"
            ],
            "displayMode": "table",
            "placement": "right"
          },
          "tooltip": {
            "mode": "single"
          }
        },
        "targets": [
          {
            "exemplar": true,
            "expr": "sum(kube_daemonset_status_number_unavailable{namespace!='default'}) by (namespace)",
            "interval": "",
            "legendFormat": "{{namespace}}",
            "refId": "A"
          }
        ],
        "title": "Daemon Unavailable",
        "type": "timeseries"
      },
      {
        "datasource": "$datasource",
        "description": "",
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "palette-classic"
            },
            "custom": {
              "axisLabel": "",
              "axisPlacement": "auto",
              "barAlignment": 0,
              "drawStyle": "line",
              "fillOpacity": 0,
              "gradientMode": "none",
              "hideFrom": {
                "legend": false,
                "tooltip": false,
                "viz": false
              },
              "lineInterpolation": "linear",
              "lineStyle": {
                "fill": "solid"
              },
              "lineWidth": 1,
              "pointSize": 5,
              "scaleDistribution": {
                "type": "linear"
              },
              "showPoints": "never",
              "spanNulls": true,
              "stacking": {
                "group": "A",
                "mode": "none"
              },
              "thresholdsStyle": {
                "mode": "off"
              }
            },
            "mappings": [],
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {
                  "color": "green",
                  "value": null
                }
              ]
            },
            "unit": "none"
          },
          "overrides": [
            {
              "matcher": {
                "id": "byName",
                "options": "monitoring"
              },
              "properties": [
                {
                  "id": "color",
                  "value": {
                    "fixedColor": "purple",
                    "mode": "fixed"
                  }
                }
              ]
            }
          ]
        },
        "gridPos": {
          "h": 5,
          "w": 8,
          "x": 16,
          "y": 13
        },
        "id": 32,
        "options": {
          "legend": {
            "calcs": [
              "lastNotNull"
            ],
            "displayMode": "table",
            "placement": "right"
          },
          "tooltip": {
            "mode": "single"
          }
        },
        "targets": [
          {
            "exemplar": true,
            "expr": "sum(kube_pod_status_phase{}) by (phase)",
            "hide": false,
            "interval": "",
            "intervalFactor": 2,
            "legendFormat": "{{phase}}",
            "refId": "A"
          },
          {
            "exemplar": true,
            "expr": "kubelet_running_pod_count{kubernetes_io_role =~ '.*node.*'}",
            "hide": false,
            "interval": "",
            "intervalFactor": 2,
            "legendFormat": "{{instance}}",
            "refId": "B"
          }
        ],
        "title": "Pods Status Count",
        "type": "timeseries"
      },
      {
        "datasource": "$datasource",
        "gridPos": {
          "h": 1,
          "w": 24,
          "x": 0,
          "y": 18
        },
        "id": 28,
        "title": "集群系统负载",
        "type": "row"
      },
      {
        "datasource": "$datasource",
        "description": "",
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "palette-classic"
            },
            "custom": {
              "axisLabel": "",
              "axisPlacement": "auto",
              "barAlignment": 0,
              "drawStyle": "line",
              "fillOpacity": 0,
              "gradientMode": "none",
              "hideFrom": {
                "legend": false,
                "tooltip": false,
                "viz": false
              },
              "lineInterpolation": "linear",
              "lineWidth": 2,
              "pointSize": 5,
              "scaleDistribution": {
                "type": "linear"
              },
              "showPoints": "never",
              "spanNulls": true,
              "stacking": {
                "group": "A",
                "mode": "none"
              },
              "thresholdsStyle": {
                "mode": "off"
              }
            },
            "mappings": [],
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {
                  "color": "green",
                  "value": null
                }
              ]
            },
            "unit": "short"
          },
          "overrides": []
        },
        "gridPos": {
          "h": 4,
          "w": 6,
          "x": 0,
          "y": 19
        },
        "id": 38,
        "options": {
          "legend": {
            "calcs": [
              "max",
              "lastNotNull"
            ],
            "displayMode": "table",
            "placement": "right"
          },
          "tooltip": {
            "mode": "single"
          }
        },
        "targets": [
          {
            "exemplar": true,
            "expr": "node_load1",
            "interval": "",
            "intervalFactor": 2,
            "legendFormat": "{{instance}}",
            "refId": "A"
          }
        ],
        "title": "CPU Load 1m [Nodes]",
        "type": "timeseries"
      },
      {
        "datasource": "$datasource",
        "description": "",
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "palette-classic"
            },
            "custom": {
              "axisLabel": "",
              "axisPlacement": "auto",
              "barAlignment": 0,
              "drawStyle": "line",
              "fillOpacity": 0,
              "gradientMode": "none",
              "hideFrom": {
                "legend": false,
                "tooltip": false,
                "viz": false
              },
              "lineInterpolation": "linear",
              "lineWidth": 2,
              "pointSize": 5,
              "scaleDistribution": {
                "type": "linear"
              },
              "showPoints": "never",
              "spanNulls": true,
              "stacking": {
                "group": "A",
                "mode": "none"
              },
              "thresholdsStyle": {
                "mode": "off"
              }
            },
            "mappings": [],
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {
                  "color": "green",
                  "value": null
                }
              ]
            },
            "unit": "bytes"
          },
          "overrides": []
        },
        "gridPos": {
          "h": 4,
          "w": 6,
          "x": 6,
          "y": 19
        },
        "id": 39,
        "options": {
          "legend": {
            "calcs": [
              "max",
              "lastNotNull"
            ],
            "displayMode": "table",
            "placement": "right"
          },
          "tooltip": {
            "mode": "single"
          }
        },
        "targets": [
          {
            "exemplar": true,
            "expr": "rate(node_disk_read_bytes_total{job='node-exporter',device!=''}[1m])",
            "interval": "",
            "intervalFactor": 2,
            "legendFormat": "{{node}} {{device}}-read",
            "refId": "A"
          },
          {
            "exemplar": true,
            "expr": "rate(node_disk_written_bytes_total{job='node-exporter',device!=''}[1m])",
            "hide": false,
            "interval": "",
            "legendFormat": "{{node}} {{device}}-write",
            "refId": "B"
          }
        ],
        "title": "Disk I/O [Read/Write]",
        "type": "timeseries"
      },
      {
        "datasource": "$datasource",
        "description": "",
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "palette-classic"
            },
            "custom": {
              "axisLabel": "",
              "axisPlacement": "auto",
              "barAlignment": 0,
              "drawStyle": "line",
              "fillOpacity": 0,
              "gradientMode": "none",
              "hideFrom": {
                "legend": false,
                "tooltip": false,
                "viz": false
              },
              "lineInterpolation": "linear",
              "lineWidth": 2,
              "pointSize": 5,
              "scaleDistribution": {
                "type": "linear"
              },
              "showPoints": "never",
              "spanNulls": true,
              "stacking": {
                "group": "A",
                "mode": "none"
              },
              "thresholdsStyle": {
                "mode": "off"
              }
            },
            "mappings": [],
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {
                  "color": "green",
                  "value": null
                }
              ]
            },
            "unit": "bytes"
          },
          "overrides": []
        },
        "gridPos": {
          "h": 4,
          "w": 6,
          "x": 12,
          "y": 19
        },
        "id": 40,
        "options": {
          "legend": {
            "calcs": [
              "lastNotNull"
            ],
            "displayMode": "table",
            "placement": "right"
          },
          "tooltip": {
            "mode": "single"
          }
        },
        "targets": [
          {
            "exemplar": true,
            "expr": "(node_memory_MemFree_bytes{job='node-exporter'} + node_memory_Buffers_bytes{job='node-exporter'} + node_memory_Cached_bytes{job='node-exporter'})",
            "interval": "",
            "intervalFactor": 2,
            "legendFormat": "{{node}}",
            "refId": "A"
          }
        ],
        "title": "Memory Avalilable [Node]",
        "type": "timeseries"
      },
      {
        "datasource": "$datasource",
        "description": "",
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "palette-classic"
            },
            "custom": {
              "axisLabel": "",
              "axisPlacement": "auto",
              "barAlignment": 0,
              "drawStyle": "line",
              "fillOpacity": 0,
              "gradientMode": "none",
              "hideFrom": {
                "legend": false,
                "tooltip": false,
                "viz": false
              },
              "lineInterpolation": "linear",
              "lineWidth": 2,
              "pointSize": 5,
              "scaleDistribution": {
                "type": "linear"
              },
              "showPoints": "never",
              "spanNulls": true,
              "stacking": {
                "group": "A",
                "mode": "none"
              },
              "thresholdsStyle": {
                "mode": "off"
              }
            },
            "mappings": [],
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {
                  "color": "green",
                  "value": null
                }
              ]
            },
            "unit": "bytes/s"
          },
          "overrides": []
        },
        "gridPos": {
          "h": 4,
          "w": 6,
          "x": 18,
          "y": 19
        },
        "id": 41,
        "options": {
          "legend": {
            "calcs": [
              "lastNotNull"
            ],
            "displayMode": "table",
            "placement": "right"
          },
          "tooltip": {
            "mode": "single"
          }
        },
        "targets": [
          {
            "exemplar": true,
            "expr": "irate(node_network_receive_bytes_total{device!=''}[2m]) / 120",
            "interval": "10s",
            "intervalFactor": 2,
            "legendFormat": "{{instance}}",
            "refId": "A"
          },
          {
            "exemplar": true,
            "expr": "- irate(node_network_transmit_bytes_total{device!=''}[2m]) / 120",
            "hide": false,
            "interval": "10s",
            "intervalFactor": 2,
            "legendFormat": "{{instance}}",
            "refId": "B"
          }
        ],
        "title": "Network  Bytes [node]",
        "type": "timeseries"
      },
      {
        "collapsed": false,
        "datasource": "$datasource",
        "gridPos": {
          "h": 1,
          "w": 24,
          "x": 0,
          "y": 23
        },
        "id": 26,
        "panels": [],
        "title": "集群ETCD资源状态",
        "type": "row"
      },
      {
        "datasource": "$datasource",
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "thresholds"
            },
            "mappings": [
              {
                "options": {
                  "0": {
                    "color": "semi-dark-red",
                    "index": 1,
                    "text": "NO"
                  },
                  "1": {
                    "color": "semi-dark-green",
                    "index": 0,
                    "text": "YES"
                  }
                },
                "type": "value"
              }
            ],
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {
                  "color": "green",
                  "value": null
                },
                {
                  "color": "semi-dark-red",
                  "value": 0
                },
                {
                  "color": "semi-dark-green",
                  "value": 1
                }
              ]
            },
            "unit": "none"
          },
          "overrides": []
        },
        "gridPos": {
          "h": 4,
          "w": 4,
          "x": 0,
          "y": 24
        },
        "id": 17,
        "options": {
          "colorMode": "value",
          "graphMode": "none",
          "justifyMode": "auto",
          "orientation": "auto",
          "reduceOptions": {
            "calcs": [
              "lastNotNull"
            ],
            "fields": "",
            "values": false
          },
          "text": {},
          "textMode": "auto"
        },
        "pluginVersion": "8.1.3",
        "targets": [
          {
            "exemplar": true,
            "expr": "max(etcd_server_has_leader)",
            "interval": "",
            "intervalFactor": 2,
            "legendFormat": "",
            "refId": "A"
          }
        ],
        "title": "Etcd has a leader?",
        "type": "stat"
      },
      {
        "datasource": "$datasource",
        "description": "",
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "palette-classic"
            },
            "custom": {
              "axisLabel": "",
              "axisPlacement": "left",
              "barAlignment": 0,
              "drawStyle": "line",
              "fillOpacity": 0,
              "gradientMode": "none",
              "hideFrom": {
                "legend": false,
                "tooltip": false,
                "viz": false
              },
              "lineInterpolation": "linear",
              "lineStyle": {
                "fill": "solid"
              },
              "lineWidth": 2,
              "pointSize": 5,
              "scaleDistribution": {
                "type": "linear"
              },
              "showPoints": "never",
              "spanNulls": false,
              "stacking": {
                "group": "A",
                "mode": "none"
              },
              "thresholdsStyle": {
                "mode": "off"
              }
            },
            "mappings": [],
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {
                  "color": "green",
                  "value": null
                },
                {
                  "color": "red",
                  "value": ""
                }
              ]
            },
            "unit": "ops"
          },
          "overrides": []
        },
        "gridPos": {
          "h": 4,
          "w": 5,
          "x": 4,
          "y": 24
        },
        "id": 19,
        "options": {
          "legend": {
            "calcs": [],
            "displayMode": "hidden",
            "placement": "bottom"
          },
          "tooltip": {
            "mode": "single"
          }
        },
        "targets": [
          {
            "exemplar": true,
            "expr": "sum(rate(grpc_server_started_total{grpc_type=\"unary\"}[5m]))",
            "interval": "",
            "intervalFactor": 2,
            "legendFormat": "RPC Rate",
            "refId": "A"
          },
          {
            "exemplar": true,
            "expr": "sum(rate(grpc_server_handled_total{grpc_type=\"unary\",grpc_code!=\"OK\"}[5m]))",
            "hide": false,
            "interval": "",
            "intervalFactor": 2,
            "legendFormat": "RPC Failed Rate",
            "refId": "B"
          }
        ],
        "title": "RPC Rate",
        "type": "timeseries"
      },
      {
        "datasource": "$datasource",
        "description": "",
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "palette-classic"
            },
            "custom": {
              "axisLabel": "",
              "axisPlacement": "left",
              "barAlignment": 0,
              "drawStyle": "line",
              "fillOpacity": 0,
              "gradientMode": "none",
              "hideFrom": {
                "legend": false,
                "tooltip": false,
                "viz": false
              },
              "lineInterpolation": "linear",
              "lineStyle": {
                "fill": "solid"
              },
              "lineWidth": 2,
              "pointSize": 5,
              "scaleDistribution": {
                "type": "linear"
              },
              "showPoints": "never",
              "spanNulls": false,
              "stacking": {
                "group": "A",
                "mode": "none"
              },
              "thresholdsStyle": {
                "mode": "off"
              }
            },
            "mappings": [],
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {
                  "color": "green",
                  "value": null
                },
                {
                  "color": "red",
                  "value": ""
                }
              ]
            },
            "unit": "bytes"
          },
          "overrides": []
        },
        "gridPos": {
          "h": 4,
          "w": 5,
          "x": 9,
          "y": 24
        },
        "id": 20,
        "options": {
          "legend": {
            "calcs": [
              "lastNotNull"
            ],
            "displayMode": "hidden",
            "placement": "right"
          },
          "tooltip": {
            "mode": "single"
          }
        },
        "targets": [
          {
            "exemplar": true,
            "expr": "etcd_debugging_mvcc_db_total_size_in_bytes",
            "interval": "",
            "intervalFactor": 2,
            "legendFormat": "{{instance}} DB Size",
            "refId": "A"
          }
        ],
        "title": "DB Size",
        "type": "timeseries"
      },
      {
        "datasource": "$datasource",
        "description": "",
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "palette-classic"
            },
            "custom": {
              "axisLabel": "",
              "axisPlacement": "left",
              "barAlignment": 0,
              "drawStyle": "line",
              "fillOpacity": 0,
              "gradientMode": "none",
              "hideFrom": {
                "legend": false,
                "tooltip": false,
                "viz": false
              },
              "lineInterpolation": "linear",
              "lineStyle": {
                "fill": "solid"
              },
              "lineWidth": 2,
              "pointSize": 5,
              "scaleDistribution": {
                "type": "linear"
              },
              "showPoints": "never",
              "spanNulls": true,
              "stacking": {
                "group": "A",
                "mode": "none"
              },
              "thresholdsStyle": {
                "mode": "off"
              }
            },
            "mappings": [],
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {
                  "color": "green",
                  "value": null
                },
                {
                  "color": "red",
                  "value": ""
                }
              ]
            },
            "unit": "s"
          },
          "overrides": []
        },
        "gridPos": {
          "h": 4,
          "w": 5,
          "x": 14,
          "y": 24
        },
        "id": 21,
        "options": {
          "legend": {
            "calcs": [],
            "displayMode": "hidden",
            "placement": "bottom"
          },
          "tooltip": {
            "mode": "single"
          }
        },
        "targets": [
          {
            "exemplar": true,
            "expr": "histogram_quantile(0.99, sum(rate(etcd_disk_wal_fsync_duration_seconds_bucket[5m])) by (instance,le))",
            "interval": "",
            "intervalFactor": 2,
            "legendFormat": "{{instance}} WAL fsync",
            "refId": "A"
          },
          {
            "exemplar": true,
            "expr": "histogram_quantile(0.99, sum(rate(etcd_disk_backend_commit_duration_seconds_bucket[5m])) by (instance,le))",
            "hide": false,
            "interval": "",
            "intervalFactor": 2,
            "legendFormat": "{{instance}} DB fsync",
            "refId": "B"
          }
        ],
        "title": "Disk Sync Duration",
        "type": "timeseries"
      },
      {
        "datasource": "$datasource",
        "description": "",
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "palette-classic"
            },
            "custom": {
              "axisLabel": "",
              "axisPlacement": "left",
              "barAlignment": 0,
              "drawStyle": "line",
              "fillOpacity": 0,
              "gradientMode": "none",
              "hideFrom": {
                "legend": false,
                "tooltip": false,
                "viz": false
              },
              "lineInterpolation": "linear",
              "lineStyle": {
                "fill": "solid"
              },
              "lineWidth": 2,
              "pointSize": 5,
              "scaleDistribution": {
                "type": "linear"
              },
              "showPoints": "never",
              "spanNulls": true,
              "stacking": {
                "group": "A",
                "mode": "none"
              },
              "thresholdsStyle": {
                "mode": "off"
              }
            },
            "mappings": [],
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {
                  "color": "green",
                  "value": null
                },
                {
                  "color": "red",
                  "value": ""
                }
              ]
            },
            "unit": "Bps"
          },
          "overrides": []
        },
        "gridPos": {
          "h": 4,
          "w": 5,
          "x": 19,
          "y": 24
        },
        "id": 22,
        "options": {
          "legend": {
            "calcs": [],
            "displayMode": "hidden",
            "placement": "bottom"
          },
          "tooltip": {
            "mode": "single"
          }
        },
        "targets": [
          {
            "exemplar": true,
            "expr": "rate(etcd_network_client_grpc_received_bytes_total[5m])",
            "interval": "",
            "intervalFactor": 2,
            "legendFormat": "{{instance}} Client Traffic IN",
            "refId": "A"
          },
          {
            "exemplar": true,
            "expr": "-rate(etcd_network_client_grpc_sent_bytes_total[5m])",
            "hide": false,
            "interval": "",
            "intervalFactor": 2,
            "legendFormat": "{{instance}} Client Traffic OUT",
            "refId": "B"
          }
        ],
        "title": "Client Traffic In/Out",
        "type": "timeseries"
      },
      {
        "collapsed": false,
        "datasource": "$datasource",
        "gridPos": {
          "h": 1,
          "w": 24,
          "x": 0,
          "y": 28
        },
        "id": 24,
        "panels": [],
        "title": "Ingress资源响应延迟详情",
        "type": "row"
      },
      {
        "columns": [],
        "datasource": "$datasource",
        "fontSize": "100%",
        "gridPos": {
          "h": 6,
          "w": 24,
          "x": 0,
          "y": 29
        },
        "hideTimeOverride": false,
        "id": 49,
        "links": [],
        "pageSize": 7,
        "repeat": null,
        "repeatDirection": "h",
        "scroll": true,
        "showHeader": true,
        "sort": {
          "col": 3,
          "desc": true
        },
        "styles": [
          {
            "alias": "Ingress",
            "align": "auto",
            "colorMode": null,
            "colors": [
              "rgba(245, 54, 54, 0.9)",
              "rgba(237, 129, 40, 0.89)",
              "rgba(50, 172, 45, 0.97)"
            ],
            "dateFormat": "YYYY-MM-DD HH:mm:ss",
            "decimals": 2,
            "pattern": "ingress",
            "preserveFormat": false,
            "sanitize": false,
            "thresholds": [],
            "type": "string",
            "unit": "short"
          },
          {
            "alias": "Requests",
            "align": "auto",
            "colorMode": null,
            "colors": [
              "rgba(245, 54, 54, 0.9)",
              "rgba(237, 129, 40, 0.89)",
              "rgba(50, 172, 45, 0.97)"
            ],
            "dateFormat": "YYYY-MM-DD HH:mm:ss",
            "decimals": 2,
            "pattern": "Value #A",
            "thresholds": [
              ""
            ],
            "type": "number",
            "unit": "ops"
          },
          {
            "alias": "Errors",
            "align": "auto",
            "colorMode": null,
            "colors": [
              "rgba(245, 54, 54, 0.9)",
              "rgba(237, 129, 40, 0.89)",
              "rgba(50, 172, 45, 0.97)"
            ],
            "dateFormat": "YYYY-MM-DD HH:mm:ss",
            "decimals": 2,
            "pattern": "Value #B",
            "thresholds": [],
            "type": "number",
            "unit": "ops"
          },
          {
            "alias": "P50 Latency",
            "align": "auto",
            "colorMode": null,
            "colors": [
              "rgba(245, 54, 54, 0.9)",
              "rgba(237, 129, 40, 0.89)",
              "rgba(50, 172, 45, 0.97)"
            ],
            "dateFormat": "YYYY-MM-DD HH:mm:ss",
            "decimals": 0,
            "link": false,
            "pattern": "Value #C",
            "thresholds": [],
            "type": "number",
            "unit": "dtdurations"
          },
          {
            "alias": "P90 Latency",
            "align": "auto",
            "colorMode": null,
            "colors": [
              "rgba(245, 54, 54, 0.9)",
              "rgba(237, 129, 40, 0.89)",
              "rgba(50, 172, 45, 0.97)"
            ],
            "dateFormat": "YYYY-MM-DD HH:mm:ss",
            "decimals": 0,
            "pattern": "Value #D",
            "thresholds": [],
            "type": "number",
            "unit": "dtdurations"
          },
          {
            "alias": "P99 Latency",
            "align": "auto",
            "colorMode": null,
            "colors": [
              "rgba(245, 54, 54, 0.9)",
              "rgba(237, 129, 40, 0.89)",
              "rgba(50, 172, 45, 0.97)"
            ],
            "dateFormat": "YYYY-MM-DD HH:mm:ss",
            "decimals": 0,
            "pattern": "Value #E",
            "thresholds": [],
            "type": "number",
            "unit": "dtdurations"
          },
          {
            "alias": "IN",
            "align": "auto",
            "colorMode": null,
            "colors": [
              "rgba(245, 54, 54, 0.9)",
              "rgba(237, 129, 40, 0.89)",
              "rgba(50, 172, 45, 0.97)"
            ],
            "dateFormat": "YYYY-MM-DD HH:mm:ss",
            "decimals": 2,
            "pattern": "Value #F",
            "thresholds": [
              ""
            ],
            "type": "number",
            "unit": "Bps"
          },
          {
            "alias": "",
            "align": "auto",
            "colorMode": null,
            "colors": [
              "rgba(245, 54, 54, 0.9)",
              "rgba(237, 129, 40, 0.89)",
              "rgba(50, 172, 45, 0.97)"
            ],
            "dateFormat": "YYYY-MM-DD HH:mm:ss",
            "decimals": 2,
            "pattern": "Time",
            "thresholds": [],
            "type": "hidden",
            "unit": "short"
          },
          {
            "alias": "OUT",
            "align": "auto",
            "colorMode": null,
            "colors": [
              "rgba(245, 54, 54, 0.9)",
              "rgba(237, 129, 40, 0.89)",
              "rgba(50, 172, 45, 0.97)"
            ],
            "dateFormat": "YYYY-MM-DD HH:mm:ss",
            "decimals": 2,
            "mappingType": 1,
            "pattern": "Value #G",
            "thresholds": [],
            "type": "number",
            "unit": "Bps"
          }
        ],
        "targets": [
          {
            "exemplar": true,
            "expr": "histogram_quantile(0.50, sum(rate(nginx_ingress_controller_request_duration_seconds_bucket{ingress!='',controller_class=~\"${ZONE}\",controller_namespace='ingress-nginx'}[2m])) by (le, ingress))",
            "format": "table",
            "hide": false,
            "instant": true,
            "interval": "",
            "intervalFactor": 1,
            "legendFormat": "{{ ingress }}",
            "refId": "C"
          },
          {
            "exemplar": true,
            "expr": "histogram_quantile(0.90, sum(rate(nginx_ingress_controller_request_duration_seconds_bucket{ingress!='',controller_class=~\"${ZONE}\",controller_namespace='ingress-nginx'}[2m])) by (le, ingress))",
            "format": "table",
            "hide": false,
            "instant": true,
            "interval": "",
            "intervalFactor": 1,
            "legendFormat": "{{ ingress }}",
            "refId": "D"
          },
          {
            "exemplar": true,
            "expr": "histogram_quantile(0.99, sum(rate(nginx_ingress_controller_request_duration_seconds_bucket{ingress!='',controller_class=~\"${ZONE}\",controller_namespace='ingress-nginx'}[2m])) by (le, ingress))",
            "format": "table",
            "hide": false,
            "instant": true,
            "interval": "",
            "intervalFactor": 1,
            "legendFormat": "{{ destination_service }}",
            "refId": "E"
          },
          {
            "exemplar": true,
            "expr": "sum(irate(nginx_ingress_controller_request_size_sum{ingress!='',controller_class=~\"${ZONE}\",controller_namespace='ingress-nginx'}[2m])) by (ingress)",
            "format": "table",
            "hide": false,
            "instant": true,
            "interval": "",
            "intervalFactor": 1,
            "legendFormat": "{{ ingress }}",
            "refId": "F"
          },
          {
            "exemplar": true,
            "expr": "sum(irate(nginx_ingress_controller_response_size_sum{ingress!='',controller_class=~\"${ZONE}\",controller_namespace='ingress-nginx'}[2m])) by (ingress)",
            "format": "table",
            "instant": true,
            "interval": "",
            "intervalFactor": 1,
            "legendFormat": "{{ ingress }}",
            "refId": "G"
          }
        ],
        "timeFrom": null,
        "title": "Zone xxx Ingress Percentile Response Times and Transfer Rates",
        "transform": "table",
        "type": "table-old"
      },
      {
        "collapsed": false,
        "datasource": "$datasource",
        "gridPos": {
          "h": 1,
          "w": 24,
          "x": 0,
          "y": 35
        },
        "id": 15,
        "panels": [],
        "title": "预留空位01",
        "type": "row"
      },
      {
        "collapsed": false,
        "datasource": "$datasource",
        "gridPos": {
          "h": 1,
          "w": 24,
          "x": 0,
          "y": 36
        },
        "id": 2,
        "panels": [],
        "title": "预留空位02",
        "type": "row"
      }
    ],
    "refresh": "30s",
    "schemaVersion": 30,
    "style": "dark",
    "tags": [],
    "templating": {
      "list": []
    },
    "time": {
      "from": "now-15m",
      "to": "now"
    },
    "timepicker": {
      "hidden": false
    },
    "timezone": "",
    "title": "CLUSTER_${ZONE}_DASHBOARD",
    "uid": "",
    "version": 0
  }
}
EOF
