/**
 * @description       : Clase wrapper para el response de OpenText
 * @author            : Martin Martinez
 * @group             : 
 * @last modified on  : 07-15-2025
 * @last modified by  : Martin Martinez
**/
public class PV_OpenText_Response implements ResponseBody_cls {
    public Integer status;
    public String errorCode;
    public String appCode;
    public List<String> messages;
    public Result result;
    public Payload payload;

    public class Result {
        public String resultCode;
        public String resultType;
        public String resultMessage;
    }

    public class Payload {
        public String status;
        public String referenceId;
    }

    public ResponseBody_cls deserializeResponseBody(String jsonBody) {
        return (PV_OpenText_Response) JSON.deserialize(jsonBody, PV_OpenText_Response.class);
    }
}