using Newtonsoft.Json;

namespace Company.Function.Model.MetricsApi
{
    public class Data
    {
        public Data()
        {
            MetricData = new CustomMetric();
        }

        [JsonProperty("baseData")]
        public CustomMetric MetricData { get; set; }
    }
}