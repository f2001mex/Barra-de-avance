/**
 *   ------------------------------------------------------------------------------------------------
 * @name     F4_Lead_Facebook_Wrapper
 * @author   jonas.montoya.landa@pwc.com
 * @date     Created: July 11 2023
 * ------------------------------------------------------------------------------------------------
 * @description Wrapper class for callouts to Facebook Conversions API
 * ------------------------------------------------------------------------------------------------
 * @changes		July 11 2023 jonas.montoya.landa@pwc.com Class Creation
 * ------------------------------------------------------------------------------------------------
 **/
public class F4_Lead_Facebook_Wrapper {
    
    /*
     * @description final String Constants to use as JSON body parameters and some values
     */
    private final String DATA_KEY = 'data';
    private final String EVENT_NAME_KEY = 'event_name';
    private final String EVENT_TIME_KEY = 'event_time';
    private final String ACTION_SOURCE_KEY = 'action_source';
    private final String ACTION_SOURCE_VALUE = 'system_generated';
    private final String USER_DATA_KEY = 'user_data';
    private final String LEAD_ID_KEY = 'lead_id';
    private final String CUSTOM_DATA_KEY = 'custom_data';
    private final String EVENT_SOURCE_KEY = 'event_source';
    private final String EVENT_SOURCE_VALUE = 'crm';
    private final String LEAD_EVENT_SOURCE_KEY = 'lead_event_source';
    private final String LEAD_EVENT_SOURCE_VALUE = 'salesforce';
    
    /*
     * @description Map<String,Object> Variable that wraps a JSON object
     */
    private Map<String,Object> wrapper = new Map<String,Object>();
    
    /*
     * @description List<Object> Contains data as part of the JSON object
     */
   	private List<Object> data = new List<Object>();
    
    /** ------------------------------------------------------------------------------------------------
	 * @Description Returns wrapper for serialization
	 * ------------------------------------------------------------------------------------------------
	 * @author   jonas.montoya.landa@pwc.com
	 * @date     July 11 2023
	 * @param 	 -
	 * @return   Map<String,Object>
	 * @example  JSON.serializePretty(wrapper.getWrapper())
	 * ------------------------------------------------------------------------------------------------*
	*/
    public Map<String,Object> getWrapper() {
        wrapper.put(DATA_KEY, data);
        return wrapper;
    }
	
    /** ------------------------------------------------------------------------------------------------
	 * @Description Adds another lead to wrapper data
	 * ------------------------------------------------------------------------------------------------
	 * @author   jonas.montoya.landa@pwc.com
	 * @date     July 11 2023
	 * @param 	 String Event name (Lead status to which it advanced)
	 * @param 	 Long UNIX timestamp when event ocurred
	 * @param	 Long Facebook Lead ID
	 * @return   void
	 * @example  wrapper.addLead('Asignado', 123455656, 098765432109876)
	 * ------------------------------------------------------------------------------------------------*
	*/
    public void addLead (String eventName, Long eventTime, Long leadId) {
        
        data.add(new Map<String,Object> {
        	EVENT_NAME_KEY => eventName,
            EVENT_TIME_KEY => eventTime,
            ACTION_SOURCE_KEY => ACTION_SOURCE_VALUE,
                
            USER_DATA_KEY => new Map<String,Object> {
            	LEAD_ID_KEY => leadId    
            },
                
            CUSTOM_DATA_KEY => new Map<String,Object> {
          		EVENT_SOURCE_KEY => EVENT_SOURCE_VALUE,
            	LEAD_EVENT_SOURCE_KEY => LEAD_EVENT_SOURCE_VALUE   
           	}
        });
    }

}