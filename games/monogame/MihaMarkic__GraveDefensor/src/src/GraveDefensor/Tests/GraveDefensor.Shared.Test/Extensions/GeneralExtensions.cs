namespace GraveDefensor.Shared.Test
{
    public static class GeneralExtensions
    {
        public static T Assign<T>(this T source, out T value)
        {
            value = source;
            return source;
        }
    }
}
