## Программа для создания standalone для wildfly на основе values.yaml
### Для работы требуется:

1. #### helm

    Fedora: 
    ```cmd 
    sudo dnf install helm
    ```

2. #### Python и библиотека yaml
    ```cmd
    pip install PyYAML
    ```

### Запуск программы:
```cmd
python3 generate_standalone.py
```
Дополнительно можно указать путь для standalone
(Базовый путь: ~/opt/wildfly/wildfly-22.0.0.Final-ppa/standalone/configuration/standalone-full-ppa.xml)
```cmd
python3 generate_standalone.py --output ~/opt/wildfly/wildfly-22.0.0.Final-ppa/standalone/configuration/standalone-full-ppa.xml
```
Также можно указать путь до values.yaml
(Базовый путь: ~/workspace/lanit/PPA/infrastructure/wildfly/helm/values-zakupki.gov.ru.yaml)
```cmd
python3 generate_standalone.py --values ~/workspace/lanit/PPA/infrastructure/wildfly/helm/values-zakupki.gov.ru.yaml
```

### Либо использовать команду без мучений с питоном
```
helm template dummy ./mychart -f ./mychart/values.yaml > standalone-full-ppa.xml
```
Но тогда в standalone будут отступы и дополнительная информация, которая не нужна