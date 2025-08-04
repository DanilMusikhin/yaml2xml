import subprocess
import yaml
import argparse
from pathlib import Path

CHART_PATH = "./mychart"
DEFAULT_VALUES_FILE = "~/workspace/lanit/PPA/infrastructure/wildfly/helm/values-zakupki.gov.ru.yaml"
OVERRIDE_VALUES_FILE = "./mychart/override_values.yaml"
DEFAULT_OUTPUT_FILE = "~/opt/wildfly/wildfly-22.0.0.Final-ppa/standalone/configuration/standalone-full-ppa.xml"

def generate_standalone(output_file: Path, values_file: Path):
    # 1. Генерируем configmap.yaml через helm template
    result = subprocess.run(
        [
            "helm", "template", "dummy", CHART_PATH,
            "-f", str(values_file),
            "-f", OVERRIDE_VALUES_FILE,
            "--show-only", "templates/configmap.yaml",
        ],
        capture_output=True,
        text=True
    )

    if result.returncode != 0:
        print("❌ Ошибка helm template:\n", result.stderr)
        return

    # 2. Парсим YAML
    docs = list(yaml.safe_load_all(result.stdout))
    standalone_xml = None
    for doc in docs:
        if doc.get("kind") == "ConfigMap" and "standalone.xml" in doc.get("data", {}):
            standalone_xml = doc["data"]["standalone.xml"]
            break

    if not standalone_xml:
        print("⁉️ Не найден standalone.xml в ConfigMap")
        return

    # 3. Создаём путь при необходимости и сохраняем в файл
    output_file.parent.mkdir(parents=True, exist_ok=True)
    with open(output_file, "w", encoding="utf-8") as f:
        f.write(standalone_xml)

    print(f"✅ Файл {output_file} успешно создан!")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Генерация standalone-full-ppa.xml из Helm-чарта")
    parser.add_argument(
        "-o", "--output", type=Path, default=DEFAULT_OUTPUT_FILE,
        help="Путь к выходному файлу (по умолчанию: ~/opt/wildfly/wildfly-22.0.0.Final-ppa/standalone/configuration/standalone-full-ppa.xml)"
    )
    parser.add_argument(
        "-v", "--values", type=Path, default=DEFAULT_VALUES_FILE,
        help="Путь к файлу values.yaml (по умолчанию: ~/workspace/lanit/PPA/infrastructure/wildfly/helm/values-zakupki.gov.ru.yaml)"
    )

    args = parser.parse_args()

    args.values = args.values.expanduser()
    args.output = args.output.expanduser()

    generate_standalone(args.output, args.values)
