/**
 * @author Tate Shi
 * @date 12/09/2021
 * @description Test Trigger :  BranchUnitTrigger and BranchUnitHandler
 */
@isTest(IsParallel=true)
public with sharing class BranchUnitTriggerTest {
	/**
	 * @description
	 *     check if BranchUnit.Name is Duplicate
	 *     when Insert or Update
	 *     Issue #31
	 */
	@isTest
	static void checkBUNameDuplicateTest() {
		List<BranchUnit> lstBU = new List<BranchUnit>();
		BranchUnit BUTest1 = new BranchUnit(Name = 'BUtest1', Type = 'Physical');
		BranchUnit BUTest2 = new BranchUnit(Name = 'BUtest2', Type = 'Physical');
		BranchUnit BUTest3 = new BranchUnit(Name = 'BUtest1', Type = 'Physical'); // duplicate
		lstBU.add(BUTest1);
		lstBU.add(BUTest2);
		lstBU.add(BUtest3);

		Test.startTest();
		Database.SaveResult[] srlistInsert = Database.insert(lstBU, false);

		BranchUnit objBUtoUpdate = [SELECT Id, Name FROM BranchUnit WHERE Name = 'BUtest2'];
		objBUtoUpdate.Name = 'BUtest1';
		Database.SaveResult srlistUpdate = Database.update(objBUtoUpdate, false);

		Test.stopTest();
		// System.debug(srlistInsert[2]);
		System.assertEquals(true, srlistInsert[0].isSuccess());
		System.assertEquals(true, srlistInsert[1].isSuccess());
		System.assertEquals(false, srlistInsert[2].isSuccess());

		System.assertEquals(true, srlistUpdate.isSuccess());
	}
}