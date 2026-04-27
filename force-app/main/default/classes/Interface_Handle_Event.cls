public interface Interface_Handle_Event {
    Data_Structure_Handle_Task.ResultTask createEvent(Data_Structure_Handle_Task.EventObject taskEvent);
    Data_Structure_Handle_Task.ResultTask changeEventStatus(Data_Structure_Handle_Task.TaskObject taskEvent);
    Data_Structure_Handle_Task.ResponseWithEvent getEventDetails(String eventId);
    Data_Structure_Handle_Task.ResultTask editEventById(String eventId, Data_Structure_Handle_Task.EventObject taskEvent);
    Data_Structure_Handle_Task.ResultTask deleteEventById(String eventId);
    Data_Structure_Handle_Task.ResponseWithRelatedPerson consultRelatedPerson(string contactName);
    
}