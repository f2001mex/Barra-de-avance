const fs = require('fs');
const path = require('path');

const reportsRoot = path.resolve(__dirname, '../force-app/main/default/reports');
const sourceFolder = path.join(reportsRoot, 'PERSONAS_MORALES');
const variants = [
  {
    apiName: 'PERSONAS_MORALES_BANQUERO',
    label: 'PERSONAS MORALES - BANQUERO',
    role: 'Banquero_Institucional',
    scope: 'user',
    suffix: 'BANQUERO',
    labelSuffix: ' - B',
  },
  {
    apiName: 'PERSONAS_MORALES_DIRECTOR',
    label: 'PERSONAS MORALES - DIRECTOR',
    role: 'Director_PM',
    scope: 'team',
    suffix: 'DIRECTOR',
    labelSuffix: ' - D',
  },
];

function replaceReportLabel(xml, suffix) {
  const matches = [...xml.matchAll(/<name>([^<]+)<\/name>/g)];
  const reportName = matches.at(-1);
  if (!reportName) throw new Error('The report does not contain a name element.');
  const label = `${reportName[1].slice(0, 36)}${suffix}`;
  return `${xml.slice(0, reportName.index)}<name>${label}</name>${xml.slice(reportName.index + reportName[0].length)}`;
}

const sourceReports = fs.readdirSync(sourceFolder).filter((file) => file.endsWith('.report-meta.xml'));

for (const variant of variants) {
  const destinationFolder = path.join(reportsRoot, variant.apiName);
  fs.mkdirSync(destinationFolder, { recursive: true });
  const folderXml = `<?xml version="1.0" encoding="UTF-8"?>
<ReportFolder xmlns="http://soap.sforce.com/2006/04/metadata">
    <folderShares>
        <accessLevel>View</accessLevel>
        <sharedTo>${variant.role}</sharedTo>
        <sharedToType>Role</sharedToType>
    </folderShares>
    <name>${variant.label}</name>
</ReportFolder>
`;
  fs.writeFileSync(`${destinationFolder}.reportFolder-meta.xml`, folderXml);

  for (const file of sourceReports) {
    let xml = fs.readFileSync(path.join(sourceFolder, file), 'utf8');
    xml = replaceReportLabel(xml, variant.labelSuffix);
    xml = xml.replace(/<scope>[^<]+<\/scope>/, `<scope>${variant.scope}</scope>`);
    const destinationName = file.replace('.report-meta.xml', `_${variant.suffix}.report-meta.xml`);
    fs.writeFileSync(path.join(destinationFolder, destinationName), xml);
  }
}

console.log(`Generated ${sourceReports.length} reports for each of ${variants.length} role folders.`);
