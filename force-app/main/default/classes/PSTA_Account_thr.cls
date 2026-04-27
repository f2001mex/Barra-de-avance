/******************************************************************************* 
* Developed by      :   VASS Mexico
* Author            :   Canche Isaac
* Project           :   Post Venta
* Clase test        :   
* Description       :   Clase para el control de acciones sobre el trigger de cuentas para procesos de POSTVENTA
*--------------------------------------------------------------------------
* No.            Date              Author                Description
* 1.0         12-Jun-2025       Canche Isaac              Creacion
*--------------------------------------------------------------------------
*******************************************************************************/
public class PSTA_Account_thr {
   public static void onBeforeUpdate(List<Account> newListAccount, Map<Id,Account> oldMapAccount){
        system.debug('*********************START BEFORE UPDATE ACCOUNT PSTA*********************');
        PSTA_ListadoClientes_cls.actualizarFechaSiguienteContacto(newListAccount,oldMapAccount);
        PSTA_ListadoClientes_cls.actualizarFechaSiguienteVisita(newListAccount,oldMapAccount);
        PSTA_ListadoClientes_cls.actualizarFechaNoQuiereSerContactado(newListAccount,oldMapAccount);
        PSTA_Segmentacion_cls.procesarSegmentoPorCambioAsesor(newListAccount, oldMapAccount);
        system.debug('*********************END BEFORE UPDATE ACCOUNT PSTA*********************');
    }

    public static void onAfterUpdate(List<Account> newListAccount, Map<Id,Account> oldMapAccount){
        PSTA_FACCadenceCompletion_cls.onAfterUpdate(newListAccount, oldMapAccount);
        ACT_CadenceReassignQueue_cls.enqueueOnAdvisorChange(newListAccount, oldMapAccount);
    }
}
