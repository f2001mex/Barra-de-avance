public with sharing class Integration_Utils {

    //Metodo que devuelve el valor API de un picklist, recibe el objeto donde vive el picklist y tambien el nombre del picklist y la etiqueta del valor que buscamos.
    public static String obtenerValorApi(String objeto, String campo, String etiqueta) {
        Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objeto);
        if (sObjectType != null) {
            // Obtengo los metadatos del campo del objeto
            Schema.DescribeFieldResult fieldResult = sObjectType.getDescribe().fields.getMap().get(campo).getDescribe();
            List<Schema.PicklistEntry> valoresPicklist = fieldResult.getPicklistValues();
            // Busco sobre los valores para encontrar el valor API correspondiente a la etiqueta
            for (Schema.PicklistEntry picklistEntry : valoresPicklist) {
                if (picklistEntry.getLabel() == etiqueta) {
                    return picklistEntry.getValue(); // Devuelvo el valor API
                }
            }
            return '';
        } else {
            return '';
        }
    }
}