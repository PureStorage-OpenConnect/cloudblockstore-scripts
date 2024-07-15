// Generated by https://quicktype.io

namespace Model.Json.CbsRest.Responses.HostPeformance
{
    using System;
    using System.Collections.Generic;

    using System.Globalization;
    using Newtonsoft.Json;
    using Newtonsoft.Json.Converters;

    public partial class HostsPerformanceResponse
    {
        [JsonProperty("continuation_token")]
        public object ContinuationToken { get; set; }

        [JsonProperty("items")]
        public Item[] Items { get; set; }

        [JsonProperty("more_items_remaining")]
        public object MoreItemsRemaining { get; set; }

        [JsonProperty("total")]
        public object[] Total { get; set; }

        [JsonProperty("total_item_count")]
        public object TotalItemCount { get; set; }
    }

    public partial class Item
    {
        [JsonProperty("usec_per_other_op")]
        public long UsecPerOtherOp { get; set; }

        [JsonProperty("others_per_sec")]
        public long OthersPerSec { get; set; }

        [JsonProperty("queue_depth")]
        public object QueueDepth { get; set; }

        [JsonProperty("local_queue_usec_per_op")]
        public long LocalQueueUsecPerOp { get; set; }

        [JsonProperty("mirrored_write_bytes_per_sec")]
        public long MirroredWriteBytesPerSec { get; set; }

        [JsonProperty("mirrored_writes_per_sec")]
        public long MirroredWritesPerSec { get; set; }

        [JsonProperty("usec_per_mirrored_write_op")]
        public long UsecPerMirroredWriteOp { get; set; }

        [JsonProperty("san_usec_per_mirrored_write_op")]
        public long SanUsecPerMirroredWriteOp { get; set; }

        [JsonProperty("queue_usec_per_mirrored_write_op")]
        public long QueueUsecPerMirroredWriteOp { get; set; }

        [JsonProperty("qos_rate_limit_usec_per_mirrored_write_op")]
        public long QosRateLimitUsecPerMirroredWriteOp { get; set; }

        [JsonProperty("service_usec_per_mirrored_write_op")]
        public long ServiceUsecPerMirroredWriteOp { get; set; }

        [JsonProperty("bytes_per_mirrored_write")]
        public long BytesPerMirroredWrite { get; set; }

        [JsonProperty("time")]
        public long Time { get; set; }

        [JsonProperty("name")]
        public string Name { get; set; }

        [JsonProperty("id")]
        public Guid Id { get; set; }

        [JsonProperty("read_bytes_per_sec")]
        public long ReadBytesPerSec { get; set; }

        [JsonProperty("write_bytes_per_sec")]
        public long WriteBytesPerSec { get; set; }

        [JsonProperty("usec_per_read_op")]
        public long UsecPerReadOp { get; set; }

        [JsonProperty("usec_per_write_op")]
        public long UsecPerWriteOp { get; set; }

        [JsonProperty("reads_per_sec")]
        public long ReadsPerSec { get; set; }

        [JsonProperty("writes_per_sec")]
        public long WritesPerSec { get; set; }

        [JsonProperty("queue_usec_per_read_op")]
        public long QueueUsecPerReadOp { get; set; }

        [JsonProperty("queue_usec_per_write_op")]
        public long QueueUsecPerWriteOp { get; set; }

        [JsonProperty("qos_rate_limit_usec_per_read_op")]
        public long QosRateLimitUsecPerReadOp { get; set; }

        [JsonProperty("qos_rate_limit_usec_per_write_op")]
        public long QosRateLimitUsecPerWriteOp { get; set; }

        [JsonProperty("san_usec_per_read_op")]
        public long SanUsecPerReadOp { get; set; }

        [JsonProperty("san_usec_per_write_op")]
        public long SanUsecPerWriteOp { get; set; }

        [JsonProperty("service_usec_per_read_op")]
        public long ServiceUsecPerReadOp { get; set; }

        [JsonProperty("service_usec_per_write_op")]
        public long ServiceUsecPerWriteOp { get; set; }

        [JsonProperty("bytes_per_read")]
        public long BytesPerRead { get; set; }

        [JsonProperty("bytes_per_write")]
        public long BytesPerWrite { get; set; }

        [JsonProperty("bytes_per_op")]
        public long BytesPerOp { get; set; }

        [JsonProperty("service_usec_per_read_op_cache_reduction")]
        public object ServiceUsecPerReadOpCacheReduction { get; set; }
    }

    public partial class HostsPerformanceResponse
    {
        public static HostsPerformanceResponse FromJson(string json) => JsonConvert.DeserializeObject<HostsPerformanceResponse>(json, Converter.Settings);
    }

    public static class Serialize
    {
        public static string ToJson(this HostsPerformanceResponse self) => JsonConvert.SerializeObject(self, Converter.Settings);
    }

    internal static class Converter
    {
        public static readonly JsonSerializerSettings Settings = new JsonSerializerSettings
        {
            MetadataPropertyHandling = MetadataPropertyHandling.Ignore,
            DateParseHandling = DateParseHandling.None,
            Converters = {
                new IsoDateTimeConverter { DateTimeStyles = DateTimeStyles.AssumeUniversal }
            },
        };
    }
}