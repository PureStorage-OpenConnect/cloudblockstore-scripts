using System;
using Company.Function.Model;
using Company.Function.Model.MetricsApi;
using Company.Function.Services;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using Azure.Identity;
using Azure.Security.KeyVault.Secrets;
using Azure.Core;

namespace Company.Function
{
    public class SendEveryMinuteMetricFunction
    {
        private readonly ILogger _logger;
        private readonly AzureMonitorMetricsClient _metricsClient;
        private readonly PureCbsRestMetricsClient _pureCbsRestMetricsClient;

        private readonly SecretClient _kvClient;

        private string _functionAppResourceId;
        private string _functionAppRegion;

        const string CBS_METRIC_NAMESPACE = "CBS metrics";
        const string CBS_READ_BYTES_PER_SEC = "Read bytes per sec";
        const string CBS_WRITE_BYTES_PER_SEC = "Write bytes per sec";
        const string CBS_DRR = "Data Reduction Rate (DRR)";

        const string CBS_SPACE_CAPACITY = "Space - capacity";
        const string CBS_SPACE_SHARED = "Space - shared";
        const string CBS_SPACE_UNIQUE = "Space - unique";
        const string CBS_SPACE_REPLICATION = "Space - replication";
        const string CBS_SPACE_SNAPSHOSTS = "Space - snapshots";
        const string CBS_SPACE_SYSTEM = "Space - system";
        const string CBS_SPACE_EMPTY = "Space - empty";

        const string CBS_SPACE_UTILIZATION = "Space - utilization";


        const string CBS_USEC_PER_READ_OP = "Usec_per_read_op";
        const string CBS_USEC_PER_WRITE_OP = "Usec_per_write_op";


        const string CONFIG_KEY_VAULT_URL = "keyVaultUri";
        const string KEY_VAULT_SECRET_CBS_API_KEY = "CBS-API-KEY";
        const string CONFIG_CBS_IP_ADDRESS = "cbsIpAddressInMonitoringVnet";

        const string CONFIG_FUNCAPP_ID = "funcAppId";
        const string CONFIG_FUNCAPP_LOCATION = "functionAppLocation";

        public SendEveryMinuteMetricFunction(
            ILoggerFactory loggerFactory,
        IHttpClientFactory httpClientFactory,
        AzureMonitorMetricsClient metricsClient)
        {
            _logger = loggerFactory.CreateLogger<SendEveryMinuteMetricFunction>();
            _metricsClient = metricsClient;

            string cbsApiKey = "";

            try
            {
                // logging into KeyVault
                SecretClientOptions kvOptions = new SecretClientOptions()
                {
                    Retry = {
                        Delay= TimeSpan.FromSeconds(2),
                        MaxDelay = TimeSpan.FromSeconds(16),
                        MaxRetries = 5,
                        Mode = RetryMode.Exponential
                    }
                };

                var kvUrl = Environment.GetEnvironmentVariable(CONFIG_KEY_VAULT_URL);

                _kvClient = new SecretClient(new Uri(kvUrl), new DefaultAzureCredential(), kvOptions);

                KeyVaultSecret secret = _kvClient.GetSecret(KEY_VAULT_SECRET_CBS_API_KEY);

                cbsApiKey = secret.Value;
                _logger.LogInformation(cbsApiKey.Substring(0, 3) + "...");
            }
            catch (Exception e)
            {
                _logger.LogCritical($"Accessing keyvault failed! {e.Message}");
            }

            try
            {
                var cbsIpAddress = Environment.GetEnvironmentVariable(CONFIG_CBS_IP_ADDRESS);
                _functionAppResourceId = Environment.GetEnvironmentVariable(CONFIG_FUNCAPP_ID);
                _functionAppRegion = Environment.GetEnvironmentVariable(CONFIG_FUNCAPP_LOCATION);

                _pureCbsRestMetricsClient = new PureCbsRestMetricsClient(
                    httpClientFactory,
                    loggerFactory,
                    options: new PureCbsConfigurationOptions()
                    {
                        ApiVersion = "2.25",
                        CbsLbIpAddressOrHostname = cbsIpAddress,
                        ApiToken = cbsApiKey
                    }
                );
            }
            catch (Exception e)
            {
                _logger.LogCritical("Problem during creating rest metrics client!");
            }
        }

