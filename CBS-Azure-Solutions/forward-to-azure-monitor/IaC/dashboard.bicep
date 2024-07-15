param dashboardName string

@description('Name of the dashboard to display in Azure portal')
param dashboardDisplayName string = 'Pure CBS Metrics Dashboard'
param location string = resourceGroup().location

param functionAppId string

var cbsNamespace = 'cbs metrics'

resource dashboard 'Microsoft.Portal/dashboards@2020-09-01-preview' = {
  name: dashboardName
  location: location
  tags: {
    'hidden-title': dashboardDisplayName
  }
  properties: {
    lenses: [
      {
        order: 0
        parts: [
          {
            position: {
              x: 0
              y: 0
              colSpan: 6
              rowSpan: 4
            }
            metadata: {
              inputs: [
                {
                  name: 'options'
                  value: {
                    chart: {
                      metrics: [
                        {
                          resourceMetadata: {
                            id: functionAppId
                          }
                          name: 'Read bytes per sec'
                          aggregationType: 4
                          namespace: cbsNamespace
                          metricVisualization: {
                            displayName: 'Read bytes per sec'
                          }
                        }
                        {
                          resourceMetadata: {
                            id: functionAppId
                          }
                          name: 'Write bytes per sec'
                          aggregationType: 4
                          namespace: cbsNamespace
                          metricVisualization: {
                            displayName: 'Write bytes per sec'
                          }
                        }
                      ]
                      title: 'Avg Read/Write bytes per sec'
                      titleKind: 1
                      visualization: {
                        chartType: 2
                        legendVisualization: {
                          isVisible: true
                          position: 2
                          hideSubtitle: false
                        }
                        axisVisualization: {
                          x: {
                            isVisible: true
                            axisType: 2
                          }
                          y: {
                            isVisible: true
                            axisType: 1
                          }
                        }
                      }
                      timespan: {
                        relative: {
                          duration: 14400000
                        }
                        showUTCTime: false
                        grain: 1
                      }
                    }
                  }
                  isOptional: true
                }
                {
                  name: 'sharedTimeRange'
                  isOptional: true
                }
              ]
              type: 'Extension/HubsExtension/PartType/MonitorChartPart'
              settings: {
                content: {
                  options: {
                    chart: {
                      metrics: [
                        {
                          resourceMetadata: {
                            id: functionAppId
                          }
                          name: 'Read bytes per sec'
                          aggregationType: 4
                          namespace: cbsNamespace
                          metricVisualization: {
                            displayName: 'Read bytes per sec'
                          }
                        }
                        {
                          resourceMetadata: {
                            id: functionAppId
                          }
                          name: 'Write bytes per sec'
                          aggregationType: 4
                          namespace: cbsNamespace
                          metricVisualization: {
                            displayName: 'Write bytes per sec'
                          }
                        }
                      ]
                      title: 'Avg Read/Write bytes per sec'
                      titleKind: 1
                      visualization: {
                        chartType: 2
                        legendVisualization: {
                          isVisible: true
                          position: 2
                          hideSubtitle: false
                        }
                        axisVisualization: {
                          x: {
                            isVisible: true
                            axisType: 2
                          }
                          y: {
                            isVisible: true
                            axisType: 1
                          }
                        }
                        disablePinning: true
                      }
                    }
                  }
                }
              }
              filters: {
                MsPortalFx_TimeRange: {
                  model: {
                    format: 'local'
                    granularity: 'auto'
                    relative: '240m'
                  }
                }
              }
            }
          }
          {
            position: {
              x: 6
              y: 0
              colSpan: 4
              rowSpan: 4
            }
            metadata: {
              inputs: [
                {
                  name: 'options'
                  isOptional: true
                }
                {
                  name: 'sharedTimeRange'
                  isOptional: true
                }
              ]
              type: 'Extension/HubsExtension/PartType/MonitorChartPart'
              settings: {
                content: {
                  options: {
                    chart: {
                      metrics: [
                        {
                          resourceMetadata: {
                            id: functionAppId
                          }
                          name: 'Data Reduction Rate (DRR)'
                          aggregationType: 4
                          namespace: cbsNamespace
                          metricVisualization: {
                            displayName: 'Data Reduction Rate (DRR)'
                            resourceDisplayName: 'monitor-cbs-fapp'
                          }
                        }
                      ]
                      title: 'DRR'
                      titleKind: 2
                      visualization: {
                        chartType: 2
                        legendVisualization: {
                          isVisible: true
                          position: 2
                          hideSubtitle: false
                        }
                        axisVisualization: {
                          x: {
                            isVisible: true
                            axisType: 2
                          }
                          y: {
                            isVisible: true
                            axisType: 1
                          }
                        }
                        disablePinning: true
                      }
                    }
                  }
                }
              }
            }
          }
          {
            position: {
              x: 10
              y: 0
              colSpan: 6
              rowSpan: 4
            }
            metadata: {
              inputs: [
                {
                  name: 'options'
                  isOptional: true
                }
                {
                  name: 'sharedTimeRange'
                  isOptional: true
                }
              ]
              type: 'Extension/HubsExtension/PartType/MonitorChartPart'
              settings: {
                content: {
                  options: {
                    chart: {
                      metrics: [
                        {
                          resourceMetadata: {
                            id: functionAppId
                          }
                          name: 'Space - shared'
                          aggregationType: 4
                          namespace: cbsNamespace
                          metricVisualization: {
                            displayName: 'Space - shared'
                            resourceDisplayName: 'monitor-cbs-fapp'
                          }
                        }
                        {
                          resourceMetadata: {
                            id: functionAppId
                          }
                          name: 'Space - snapshots'
                          aggregationType: 4
                          namespace: cbsNamespace
                          metricVisualization: {
                            displayName: 'Space - snapshots'
                            resourceDisplayName: 'monitor-cbs-fapp'
                          }
                        }
                        {
                          resourceMetadata: {
                            id: functionAppId
                          }
                          name: 'Space - unique'
                          aggregationType: 4
                          namespace: cbsNamespace
                          metricVisualization: {
                            displayName: 'Space - unique'
                            resourceDisplayName: 'monitor-cbs-fapp'
                          }
                        }
                      ]
                      title: 'Avg Space - shared, snapshots, unique'
                      titleKind: 1
                      visualization: {
                        chartType: 1
                        legendVisualization: {
                          isVisible: true
                          position: 2
                          hideSubtitle: false
                        }
                        axisVisualization: {
                          x: {
                            isVisible: true
                            axisType: 2
                          }
                          y: {
                            isVisible: true
                            axisType: 1
                          }
                        }
                        disablePinning: true
                      }
                    }
                  }
                }
              }
            }
          }
          {
            position: {
              x: 0
              y: 4
              colSpan: 6
              rowSpan: 4
            }
            metadata: {
              inputs: [
                {
                  name: 'options'
                  isOptional: true
                }
                {
                  name: 'sharedTimeRange'
                  isOptional: true
                }
              ]
              type: 'Extension/HubsExtension/PartType/MonitorChartPart'
              settings: {
                content: {
                  options: {
                    chart: {
                      metrics: [
                        {
                          resourceMetadata: {
                            id: functionAppId
                          }
                          name: 'Usec_per_read_op'
                          aggregationType: 4
                          namespace: cbsNamespace
                          metricVisualization: {
                            displayName: 'Usec_per_read_op'
                            resourceDisplayName: 'monitor-cbs-fapp'
                          }
                        }
                        {
                          resourceMetadata: {
                            id: functionAppId
                          }
                          name: 'Usec_per_write_op'
                          aggregationType: 4
                          namespace: cbsNamespace
                          metricVisualization: {
                            displayName: 'Usec_per_write_op'
                            resourceDisplayName: 'monitor-cbs-fapp'
                          }
                        }
                      ]
                      title: 'Avg Usec_per_read_op and Avg Usec_per_write_op'
                      titleKind: 1
                      visualization: {
                        chartType: 2
                        legendVisualization: {
                          isVisible: true
                          position: 2
                          hideSubtitle: false
                        }
                        axisVisualization: {
                          x: {
                            isVisible: true
                            axisType: 2
                          }
                          y: {
                            isVisible: true
                            axisType: 1
                          }
                        }
                        disablePinning: true
                      }
                    }
                  }
                }
              }
            }
          }
        ]
      }
    ]
    metadata: {
      model: {
        timeRange: {
          value: {
            relative: {
              duration: 24
              timeUnit: 1
            }
          }
          type: 'MsPortalFx.Composition.Configuration.ValueTypes.TimeRange'
        }
        filterLocale: {
          value: 'en-us'
        }
        filters: {
          value: {
            MsPortalFx_TimeRange: {
              model: {
                format: 'utc'
                granularity: 'auto'
                relative: '1h'
              }
              displayCache: {
                name: 'UTC Time'
                value: 'Past hour'
              }
              filteredPartIds: [
              ]
            }
          }
        }
      }
    }
  }
}
