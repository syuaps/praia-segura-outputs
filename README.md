# praia-segura-outputs

> Repositório público de entrega do Praia Segura.
> Funciona como API estática temporária para a primeira integração com a equipe da Prefeitura do Recife e futura migração para o Conecta Recife.

## Status Da Entrega

Este repositório já contém a base pública consumida pelo aplicativo:

- Previsão consolidada em `outputs/forecast_full.json`.
- Avisos meteorológicos do INMET em `outputs/avisoinmet.json`.
- Dados estáticos de setores, piscinas, serviços, emergências, Guia do Mar, projetos e balneabilidade.
- Imagens públicas de setores, piscinas, Guia do Mar, projetos e marcadores de mapa, incluindo o conjunto atual de pins `pin-grey`, `pin-blue`, `pin-red`, `pin-green`, `pin-yellow`, `pin-accessibility` e `pin-me`.
- JSONs localizados em `data_static/i18n/<locale>/...` para `en-US`, `es` e `fr`.
- `rodada_atual.json` para controle de atualização pelo cliente.

Base URL atual:

```text
https://syuaps.github.io/praia-segura-outputs/
```

## Arquitetura Atual

```text
Backend local/servidor
  - scripts Python coletam e processam ECMWF, Copernicus/CMEMS, TPXO10, CPRH e INMET
  - geram JSON em outputs/ e data_static/
  - executam publicar.bat no fim da rodada

        publicar.bat
             |
             v

Repositório público praia-segura-outputs
  - hospedado no GitHub Pages
  - expõe JSONs e imagens por HTTPS
  - atua como camada de dados pública com cache

             HTTP GET
             |
             v

Aplicativo Praia Segura / Conecta Recife
  - consome JSONs e imagens diretamente pela URL pública
  - exibe previsão, balneabilidade, setores, piscinas, serviços e avisos
```

Não há servidor de aplicação, banco de dados ou autenticação nesta camada. Todo o consumo é feito por arquivos estáticos via HTTPS.

## Como Consumir

Fluxo recomendado:

```text
1. GET /rodada_atual.json
2. Comparar updated_at com o valor em cache no app
3. Se mudou, baixar os JSONs necessários
4. Cachear localmente no app
5. Carregar imagens por demanda pela URL pública
```

Exemplo:

```js
const BASE_URL = "https://syuaps.github.io/praia-segura-outputs/"

const rodada = await fetch(`${BASE_URL}rodada_atual.json?t=${Date.now()}`).then((r) => r.json())
const forecast = await fetch(`${BASE_URL}outputs/forecast_full.json`).then((r) => r.json())
const setores = await fetch(`${BASE_URL}data_static/setores/setoresRecife.json`).then((r) => r.json())
```

O parâmetro `?t=${Date.now()}` é recomendado em `rodada_atual.json` para evitar cache antigo do GitHub Pages.

## Endpoints Principais

| Caminho                                                                              | Descrição                                   |
| ------------------------------------------------------------------------------------ | --------------------------------------------- |
| `rodada_atual.json`                                                                | Timestamp da última publicação.            |
| `outputs/forecast_full.json`                                                       | Arquivo principal da previsão de 5 a 6 dias. |
| `outputs/avisoinmet.json`                                                          | Avisos meteorológicos do INMET para Recife.  |
| `outputs/products/ifs_oper__recife.json`                                           | Produto ECMWF IFS operacional.                |
| `outputs/products/ifs_ens_probs__recife.json`                                      | Probabilidades ensemble ECMWF.                |
| `outputs/products/TPXO10_atlas_v2_recife.json`                                     | Maré astronômica TPXO10.                    |
| `outputs/products/cmems_mod_glo_phy_anfc_merged-sl_PT1H-i__recife_timeseries.json` | Nível do mar CMEMS.                          |
| `data_static/setores/setoresRecife.json`                                           | 31 setores da orla do Recife.                 |
| `data_static/piscinas/piscinasNaturais.json`                                       | Piscinas naturais mapeadas.                   |
| `data_static/balneabilidade/balneabilidade_latest.json`                            | Metadados do boletim CPRH mais recente.       |
| `data_static/guiadomar/guiaTemas.json`                                             | Temas educativos do Guia do Mar.              |
| `data_static/servicos/servicos.json`                                               | Serviços e infraestrutura da orla.           |
| `data_static/emergencia/emergencia.json`                                           | Telefones e canais de emergência.            |
| `data_static/projetos/projetos.json`                                               | Projetos e iniciativas costeiras.             |
| `data_static/assets/map-markers/*.png`                                             | Marcadores de mapa.                           |
| `data_static/i18n/<locale>/...`                                                    | Cópias localizadas dos JSONs estáticos.     |

