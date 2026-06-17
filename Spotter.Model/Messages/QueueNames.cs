namespace Spotter.Model.Messages
{
    public static class QueueNames
    {
        public const string Geocoding = "spotter.geocoding";
        public const string GeocodingDlq = "spotter.geocoding.dlq";
        public const string Email = "spotter.email";
        public const string EmailDlq = "spotter.email.dlq";
    }
}
