@IsTest(SeeAllData=true)
private class PSTA_MetaMensualDashboard_ctr_tst {

    @IsTest
    static void testGetDashboardDataBuildsTotalsAndRows() {
        Date targetDate = System.today();
        Id bankerMemberId = [SELECT Id FROM BranchUnitBusinessMember LIMIT 1].Id;
        List<ResumenGlobalPostventa__c> existingSummaries = [
            SELECT Meta__c, MetaMensual__c, Contactados__c, ContactadosMensual__c
            FROM ResumenGlobalPostventa__c
            WHERE Fecha__c = :targetDate
        ];

        Decimal expectedMetaDiaria = 0;
        Decimal expectedMetaMensual = 0;
        Decimal expectedContactadosHoy = 0;
        Decimal expectedContactadosMensual = 0;
        Integer expectedTotalAsesores = existingSummaries.size() + 2;

        for (ResumenGlobalPostventa__c existingSummary : existingSummaries) {
            expectedMetaDiaria += existingSummary.Meta__c != null ? existingSummary.Meta__c : 0;
            expectedMetaMensual += existingSummary.MetaMensual__c != null ? existingSummary.MetaMensual__c : 0;
            expectedContactadosHoy += existingSummary.Contactados__c != null ? existingSummary.Contactados__c : 0;
            expectedContactadosMensual += existingSummary.ContactadosMensual__c != null ? existingSummary.ContactadosMensual__c : 0;
        }

        List<ResumenGlobalPostventa__c> summaries = new List<ResumenGlobalPostventa__c>{
            new ResumenGlobalPostventa__c(
                Name = 'Resumen 1',
                Fecha__c = targetDate,
                ExternalId_Nomina__c = 'TEST001',
                Banker__c = bankerMemberId,
                Meta__c = 1,
                MetaMensual__c = 3,
                Contactados__c = 0,
                ContactadosMensual__c = 1,
                OwnerId = UserInfo.getUserId()
            ),
            new ResumenGlobalPostventa__c(
                Name = 'Resumen 2',
                Fecha__c = targetDate,
                ExternalId_Nomina__c = 'TEST002',
                Banker__c = bankerMemberId,
                Meta__c = 2,
                MetaMensual__c = 5,
                Contactados__c = 1,
                ContactadosMensual__c = 4,
                OwnerId = UserInfo.getUserId()
            )
        };
        insert summaries;

        expectedMetaDiaria += 3;
        expectedMetaMensual += 8;
        expectedContactadosHoy += 1;
        expectedContactadosMensual += 5;

        Test.startTest();
        PSTA_MetaMensualDashboard_ctr.DashboardResponse response =
            PSTA_MetaMensualDashboard_ctr.getDashboardData();
        Test.stopTest();

        System.assertNotEquals(null, response);
        System.assertEquals(targetDate, response.targetDate);
        System.assertEquals(expectedTotalAsesores, response.totalAsesores);
        System.assertEquals(expectedMetaDiaria, response.metaDiariaTotal);
        System.assertEquals(expectedMetaMensual, response.metaMensualTotal);
        System.assertEquals(expectedContactadosHoy, response.contactadosHoyTotal);
        System.assertEquals(expectedContactadosMensual, response.contactadosMensualTotal);
        System.assertEquals(expectedTotalAsesores, response.rows.size());
        System.assertEquals(calculateProgress(expectedContactadosHoy, expectedMetaDiaria), response.porcentajeDiarioTotal);
        System.assertEquals(calculateProgress(expectedContactadosMensual, expectedMetaMensual), response.porcentajeMensualTotal);
        System.assertNotEquals(null, response.monthlyReportId);
        System.assertNotEquals(null, response.detailReportId);
    }

    private static Decimal calculateProgress(Decimal contactados, Decimal meta) {
        if (meta == null || meta <= 0) {
            return 0;
        }

        Decimal avance = (contactados == null ? 0 : contactados) / meta;
        if (avance > 1) {
            return 1;
        }

        return avance.setScale(4);
    }
}