## Estrutura De Arquivos

```text
praia-segura-outputs/
├── rodada_atual.json
├── index.html
├── styles.css
├── publicar.bat
├── outputs/
│   ├── index.html
│   ├── forecast_full.json
│   ├── avisoinmet.json
│   └── products/
│       ├── ifs_oper__recife.json
│       ├── ifs_ens_probs__recife.json
│       ├── TPXO10_atlas_v2_recife.json
│       └── cmems_mod_glo_phy_anfc_merged-sl_PT1H-i__recife_timeseries.json
├── data_static/
│   ├── assets/map-markers/
│   ├── balneabilidade/
│   ├── emergencia/
│   ├── guiadomar/
│   ├── i18n/
│   ├── piscinas/
│   ├── projetos/
│   ├── servicos/
│   └── setores/
└── i18n/
```

`data_static/i18n/` é o caminho usado pelo app atual. A pasta `i18n/` na raiz é uma cópia publicada para conveniência/compatibilidade operacional.

## `rodada_atual.json`

Arquivo mínimo usado para saber se existe uma rodada nova:

```json
{
  "updated_at": "2026-07-20T11:07:02-03:00"
}
```

| Campo          | Tipo            | Observação                                      |
| -------------- | --------------- | ------------------------------------------------- |
| `updated_at` | string ISO 8601 | Horário local de Recife da última publicação. |

## `outputs/forecast_full.json`

É o arquivo principal para o cliente. Ele agrega os produtos do backend em uma estrutura pronta para exibição.

Campos de alto nível esperados no contrato simplificado:

| Campo                  | Conteúdo                     |
| ---------------------- | ----------------------------- |
| `generated_at_local` | Data/hora local de geração. |
| `days[]`             | Lista de dias da previsão.   |

Campos principais por dia:

| Campo                        | Conteúdo                                           |
| ---------------------------- | --------------------------------------------------- |
| `date_local`               | Data local da previsão.                            |
| `sun`                      | Nascer e pôr do sol usados nas janelas de banho.   |
| `tide`                     | Série, preamares e baixa-mares da maré TPXO.      |
| `meteo.daily`              | Temperatura, vento, direção do vento e classe UV. |
| `waves.daily`              | Altura significativa mínima e máxima das ondas.   |
| `probabilities.daily`      | Probabilidades usadas nas regras de risco do app.   |
| `ui_cards.manha.icon_hint` | Sugestão visual simples para o card principal.     |

O app usa esse arquivo para as telas de "Mar hoje", "Previsão", "Previsão completa", "Resumo da previsão" e para colorir os pins do `mapapraia` conforme o risco do dia atual.

## `outputs/avisoinmet.json`

Arquivo de avisos meteorológicos oficiais do INMET para Recife.

Campos principais:

