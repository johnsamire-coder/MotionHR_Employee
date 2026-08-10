"""
Final Check - Verify the 2 supposedly missing features
"""
from pathlib import Path

print("="*60)
print("Checking employee:missions")
print("="*60)
matches = list(Path("lib").rglob("*missions*.dart"))
for m in matches:
    print(f"  📄 {m}")

print("\n" + "="*60)
print("Checking employee:org-chart / organization_tree")
print("="*60)
matches = list(Path("lib").rglob("*organization*.dart"))
matches += list(Path("lib").rglob("*org_chart*.dart"))
matches += list(Path("lib").rglob("*org-chart*.dart"))
for m in matches:
    print(f"  📄 {m}")

print("\n" + "="*60)
print("Search in main.dart for keywords")
print("="*60)
import re
text = Path("lib/main.dart").read_text(encoding="utf-8")

for keyword in ["OrganizationTree", "EmployeeMission", "org_chart", "organization"]:
    matches = [line for line in text.split("\n") if keyword.lower() in line.lower()]
    if matches:
        print(f"\n🔍 '{keyword}':")
        for m in matches[:5]:
            print(f"   {m.strip()[:100]}")
