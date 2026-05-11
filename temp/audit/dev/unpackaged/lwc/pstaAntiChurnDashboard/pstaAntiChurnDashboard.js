import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getDashboardData from '@salesforce/apex/PSTA_AntiChurnDashboard_ctr.getDashboardData';

const PALETTE = ['#0b7d77', '#d59410', '#c63d32', '#2563eb', '#7c3aed', '#0891b2', '#65a30d', '#475569'];

export default class PstaAntiChurnDashboard extends NavigationMixin(LightningElement) {
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
        return !!this.data;
    }

    get hasMotivos() {
        return (this.data?.motivoFuga || []).length > 0;
    }

    get generatedDate() {
        return this.data?.generatedDate || '';
    }

    get totalPilotClients() {
        return this.data?.totalPilotClients || 0;
    }

    get totalActivities() {
        return this.data?.totalActivities || 0;
    }

    get highRiskClientsWithActivity() {
        return this.data?.highRiskClientsWithActivity || 0;
    }

    get highRiskAssignedPct() {
        return this.data?.highRiskAssignedPct || 0;
    }

    get positiveActivities() {
        return this.data?.positiveActivities || 0;
    }

    get negativeActivities() {
        return this.data?.negativeActivities || 0;
    }

    get noContactActivities() {
        return this.data?.noContactActivities || 0;
    }

    get pendingActivities() {
        return this.data?.pendingActivities || 0;
    }

    get avgContactDays() {
        return this.data?.avgContactDays || 0;
    }

    get effectiveContactRate() {
        return this.data?.effectiveContactRate || 0;
    }

    get churnVariationPct() {
        return this.data?.churnVariationPct || 0;
    }

    get pilotPopulationDefinition() {
        return this.data?.pilotPopulationDefinition || '';
    }

    get motiveLegend() {
        return (this.data?.motivoFuga || []).map((slice, index) => {
            const color = PALETTE[index % PALETTE.length];
            return {
                key: `${slice.label}-${index}`,
                label: slice.label,
                count: slice.count,
                percentage: slice.percentage,
                color,
                colorStyle: `background:${color};`
            };
        });
    }

    get motivoChartStyle() {
        if (!this.hasMotivos) {
            return 'background: conic-gradient(#d7dee7 0deg 360deg);';
        }

        let currentAngle = 0;
        const segments = this.motiveLegend.map((slice) => {
            const degrees = (slice.percentage || 0) * 3.6;
            const start = currentAngle;
            currentAngle += degrees;
            return `${slice.color} ${start.toFixed(2)}deg ${currentAngle.toFixed(2)}deg`;
        });

        if (currentAngle < 360) {
            segments.push(`#eef2f7 ${currentAngle.toFixed(2)}deg 360deg`);
        }

        return `background: conic-gradient(${segments.join(', ')});`;
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

    openHighRiskReport() {
        this.navigateToReport(this.data?.highRiskReportId);
    }

    openActivitiesReport() {
        this.navigateToReport(this.data?.activitiesReportId);
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