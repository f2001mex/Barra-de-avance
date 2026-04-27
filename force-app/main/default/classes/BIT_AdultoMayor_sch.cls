/**
 * @developed by      : VASS México
 * @author            : erik.romero@vasscompany.com
 * @last modified on  : 07-02-2025
 * @last modified by  : erik.romero@vasscompany.com
 * @description       : 
**/
global class BIT_AdultoMayor_sch implements Schedulable {
	global void execute (SchedulableContext sc) {
		Database.executeBatch(new BIT_AdultoMayor_bch(),200);
	}
}