import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

const PROGRESS_FIELD = 'Task.Avance_FAC__c';
const SUBJECT_FIELD = 'Task.Subject';
const FIELDS = [PROGRESS_FIELD, SUBJECT_FIELD];
const REQUIRED_SUBJECT_TEXT = 'ficha de afinidad con el cliente';

export default class TaskProgressBar extends LightningElement {
    @api recordId;
    @api allowedRecordTypeDeveloperName;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    record;

    get percent() {
        const rawValue = getFieldValue(this.record.data, PROGRESS_FIELD);
        const numValue = Number(rawValue);

        if (!Number.isFinite(numValue)) {
            return 0;
        }

        return Math.max(0, Math.min(100, numValue));
    }

    get displayPercent() {
        return `${this.percent}%`;
    }

    get progressStyle() {
        return `width: ${this.percent}%; background-color: ${this.progressColor};`;
    }

    get progressColor() {
        const percent = this.percent;

        if (percent <= 50) {
            return this.interpolateColor([220, 53, 69], [255, 193, 7], percent / 50);
        }

        return this.interpolateColor([255, 193, 7], [40, 167, 69], (percent - 50) / 50);
    }

    interpolateColor(start, end, ratio) {
        const safeRatio = Math.max(0, Math.min(1, ratio));
        const r = Math.round(start[0] + (end[0] - start[0]) * safeRatio);
        const g = Math.round(start[1] + (end[1] - start[1]) * safeRatio);
        const b = Math.round(start[2] + (end[2] - start[2]) * safeRatio);

        return `rgb(${r}, ${g}, ${b})`;
    }

    get hasRecord() {
        return !!this.record.data;
    }

    get shouldShowComponent() {
        if (!this.hasRecord) {
            return false;
        }

        const subjectRaw = getFieldValue(this.record.data, SUBJECT_FIELD) || '';
        const subject = subjectRaw
            .toLowerCase()
            .normalize('NFD')
            .replace(/[\u0300-\u036f]/g, '');

        return subject.includes(REQUIRED_SUBJECT_TEXT);
    }
}
