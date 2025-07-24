import subprocess
import yaml

CHART_PATH = "./mychart"        # путь к твоему чарту
VALUES_FILE = "./mychart/values.yaml"
OUTPUT_FILE = "standalone.xml"

def generate_standalone():
    # 1. Генерируем configmap.yaml через helm template
    result = subprocess.run(
        [
            "helm", "template", "dummy", CHART_PATH,
            "-f", VALUES_FILE,
            "--show-only", "templates/configmap.yaml",
        ],
        capture_output=True,
        text=True
    )

    if result.returncode != 0:
        print("Ошибка helm template:\n", result.stderr)
        return

    # 2. Парсим YAML
    docs = list(yaml.safe_load_all(result.stdout))
    standalone_xml = None
    for doc in docs:
        if doc.get("kind") == "ConfigMap" and "standalone.xml" in doc.get("data", {}):
            standalone_xml = doc["data"]["standalone.xml"]
            break

    if not standalone_xml:
        print("Не найден standalone.xml в ConfigMap")
        return

    # 3. Сохраняем в файл
    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        f.write(standalone_xml)

    print(f"Файл {OUTPUT_FILE} успешно создан!")

if __name__ == "__main__":
    generate_standalone()
