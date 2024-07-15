using System;
using Newtonsoft.Json;

namespace Company.Function.Model.MetricsApi
{
    public class MetricPayload
    {
        public MetricPayload()
        {
            Data = new Data();
        }

        [JsonProperty("time")]
        public DateTime Time { get; set; }

        [JsonProperty("data")]
        public Data Data { get; set; }
    }
}