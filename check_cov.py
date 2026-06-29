import xml.etree.ElementTree as ET
try:
    tree = ET.parse('/vagrant/target/site/jacoco/jacoco.xml')
    print('--- COVERAGE SUMMARY ---')
    for package in tree.findall('package'):
        print(f"Package: {package.attrib['name']}")
        for counter in package.findall('counter'):
            if counter.attrib['type'] in ['INSTRUCTION', 'LINE', 'METHOD', 'CLASS']:
                missed = int(counter.attrib['missed'])
                covered = int(counter.attrib['covered'])
                total = missed + covered
                pct = covered * 100.0 / total if total > 0 else 100.0
                print(f"  {counter.attrib['type']}: {pct:.2f}% ({covered}/{total})")
except Exception as e:
    print("Error parsing jacoco.xml:", e)
