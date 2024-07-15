using System.Collections.Generic;
using Newtonsoft.Json;

namespace Company.Function.Model.MetricsApi
{
    public class CustomMetric
    {
        public CustomMetric()
        {
            Series = new List<Series>();
            DimensionNames = new List<string>();
        }

        [JsonProperty("metric")]
        public string Metric { get; set; }
     
        [JsonProperty("namespace")]
        public string MetricNamespace { get; set; }

        [JsonProperty("dimNames")]
        public List<string> DimensionNames { get; set; }
        
        [JsonProperty("series")]
        public List<Series> Series { get; set; }
    }
}