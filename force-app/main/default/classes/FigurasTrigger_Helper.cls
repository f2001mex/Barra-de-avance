public with sharing class FigurasTrigger_Helper {
	public static void trimName(list<Figuras_Relacionadas__c> figurasNew) {
		for (Figuras_Relacionadas__c figura : figurasNew) {
			if (String.isBlank(figura.FullName__c)) {
				figura.addError('La figura relacionada no tiene nombre');
				continue;
			}
			figura.name = figura.FullName__c.length() > 80 ? figura.FullName__c.substring(0, 80) : figura.FullName__c;
		}
	}
}