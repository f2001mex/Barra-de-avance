/**
 * @developed by      : VASS México
 * @author            : erik.romero@vasscompany.com
 * @last modified on  : 11-12-2024
 * @last modified by  : erik.romero@vasscompany.com
 * @description       : 
**/
public class BIT_GetConstancies_Response implements ResponseBody_cls {
	public Integer status;
	public Payload payload;
	public List<String> messages;
	public class Payload {
		public List<Date_x> date_x;
	}
	public class Date_x {
		public Integer year;
		public Integer yearExercise;
		public String type;
	}
	public ResponseBody_CLS deserializeResponseBody(String jsonBody) {
		jsonBody = jsonBody.replace('date', 'date_x');
		return (BIT_GetConstancies_Response) JSON.deserialize(jsonBody, BIT_GetConstancies_Response.class);
	}
}