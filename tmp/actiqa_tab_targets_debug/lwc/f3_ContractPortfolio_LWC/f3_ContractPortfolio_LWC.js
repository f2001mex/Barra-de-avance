import { LightningElement, wire } from "lwc";
import { CurrentPageReference } from "lightning/navigation";
import getContractPortfolio from "@salesforce/apex/F3_SendDataToSAP_Controller.getContractPortfolio";

const columns = [
	{
		fieldName: "station",
		label: "Emisora",
		wrapText: true,
		hideDefaultActions: true
	},
	{
		fieldName: "serie",
		label: "Serie",
		wrapText: true,
		hideDefaultActions: true
	},
	{
		fieldName: "initialPosition",
		label: "Pos. Inicial",
		wrapText: true,
		hideDefaultActions: true,
		type: "number"
	},
	{
		fieldName: "position24H",
		label: "Liq.24 Hr",
		wrapText: true,
		hideDefaultActions: true,
		type: "number"
	},
	{
		fieldName: "position48H",
		label: "Liq.48 Hr",
		wrapText: true,
		hideDefaultActions: true,
		type: "number"
	},
	{
		fieldName: "position72H",
		label: "Otras Liq.",
		wrapText: true,
		hideDefaultActions: true,
		type: "number"
	},
	{
		fieldName: "endPosition",
		label: "Pos. Final",
		wrapText: true,
		hideDefaultActions: true,
		type: "number"
	},
	{
		fieldName: "cost",
		label: "Costo Virt.",
		wrapText: true,
		hideDefaultActions: true,
		type: "number"
	},
	{
		fieldName: "var1",
		label: "% Var",
		wrapText: true,
		hideDefaultActions: true,
		type: "number"
	},
	{
		fieldName: "precio",
		label: "Precio Ult.",
		wrapText: true,
		hideDefaultActions: true,
		type: "number"
	},
	{
		fieldName: "var2",
		label: "% Var",
		wrapText: true,
		hideDefaultActions: true,
		type: "number"
	},
	{
		fieldName: "valuation",
		label: "Valuación",
		wrapText: true,
		hideDefaultActions: true,
		type: "currency"
	}
];

let sections = new Map([
	["DEUDA", "Instrumentos de Deuda"],
	["VARIABLE", "Instrumentos de Capitales"],
	["COBERTURA", "Instrumentos de Deuda"],
	["MERCADO DE CAPITALES", "Instrumentos de Capitales"],
	["MERCADO DE DINERO", "Instrumentos de Deuda"]
]);
let subsections = new Map([
	["DEUDA", "S.I. de Deuda"],
	["VARIABLE", "S.I. de Renta Variable"],
	["COBERTURA", "S.I. de Cobertura"],
	["MERCADO DE CAPITALES", "Mercado de Capitales"],
	["MERCADO DE DINERO", "Mercado de Dinero"]
]);

export default class F3_ContractPortfolio_LWC extends LightningElement {
	columns = columns;
	orderedMarketDataElements;
	cashData;
	cashLabel;
	cashMaxHeight;
	activeSections;
	activeSubsections;
	errorMessage;
	@wire(CurrentPageReference)
	currentPageReference;

	async connectedCallback() {
		try {
			let contractNumber = this.currentPageReference.state?.c__contnumb;
			let executiveId = this.currentPageReference.state?.c__usid;
			if (!contractNumber) {
				throw new Error(`El contrato no tiene ID Contrato`);
			}
			if (!executiveId) {
				throw new Error(`El contrato no tiene ID Asesor`);
			}
			let response = JSON.parse(
				await getContractPortfolio({
					contractNumber: contractNumber,
					executiveID: executiveId
				})
			);
			if (!response.serviceCode.startsWith("2")) {
				throw new Error(
					"Error " +
						response.serviceCode +
						" en el servicio: " +
						response.serviceResponse
				);
			}
			let body = JSON.parse(response.serviceResponse);
			if (body === null) {
				throw new Error("No se encontró información");
			}
			if (body.payload.messages[0].criticality !== "INFO") {
				throw new Error(body.payload.messages[0].description);
			}
			this.orderMarketData(body.payload.markets);
			this.orderCashData(body.payload.totalCash);
		} catch (error) {
			this.errorMessage = error.message || error.body?.message;
		}
	}

	orderMarketData(marketData) {
		marketData.forEach((item) => {
			item.station = `🟨 ${item.station}`;
			item.section = sections.get(
				item.fundType === "0"
					? item.descriptionMarket
					: item.fundTypeDescription
			);
			item.subsection = subsections.get(
				item.fundType === "0"
					? item.descriptionMarket
					: item.fundTypeDescription
			);
		});
		let presentedSections = [
			...new Set(
				marketData.map((item) => {
					return item.section;
				})
			)
		];
		this.activeSubsections = [
			...new Set(
				marketData.map((item) => {
					return item.subsection;
				})
			)
		];
		this.activeSections = presentedSections;
		let sectionedMarketRecords = presentedSections.map((section) => {
			let sectionRecords = marketData.filter(
				(item) => item.section === section
			);
			let totalPerSection = sectionRecords
				.map((record) => record.valuation)
				.reduce(
					(previousValue, currentValue) =>
						previousValue + currentValue,
					0
				);
			let presentedSubsections = [
				...new Set(
					sectionRecords.map((item) => {
						return item.subsection;
					})
				)
			];
			let subsectionedMarketRecords = presentedSubsections.map(
				(subsection) => {
					let subsectionRecords = marketData.filter(
						(item) => item.subsection === subsection
					);
					let totalPerSubsection = subsectionRecords
						.map((record) => record.valuation)
						.reduce(
							(previousValue, currentValue) =>
								previousValue + currentValue,
							0
						);
					let subsectionData = {
						values: subsectionRecords,
						tableMaxHeight:
							subsectionRecords.length > 9 ? true : false,
						subsection: subsection,
						subsectionLabel: `${subsection} - ${new Intl.NumberFormat(
							"es-MX",
							{
								style: "currency",
								currency: "MXN"
							}
						).format(totalPerSubsection)}`,
						total: totalPerSubsection
					};
					return subsectionData;
				}
			);
			let orderedData = {
				section: section,
				sectionLabel: `${section} - ${new Intl.NumberFormat("es-MX", {
					style: "currency",
					currency: "MXN"
				}).format(totalPerSection)}`,
				sectionRecords: subsectionedMarketRecords
			};
			return orderedData;
		});
		this.orderedMarketDataElements = sectionedMarketRecords;
	}

	orderCashData(cashData) {
		cashData.forEach((item) => {
			item.station = `🟨 ${item.coinType}`;
			item.initialPosition = item.cashToday;
			item.position24H = 0.0;
			item.position48H = 0.0;
			item.position72H = 0.0;
			item.var2 = item.exchangeRate;
		});
		let totalCash = cashData
			.map((record) => record.valuation)
			.reduce(
				(previousValue, currentValue) => previousValue + currentValue,
				0
			);
		this.cashData = cashData;
		this.cashLabel = `Efectivo y equivalentes - ${new Intl.NumberFormat(
			"es-MX",
			{
				style: "currency",
				currency: "MXN"
			}
		).format(totalCash)}`;
		this.cashMaxHeight = cashData.length > 9 ? true : false;
	}
}