using System.Collections.Generic;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;
using Company.Function.Model;
using Newtonsoft.Json;

namespace Company.Function.Extensions
{
    internal static class ObjectExtensions
    {
        private const string JsonMediaType = "application/json";

        public static StringContent ToStringContent(this object instance)
        {
            var jsonContent = JsonConvert.SerializeObject(instance);

            return new StringContent(jsonContent, Encoding.UTF8, JsonMediaType);
        }
    }
}