using System;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Threading.Tasks;
using Company.Function.Model.MetricsApi;
using Azure.Identity;
using Microsoft.Extensions.Logging;
using Company.Function.Extensions;
using Company.Function.Model;
using System.ComponentModel.DataAnnotations;
using Model.Json.CbsRest.Responses;
using Newtonsoft.Json;
using Pure.Model.Runtime;
using Model.Json.CbsRest.Responses.HostPeformance;
using Model.Json.CbsRest.Responses.HostSpace;

namespace Company.Function.Services
{
    public class PureCbsRestMetricsClient
    {
        private readonly HttpClient _httpClient;
        private readonly ILogger _logger;

        private readonly PureCbsConfigurationOptions _options;

        private string _sessionToken = String.Empty;

        public PureCbsRestMetricsClient(
            IHttpClientFactory httpClientFactory,
            ILoggerFactory loggerFactory,
            PureCbsConfigurationOptions options
            )
        {
            _httpClient = httpClientFactory.CreateClient("IgnoreSSLCheck");
            _logger = loggerFactory.CreateLogger<PureCbsRestMetricsClient>();
            _options = options;

        }

        public async Task<bool> LoginAsync()
        {
            var sessionTokenResult = await GetSessionAccessTokenAsync();
            if (sessionTokenResult == null)
            {
                return false;
            }
            
            _sessionToken = sessionTokenResult.AuthToken;

            return true;
        }


        public async Task<HostsPerformanceResponse?> GetHostsPerformanceAsync(int resolution = 30000)
        {
            var request = new HttpRequestMessage
            {
                RequestUri = new Uri(
                         string.Concat("https://", _options.CbsLbIpAddressOrHostname, "/", "api", "/", _options.ApiVersion, "/arrays/performance", "?", $"resolution={resolution}")),
                Method = HttpMethod.Get
            };
            request.Headers.Add("x-auth-token", _sessionToken);

            var response = await _httpClient.SendAsync(request);
            string responseText = await response.Content.ReadAsStringAsync();
            _logger.LogWarning(responseText);

            if (!response.IsSuccessStatusCode)
            {
                _logger.LogError($"Gathering /hosts/performance failed! Status code: {response.StatusCode}, message: {responseText}");
                return null;
            }

            var responseModel = JsonConvert.DeserializeObject<HostsPerformanceResponse>(responseText);

            return responseModel;

        }


        public async Task<HostsSpaceResponse?> GetHostsSpaceAsync(int resolution = 300000)
        {
            var request = new HttpRequestMessage
            {
                RequestUri = new Uri(
                         string.Concat("https://", _options.CbsLbIpAddressOrHostname, "/", "api", "/", _options.ApiVersion, "/arrays/space", "?", $"resolution={resolution}")),
                Method = HttpMethod.Get
            };
            request.Headers.Add("x-auth-token", _sessionToken);

            var response = await _httpClient.SendAsync(request);
            string responseText = await response.Content.ReadAsStringAsync();
            _logger.LogWarning(responseText);

            if (!response.IsSuccessStatusCode)
            {
                _logger.LogError($"Gathering /hosts/space failed! Status code: {response.StatusCode}, message: {responseText}");
                return null;
            }

            var responseModel = JsonConvert.DeserializeObject<HostsSpaceResponse>(responseText);

            return responseModel;

        }

        private async Task<SessionTokenResult?> GetSessionAccessTokenAsync()
        {
            var request = new HttpRequestMessage
            {
                RequestUri = new Uri(
                string.Concat("https://", _options.CbsLbIpAddressOrHostname, "/", "api", "/", _options.ApiVersion, "/login")),
                Method = HttpMethod.Post
            };
            request.Headers.Add("api-token", _options.ApiToken);

            var response = await _httpClient.SendAsync(request);
            string responseText = await response.Content.ReadAsStringAsync();

            if (!response.IsSuccessStatusCode)
            {
                _logger.LogError($"Gathering CBS session access token failed! Status code: {response.StatusCode}, message: {responseText}");
                return null;
            }
            var authToken = response.Headers.First(x => x.Key.Equals("x-auth-token")).Value.Single();

            var loginResponse = JsonConvert.DeserializeObject<LoginResponse>(responseText);

            return new SessionTokenResult()
            {
                Username = loginResponse.items[0].username,
                AuthToken = authToken,
            };

        }

    }



}
