import { LightningElement } from 'lwc';
import getDashboard from '@salesforce/apex/BancasDashboardController.getDashboard';
const ALL={label:'Todos',value:''};
export default class BancasDashboardHome extends LightningElement {
    data; error; loading=false; fromDate; toDate; dateRange='THIS_YEAR'; product=''; industry=''; ownerId='';
    dateOptions=[{label:'Este mes',value:'THIS_MONTH'},{label:'Mes anterior',value:'LAST_MONTH'},{label:'Este trimestre',value:'THIS_QUARTER'},{label:'Este año',value:'THIS_YEAR'},{label:'Personalizado',value:'CUSTOM'}];
    connectedCallback(){this.reset();}
    get isCustomDate(){return this.dateRange==='CUSTOM';}
    get productOptions(){return[ALL,...(this.data?.productOptions||[])];}
    get executiveOptions(){return[ALL,...(this.data?.executiveOptions||[])];}
    get industryOptions(){return[ALL,...(this.data?.industryOptions||[])];}
    get generatedAt(){return this.data?.generatedAt?new Intl.DateTimeFormat('es-MX',{dateStyle:'medium',timeStyle:'short'}).format(new Date(this.data.generatedAt)):'';}
    handleFrom(e){this.fromDate=e.detail.value;} handleTo(e){this.toDate=e.detail.value;}
    handleProduct(e){this.product=e.detail.value;} handleOwner(e){this.ownerId=e.detail.value;} handleIndustry(e){this.industry=e.detail.value;}
    handleDateRange(e){this.dateRange=e.detail.value;if(!this.isCustomDate)this.setDateRange();}
    formatDate(d){return`${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`;}
    setDateRange(){const now=new Date(),y=now.getFullYear(),m=now.getMonth();let start,end;if(this.dateRange==='THIS_MONTH'){start=new Date(y,m,1);end=new Date(y,m+1,0);}else if(this.dateRange==='LAST_MONTH'){start=new Date(y,m-1,1);end=new Date(y,m,0);}else if(this.dateRange==='THIS_QUARTER'){const q=Math.floor(m/3)*3;start=new Date(y,q,1);end=new Date(y,q+3,0);}else{start=new Date(y,0,1);end=new Date(y,11,31);}this.fromDate=this.formatDate(start);this.toDate=this.formatDate(end);}
    async load(){this.loading=true;this.error=undefined;try{this.data=await getDashboard({fromDate:this.fromDate,toDate:this.toDate,ownerId:this.ownerId||null,product:this.product||null,industry:this.industry||null});}catch(e){this.data=undefined;this.error=e?.body?.message||'No fue posible cargar el dashboard.';}finally{this.loading=false;}}
    reset(){this.dateRange='THIS_YEAR';this.product='';this.industry='';this.ownerId='';this.setDateRange();this.load();}
}