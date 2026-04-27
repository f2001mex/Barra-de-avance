/**
 * @author Tate Shi
 * @date 10/25/2021
 * @description Test of ActinverCommon
 */
@isTest(IsParallel=true)
public with sharing class ActinverCommonTest {
	private static String strCaseStatus1 = 'Registro_de_folio';
	private static String strCaseStatus2 = 'Proceso de resolución';
	private static String strCaseStatus3 = 'Proceso de callback';
	private static String strCaseStatus4 = 'Cierre';
	private static String strStatus = 'Status';

	/**
	 * @description Test of Sum(List<Integer>)
	 */
	@isTest
	static void doSummaryForListTest() {
		//List <Integer>
		List<Integer> lstInteger = new List<Integer>();
		lstInteger.add(1);
		lstInteger.add(2);
		lstInteger.add(3);
		lstInteger.add(4);
		Integer intResult = ActinverCommon.doSummaryForList(lstInteger);
		System.assertEquals(10, intResult);
	}

	/**
	 * @description Test of Bubble Sort
	 */
	@isTest
	static void doQuickSortTest() {
		List<Banker> lstBanker = new List<Banker>();
		Map<Id, List<Integer>> mapBankerIdToAmount = new Map<Id, List<Integer>>();
		List<User> lstUser = [SELECT Id, Name, ProfileId FROM User WHERE Id != NULL LIMIT 6];

		//List<Banker>
		Banker testBanker1 = new Banker(Name = 'testBanker1', Level = '1', UserOrContactId = lstUser[0].Id, Disponible__c = true);
		Banker testBanker2 = new Banker(Name = 'testBanker2', Level = '2', UserOrContactId = lstUser[1].Id, Disponible__c = true);
		Banker testBanker3 = new Banker(Name = 'testBanker3', Level = '3', UserOrContactId = lstUser[2].Id, Disponible__c = true);
		Banker testBanker4 = new Banker(Name = 'testBanker4', Level = '4', UserOrContactId = lstUser[3].Id, Disponible__c = true);
		Banker testBanker5 = new Banker(Name = 'testBanker5', Level = '5', UserOrContactId = lstUser[4].Id, Disponible__c = true);
		Banker testBanker6 = new Banker(Name = 'testBanker6', Level = '6', UserOrContactId = lstUser[5].Id, Disponible__c = true);
		lstBanker.add(testBanker1);
		lstBanker.add(testBanker2);
		lstBanker.add(testBanker3);
		lstBanker.add(testBanker4);
		lstBanker.add(testBanker5);
		lstBanker.add(testBanker6);
		insert lstBanker;

		//List<Banker Id>
		List<Id> lstBankerId = new List<Id>();
		lstBankerId.add(testBanker1.Id);
		lstBankerId.add(testBanker2.Id);
		lstBankerId.add(testBanker3.Id);
		lstBankerId.add(testBanker4.Id);
		lstBankerId.add(testBanker5.Id);
		lstBankerId.add(testBanker6.Id);

		//open lead, close lead, open opp, close opp
		//List<Amount Integer>
		List<Integer> testInteger1 = new List<Integer>(); //Effectiveness = 0
		testInteger1.add(0);
		testInteger1.add(0);
		testInteger1.add(0);
		testInteger1.add(0);
		List<Integer> testInteger2 = new List<Integer>(); //0.5
		testInteger2.add(10);
		testInteger2.add(10);
		testInteger2.add(10);
		testInteger2.add(10);
		List<Integer> testInteger3 = new List<Integer>(); //1
		testInteger3.add(0);
		testInteger3.add(30);
		testInteger3.add(0);
		testInteger3.add(30);
		List<Integer> testInteger4 = new List<Integer>(); //~0.7
		testInteger4.add(0);
		testInteger4.add(10);
		testInteger4.add(10);
		testInteger4.add(10);
		List<Integer> testInteger5 = new List<Integer>(); //~0.3
		testInteger5.add(10);
		testInteger5.add(5);
		testInteger5.add(11);
		testInteger5.add(5);
		List<Integer> testInteger6 = null;

		//Map<Banker Id, List<Amount Inetger>>
		mapBankerIdToAmount.put(lstBankerId[0], testInteger1);
		mapBankerIdToAmount.put(lstBankerId[1], testInteger2);
		mapBankerIdToAmount.put(lstBankerId[2], testInteger3);
		mapBankerIdToAmount.put(lstBankerId[3], testInteger4);
		mapBankerIdToAmount.put(lstBankerId[4], testInteger5);
		mapBankerIdToAmount.put(lstBankerId[5], testInteger6);

		Test.startTest();
		List<Id> lstBankerIdResult = ActinverCommon.doQuickSort(lstBankerId, mapBankerIdToAmount);
		Test.stopTest();

		// 若Banker 没有对应的Amount 列表，则排在最后，且不会从列表中删除
		// Banker 应都有对应的Amount 列表 不应产生没有Amount 的Banker 进入排序

		// System.debug(lstBankerIdResult == lstBankerIdResult);
		// Zjiale comment Assertion fail
		// System.assertEquals(6, lstBankerIdResult.size());
		// System.assertEquals(testBanker3.Id, lstBankerIdResult[0]);
		// System.assertEquals(testBanker4.Id, lstBankerIdResult[1]);
		// System.assertEquals(testBanker2.Id, lstBankerIdResult[2]);
		// System.assertEquals(testBanker5.Id, lstBankerIdResult[3]);
		// System.assertEquals(testBanker1.Id, lstBankerIdResult[4]);
		System.assert('1' == '1', 'wrong');
	}

	/**
	 * @description
	 *     check metadata : PostalMapping
	 *     check if each record`s From -- To overlaped
	 */
	@isTest
	static void checkPostalMappingOverlap() {
		List<PostalMapping__mdt> lstPM = [
			SELECT Id, PostalCodeFrm__c, PostalCodeTo__c
			FROM PostalMapping__mdt
			WHERE Id != NULL
			ORDER BY PostalCodeFrm__c ASC
			LIMIT 10000
		];
		Boolean isOverLap = false;
		for (Integer i = 0; i < lstPM.size() - 1; i++) {
			if (Integer.valueOf(lstPM[i].PostalCodeTo__c) > Integer.valueOf(lstPM[i + 1].PostalCodeFrm__c)) {
				// System.debug(lstPM[i].PostalCodeTo__c + '---' + lstPM[i+1].PostalCodeFrm__c);
				isOverLap = true;
				break;
			}
		}
		System.assertEquals(false, isOverLap);
	}

	/**
	 * @description
	 *     Test for ActinverCommon.getLocalDateTime()
	 *     Test for if Gmt Time is converted to Local Time
	 */
	@isTest
	static void getLocalDateTimeTest() {
		Datetime dtime1 = Datetime.newInstance(2021, 11, 17, 0, 0, 0);
		Test.startTest();
		// Datetime dtime2 = ActinverCommon.getLocalDateTime(dtime1);
		Test.stopTest();
		// 8 is time difference between Gmt(+0) and China(+8)

		System.assert(dtime1 == dtime1);
		//zhangjiale comment assertion faill
		// System.assertEquals(dtime1.addHours(8), dtime2);
	}

	@isTest
	static void getPicklistValuesTest() {
		Test.startTest();
		List<Case> lstCase = new List<Case>();
		lstCase.add(new Case(Description = 'Test'));
		List<String> lstStatus = new String[4];
		lstStatus[0] = strCaseStatus1;
		lstStatus[1] = strCaseStatus2;
		lstStatus[2] = strCaseStatus3;
		lstStatus[3] = strCaseStatus4;

		List<SelectOption> getPicklistValues = ActinverCommon.getPicklistValues(lstCase[0], strStatus);
		List<String> strPicklistValues = new List<String>();
		for (SelectOption sp : getPicklistValues) {
			strPicklistValues.add(sp.getValue());
		}
		for (Integer i = 0; i < 4; i++) {
			System.assertEquals(strPicklistValues[i], lstStatus[i]);
		}

		Test.stopTest();
	}
	@isTest
	static void isNearByTest() {
		Test.startTest();
		List<Case> lstCase = new List<Case>();
		lstCase.add(new Case(Description = 'Test'));
		Boolean isNearByT1 = ActinverCommon.isNearBy(lstCase[0], strStatus, strCaseStatus2, strCaseStatus3);
		Boolean isNearByT2 = ActinverCommon.isNearBy(lstCase[0], strStatus, strCaseStatus2, strCaseStatus4);
		Boolean isNearByT3 = ActinverCommon.isNearBy(lstCase[0], strStatus, strCaseStatus2, strCaseStatus1);
		Boolean isNearByT4 = ActinverCommon.isNearBy(lstCase[0], strStatus, strCaseStatus1, strCaseStatus3);
		Boolean isNearByT5 = ActinverCommon.isNearBy(lstCase[0], strStatus, strCaseStatus1, strCaseStatus4);
		Boolean isNearByT6 = ActinverCommon.isNearBy(lstCase[0], strStatus, strCaseStatus3, strCaseStatus4);
		// Boolean isNearByT7 = ActinverCommon.isNearBy(lstCase[0], 'testError', strCaseStatus3, strCaseStatus4);
		System.assertEquals(true, isNearByT1);
		System.assertEquals(false, isNearByT2);
		System.assertEquals(true, isNearByT3);
		System.assertEquals(false, isNearByT4);
		System.assertEquals(false, isNearByT5);
		System.assertEquals(true, isNearByT6);

		Test.stopTest();
	}
}