| Campo                  | Conteúdo                                                            |
| ---------------------- | -------------------------------------------------------------------- |
| `schema_version`     | Versão do schema do arquivo.                                        |
| `fonte`              | Metadados do INMET e URL do RSS.                                     |
| `local`              | Município, UF e código IBGE de Recife.                             |
| `gerado_em`          | Data/hora local da consulta.                                         |
| `status_consulta`    | `ok`, `erro` ou `erro_com_cache`.                              |
| `dados_em_cache`     | Indica se a resposta veio de cache válido.                          |
| `tem_alerta`         | `true`, `false` ou `null` quando não foi possível confirmar. |
| `tem_alerta_vigente` | Indica aviso vigente.                                                |
| `tem_alerta_futuro`  | Indica aviso futuro.                                                 |
| `quantidade_alertas` | Total de alertas não expirados.                                     |
| `maior_severidade`   | `amarelo`, `laranja`, `vermelho` ou `null`.                  |
| `mensagem`           | Texto resumido para o app.                                           |
| `alertas[]`          | Lista estruturada de alertas, quando houver.                         |

O app combina este arquivo com `forecast_full.json` para destacar chuva forte, vento, tempestade, ressaca, calor e outros riscos relevantes para banhistas.

## Dados Estáticos

| Caminho                                                   | Conteúdo                                                                   |
| --------------------------------------------------------- | --------------------------------------------------------------------------- |
| `data_static/setores/setoresRecife.json`                | Setores da praia, coordenadas, limites e atributos de risco/infraestrutura. |
| `data_static/piscinas/piscinasNaturais.json`            | Piscinas naturais, vínculo com setor, imagem e balneabilidade.             |
| `data_static/balneabilidade/balneabilidade_latest.json` | Boletim CPRH processado, período, coleta, PDF e fonte.                     |
| `data_static/guiadomar/guiaTemas.json`                  | Temas educativos, explicações, dicas e alertas finais.                    |
| `data_static/servicos/servicos.json`                    | Pontos de apoio, categoria, contato, funcionamento e coordenadas.           |
| `data_static/emergencia/emergencia.json`                | Telefones e canais de emergência.                                          |
| `data_static/projetos/projetos.json`                    | Projetos, foco, resumo e links oficiais.                                    |

## Imagens E Assets

Todas as imagens são servidas como arquivos públicos. Não há endpoint separado de mídia.

| Recurso            | Padrão de URL                                                                                                                                                       |
| ------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Setor              | `data_static/setores/setores_img/ID_0001.jpg`                                                                                                                      |
| Piscina            | `data_static/piscinas/piscinas_img/ID_0001.jpg`                                                                                                                    |
| Guia do Mar        | `data_static/guiadomar/guiadomar_img/mare.png`                                                                                                                     |
| Ícone do Guia     | `data_static/guiadomar/guiadomar_icons/icon-mare.png`                                                                                                              |
| Ícone fallback    | `data_static/guiadomar/guiadomar_icons/icon-fallback.png`                                                                                                          |
| Projeto            | `data_static/projetos/projetos_img/<id>.png`                                                                                                                       |
| Marcadores de mapa | `data_static/assets/map-markers/pin-grey.png`, `pin-blue.png`, `pin-red.png`, `pin-green.png`, `pin-yellow.png`, `pin-accessibility.png`, `pin-me.png` |

Exemplo:

```text
https://syuaps.github.io/praia-segura-outputs/data_static/setores/setores_img/ID_0001.jpg
```

Marcadores atuais:

| Arquivo                   | Uso no app                                                   |
| ------------------------- | ------------------------------------------------------------ |
| `pin-grey.png`          | Pin padrão do mapa de serviços.                            |
| `pin-blue.png`          | Pin selecionado nos mapas de praia e serviços.              |
| `pin-accessibility.png` | Pin de acessibilidade/Praia sem Barreiras.                   |
| `pin-red.png`           | Risco alto no mapa da praia.                                 |
| `pin-green.png`         | Piscinas e setores protegidos em risco baixo/intermediário. |
| `pin-yellow.png`        | Setores sem proteção em risco baixo/intermediário.        |
| `pin-me.png`            | Localização aproximada do usuário.                        |

`pin-default.png` e `pin-selected.png` podem permanecer publicados por compatibilidade histórica, mas o app atual usa `pin-grey.png` e `pin-blue.png`.

## Internacionalização

O conteúdo padrão fica em português:

```text
data_static/<modulo>/<arquivo>.json
```

