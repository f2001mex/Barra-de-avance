/** ------------------------------------------------------------------------------------------------
 *   ------------------------------------------------------------------------------------------------
 * @Name     FigurasTrigger_Handler
 * @Author   luis.felipe.ortiz@pwc.com
 * @Date     Created: 18/03/2022
 * @Group    PWC
 *   ------------------------------------------------------------------------------------------------
 * @Description Handler for the Figuras Trigger.
 *   ------------------------------------------------------------------------------------------------
 * @Changes
 * 18/03/2022 luis.felipe.ortiz@pwc.com
 *             Class creation.
 *   ------------------------------------------------------------------------------------------------
 **/
public without sharing class FigurasTrigger_Handler extends TriggerHandler {
	list<Figuras_Relacionadas__c> figurasNew = Trigger.new;
	list<Figuras_Relacionadas__c> figurasOld = Trigger.Old;
	Map<id, Figuras_Relacionadas__c> figurasNewMap = ((Map<Id, Figuras_Relacionadas__c>) (Trigger.NewMap));
	Map<id, Figuras_Relacionadas__c> figurasOldMap = ((Map<Id, Figuras_Relacionadas__c>) (Trigger.OldMap));

	/** ------------------------------------------------------------------------------------------------
	 * @Description executes all the logic before inserting a Figuras_Relacionadas__c record
	 *   ------------------------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     18/03/2022
	 * @param
	 * @return   void
	 * @example  beforeInsert()
	 * ------------------------------------------------------------------------------------------------**/
	@TestVisible
	protected override void beforeInsert() {
		FigurasTrigger_Helper.trimName(figurasNew);
	}

	/** ------------------------------------------------------------------------------------------------
	 * @Description executes all the logic before inserting a Figuras_Relacionadas__c record
	 *   ------------------------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     18/03/2022
	 * @param
	 * @return   void
	 * @example  beforeUpdate()
	 * ------------------------------------------------------------------------------------------------**/
	@TestVisible
	protected override void beforeUpdate() {
		FigurasTrigger_Helper.trimName(figurasNew);
	}
}