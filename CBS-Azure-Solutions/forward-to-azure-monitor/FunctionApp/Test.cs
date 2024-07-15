using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using Company.Function.Model;
using Company.Function.Model.MetricsApi;
using Company.Function.Services;
using Company.Function.Extensions;
using Newtonsoft.Json;

namespace Company.Function
{
    public class Test
    {
        const string CONFIG_FUNCAPP_ID = "funcAppId";
        const string CONFIG_FUNCAPP_LOCATION = "functionAppLocation";

        private readonly ILogger<Test> _logger;

        private readonly AzureMonitorMetricsClient _metricsClient;

        public Test(ILogger<Test> logger, AzureMonitorMetricsClient metricsClient)
        {
            _logger = logger;
            _metricsClient = metricsClient;
        }

        [Function("Test")]
        public async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Anonymous, "get", "post")] HttpRequest req
        )
        {
            _logger.LogInformation("C# HTTP trigger function processed a request.");

string metricName = "Capacity - unique";
string metricNamespace = "Test Metrics";
int count = 1;
decimal value = 11;

            var payload = new MetricPayload { Time = DateTime.UtcNow };
            var metricData = payload.Data.MetricData;
            metricData.Metric = metricName;
            metricData.MetricNamespace = metricNamespace;
            metricData.DimensionNames.Add("storagecontainer");

            var series = new List<Series>(){
                new Series()
                    {
                        Count = count,
                        Max = value,
                        Min = value,
                        Sum = value,
                        DimensionValues = new List<string>(){
                            "testcontainer1"
                        }
                    }
            };

            metricData.Series.AddRange(series);

            var functionAppResourceId = Environment.GetEnvironmentVariable(CONFIG_FUNCAPP_ID);
            var functionAppRegion = Environment.GetEnvironmentVariable(CONFIG_FUNCAPP_LOCATION);
            string debug = JsonConvert.SerializeObject(payload);
            try{
                await _metricsClient.CreateMetricAsync(functionAppRegion, functionAppResourceId, payload);
            }
            catch(Exception e ){  
debug += e.Message;

            }


            value = 15;

            payload = new MetricPayload { Time = DateTime.UtcNow };
            metricData = payload.Data.MetricData;
            metricData.Metric = metricName;
            metricData.MetricNamespace = metricNamespace;
            metricData.DimensionNames.Add("storagecontainer");

            series = new List<Series>(){
                new Series()
                    {
                        Count = count,
                        Max = value,
                        Min = value,
                        Sum = value,
                        DimensionValues = new List<string>(){
                            "testcontainer2"
                        }
                    }
            };

            metricData.Series.AddRange(series);

            debug = JsonConvert.SerializeObject(payload);
            try{
                await _metricsClient.CreateMetricAsync(functionAppRegion, functionAppResourceId, payload);
            }
            catch(Exception e ){  
debug += e.Message;

            }

            return new OkObjectResult("Welcome to Azure Functions!" + debug);
        }
    }
}
