/**
 *   ------------------------------------------------------------------------------------------------
 * @Name     F3_JsonToSobject_Test
 * @Author   luis.felipe.ortiz@pwc.com
 * @Date     Created: 01/01/2023
 * ------------------------------------------------------------------------------------------------
 * @Description Test class for the F3_JsonToSobject service
 * ------------------------------------------------------------------------------------------------
 * @Changes
 * 01/01/2023 luis.felipe.ortiz@pwc.com
 *             Class creation.
 * ------------------------------------------------------------------------------------------------
 **/
@IsTest
public with sharing class F3_JsonToSobject_Test {
	@isTest
	static void testJsonDecompose() {
		Map<String, List<SObject>> sObjectMap = F3_JsonToSobject_Service.jsonToSObject(
			'{"Data":{"clientes":[[{"cliente":{"NUM_CLIENTE_PK":"100","NOMBRE":"Test JSON","contratos":[[{"NUM_CONTRATO":"101","UNIDAD_NEGOCIO":"1","direcciones":[{"direccion":{"TIPO":"10"}},{"direccion":{"TIPO":"11"}}],"telefono":{"NUMERO":"55"}}],[{"NUM_CONTRATO":"102","UNIDAD_NEGOCIO":"2","direcciones":[{"direccion":{"TIPO":"20"}}]}]]}}]]}}',
			'Test1'
		);
		System.assertEquals(4, sObjectMap.size());
		System.assertEquals(1, sObjectMap.get('Account').size());
		System.assertEquals(2, sObjectMap.get('Contract').size());
		System.assertEquals(1, sObjectMap.get('Telefono_de_Contrato__c').size());
		System.assertEquals(3, sObjectMap.get('Direcci_n_de_Contrato__c').size());
		for (Account acc : (List<Account>) sObjectMap.get('Account')) {
			System.assert(String.isNotBlank(acc.Client_ID__c));
			System.assert(String.isNotBlank(acc.Client_ID__c));
		}
		for (Contract cont : (List<Contract>) sObjectMap.get('Contract')) {
			System.assert(String.isNotBlank(cont.ContractNumber__c));
			System.assert(String.isNotBlank(cont.BusinessUnitNumber__c));
			System.assert(String.isNotBlank(cont.Account.Client_ID__c));
			System.assert(String.isNotBlank(cont.IDSap__c));
		}
		for (Direcci_n_de_Contrato__c dir : (List<Direcci_n_de_Contrato__c>) sObjectMap.get('Direcci_n_de_Contrato__c')) {
			System.assert(String.isNotBlank(dir.AddressTypeNumber__c));
			System.assert(String.isNotBlank(dir.NUM_CONTRATO__r.IDSap__c));
			System.assert(String.isNotBlank(dir.Direction_ID__c));
		}
	}

	@isTest
	static void parseValue() {
		Object booleanObject = 'true';
		booleanObject = F3_JsonToSobject_Service.parseValue(booleanObject, 'Boolean', null, null);
		System.assert(booleanObject instanceof Boolean);
		System.assertEquals(true, booleanObject);

		Object doubleObject = '3.1416';
		doubleObject = F3_JsonToSobject_Service.parseValue(doubleObject, 'Double', null, null);
		System.assert(doubleObject instanceof Double);
		System.assertEquals(3.1416, doubleObject);

		Object integerObject = '3';
		integerObject = F3_JsonToSobject_Service.parseValue(integerObject, 'Integer', null, null);
		System.assert(integerObject instanceof Integer);
		System.assertEquals(3, integerObject);

		Object StringObject = 3;
		StringObject = F3_JsonToSobject_Service.parseValue(StringObject, 'String', null, null);
		System.assert(StringObject instanceof String);
		System.assertEquals('3', StringObject);

		Object dateObject = '20/02/2020';
		dateObject = F3_JsonToSobject_Service.parseValue(dateObject, 'Date', null, null);
		System.assert(dateObject instanceof Date);
		System.assertEquals(Date.newInstance(2020, 2, 20), dateObject);

		Object randomObject = 3;
		randomObject = F3_JsonToSobject_Service.parseValue(randomObject, 'Random', null, null);
		System.assertEquals(3, randomObject);
	}
}