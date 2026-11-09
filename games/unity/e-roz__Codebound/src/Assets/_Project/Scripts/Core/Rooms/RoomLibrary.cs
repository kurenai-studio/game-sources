namespace Codebound.Core
{
    // Rooms written in code for now; later they move to data files.
    public static class RoomLibrary
    {
        public static bool Has(string roomId) => TryCreate(roomId, out _);

        public static bool TryCreate(string roomId, out RoomDefinition room)
        {
            switch (roomId)
            {
                case Room11.Id: room = Room11.Create(); break;
                case Room12.Id: room = Room12.Create(); break;
                case Room13.Id: room = Room13.Create(); break;
                case Room14.Id: room = Room14.Create(); break;
                case Room15.Id: room = Room15.Create(); break;
                case Room16.Id: room = Room16.Create(); break;
                case Room21.Id: room = Room21.Create(); break;
                case Room22.Id: room = Room22.Create(); break;
                case Room23.Id: room = Room23.Create(); break;
                case Room24.Id: room = Room24.Create(); break;
                case Room25.Id: room = Room25.Create(); break;
                case Room26.Id: room = Room26.Create(); break;
                case Room31.Id: room = Room31.Create(); break;
                case Room32.Id: room = Room32.Create(); break;
                case Room33.Id: room = Room33.Create(); break;
                case Room34.Id: room = Room34.Create(); break;
                case Room35.Id: room = Room35.Create(); break;
                case Room36.Id: room = Room36.Create(); break;
                case Room41.Id: room = Room41.Create(); break;
                case Room42.Id: room = Room42.Create(); break;
                case Room43.Id: room = Room43.Create(); break;
                case Room44.Id: room = Room44.Create(); break;
                case Room45.Id: room = Room45.Create(); break;
                case Room46.Id: room = Room46.Create(); break;
                case Room51.Id: room = Room51.Create(); break;
                case Room52.Id: room = Room52.Create(); break;
                case Room53.Id: room = Room53.Create(); break;
                case Room54.Id: room = Room54.Create(); break;
                case Room55.Id: room = Room55.Create(); break;
                case Room56.Id: room = Room56.Create(); break;
                case Room61.Id: room = Room61.Create(); break;
                case Room62.Id: room = Room62.Create(); break;
                case Room63.Id: room = Room63.Create(); break;
                case Room64.Id: room = Room64.Create(); break;
                case Room65.Id: room = Room65.Create(); break;
                case Room66.Id: room = Room66.Create(); break;
                case Room71.Id: room = Room71.Create(); break;
                case Room72.Id: room = Room72.Create(); break;
                case Room73.Id: room = Room73.Create(); break;
                case Room74.Id: room = Room74.Create(); break;
                case Room75.Id: room = Room75.Create(); break;
                case Room76.Id: room = Room76.Create(); break;
                default: room = null; break;
            }
            return room != null;
        }
    }
}
