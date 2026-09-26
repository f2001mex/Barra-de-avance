public without sharing class BancasDashboardSelector {
    private static final String OPP_RT = 'Oportunidad_Personas_Morales';
    private static final String ACCOUNT_RT = 'Cuentas_empresariales';
    public static List<AggregateResult> pipeline(Date fromDate, Date toDate, Id ownerId, String product, String industry) {
        String query='SELECT StageName label,COUNT(Id) qty,SUM(MontoEstimadoDeInversion__c) amount FROM Opportunity WHERE RecordType.DeveloperName=\''+OPP_RT+'\' AND IsClosed=false AND CloseDate>='+dateLiteral(fromDate)+' AND CloseDate<='+dateLiteral(toDate)+opportunityFilter(ownerId,product,industry)+' GROUP BY StageName ORDER BY StageName';
        return Database.query(query);
    }
    public static List<AggregateResult> products(Date fromDate, Date toDate, Id ownerId, String product, String industry) {
        String query='SELECT Producto_Solicitado__c label,COUNT(Id) qty,SUM(MontoEstimadoDeInversion__c) amount FROM Opportunity WHERE RecordType.DeveloperName=\''+OPP_RT+'\' AND IsClosed=false AND CloseDate>='+dateLiteral(fromDate)+' AND CloseDate<='+dateLiteral(toDate)+' AND Producto_Solicitado__c!=null'+opportunityFilter(ownerId,product,industry)+' GROUP BY Producto_Solicitado__c ORDER BY COUNT(Id) DESC';
        return Database.query(query);
    }
    public static List<AggregateResult> institutionalDistribution(Id ownerId,String industry) {
        String industryFilter=String.isBlank(industry)?'':' AND Tipo_de_cliente_PM__c=\''+String.escapeSingleQuotes(industry)+'\'';
        String query='SELECT Tipo_de_cliente_PM__c label,COUNT(Id) qty FROM Account WHERE RecordType.DeveloperName=\''+ACCOUNT_RT+'\' AND FinServ__Status__c IN (\'Active\',\'Activo\') AND Tipo_de_cliente_PM__c!=null'+ownerFilter(ownerId)+industryFilter+' GROUP BY Tipo_de_cliente_PM__c ORDER BY COUNT(Id) DESC';
        return Database.query(query);
    }
    public static List<Opportunity> upcoming(Date today, Date endDate, Id ownerId, String product, String industry) {
        String query='SELECT Id,Name,Account.Name,StageName,Producto_Solicitado__c,CloseDate,MontoEstimadoDeInversion__c,Owner.Name FROM Opportunity WHERE RecordType.DeveloperName=\''+OPP_RT+'\' AND IsClosed=false AND CloseDate>='+dateLiteral(today)+' AND CloseDate<='+dateLiteral(endDate)+opportunityFilter(ownerId,product,industry)+' ORDER BY CloseDate ASC,MontoEstimadoDeInversion__c DESC NULLS LAST LIMIT 100';
        return Database.query(query);
    }
    public static Integer pendingTasks(Id ownerId,String industry) {
        String query='SELECT COUNT(Id) total FROM Task WHERE IsClosed=false AND Account.RecordType.DeveloperName=\''+ACCOUNT_RT+'\''+activityFilter(ownerId,industry);
        return ((Decimal)Database.query(query)[0].get('total')).intValue();
    }
    public static List<AggregateResult> taskCompetitors(Date fromDate, Date toDate, Id ownerId,String industry) {
        return Database.query('SELECT Competidor__c label,COUNT(Id) qty FROM Task WHERE Competidor__c!=null AND Account.RecordType.DeveloperName=\''+ACCOUNT_RT+'\' AND ActivityDate>='+dateLiteral(fromDate)+' AND ActivityDate<='+dateLiteral(toDate)+activityFilter(ownerId,industry)+' GROUP BY Competidor__c ORDER BY COUNT(Id) DESC LIMIT 10');
    }
    public static List<AggregateResult> eventCompetitors(Date fromDate, Date toDate, Id ownerId,String industry) {
        return Database.query('SELECT Competidor__c label,COUNT(Id) qty FROM Event WHERE Competidor__c!=null AND Account.RecordType.DeveloperName=\''+ACCOUNT_RT+'\' AND ActivityDate>='+dateLiteral(fromDate)+' AND ActivityDate<='+dateLiteral(toDate)+activityFilter(ownerId,industry)+' GROUP BY Competidor__c ORDER BY COUNT(Id) DESC LIMIT 10');
    }
    public static List<Task> taskActivity(Date fromDate, Date toDate, Id ownerId,String industry) {
        return Database.query('SELECT Subject,Owner.Name,ActivityDate FROM Task WHERE Account.RecordType.DeveloperName=\''+ACCOUNT_RT+'\' AND ActivityDate>='+dateLiteral(fromDate)+' AND ActivityDate<='+dateLiteral(toDate)+activityFilter(ownerId,industry)+' LIMIT 5000');
    }
    public static List<AggregateResult> eventActivity(Date fromDate, Date toDate, Id ownerId,String industry) {
        return Database.query('SELECT Owner.Name label,COUNT(Id) qty FROM Event WHERE Account.RecordType.DeveloperName=\''+ACCOUNT_RT+'\' AND ActivityDate>='+dateLiteral(fromDate)+' AND ActivityDate<='+dateLiteral(toDate)+activityFilter(ownerId,industry)+' GROUP BY Owner.Name');
    }
    public static List<AggregateResult> eventTrend(Date fromDate, Date toDate, Id ownerId,String industry) {
        return Database.query('SELECT CALENDAR_YEAR(StartDateTime) yr,CALENDAR_MONTH(StartDateTime) mo,COUNT(Id) qty FROM Event WHERE Account.RecordType.DeveloperName=\''+ACCOUNT_RT+'\' AND ActivityDate>='+dateLiteral(fromDate)+' AND ActivityDate<='+dateLiteral(toDate)+activityFilter(ownerId,industry)+' GROUP BY CALENDAR_YEAR(StartDateTime),CALENDAR_MONTH(StartDateTime) ORDER BY CALENDAR_YEAR(StartDateTime),CALENDAR_MONTH(StartDateTime)');
    }
    public static List<AggregateResult> taskStatuses(Id ownerId,String industry) {
        return Database.query('SELECT Status label,COUNT(Id) qty FROM Task WHERE IsClosed=false AND Account.RecordType.DeveloperName=\''+ACCOUNT_RT+'\''+activityFilter(ownerId,industry)+' GROUP BY Status ORDER BY COUNT(Id) DESC');
    }
    public static List<AggregateResult> strategicContacts(Id ownerId, String industry) {
        String extra=String.isBlank(industry)?'': ' AND Account.Tipo_de_cliente_PM__c=\''+String.escapeSingleQuotes(industry)+'\'';
        return Database.query('SELECT Account.Name label,COUNT(Id) qty FROM Contact WHERE RecordType.DeveloperName=\'IndustriesBusiness\' AND Account.RecordType.DeveloperName=\''+ACCOUNT_RT+'\''+accountOwnerFilter(ownerId)+extra+' GROUP BY Account.Name ORDER BY COUNT(Id) DESC LIMIT 10');
    }
    public static Map<String,Id> reportIds() {
        Map<String,Id> result=new Map<String,Id>();
        for (Report item : [SELECT Id,DeveloperName FROM Report WHERE FolderName='PERSONAS MORALES']) result.put(item.DeveloperName,item.Id);
        return result;
    }
    public static List<BancasDashboardDTO.FilterOption> productOptions(Id restrictedOwnerId) {
        List<BancasDashboardDTO.FilterOption> result=new List<BancasDashboardDTO.FilterOption>();
        String query='SELECT Producto_Solicitado__c label FROM Opportunity WHERE RecordType.DeveloperName=\''+OPP_RT+'\' AND Producto_Solicitado__c!=null'+ownerFilter(restrictedOwnerId)+' GROUP BY Producto_Solicitado__c ORDER BY Producto_Solicitado__c';
        for (AggregateResult row : Database.query(query)) result.add(new BancasDashboardDTO.FilterOption((String)row.get('label'),(String)row.get('label')));
        return result;
    }
    public static List<BancasDashboardDTO.FilterOption> executiveOptions(Id restrictedOwnerId) {
        List<BancasDashboardDTO.FilterOption> result=new List<BancasDashboardDTO.FilterOption>();
        Set<Id> eligibleUserIds=BancasDashboardSecurity.getEligibleUserIds();
        Set<Id> visibleOwnerIds=BancasDashboardSecurity.getVisibleOwnerIds();
        if (visibleOwnerIds!=null) eligibleUserIds.retainAll(visibleOwnerIds);
        if (restrictedOwnerId!=null) eligibleUserIds.retainAll(new Set<Id>{restrictedOwnerId});
        if (!eligibleUserIds.isEmpty()) for (User item : [
            SELECT Id,Name
            FROM User
            WHERE Id IN :eligibleUserIds AND IsActive=true
            ORDER BY Name
        ]) result.add(new BancasDashboardDTO.FilterOption(item.Name,String.valueOf(item.Id)));
        return result;
    }
    public static List<BancasDashboardDTO.FilterOption> industryOptions(Id restrictedOwnerId) {
        List<BancasDashboardDTO.FilterOption> result=new List<BancasDashboardDTO.FilterOption>();
        for (String clientType : new List<String>{
            'AFORE',
            'Mutual Fund',
            'Insurance Company',
            'Broker Dealer',
            'Private Bank',
            'Bank',
            'Hedge Fund',
            'Family Office',
            'Asset Manager',
            'Other'
        }) result.add(new BancasDashboardDTO.FilterOption(clientType,clientType));
        return result;
    }
    private static String opportunityFilter(Id ownerId,String product,String industry) {
        String result='';
        result+=ownerFilter(ownerId);
        if (!String.isBlank(product)) result+=' AND Producto_Solicitado__c=\''+String.escapeSingleQuotes(product)+'\'';
        if (!String.isBlank(industry)) result+=' AND Account.Tipo_de_cliente_PM__c=\''+String.escapeSingleQuotes(industry)+'\'';
        return result;
    }
    private static String activityFilter(Id ownerId,String industry) {
        String result='';
        result+=ownerFilter(ownerId);
        if (!String.isBlank(industry)) result+=' AND Account.Tipo_de_cliente_PM__c=\''+String.escapeSingleQuotes(industry)+'\'';
        return result;
    }
    private static String ownerFilter(Id ownerId) {
        if (ownerId!=null) return ' AND OwnerId=\''+String.escapeSingleQuotes(String.valueOf(ownerId))+'\'';
        Set<Id> scope=BancasDashboardSecurity.getVisibleOwnerIds();
        if (scope==null) return '';
        if (scope.isEmpty()) return ' AND OwnerId=null';
        List<String> values=new List<String>();
        for (Id scopedOwnerId : scope) values.add('\''+String.escapeSingleQuotes(String.valueOf(scopedOwnerId))+'\'');
        return ' AND OwnerId IN ('+String.join(values,',')+')';
    }
    private static String accountOwnerFilter(Id ownerId) {
        if (ownerId!=null) return ' AND Account.OwnerId=\''+String.escapeSingleQuotes(String.valueOf(ownerId))+'\'';
        Set<Id> scope=BancasDashboardSecurity.getVisibleOwnerIds();
        if (scope==null) return '';
        if (scope.isEmpty()) return ' AND Account.OwnerId=null';
        List<String> values=new List<String>();
        for (Id scopedOwnerId : scope) values.add('\''+String.escapeSingleQuotes(String.valueOf(scopedOwnerId))+'\'');
        return ' AND Account.OwnerId IN ('+String.join(values,',')+')';
    }
    private static String dateLiteral(Date value) { return String.valueOf(value); }
}