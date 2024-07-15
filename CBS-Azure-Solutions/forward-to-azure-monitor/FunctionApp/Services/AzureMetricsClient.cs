using System;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Threading.Tasks;
using Company.Function.Model.MetricsApi;
using Azure.Identity;
using Microsoft.Extensions.Logging;
using Company.Function.Extensions;

namespace Company.Function.Services
{
    public class AzureMonitorMetricsClient
    {
        private const string AzureMonitorRegionalEndpoint = "https://{0}.monitoring.azure.com";
        private readonly HttpClient _client;

        private readonly ILogger _logger;

        public AzureMonitorMetricsClient(IHttpClientFactory httpClientFactory, ILoggerFactory loggerFactory)
        {
            _client = httpClientFactory.CreateClient();
            _logger = loggerFactory.CreateLogger<AzureMonitorMetricsClient>();


        }

        private string GetAccessToken()
        {


            var credential = new ManagedIdentityCredential();
            var token = credential.GetToken(new Azure.Core.TokenRequestContext(new[] { "https://monitoring.azure.com/" }));

            string accessToken = token.Token;

            _logger.LogInformation($"Credentials token: {accessToken}");

            return accessToken;

        }

        public async Task CreateMetricAsync(string region, string resourceId, MetricPayload detail)
        {
            var payload = detail.ToStringContent();
            var regionIngressEndpoint = string.Format(AzureMonitorRegionalEndpoint, region);

            var request = new HttpRequestMessage
            { RequestUri = new Uri(string.Concat(regionIngressEndpoint, resourceId, "/metrics")), Content = payload, Method = HttpMethod.Post };

            _logger.LogInformation($"Request: {request.RequestUri.ToString()}");
            var token = GetAccessToken();

            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);

            var response = await _client.SendAsync(request);
            string responseText = await response.Content.ReadAsStringAsync();
            _logger.LogInformation($"Response: {responseText}");
        }

        public async Task BasicPushMetricAsync(string region, string resourceId, string metricNamespace, string metricName, decimal value, int count = 1)
        {
            var payload = new MetricPayload { Time = DateTime.UtcNow };
            var metricData = payload.Data.MetricData;
            metricData.Metric = metricName;
            metricData.MetricNamespace = metricNamespace;
            metricData.DimensionNames.Add(metricName);

            var series = new List<Series>(){
                new Series()
                    {
                        Count = count,
                        Max = value,
                        Min = value,
                        Sum = value,
                        DimensionValues = new List<string>(){
                            metricName
                        }
                    }
            };

            metricData.Series.AddRange(series);

            if (metricData.Series.Count > 0)
            {
                await CreateMetricAsync(region, resourceId, payload);
            }

        }
    }
}
