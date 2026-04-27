public interface Interface_Handle_Task {
    //Data_Structure_Handle_Task.responseWithTasksList consultTask(Data_Structure_Handle_Task.TaskObject taskObject);
    Data_Structure_Handle_Task.ResultTask createTask(Data_Structure_Handle_Task.TaskObject taskObject);
    Data_Structure_Handle_Task.ResultTask updateTask(Id taskIdParam, Data_Structure_Handle_Task.TaskObject taskObject);
    Data_Structure_Handle_Task.ResultTask deleteTaskById(Id taskId);
}