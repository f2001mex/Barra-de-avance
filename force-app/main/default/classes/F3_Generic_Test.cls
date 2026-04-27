@isTest(IsParallel=true)
public with sharing class F3_Generic_Test {
	@isTest
	static void verifyWorkDaysWithoutHolidays() {
		Date startDate = [SELECT ActivityDate FROM Holiday WHERE ActivityDate = THIS_YEAR OR ActivityDate = LAST_YEAR LIMIT 1][0]
			.ActivityDate.toStartOfWeek()
			.addDays(7);
		System.assertEquals(
			5,
			F3_Generic_Utility.calculateWorkDays(startDate, startDate.addDays(6)),
			'Count of workable days considering Monday-Friday week'
		);
	}

	@isTest
	static void verifyWorkDaysWithHoliday() {
		Id businessHoursId = [SELECT Id FROM BusinessHours WHERE name = 'Workable Days' LIMIT 1][0].id;
		Date startDate;
		List<Holiday> lstHolidays = [SELECT Id, ActivityDate FROM Holiday WHERE ActivityDate = THIS_YEAR OR ActivityDate = LAST_YEAR];
		for (Holiday objHoliday : lstHolidays) {
			Datetime tmpDatetime = (DateTime) objHoliday.ActivityDate;
			String strDayOfWeek = tmpDatetime.formatGmt('EEEE');
			if (!(strDayOfWeek == 'Sunday' || strDayOfWeek == 'Saturday')) {
				startDate = objHoliday.ActivityDate;
				break;
			}
		}
		System.assertEquals(
			4,
			F3_Generic_Utility.calculateWorkDays(startDate.toStartOfWeek(), startDate.toStartOfWeek().addDays(6)),
			'Count of workable days considering Monday-Friday week and one day as holiday'
		);
	}

	@isTest
	static void verifyWorkDaysV2WithoutHolidays() {
		Date startDate = [SELECT ActivityDate FROM Holiday WHERE ActivityDate = THIS_YEAR OR ActivityDate = LAST_YEAR LIMIT 1][0]
			.ActivityDate.toStartOfWeek()
			.addDays(7);
		System.assertEquals(
			5,
			F3_Generic_Utility.calculateWorkDaysV2(startDate, startDate.addDays(6), 'Workable Days'),
			'Count of workable days considering Monday-Friday week'
		);
	}

	@isTest
	static void verifyWorkDaysV2WithHoliday() {
		Id businessHoursId = [SELECT Id FROM BusinessHours WHERE name = 'Workable Days' LIMIT 1][0].id;
		Date startDate;
		List<Holiday> lstHolidays = [SELECT Id, ActivityDate FROM Holiday WHERE ActivityDate = THIS_YEAR OR ActivityDate = LAST_YEAR];
		for (Holiday objHoliday : lstHolidays) {
			Datetime tmpDatetime = (DateTime) objHoliday.ActivityDate;
			String strDayOfWeek = tmpDatetime.formatGmt('EEEE');
			if (!(strDayOfWeek == 'Sunday' || strDayOfWeek == 'Saturday')) {
				startDate = objHoliday.ActivityDate;
				break;
			}
		}
		System.assertEquals(
			4,
			F3_Generic_Utility.calculateWorkDaysV2(startDate.toStartOfWeek(), startDate.toStartOfWeek().addDays(6), 'Workable Days'),
			'Count of workable days considering Monday-Friday week and one day as holiday'
		);
	}

	@isTest
	static void verifyIsFilled() {
		String sFilled = 'String';
		String sNotFilled;
		System.assertEquals(true, F3_Generic_Utility.isFilled(sFilled, 'string'));
		System.assertEquals(false, F3_Generic_Utility.isFilled(sNotFilled, 'string'));
		Map<String, String> mssFilled = new Map<String, String>{ 's' => 's' };
		Map<String, String> mssNotFilled = new Map<String, String>();
		System.assertEquals(true, F3_Generic_Utility.isFilled(mssFilled, 'mapstringstring'));
		System.assertEquals(false, F3_Generic_Utility.isFilled(mssNotFilled, 'mapstringstring'));
		Map<String, Object> msoFilled = new Map<String, Object>{ 's' => 's' };
		Map<String, Object> msoNotFilled = new Map<String, Object>();
		System.assertEquals(true, F3_Generic_Utility.isFilled(msoFilled, 'mapstringobject'));
		System.assertEquals(false, F3_Generic_Utility.isFilled(msoNotFilled, 'mapstringobject'));
		Map<Object, Object> mooFilled = new Map<Object, Object>{ 's' => 's' };
		Map<Object, Object> mooNotFilled = new Map<Object, Object>();
		System.assertEquals(true, F3_Generic_Utility.isFilled(mooFilled, 'mapobjectobject'));
		System.assertEquals(false, F3_Generic_Utility.isFilled(mooNotFilled, 'mapobjectobject'));
		List<Object> lFilled = new List<Object>();
		lFilled.add('s');
		List<Object> lNotFilled = new List<Object>();
		System.assertEquals(true, F3_Generic_Utility.isFilled(lFilled, 'list'));
		System.assertEquals(false, F3_Generic_Utility.isFilled(lNotFilled, 'list'));
		String eFilled = 'String';
		String eNotFilled;
		System.assertEquals(true, F3_Generic_Utility.isFilled(eFilled, 'sdfx'));
		System.assertEquals(false, F3_Generic_Utility.isFilled(eNotFilled, 'sdfx'));
	}
}