        [Function("SendEveryMinuteMetricFunction")]
        public async Task Run([TimerTrigger("0 * * * * *")] TimerInfo myTimer)
        {

            // login into CBS
            var credentialsResult = await _pureCbsRestMetricsClient.LoginAsync();


            // ask CBS REST endpoint
            var hostPerformanceResults = await _pureCbsRestMetricsClient.GetHostsPerformanceAsync();

            var serialized = JsonConvert.SerializeObject(hostPerformanceResults);

            _logger.LogWarning(serialized);

            if (hostPerformanceResults == null)
            {
                _logger.LogError("Host performance results null!");
                return;
            }
            else
            {
                // read bytes per sec
                try
                {
                    var readBytesPerSec = hostPerformanceResults.Items[0].ReadBytesPerSec;
                    await _metricsClient.BasicPushMetricAsync(_functionAppRegion, _functionAppResourceId, CBS_METRIC_NAMESPACE, CBS_READ_BYTES_PER_SEC, readBytesPerSec);
                }
                catch (Exception) { }

                // write bytes per sec
                try
                {
                    var writeBytesPerSec = hostPerformanceResults.Items[0].WriteBytesPerSec;
                    await _metricsClient.BasicPushMetricAsync(_functionAppRegion, _functionAppResourceId, CBS_METRIC_NAMESPACE, CBS_WRITE_BYTES_PER_SEC, writeBytesPerSec);
                }
                catch (Exception) { }

                //I/O - usec read
                try
                {
                    var usec_per_read_op = Convert.ToDecimal(hostPerformanceResults.Items[0].UsecPerReadOp);
                    await _metricsClient.BasicPushMetricAsync(_functionAppRegion, _functionAppResourceId, CBS_METRIC_NAMESPACE, CBS_USEC_PER_READ_OP, usec_per_read_op);
                }
                catch (Exception) { }

                //I/O - usec write
                try
                {
                    var usec_per_write_op = Convert.ToDecimal(hostPerformanceResults.Items[0].UsecPerWriteOp);
                    await _metricsClient.BasicPushMetricAsync(_functionAppRegion, _functionAppResourceId, CBS_METRIC_NAMESPACE, CBS_USEC_PER_WRITE_OP, usec_per_write_op);
                }
                catch (Exception) { }

            }

            decimal drr = 0, spaceCapacity = 0, spaceReplication = 0, spaceUnique = 0, spaceShared = 0, spaceSnapshots = 0, spaceSystem = 0, spaceEmpty = 0, spaceUtilization = 0;

            var hostSpaceResults = await _pureCbsRestMetricsClient.GetHostsSpaceAsync();
            if (hostSpaceResults == null)
            {
                _logger.LogError("Host space results null!");
            }
            else
            {
                // DRR
                try
                {
                    drr = Convert.ToDecimal(hostSpaceResults.Items[0].Space["data_reduction"]);
                    await _metricsClient.BasicPushMetricAsync(_functionAppRegion, _functionAppResourceId, CBS_METRIC_NAMESPACE, CBS_DRR, drr);
                }
                catch (Exception) { }

                //space - capacity
                try
                {
                    spaceCapacity = Convert.ToDecimal(hostSpaceResults.Items[0].Capacity);
                    await _metricsClient.BasicPushMetricAsync(_functionAppRegion, _functionAppResourceId, CBS_METRIC_NAMESPACE, CBS_SPACE_CAPACITY, spaceCapacity);
                }
                catch (Exception e) {
                    _logger.LogError($"Failed gathering of capacity: ${e.Message}");

                }


                // space - unique
                try
                {
                    spaceUnique = Convert.ToDecimal(hostSpaceResults.Items[0].Space["unique"]);
                    await _metricsClient.BasicPushMetricAsync(_functionAppRegion, _functionAppResourceId, CBS_METRIC_NAMESPACE, CBS_SPACE_UNIQUE, spaceUnique);
                }
                catch (Exception) { }

                // space - replication
                try
                {
                    spaceReplication = Convert.ToDecimal(hostSpaceResults.Items[0].Space["replication"]);
                    await _metricsClient.BasicPushMetricAsync(_functionAppRegion, _functionAppResourceId, CBS_METRIC_NAMESPACE, CBS_SPACE_REPLICATION, spaceReplication);
                }
                catch (Exception) { }

                // space - shared
                try
                {
                    spaceShared = Convert.ToDecimal(hostSpaceResults.Items[0].Space["shared"]);
                    await _metricsClient.BasicPushMetricAsync(_functionAppRegion, _functionAppResourceId, CBS_METRIC_NAMESPACE, CBS_SPACE_SHARED, spaceShared);
                }
                catch (Exception) { }

                //space - snapshots
                try
                {
                    spaceSnapshots = Convert.ToDecimal(hostSpaceResults.Items[0].Space["snapshots"]);
                    await _metricsClient.BasicPushMetricAsync(_functionAppRegion, _functionAppResourceId, CBS_METRIC_NAMESPACE, CBS_SPACE_SNAPSHOSTS, spaceSnapshots);
                }
                catch (Exception) { }

                //space - system
                try
                {
                    spaceSystem = Convert.ToDecimal(hostSpaceResults.Items[0].Space["system"]);
                    await _metricsClient.BasicPushMetricAsync(_functionAppRegion, _functionAppResourceId, CBS_METRIC_NAMESPACE, CBS_SPACE_SYSTEM, spaceSystem);
                }
                catch (Exception) { }

                //space - empty
                try
                {
                    spaceEmpty = spaceCapacity - spaceReplication - spaceShared - spaceSnapshots - spaceUnique;
                    await _metricsClient.BasicPushMetricAsync(_functionAppRegion, _functionAppResourceId, CBS_METRIC_NAMESPACE, CBS_SPACE_EMPTY, spaceEmpty);
                }
                catch (Exception) { }

                //space - utilization
                try
                {
                    spaceUtilization = (spaceSystem + spaceReplication + spaceShared + spaceSnapshots + spaceUnique) / spaceCapacity;
                    await _metricsClient.BasicPushMetricAsync(_functionAppRegion, _functionAppResourceId, CBS_METRIC_NAMESPACE, CBS_SPACE_UTILIZATION, spaceUtilization);
                }
                catch (Exception) { }

            }


            if (myTimer.ScheduleStatus is not null)
            {
                _logger.LogInformation($"Next timer schedule at: {myTimer.ScheduleStatus.Next}");
            }
        }
    }
}
