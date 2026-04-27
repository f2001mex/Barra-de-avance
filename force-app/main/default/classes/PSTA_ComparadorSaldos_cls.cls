/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Canche Isaac
* Project           :   Post venta
* Clase test		:   PSTA_ComparadorSaldos_cls_tst
* Description       :   Clase comparador para la priorizacion del saldo de los clientes.
*--------------------------------------------------------------------------
* No.            Date              Author                Description
* 1.0         09-Jun-2025       Canche Isaac              Creación
*--------------------------------------------------------------------------
*******************************************************************************/
public class PSTA_ComparadorSaldos_cls implements Comparator<Account>{
    public Integer compare(Account a1, Account a2) {
        // Orden DESCENDENTE (mayor a menor)
        if (a1.SaldoIntegral__c > a2.SaldoIntegral__c) return -1;
        if (a1.SaldoIntegral__c < a2.SaldoIntegral__c) return 1;
        return 0; // Si son iguales
    }
}