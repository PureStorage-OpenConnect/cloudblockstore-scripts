using System.Collections.Generic;
using Newtonsoft.Json;

namespace Company.Function.Model.MetricsApi
{
    public class Series
    {
        public Series()
        {
            DimensionValues = new List<string>();
        }

        [JsonProperty("dimValues")]
        public List<string> DimensionValues { get; set; }
        
        [JsonProperty("min")]
        public decimal Min { get; set; }
        
        [JsonProperty("max")]
        public decimal Max { get; set; }
        
        [JsonProperty("sum")]
        public decimal Sum { get; set; }

        [JsonProperty("count")]
        public int Count { get; set; }
    }
}