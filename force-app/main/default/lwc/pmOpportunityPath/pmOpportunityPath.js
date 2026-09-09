import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue, notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { RefreshEvent } from 'lightning/refresh';
import { refreshApex } from '@salesforce/apex';

import STAGE_FIELD from '@salesforce/schema/Opportunity.StageName';
import RECORD_TYPE_FIELD from '@salesforce/schema/Opportunity.RecordTypeId';
import LOSS_REASON_FIELD from '@salesforce/schema/Opportunity.Motivo_de_perdidaPM__c';

const RECORD_FIELDS = [STAGE_FIELD, RECORD_TYPE_FIELD, LOSS_REASON_FIELD];
const CLOSED_STEP = '__closed__';
const CLOSED_WON_VALUES = new Set(['Closed Won', 'Cerrada Ganada']);
const CLOSED_LOST_VALUES = new Set(['Closed Lost', 'Cerrada Perdida']);

const LOSS_REASON_OPTIONS = [
    'Precio / condiciones no competitivas',
    'Perdido con competidor',
    'Cliente postergó la decisión',
    'Producto no disponible o no aplicable',
    'Relación comercial insuficiente',
    'Cambio interno del cliente (reestructura, fusión, etc.)',
    'Incumplimiento de requisitos (KYC, scoring, etc.)',
    'Otro'
].map((value) => ({ label: value, value }));

export default class PmOpportunityPath extends LightningElement {
    @api recordId;

    recordTypeId;
    currentStage;
    selectedStep;
    stageOptions = [];
    showCloseModal = false;
    selectedClosedStage;
    lossReason;
    isSaving = false;
    loadError;
    saveError;
    wiredRecordResult;

    closedStepValue = CLOSED_STEP;
    lossReasonOptions = LOSS_REASON_OPTIONS;

    @wire(getRecord, { recordId: '$recordId', fields: RECORD_FIELDS })
    wiredRecord(result) {
        this.wiredRecordResult = result;
        const { data, error } = result;
        if (data) {
            this.recordTypeId = getFieldValue(data, RECORD_TYPE_FIELD);
            this.currentStage = getFieldValue(data, STAGE_FIELD);
            this.lossReason = getFieldValue(data, LOSS_REASON_FIELD);
            this.selectedStep = this.isClosedValue(this.currentStage) ? CLOSED_STEP : this.currentStage;
            this.loadError = undefined;
        } else if (error) {
            this.loadError = this.reduceError(error);
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: STAGE_FIELD })
    wiredStages({ data, error }) {
        if (data) {
            this.stageOptions = data.values.map(({ label, value }) => ({ label, value }));
            this.loadError = undefined;
        } else if (error) {
            this.loadError = this.reduceError(error);
        }
    }

    get isReady() {
        return Boolean(this.currentStage && this.stageOptions.length);
    }

    get openStages() {
        return this.stageOptions.filter((stage) => !this.isClosedValue(stage.value));
    }

    get closedStages() {
        return this.stageOptions.filter((stage) => this.isClosedValue(stage.value));
    }

    get actionLabel() {
        return this.selectedStep === CLOSED_STEP ? 'Seleccionar etapa cerrada' : 'Marcar etapa como actual';
    }

    get disablePrimaryAction() {
        return this.isSaving || !this.selectedStep || this.selectedStep === this.currentStage;
    }

    get isClosedLostSelected() {
        return CLOSED_LOST_VALUES.has(this.selectedClosedStage);
    }

    handleStepClick(event) {
        this.selectedStep = event.currentTarget.dataset.value;
    }

    async handlePrimaryAction() {
        if (this.selectedStep === CLOSED_STEP) {
            this.selectedClosedStage = this.isClosedValue(this.currentStage) ? this.currentStage : undefined;
            this.saveError = undefined;
            this.showCloseModal = true;
            return;
        }

        await this.saveStage(this.selectedStep);
    }

    handleClosedStageChange(event) {
        this.selectedClosedStage = event.detail.value;
        this.saveError = undefined;
        if (!this.isClosedLostSelected) {
            this.lossReason = undefined;
        }
    }

    handleLossReasonChange(event) {
        this.lossReason = event.detail.value;
        this.saveError = undefined;
    }

    handleCancelModal() {
        if (!this.isSaving) {
            this.showCloseModal = false;
            this.saveError = undefined;
        }
    }

    async handleSaveClosedStage() {
        const inputs = [...this.template.querySelectorAll('lightning-combobox')];
        const isValid = inputs.reduce((valid, input) => {
            input.reportValidity();
            return valid && input.checkValidity();
        }, true);

        if (!isValid) {
            return;
        }

        await this.saveStage(this.selectedClosedStage, this.isClosedLostSelected ? this.lossReason : null);
    }

    async saveStage(stageName, lossReason) {
        this.isSaving = true;
        this.saveError = undefined;
        try {
            const fields = {
                Id: this.recordId,
                StageName: stageName
            };

            // Only send the reason field during the close operation. This avoids
            // clearing historical information or requiring reason-field edit
            // access when users move between ordinary pipeline stages.
            if (lossReason !== undefined) {
                fields.Motivo_de_perdidaPM__c = lossReason;
            }

            await updateRecord({ fields });

            await notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
            await refreshApex(this.wiredRecordResult);
            this.showCloseModal = false;
            this.dispatchEvent(new RefreshEvent());
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Oportunidad actualizada',
                    message: `La etapa cambió a ${stageName}.`,
                    variant: 'success'
                })
            );
        } catch (error) {
            const message = this.reduceError(error);
            this.saveError = message;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'No se pudo actualizar la oportunidad',
                    message,
                    variant: 'error',
                    mode: 'sticky'
                })
            );
        } finally {
            this.isSaving = false;
        }
    }

    isClosedValue(value) {
        return CLOSED_WON_VALUES.has(value) || CLOSED_LOST_VALUES.has(value);
    }

    reduceError(error) {
        if (Array.isArray(error?.body)) {
            return error.body.map((item) => item.message).join(', ');
        }

        const messages = [];
        const output = error?.body?.output;

        if (Array.isArray(output?.errors)) {
            output.errors.forEach((item) => {
                if (item?.message) {
                    messages.push(item.message);
                }
            });
        }

        if (output?.fieldErrors) {
            Object.values(output.fieldErrors).flat().forEach((item) => {
                if (item?.message) {
                    messages.push(item.message);
                }
            });
        }

        if (Array.isArray(output?.duplicateResults)) {
            output.duplicateResults.forEach((item) => {
                if (item?.message) {
                    messages.push(item.message);
                }
            });
        }

        if (messages.length) {
            return [...new Set(messages)].join(' ');
        }

        return error?.body?.message || error?.message || 'Ocurrió un error inesperado.';
    }
}