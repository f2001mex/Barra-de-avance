import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getDashboardData from '@salesforce/apex/PSTA_MetaMensualDashboard_ctr.getDashboardData';

const COLUMNS = [
    { label: 'Asesor', fieldName: 'ownerName', type: 'text' },
    { label: 'Centro financiero', fieldName: 'centroFinanciero', type: 'text' },
    { label: 'Meta mensual', fieldName: 'metaMensual', type: 'number' },
    { label: 'Contactados mensual', fieldName: 'contactadosMensual', type: 'number' },
    { label: '% mensual', fieldName: 'porcentajeMensual', type: 'percent', typeAttributes: { maximumFractionDigits: 2 } },
    { label: 'Meta diaria', fieldName: 'metaDiaria', type: 'number' },
    { label: 'Contactados hoy', fieldName: 'contactadosHoy', type: 'number' },
    { label: '% diario', fieldName: 'porcentajeDiario', type: 'percent', typeAttributes: { maximumFractionDigits: 2 } }
];

export default class PstaMetaMensualDashboard extends NavigationMixin(LightningElement) {
    columns = COLUMNS;
    data;
    error;

    @wire(getDashboardData)
    wiredDashboard({ data, error }) {
        if (data) {
            this.data = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.data = undefined;
        }
    }

    get hasData() {
        return this.data && this.data.rows && this.data.rows.length > 0;
    }

    get rows() {
        return this.data?.rows || [];
    }

    get targetDateLabel() {
        return this.data?.targetDate || '';
    }

    get totalAsesores() {
        return this.data?.totalAsesores || 0;
    }

    get metaMensualTotal() {
        return this.data?.metaMensualTotal || 0;
    }

    get contactadosMensualTotal() {
        return this.data?.contactadosMensualTotal || 0;
    }

    get porcentajeMensualTotal() {
        return this.data?.porcentajeMensualTotal || 0;
    }

    get metaDiariaTotal() {
        return this.data?.metaDiariaTotal || 0;
    }

    get contactadosHoyTotal() {
        return this.data?.contactadosHoyTotal || 0;
    }

    get porcentajeDiarioTotal() {
        return this.data?.porcentajeDiarioTotal || 0;
    }

    get monthlyGauge() {
        return this.buildGaugeModel(
            this.porcentajeMensualTotal,
            this.contactadosMensualTotal,
            this.metaMensualTotal
        );
    }

    get dailyGauge() {
        return this.buildGaugeModel(
            this.porcentajeDiarioTotal,
            this.contactadosHoyTotal,
            this.metaDiariaTotal
        );
    }

    get errorMessage() {
        if (!this.error) {
            return '';
        }

        if (Array.isArray(this.error.body)) {
            return this.error.body.map((item) => item.message).join(', ');
        }

        return this.error.body?.message || this.error.message || 'No fue posible cargar el tablero.';
    }

    buildGaugeModel(progress, achieved, goal) {
        const boundedValue = this.boundGaugeValue(progress);
        const centerX = 110;
        const centerY = 112;
        const radius = 88;
        const labelRadius = 62;
        const tickOuterRadius = 94;
        const tickInnerRadius = 86;
        const angle = 180 - (180 * boundedValue);

        const segments = [
            { key: 'red', className: 'gauge-segment-red', path: this.describeArc(centerX, centerY, radius, 180, 120.6) },
            { key: 'amber', className: 'gauge-segment-amber', path: this.describeArc(centerX, centerY, radius, 120.6, 59.4) },
            { key: 'green', className: 'gauge-segment-green', path: this.describeArc(centerX, centerY, radius, 59.4, 0) }
        ];

        const ticks = [];
        for (let index = 0; index <= 10; index++) {
            const tickAngle = 180 - (18 * index);
            const outerPoint = this.pointOnCircle(centerX, centerY, tickOuterRadius, tickAngle);
            const innerPoint = this.pointOnCircle(centerX, centerY, tickInnerRadius, tickAngle);
            const labelPoint = this.pointOnCircle(centerX, centerY, labelRadius, tickAngle);

            ticks.push({
                key: `tick-${index}`,
                x1: outerPoint.x,
                y1: outerPoint.y,
                x2: innerPoint.x,
                y2: innerPoint.y,
                labelX: labelPoint.x,
                labelY: labelPoint.y,
                label: `${index * 10}%`
            });
        }

        return {
            segments,
            ticks,
            pointerPath: this.buildPointerPath(centerX, centerY, angle),
            centerX,
            centerY,
            caption: `${achieved || 0} de ${goal || 0}`
        };
    }

    boundGaugeValue(value) {
        if (!value || value < 0) {
            return 0;
        }

        if (value > 1) {
            return 1;
        }

        return value;
    }

    describeArc(cx, cy, radius, startAngle, endAngle) {
        const start = this.pointOnCircle(cx, cy, radius, startAngle);
        const end = this.pointOnCircle(cx, cy, radius, endAngle);
        return `M ${start.x} ${start.y} A ${radius} ${radius} 0 0 1 ${end.x} ${end.y}`;
    }

    pointOnCircle(cx, cy, radius, angleDegrees) {
        const radians = (angleDegrees * Math.PI) / 180;
        return {
            x: Number((cx + (radius * Math.cos(radians))).toFixed(2)),
            y: Number((cy - (radius * Math.sin(radians))).toFixed(2))
        };
    }

    buildPointerPath(cx, cy, angleDegrees) {
        const radians = (angleDegrees * Math.PI) / 180;
        const directionX = Math.cos(radians);
        const directionY = -Math.sin(radians);
        const perpendicularX = -directionY;
        const perpendicularY = directionX;

        const tipX = cx + (directionX * 68);
        const tipY = cy + (directionY * 68);
        const backX = cx - (directionX * 12);
        const backY = cy - (directionY * 12);
        const leftX = backX + (perpendicularX * 7);
        const leftY = backY + (perpendicularY * 7);
        const rightX = backX - (perpendicularX * 7);
        const rightY = backY - (perpendicularY * 7);

        return `M ${leftX.toFixed(2)} ${leftY.toFixed(2)} L ${tipX.toFixed(2)} ${tipY.toFixed(2)} L ${rightX.toFixed(2)} ${rightY.toFixed(2)} Z`;
    }

    openMonthlyReport() {
        this.navigateToReport(this.data?.monthlyReportId);
    }

    openDetailReport() {
        this.navigateToReport(this.data?.detailReportId);
    }

    navigateToReport(reportId) {
        if (!reportId) {
            return;
        }

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: reportId,
                objectApiName: 'Report',
                actionName: 'view'
            }
        });
    }
}