Para idiomas adicionais, o app usa:

```text
data_static/i18n/en-US/data_static/<modulo>/<arquivo>.json
data_static/i18n/es/data_static/<modulo>/<arquivo>.json
data_static/i18n/fr/data_static/<modulo>/<arquivo>.json
```

Arquivos localizados disponíveis:

- `setores/setoresRecife.json`
- `piscinas/piscinasNaturais.json`
- `servicos/servicos.json`
- `projetos/projetos.json`
- `guiadomar/guiaTemas.json`
- `emergencia/emergencia.json`

O app atual cai automaticamente para português quando um recurso localizado não está disponível.

## Atualização Dos Dados

O fluxo de publicação parte do backend:

```text
praia_segura_backend
  -> gerar outputs/
  -> gerar data_static/
  -> gerar data_static/i18n/
  -> publicar.bat
  -> robocopy para praia-segura-outputs
  -> atualizar rodada_atual.json
  -> git commit
  -> git push
  -> GitHub Pages publica
```

Frequência esperada para a primeira operação: diária, com possibilidade de execução manual sob demanda.

## Integração Com Conecta Recife

Para integração inicial, considerar:

| Item           | Contrato atual                                                  |
| -------------- | --------------------------------------------------------------- |
| Protocolo      | HTTPS                                                           |
| Método        | `GET`                                                         |
| Autenticação | Nenhuma                                                         |
| CORS           | GitHub Pages permite consumo público                           |
| Formato        | JSON UTF-8 e imagens estáticas                                 |
| Timezone       | `America/Recife`                                              |
| Cache          | Cliente deve usar`rodada_atual.json` como controle de versão |
| Dados pessoais | Esta camada não recebe nem armazena dados de usuários         |

Decisões para migração institucional:

- Manter GitHub Pages temporariamente ou migrar para domínio/CDN oficial.
- Definir URL pública final.
- Definir política de cache e invalidação.
- Validar limites de tráfego e disponibilidade.
- Validar licenças das fontes externas conforme uso institucional.

## Fontes De Dados

| Fonte                             | Uso                                                                         |
| --------------------------------- | --------------------------------------------------------------------------- |
| ECMWF Open Data                   | Meteorologia, ondas e probabilidades ensemble.                              |
| Copernicus Marine Service / CMEMS | Nível do mar e componente de maré oceânica.                              |
| TPXO10-atlas v2                   | Maré astronômica.                                                         |
| CPRH-PE                           | Balneabilidade.                                                             |
| INMET                             | Avisos meteorológicos oficiais.                                            |
| Bases próprias                   | Setores, piscinas, serviços, projetos, emergências e conteúdo educativo. |

## Troubleshooting

| Sintoma                      | Possível causa                                                              | Ação                                                                   |
| ---------------------------- | ---------------------------------------------------------------------------- | ------------------------------------------------------------------------ |
| `rodada_atual.json` antigo | Backend não rodou, publicação falhou ou GitHub Pages ainda não propagou. | Conferir logs do backend,`git push` e aguardar alguns minutos.         |
| JSON retorna 404             | Caminho/nome incorreto ou arquivo não publicado.                            | Conferir maiúsculas/minúsculas e estrutura de diretórios.             |
| App mostra dados antigos     | Cache do cliente ou do GitHub Pages.                                         | Buscar`rodada_atual.json` com cache-busting e comparar `updated_at`. |
| Imagem não aparece          | Nome do arquivo fora do padrão esperado pelo app.                           | Conferir pasta e extensão.                                              |
| Idioma cai para PT-BR        | JSON localizado ausente ou erro no download.                                 | Verificar`data_static/i18n/<locale>/...`.                              |

## Repositórios Relacionados

| Repositório             | Papel                                 |
| ------------------------ | ------------------------------------- |
| `praia_segura_backend` | Coleta, processamento e publicação. |
| `praia-segura-outputs` | Camada pública estática.            |
| `praia-segura`         | App Expo/React Native.                |
