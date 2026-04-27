/**
 *   ------------------------------------------------------------------------------------------------
 * @Name     F3_JsonToSobject_Service
 * @Author   luis.felipe.ortiz@pwc.com
 * @Date     Created: 01/01/2023
 * ------------------------------------------------------------------------------------------------
 * @Description Class to dynamically convert a json to SObjects
 * ------------------------------------------------------------------------------------------------
 * @Changes
 * 01/01/2023 luis.felipe.ortiz@pwc.com
 *             Class creation.
 * ------------------------------------------------------------------------------------------------
 **/
public with sharing class F3_JsonToSobject_Service {
	static Map<String, F3_JSON_Structure__mdt> structuresMap = new Map<String, F3_JSON_Structure__mdt>();

	/** -----------------------------------------------------------------------------
	 * @Description Init of the process.
	 *--------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     31/01/2023
	 * @return   Map<String, List<SObject>>
	 * @example  jsonToSobject(String jsonString, String serviceName)
	 **/
	public static Map<String, List<SObject>> jsonToSobject(String jsonString, String serviceName) {
		retrieveJsonStructure(serviceName);
		return objectGenerator(jsonString, new Map<String, Object>(), null);
	}

	/** -----------------------------------------------------------------------------
	 * @Description In charge of accessing the layers of the json and convert it to sobjects.
	 *--------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     31/01/2023
	 * @return   Map<String, List<SObject>>
	 * @example  objectGenerator(String jsonString, Map<String, Object> parentValues, Object relationshipID)
	 **/
	private static Map<String, List<SObject>> objectGenerator(String jsonString, Map<String, Object> parentValues, Object relationshipID) {
		Map<String, List<SObject>> generatedSObjects = new Map<String, List<SObject>>();
		String currentJson = jsonString;
		if (String.isNotBlank(currentJson)) {
			switch on collectionType(currentJson) {
				when 'Map' {
					Map<String, Object> jsonObject = (Map<String, Object>) JSON.deserializeUntyped(currentJson);
					for (String jsonKey : jsonObject.keySet()) {
						F3_JSON_Structure__mdt currentStructure = structuresMap.get(jsonKey);
						if (currentStructure == null) {
							continue;
						}
						if (currentStructure.F3_JSON_Field_Mapping__r.isEmpty()) {
							Map<String, List<SObject>> tmpGeneratedSObjects = objectGenerator(
								JSON.serialize(jsonObject.get(currentStructure.F3_Wrapper_Name__c)),
								parentValues,
								relationshipID
							);
							generatedSObjects = mergeMaps(generatedSObjects, tmpGeneratedSObjects);
						} else {
							Object jsonValue = jsonObject.remove(currentStructure.F3_Wrapper_Name__c);
							currentJson = JSON.serialize(jsonObject);
							switch on collectionType(JSON.serialize(jsonValue)) {
								when 'Map' {
									GeneratorResults generatorResult = generateSObject(
										(Map<String, Object>) jsonValue,
										currentStructure,
										parentValues,
										relationshipID
									);
									if (generatorResult.newSObject != null) {
										if (generatedSObjects.containsKey(currentStructure.F3_Object_Name__c)) {
											generatedSObjects.get(currentStructure.F3_Object_Name__c)
												.add((SObject) generatorResult.newSObject);
										} else {
											generatedSObjects.put(
												currentStructure.F3_Object_Name__c,
												new List<SObject>{ (SObject) generatorResult.newSObject }
											);
										}
									}
									if (String.isNotBlank(generatorResult.nestedObject)) {
										Map<String, List<SObject>> tmpGeneratedSObjects = objectGenerator(
											generatorResult.nestedObject,
											generatorResult.nextParentValues,
											generatorResult.nextRelationshipID
										);
										generatedSObjects = mergeMaps(generatedSObjects, tmpGeneratedSObjects);
									}
								}
								when 'List' {
									for (Object possibleSObject : (List<Object>) jsonValue) {
										Map<String, List<SObject>> tmpGeneratedSObjects = objectGenerator(
											JSON.serialize(new Map<String, Object>{ jsonKey => possibleSObject }),
											parentValues,
											relationshipID
										);
										generatedSObjects = mergeMaps(generatedSObjects, tmpGeneratedSObjects);
									}
								}
								when 'Invalid' {
									throw new F3_JsonToSobject_Exception('JSON Invalido');
								}
							}
						}
					}
				}
				when 'List' {
					for (Object jsonList : (List<Object>) JSON.deserializeUntyped(currentJson)) {
						Map<String, List<SObject>> tmpGeneratedSObjects = objectGenerator(
							JSON.serialize(jsonList),
							parentValues,
							relationshipID
						);
						generatedSObjects = mergeMaps(generatedSObjects, tmpGeneratedSObjects);
					}
				}
				when 'Invalid' {
					throw new F3_JsonToSobject_Exception('JSON Invalido');
				}
			}
		}
		return generatedSObjects;
	}

	/** -----------------------------------------------------------------------------
	 * @Description Merge maps.
	 *--------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     31/01/2023
	 * @return   Map<String, List<SObject>>
	 * @example  mergeMaps(Map<String, List<SObject>> initialMap, Map<String, List<SObject>> mapToMerge)
	 **/
	private static Map<String, List<SObject>> mergeMaps(Map<String, List<SObject>> initialMap, Map<String, List<SObject>> mapToMerge) {
		Map<String, List<SObject>> mergedMap = initialMap;
		if (!mapToMerge.isEmpty()) {
			for (String objectName : mapToMerge.keySet()) {
				if (mergedMap.containsKey(objectName)) {
					mergedMap.get(objectName).addAll(mapToMerge.get(objectName));
				} else {
					mergedMap.put(objectName, mapToMerge.get(objectName));
				}
			}
		}
		return mergedMap;
	}

	/** -----------------------------------------------------------------------------
	 * @Description Creation of the sobject record with all of its dependencies. It
	 * implements an edition hook to allow a deeper customization of each sobject in
	 * a certain structure
	 *--------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     31/01/2023
	 * @return   Map<String, List<SObject>>
	 * @example  generateSObject(Map<String, Object> jsonObject,F3_JSON_Structure__mdt currentStructure,Map<String, Object> parentValues,Object relationshipID)
	 **/
	private static GeneratorResults generateSObject(
		Map<String, Object> jsonObject,
		F3_JSON_Structure__mdt currentStructure,
		Map<String, Object> parentValues,
		Object relationshipID
	) {
		Map<String, String> fieldsToPass = new Map<String, String>();
		String relationshipField = null;
		jsonObject.putAll(parentValues);
		GeneratorResults results = new GeneratorResults();
		sObject newSObject = ((SObject) Type.forName('Schema', currentStructure.F3_Object_Name__c).newInstance())
			.getSObjectType()
			.newSObject();
		for (F3_JSON_Field_Mapping__mdt fieldMapping : currentStructure.F3_JSON_Field_Mapping__r) {
			if (jsonObject.containsKey(fieldMapping.F3_JSON_Field_Name__c)) {
				Object fieldData = jsonObject.remove(fieldMapping.F3_JSON_Field_Name__c);
				if (fieldMapping.F3_Is_Parent_Id_For_Child_Levels__c == true) {
					relationshipField = fieldMapping.F3_SF_Api_Name__c;
				}
				if (fieldMapping.F3_Pass_Value_To_Child__c == true) {
					fieldsToPass.put(fieldMapping.F3_JSON_Field_Name__c, fieldMapping.F3_SF_Api_Name__c);
				}
				newSObject = addFieldToSObject(
					newSObject,
					fieldData,
					fieldMapping.F3_SF_Api_Name__c,
					fieldMapping.F3_Data_Type__c,
					fieldMapping.F3_Relationship_External_Field__c
				);
			}
		}
		if (!jsonObject.isEmpty()) {
			results.nestedObject = JSON.serialize(jsonObject);
		}
		if (!newSObject.getPopulatedFieldsAsMap().isEmpty()) {
			if (String.isNotBlank(currentStructure.F3_Relationship_Field__c) && relationshipID != null) {
				newSObject = addFieldToSObject(
					newSObject,
					relationshipID,
					currentStructure.F3_Relationship_Field__c,
					'Relationship',
					currentStructure.F3_Relationship_External_Field__c
				);
			}
			if (String.isNotBlank(currentStructure.F3_Object_Edition_Hook__c)) {
				List<String> editionHook = currentStructure.F3_Object_Edition_Hook__c.split(',');
				if (editionHook.size() == 2) {
					Callable extension = (Callable) Type.forName(editionHook[0]).newInstance();
					newSObject = (SObject) extension.call(editionHook[1], new Map<String, Object>{ 'newSObject' => newSObject });
				}
			}
			if (String.isNotBlank(relationshipField)) {
				results.nextRelationshipID = newSObject.get(relationshipField);
			}
			if (!fieldsToPass.isEmpty()) {
				for (String field : fieldsToPass.keySet()) {
					results.nextParentValues.put(field, newSObject.get(fieldsToPass.get(field)));
				}
			}
			if (currentStructure.F3_Hash_Field__c != null && currentStructure.F3_Fields_For_Hash__c != null) {
				String hashVal = generateHashVal(newSObject, currentStructure.F3_Fields_For_Hash__c.split(','));
				newSObject = addFieldToSObject(newSObject, hashVal, currentStructure.F3_Hash_Field__c, 'String', null);
				results.nextRelationshipID = hashVal;
			}
			results.newSObject = newSObject;
		}
		return results;
	}

	/** ------------------------------------------------------------------------------------------------
	 * Add field and value to an sObject
	 * -------------------------------------------------------------------------------------------------
	 * author   luis.felipe.ortiz@pwc.com
	 * date     12/08/2022
	 * param    sObject newSObject, object value, String fieldMapping, String type
	 * return   sObject
	 * example	addFieldToSObject(newSObject, fieldsInSObject.get(field), fieldMapping.F3_SF_Api_Name__c, fieldMapping.F3_Data_Type__c)
	 * ------------------------------------------------------------------------------------------------**/
	private static sObject addFieldToSObject(
		sObject newSObject,
		object value,
		String fieldMapping,
		String type,
		String childObjectIdField
	) {
		try {
			if (childObjectIdField == null) {
				newSObject.put(fieldMapping, parseValue(value, type, null, null));
			} else if (childObjectIdField != null && String.isNotBlank(String.valueOf(value))) {
				Schema.DescribeFieldResult relationship = newSObject.getSObjectType()
					.getDescribe()
					.fields.getMap()
					.get(fieldMapping)
					.getDescribe();
				newSObject.putSObject(
					relationship.getRelationshipName(),
					(sObject) parseValue(value, type, relationship.getReferenceTo()[0].getDescribe().getName(), childObjectIdField)
				);
			}
			return newSObject;
		} catch (Exception error) {
			throw new F3_RestServices_Exception(
				'Valor Invalido ' +
					value +
					' En el campo ' +
					fieldMapping +
					' de tipo: ' +
					type +
					' para el objeto ' +
					newSObject.getSObjectType() +
					' Error Tecnico: ' +
					error.getMessage()
			);
		}
	}

	/** -----------------------------------------------------------------------------
	 * @Description Generation of the Actinver's Hash val
	 *--------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     31/01/2023
	 * @return   Map<String, List<SObject>>
	 * example	generateHashVal(SObject newSObject, List<String> fieldsForHash)
	 **/
	private static String generateHashVal(SObject newSObject, List<String> fieldsForHash) {
		String concatValues = '';
		for (String field : fieldsForHash) {
			String value = String.valueOf(newSObject.get(field));
			if (String.isNotBlank(value)) {
				concatValues = concatValues + value;
			} else {
				throw new F3_JsonToSobject_Exception(
					'No hay información suficiente para generar el Hash para el objeto ' + newSObject.getSObjectType()
				);
			}
		}
		if (String.isBlank(concatValues)) {
			throw new F3_JsonToSobject_Exception('No hay información para generar el Hash para el objeto ' + newSObject.getSObjectType());
		}
		return EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', blob.valueOf(concatValues))).toUpperCase();
	}

	/** ------------------------------------------------------------------------------------------------
	 * parse an Object to the specified type
	 * -------------------------------------------------------------------------------------------------
	 * author   luis.felipe.ortiz@pwc.com
	 * date     12/08/2022
	 * param    Object value, String type
	 * return   object
	 * example	parseValue(value, type)
	 * ------------------------------------------------------------------------------------------------**/
	@TestVisible
	private static object parseValue(Object value, String type, String childObjectType, String childObjectIdField) {
		Object parsedValue;
		switch on type {
			when 'Boolean' {
				parsedValue = String.valueOf(value) == '1' ? true : String.valueOf(value) == '0' ? false : Boolean.valueOf(value);
			}
			when 'Double' {
				parsedValue = Double.valueOf(value);
			}
			when 'Integer' {
				parsedValue = Integer.valueOf(value);
			}
			when 'String' {
				parsedValue = String.valueOf(value);
			}
			when 'Date' {
				parsedValue = Date.parse(String.valueOf(value));
			}
			when 'Relationship' {
				sObject childObject = ((SObject) System.Type.forName('Schema', childObjectType).newInstance())
					.getSObjectType()
					.newSObject();
				childObject.put(childObjectIdField, value);
				parsedValue = childObject;
			}
			when else {
				parsedValue = value;
			}
		}
		return parsedValue;
	}

	/** -----------------------------------------------------------------------------
	 * @Description Get the collection type in a JSON
	 *--------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     31/01/2023
	 * @return   Map<String, List<SObject>>
	 * example	generateHashVal(SObject newSObject, List<String> fieldsForHash)
	 **/
	private static String collectionType(String jsonString) {
		Integer length = jsonString.length();
		String firstCharacter = jsonString.substring(0, 1);
		String lastCharacter = jsonString.substring(length - 1, length);
		return '{' == firstCharacter && '}' == lastCharacter ? 'Map' : '[' == firstCharacter && ']' == lastCharacter ? 'List' : 'Invalid';
	}

	/** -----------------------------------------------------------------------------
	 * @Description retrieve the mapping for the JSON
	 *--------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     31/01/2023
	 * @return   Map<String, List<SObject>>
	 * example	generateHashVal(SObject newSObject, List<String> fieldsForHash)
	 **/
	private static void retrieveJsonStructure(String serviceName) {
		List<F3_JSON_Structure__mdt> structuresList = [
			SELECT
				F3_Object_Name__c,
				F3_Wrapper_Name__c,
				F3_Relationship_Field__c,
				F3_Relationship_External_Field__c,
				F3_Fields_For_Hash__c,
				F3_Hash_Field__c,
				F3_Object_Edition_Hook__c,
				(
					SELECT
						F3_JSON_Field_Name__c,
						F3_SF_Api_Name__c,
						F3_Is_Parent_Id_For_Child_Levels__c,
						F3_Relationship_External_Field__c,
						F3_Data_Type__c,
						F3_Pass_Value_To_Child__c
					FROM F3_JSON_Field_Mapping__r
				)
			FROM F3_JSON_Structure__mdt
			WHERE F3_Service_Name__c = :serviceName
		];
		for (F3_JSON_Structure__mdt structure : structuresList) {
			structuresMap.put(structure.F3_Wrapper_Name__c, structure);
		}
	}

	/** -----------------------------------------------------------------------------
	 * @Description Exception class for the F3_JsonToSobject service
	 *--------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     31/01/2023
	 **/
	class F3_JsonToSobject_Exception extends Exception {
	}

	/** -----------------------------------------------------------------------------
	 * @Description Class to store the generator results
	 *--------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     31/01/2023
	 **/
	private class GeneratorResults {
		Object nextRelationshipID;
		SObject newSObject;
		Map<String, Object> nextParentValues = new Map<String, Object>();
		String nestedObject;
	}
}