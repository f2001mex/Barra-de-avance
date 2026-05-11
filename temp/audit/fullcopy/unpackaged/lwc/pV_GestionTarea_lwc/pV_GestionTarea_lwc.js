import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';
import Id from '@salesforce/user/Id';
export default class PV_GestionTarea_lwc extends LightningElement {
    channelName = '/event/PV_FinalizacionCadencia__e';
    subscription = {};
    @api recordId;
    userId = Id;
    connectedCallback() {
        this.iniciarSuscripcion();
        this.configurarErrores();
    }
    iniciarSuscripcion() {
        subscribe(this.channelName, -1, (mensaje) => {
            if (mensaje.data.payload.AccountId__c == this.recordId && mensaje.data.payload.UserId__c == this.userId) {
                this.handleToast(
                    'success',
                    'Cadencia finalizada con éxito, favor de dar seguimiento en la tarea: {0}.',
                    'Se ha finalizado la cadencia',
                    mensaje.data.payload.TaskId__c);
            }
            //this.desconectar();
        }).then((response) => {
            this.subscription = response;
            console.log('Suscripción realizada con éxito');
        });
    }
    configurarErrores() {
        onError((error) => {
            console.error('Error en suscripción:', error);
        });
    }
    desconectar() {
        unsubscribe(this.subscription, (respuesta) => {
            console.log('Desuscrito:', respuesta);
        });
    }
    handleToast(variant, message, title, recordId) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
                messageData: [
                    {
                        url: '/lightning/r/Task/' + recordId + '/view',
                        label: 'Ver tarea'
                    }
                ]
            }),
        );
    }
}