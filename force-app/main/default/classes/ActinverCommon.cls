/**
 * @author Dio, Xi
 * @date 10/25/2021
 * @description Common method of Actinver
 */
public inherited sharing class ActinverCommon {
	/**
	 * @params List<Integer>
	 * @description sum the elements in List
	 * @return Integer : sum(List<Integer>)
	 */
	public static Integer doSummaryForList(List<Integer> lstIntData) {
		Integer intRtn = 0;
		for (Integer intValue : lstIntData) {
			intRtn += intValue;
		}

		return intRtn;
	}

	/**
	 * @params List<Id> BankerId List, Map<Id, List<Integer>> BankerId to Amount
	 * @description bubble sort the Banker List by Effectiveness
	 * @return List<Id> sorted BankerId Lsit
	 */
	public static List<Id> doQuickSort(List<Id> lstBanker, Map<Id, List<Integer>> mapBankerIdToAmountGlobal) {
		// this temp value
		Integer intClosedLeadThis = 0;
		Integer intClosedOppThis = 0;
		Integer intSummaryThis = 0;
		// next temp value
		Integer intClosedLeadNext = 0;
		Integer intClosedOppNext = 0;
		Integer intSummaryNext = 0;

		Id objTmpBankerId = null;

		// if lstBanker size >= 2, will enter into below source
		for (Integer i = 0; i < lstBanker.size() - 1; i++) {
			for (Integer j = 0; j < lstBanker.size() - 1 - i; j++) {
				List<Integer> lstAmountThis = mapBankerIdToAmountGlobal.get(lstBanker[j]);
				List<Integer> lstAmountNext = mapBankerIdToAmountGlobal.get(lstBanker[j + 1]);
				if (lstAmountThis == null || lstAmountNext == null) {
					continue;
				}

				// Closed for this
				intClosedLeadThis = lstAmountThis[1];
				intClosedOppThis = lstAmountThis[3];
				intSummaryThis = doSummaryForList(lstAmountThis);

				// Closed for next
				intClosedLeadNext = lstAmountNext[1];
				intClosedOppNext = lstAmountNext[3];
				intSummaryNext = doSummaryForList(lstAmountNext);

				// have no Case or Opportunity , assign first , default efficiency = 1
				Double dbEffectivenessThis = 1;
				Double dbEffectivenessNext = 1;
				if (intSummaryThis > 0) {
					dbEffectivenessThis = (intClosedLeadThis + intClosedOppThis) / Double.valueOf(intSummaryThis);
				}

				if (intSummaryNext > 0) {
					dbEffectivenessNext = (intClosedLeadNext + intClosedOppNext) / Double.valueOf(intSummaryNext);
				}

				//Bubble Sort Order By Efficiency DES
				if (dbEffectivenessThis < dbEffectivenessNext) {
					objTmpBankerId = lstBanker[j];
					lstBanker[j] = lstBanker[j + 1];
					lstBanker[j + 1] = objTmpBankerId;
				}
			}
		}

		return lstBanker;
	}

	/**
	 * @param Datetime dtimeGmtTime : normally get from DB
	 * @description
	 *     convert Gmt Time to Local Time
	 *     only used in date calculation
	 *     get Gmt time from DB, convert it to Local Time Of Type Datetime
	 *     store Local Time in the form of Gmt Time
	 */
	public static Datetime getLocalDateTime(Datetime dtimeGmtTime) {
		Datetime dtimeLocalTime = dtimeGmtTime.Date();
		dtimeLocalTime = dtimeLocalTime.addHours(dtimeGmtTime.hour());
		dtimeLocalTime = dtimeLocalTime.addMinutes(dtimeGmtTime.minute());
		dtimeLocalTime = dtimeLocalTime.addSeconds(dtimeGmtTime.second());
		return dtimeLocalTime;
	}

	/**
	 * @description get picklist from the field of the object
	 *
	 * @param obj api name of object
	 * @param strFieldName　field name
	 * @return
	 */
	public static List<SelectOption> getPicklistValues(SObject obj, String strFieldName) {
		List<SelectOption> lstOptions = new List<SelectOption>();
		// Get the object type of the SObject.
		Schema.sObjectType objType = obj.getSObjectType();
		// Describe the SObject using its object type.
		Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
		// Get a map of fields for the SObject
		map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();
		// Get the list of picklist values for this field.
		List<Schema.PicklistEntry> values = fieldMap.get(strFieldName).getDescribe().getPickListValues();
		// Add these values to the selectoption list.
		for (Schema.PicklistEntry a : values) {
			lstOptions.add(new SelectOption(a.getValue(), a.getLabel()));
		}
		//System.debug('getPicklistValues:' + lstOptions);
		return lstOptions;
	}

	//to limit the option?
	/**
	 * @description
	 *
	 * @param
	 */
	public static Boolean isNearBy(SObject obj, String strFieldName, String strOld, String strNew) {
		//Let'say
		Boolean isResult = false;
		Integer oldIndex = 0;
		Integer newIndex = 0;
		try {
			List<SelectOption> lstPickListValues = getPicklistValues(obj, strFieldName);

			for (Integer i = 0; i < lstPickListValues.size(); i++) {
				SelectOption selOtion = lstPickListValues[i];
				if (selOtion.getValue().equals(strOld)) {
					oldIndex = i;
				}
				if (selOtion.getValue().equals(strNew)) {
					newIndex = i;
				}
			}
			// Math.abs <= 1
			if (lstPickListValues != null && newIndex < lstPickListValues.size()) {
				if (Math.abs(newIndex - oldIndex) <= 1) {
					isResult = true;
				}
			}
		} catch (Exception e) {
			System.debug('Error Msg : ' + e.getMessage());
			System.debug('Error Line No : ' + e.getLineNumber());
		}
		return isResult;
	}
}