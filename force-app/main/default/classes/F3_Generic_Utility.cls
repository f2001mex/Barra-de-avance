/**
 *   ------------------------------------------------------------------------------------------------
 * @Name     F3_Generic_Utility
 * @Author   luis.felipe.ortiz@pwc.com
 * @Date     Created: 12/08/2022
 * @Group    PWC
 * ------------------------------------------------------------------------------------------------
 * @Description Class made to create generic methods
 * ------------------------------------------------------------------------------------------------
 * @Changes
 * 12/08/2022 luis.felipe.ortiz@pwc.com
 *             Class creation.
 * ------------------------------------------------------------------------------------------------
 **/
public with sharing class F3_Generic_Utility {
	private static Id businessHoursId;
	/** ------------------------------------------------------------------------------------------------
	 * @Description Calculate work days between two dates without using business days. It includes holidays.
	 *   ------------------------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     23/11/2022
	 * @param
	 * @return   Integer
	 * @example  calculateWorkDays(Date startDate, Date endDate)
	 * ------------------------------------------------------------------------------------------------**/
	public static Integer calculateWorkDays(Date startDate, Date endDate) {
		final Set<Date> setHolidayDate = populateHolidays();
		Integer workDaysCounter = 0;
		Integer offDaysCounter = 0;
		workDaysCounter += startDate.daysBetween(endDate) + 1;
		for (Date tmpDate = startDate; tmpDate <= endDate; tmpDate = tmpDate.addDays(1)) {
			Datetime tmpDatetime = (DateTime) tmpDate;
			String strDayOfWeek = tmpDatetime.formatGmt('EEEE');
			if (strDayOfWeek == 'Sunday' || strDayOfWeek == 'Saturday' || setHolidayDate.contains(tmpDate)) {
				offDaysCounter++;
			}
		}
		return workDaysCounter - offDaysCounter;
	}

	/** ------------------------------------------------------------------------------------------------
	 * @Description Calculate work days between two dates using business days. It includes holidays.
	 *   ------------------------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     23/11/2022
	 * @param
	 * @return   Integer
	 * @example  calculateWorkDaysV2(Date startDate, Date endDate, String businessHoursName)
	 * ------------------------------------------------------------------------------------------------**/
	public static Integer calculateWorkDaysV2(Date startDate, Date endDate, String businessHoursName) {
		if (String.isBlank(businessHoursId)) {
			businessHoursId = [SELECT Id FROM BusinessHours WHERE name = :businessHoursName LIMIT 1][0].id;
		}
		if (String.isBlank(businessHoursId)) {
			throw new GeneralUtilityException('No existe el horario "' + businessHoursName + '"');
		}
		Datetime startDatetime = Datetime.newInstanceGMT(startDate.year(), startDate.month(), startDate.day(), 0, 0, 0);
		Datetime endDatetime = Datetime.newInstanceGMT(endDate.year(), endDate.month(), endDate.day(), 23, 59, 59);
		Long hours = Math.abs(BusinessHours.diff(businessHoursId, startDatetime, endDatetime) / 1000 / 60 / 60);
		Decimal days = hours / 24;
		return Integer.valueOf(days);
	}

	/** ------------------------------------------------------------------------------------------------
	 * @Description Check if day is workable.
	 *   ------------------------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     23/11/2022
	 * @param
	 * @return   Boolean
	 * @example  isDayWorkable(Datetime targetDay, String businessHoursName)
	 * ------------------------------------------------------------------------------------------------**/
	public static Boolean isDayWorkable(Datetime targetDay, String businessHoursName) {
		if (String.isBlank(businessHoursId)) {
			businessHoursId = [SELECT Id FROM BusinessHours WHERE name = :businessHoursName LIMIT 1][0].id;
		}
		if (String.isBlank(businessHoursId)) {
			throw new GeneralUtilityException('No existe el horario "' + businessHoursName + '"');
		}
		return BusinessHours.isWithin(businessHoursId, targetDay);
	}

	/** ------------------------------------------------------------------------------------------------
	 * @Description Generic method to split names based on Mexico's most probable combination
	 *   ------------------------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     23/11/2022
	 * @param
	 * @return   Map<String, String>
	 * @example  beforeInsert()
	 * ------------------------------------------------------------------------------------------------**/
	public static Map<String, String> splitCompleteName(String completeName) {
		Map<String, String> names = new Map<String, String>();
		if (String.isNotBlank(completeName)) {
			List<String> partsOfName = completeName != null ? completeName.split(' ') : new List<String>();
			if (partsOfName.size() == 1) {
				names.put('LastName', partsOfName[0]);
			} else if (partsOfName.size() == 2) {
				names.put('FirstName', partsOfName[0]);
				names.put('LastName', partsOfName[1]);
			} else if (partsOfName.size() == 3) {
				names.put('FirstName', partsOfName[0]);
				names.put('LastName', partsOfName[1] + ' ' + partsOfName[2]);
			} else if (partsOfName.size() == 4) {
				names.put('FirstName', partsOfName[0] + ' ' + partsOfName[1]);
				names.put('LastName', partsOfName[2] + ' ' + partsOfName[3]);
			} else if (partsOfName.size() > 4) {
				names.put('FirstName', partsOfName[0] + ' ' + partsOfName[1]);
				partsOfName.remove(0);
				partsOfName.remove(1);
				names.put('LastName', String.join(partsOfName, ' '));
			}
		}
		return names;
	}

	/** ------------------------------------------------------------------------------------------------
	 * @Description Generic method to check if variable isn't empty
	 *   ------------------------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     23/11/2022
	 * @param
	 * @return   Boolean
	 * @example  isFilled(Object objectToCheck, String type)
	 * ------------------------------------------------------------------------------------------------**/
	public static Boolean isFilled(Object objectToCheck, String type) {
		Boolean hasValue = true;
		switch on type.toLowerCase() {
			when 'string' {
				if (objectToCheck == null || String.isBlank(String.valueOf(objectToCheck))) {
					hasValue = false;
				}
			}
			when 'mapstringstring' {
				if (objectToCheck == null || ((Map<String, String>) objectToCheck).isEmpty()) {
					hasValue = false;
				}
			}
			when 'mapstringobject' {
				if (objectToCheck == null || ((Map<String, Object>) objectToCheck).isEmpty()) {
					hasValue = false;
				}
			}
			when 'mapobjectobject' {
				if (objectToCheck == null || ((Map<Object, Object>) objectToCheck).isEmpty()) {
					hasValue = false;
				}
			}
			when 'list' {
				if (objectToCheck == null || ((List<Object>) objectToCheck).isEmpty()) {
					hasValue = false;
				}
			}
			when else {
				if (objectToCheck == null) {
					hasValue = false;
				}
			}
		}
		return hasValue;
	}

	/** ------------------------------------------------------------------------------------------------
	 * @Description Get set of holidays
	 *   ------------------------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     23/11/2022
	 * @param
	 * @return   Set<Date>
	 * @example  populateHolidays()
	 * ------------------------------------------------------------------------------------------------**/
	public static Set<Date> populateHolidays() {
		List<Holiday> lstHolidays = [SELECT Id, ActivityDate FROM Holiday WHERE ActivityDate = THIS_YEAR OR ActivityDate = LAST_YEAR];
		Set<Date> setHolidayDate = new Set<Date>();
		for (Holiday objHoliday : lstHolidays) {
			setHolidayDate.add(objHoliday.ActivityDate);
		}
		return setHolidayDate;
	}

	/** ------------------------------------------------------------------------------------------------
	 * @Description Generic exception class
	 *   ------------------------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     23/11/2022
	 * @param
	 * @return   void
	 * ------------------------------------------------------------------------------------------------**/
	class GeneralUtilityException extends Exception {
	}
}