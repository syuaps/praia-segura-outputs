# praia-segura-outputs

> **Repositório de entrega — API estática do Praia Segura**
> Serve como camada de dados pública do aplicativo, hospedada via **GitHub Pages**.

---

## Visão geral

O **Praia Segura** é um aplicativo de informação praia/mar para o litoral do Recife-PE. Ele exibe ao usuário:

- Previsão meteorológica e oceanográfica dos próximos 5–6 dias (vento, temperatura, chuva, UV, ondas, maré, nível do mar)
- Balneabilidade semanal atualizada (fonte: CPRH-PE)
- Mapa e fichas dos 31 setores de praia do Recife, com atributos de segurança (correntes, recifes, histórico de tubarão etc.)
- Piscinas naturais mapeadas com status de balneabilidade
- Guia do Mar — conteúdo educativo sobre segurança costeira
- Serviços e infraestrutura da orla (academias, banheiros, guarda-vidas etc.)
- Emergências (telefones)
- Projetos e iniciativas costeiras relacionadas

Este repositório **não contém o aplicativo mobile/web em si**. Ele é a camada de dados estáticos — o "backend público" — que o app consome via requisições HTTP simples.

---

## Arquitetura

```
┌────────────────────────────────────────────────────────────────┐
│  Backend (máquina local / servidor)                            │
│  Repositório: praia_segura_backend  (privado)                  │
│                                                                │
│  Scripts Python que:                                           │
│  • Baixam dados das fontes externas (ECMWF, Copernicus,        │
│    TPXO10, CPRH)                                               │
│  • Processam e geram os arquivos JSON em outputs/ e            │
│    data_static/                                                │
│  • Executam publicar.bat ao final de cada rodada               │
└───────────────────────┬────────────────────────────────────────┘
                        │  publicar.bat  (robocopy + git push)
                        ▼
┌────────────────────────────────────────────────────────────────┐
│  Este repositório: praia-segura-outputs  (público)             │
│  Hospedagem: GitHub Pages                                      │
│  Base URL: https://syuaps.github.io/praia-segura-outputs/      │
└───────────────────────┬────────────────────────────────────────┘
                        │  requisições HTTP (GET)
                        ▼
┌────────────────────────────────────────────────────────────────┐
│  Aplicativo (Conecta Recife / app mobile/web)                  │
│  Consome os JSON diretamente pela URL pública                  │
└────────────────────────────────────────────────────────────────┘
```

**Não há servidor, banco de dados ou autenticação.** Todos os arquivos são estáticos e qualquer cliente com acesso à internet pode ler os JSON pela URL pública.

---

## URL base e fluxo de leitura recomendado

```
Base URL: https://syuaps.github.io/praia-segura-outputs/
```

Índice dedicado de outputs: [https://syuaps.github.io/praia-segura-outputs/outputs/](https://syuaps.github.io/praia-segura-outputs/outputs/)

Fluxo recomendado para verificar se há dados novos e carregar a previsão:

```
1. GET rodada_atual.json           → verifica timestamp da última rodada
2. GET outputs/forecast_full.json  → carrega previsão completa 5 dias
3. (opcional) GET outputs/index.html  → índice navegável dos arquivos de previsão
4. (opcional) GET outputs/products/<produto>.json  → dados brutos por fonte
```

---

## Estrutura de arquivos

```
praia-segura-outputs/
├── rodada_atual.json                         # carimbo da última atualização
├── index.html                                # menu navegável (GitHub Pages)
├── styles.css
├── publicar.bat                              # script de publicação (backend → GitHub)
│
├── outputs/                                  # dados dinâmicos (atualizam ~diariamente)
│   ├── index.html                            # índice dedicado de outputs
│   ├── forecast_full.json                    # agregador principal — use este no app
│   └── products/                             # produtos brutos por fonte
│       ├── ifs_oper__recife.json
│       ├── ifs_ens_probs__recife.json
│       ├── TPXO10_atlas_v2_recife.json
│       └── cmems_mod_glo_phy_anfc_merged-sl_PT1H-i__recife_timeseries.json
│
└── data_static/                              # dados semi-estáticos (atualizam sob demanda)
    ├── balneabilidade/
    │   ├── balneabilidade_latest.json        # metadados do boletim mais recente
    │   └── pdfs/                             # PDFs dos informativos da CPRH
    ├── emergencia/
    │   └── emergencia.json                   # telefones de emergência
    ├── guiadomar/
    │   ├── guiaTemas.json                    # conteúdo educativo por tema
    │   └── guiadomar_img/                    # imagens dos temas (PNG)
    ├── piscinas/
    │   ├── piscinasNaturais.json             # piscinas mapeadas + balneabilidade
    │   └── piscinas_img/                     # fotos das piscinas (ID_XXXX.jpg)
    ├── projetos/
    │   └── projetos.json                     # projetos e iniciativas costeiras
    ├── servicos/
    │   └── servicos.json                     # infraestrutura e serviços da orla
    └── setores/
        ├── setoresRecife.json                # 31 setores de praia + atributos
        └── setores_img/                      # fotos dos setores (ID_XXXX.jpg)
```

---

## Descrição detalhada de cada endpoint

### `rodada_atual.json`

Arquivo de sinalização. O app deve verificar este arquivo para saber se há dados novos antes de baixar os demais.

```json
{
  "updated_at": "2026-06-12T06:41:28-03:00"
}
```

| Campo          | Tipo                         | Descrição                                                        |
| -------------- | ---------------------------- | ------------------------------------------------------------------ |
| `updated_at` | string ISO 8601 com timezone | Horário local (America/Recife, UTC-3) da última rodada publicada |

---

### `outputs/forecast_full.json` ⭐ principal

Agregador da rodada. Contém previsão dia a dia para os próximos 5 dias, com todos os dados necessários para o app (maré, meteorologia, ondas, sol).

**Campos raiz:**

| Campo                  | Tipo            | Descrição                                                                                   |
| ---------------------- | --------------- | --------------------------------------------------------------------------------------------- |
| `schema_version`     | string          | Versão do schema (`"1.1"`)                                                                 |
| `generated_at_local` | string ISO 8601 | Horário de geração em America/Recife                                                       |
| `timezone`           | string          | `"America/Recife"`                                                                          |
| `location.name`      | string          | `"Recife, PE"`                                                                              |
| `location.bbox`      | object          | Bounding box usada para extração dos dados (`minLon`, `maxLon`, `minLat`, `maxLat`) |
| `location.sun_point` | object          | Ponto de referência para cálculo de nascer/pôr do sol (`lat`, `lon`)                   |
| `time_window`        | object          | Janela temporal coberta (`start_utc`, `end_utc`, em UTC e local)                          |
| `sources`            | object          | Metadados das fontes usadas na rodada                                                         |
| `notes`              | object          | Notas técnicas sobre aproximações aplicadas                                                |
| `days`               | array           | Array com um objeto por dia (ver abaixo)                                                      |

**Estrutura de cada item em `days[]`:**

```jsonc
{
  "date_local": "2026-06-12",       // data local (America/Recife)
  "timezone": "America/Recife",
  "sun": {
    "sunrise_local": "05:29",       // horário de nascer do sol (HH:mm)
    "sunset_local": "17:09"         // horário de pôr do sol (HH:mm)
  },
  "sea_level": {                    // nível do mar (Copernicus Marine, datum Porto do Recife)
    "unit": "m",
    "series": {
      "time_local": ["..."],        // array de timestamps a cada 3 h (8 pontos/dia)
      "values": [...]               // alturas em metros
    },
    "high_tides": [{ "time_local": "...", "height_m": 2.363 }],
    "low_tides":  [{ "time_local": "...", "height_m": 0.34 }],
    "low_tide_m": 0.322,            // mínimo do dia
    "high_tide_m": 2.245            // máximo do dia
  },
  "tide_tpxo": {                    // maré astronômica pura (TPXO10)
    "unit": "m",
    "series": { "time_local": [...], "values": [...] },  // a cada 30 min
    "high_tides": [...],
    "low_tides":  [...]
  },
  "meteo": {                        // meteorologia (ECMWF IFS HRES)
    "units": { ... },               // dicionário de unidades por variável
    "daily": {                      // resumo diário
      "air_temp": { "min", "max", "mean", "min_time_local", "max_time_local" },
      "humidity": { "mean" },
      "wind_speed": { "min", "max", "mean", "min_time_local", "max_time_local" },
      "wind_dir_sector_mode": "SSE", // direção dominante (rosa de 16 pontos)
      "rain_prob_pct_max": 93.0,
      "rain_prob_pct_mean": 93.0,
      "cloud_cover": { "mean" },
      "uv_class": "médio"            // "baixo" | "moderado" | "médio" | "alto" | "muito alto" | "extremo"
    },
    "series": {                      // séries temporais a cada 3 h (8 pontos/dia)
      "air_temp_c":      { "time_local": [...], "values": [...] },
      "humidity_pct":    { "time_local": [...], "values": [...] },
      "wind_speed_ms":   { "time_local": [...], "values": [...] },
      "wind_dir_sector": { "time_local": [...], "values": [...] },
      "rain_prob_pct":   { "time_local": [...], "values": [...] },
      "cloud_cover_pct": { "time_local": [...], "values": [...] },
      "msl_pressure_hpa":{ "time_local": [...], "values": [...] }
    }
  }
}
```

> **Datum de maré:** todos os valores de nível do mar estão referenciados ao datum do **Porto do Recife** (offset +1,282 m aplicado). Maré astronômica TPXO10 também usa o mesmo datum.

---

### `outputs/products/ifs_oper__recife.json`

Produto bruto ECMWF IFS HRES operacional. Contém as séries horárias completas (passo 1–3 h) para a área de Recife, antes do reagregamento em `forecast_full.json`. Útil para aplicações que precisam de maior resolução temporal ou variáveis não incluídas no agregador.

**Variáveis disponíveis (parâmetros ECMWF):**

| Código ECMWF     | Descrição                               | Unidade         |
| ----------------- | ----------------------------------------- | --------------- |
| `2t`            | Temperatura do ar a 2 m                   | K → °C        |
| `2d`            | Temperatura de ponto de orvalho a 2 m     | K → °C        |
| `10u` / `10v` | Componentes U e V do vento a 10 m         | m/s             |
| `tp`            | Precipitação total acumulada            | m               |
| `ssrd`          | Radiação solar de onda curta acumulada  | J/m²           |
| `msl`           | Pressão ao nível médio do mar          | Pa → hPa       |
| `tcc`           | Cobertura de nuvens total                 | fração (0–1) |
| `swh`           | Altura significativa das ondas            | m               |
| `mwd`           | Direção das ondas (mean wave direction) | graus           |
| `mwp`           | Período médio das ondas                 | s               |

---

### `outputs/products/ifs_ens_probs__recife.json`

Probabilidades do ensemble ECMWF (stream `enfo`, type `ep`). Fornece limiares de precipitação e vento forte para os próximos 6 dias, com resolução diária.

| Parâmetro  | Significado                                |
| ----------- | ------------------------------------------ |
| `tpg1`    | Prob. precipitação acumulada > 1 mm/dia  |
| `tpg5`    | Prob. precipitação acumulada > 5 mm/dia  |
| `tpg10`   | Prob. precipitação acumulada > 10 mm/dia |
| `tpg20`   | Prob. precipitação acumulada > 20 mm/dia |
| `10fgg10` | Prob. rajada de vento > 10 m/s             |
| `10fgg15` | Prob. rajada de vento > 15 m/s             |
| `10fgg25` | Prob. rajada de vento > 25 m/s             |

> ⚠️ `rain_prob_pct` nas séries de 3 h em `forecast_full.json` é uma **aproximação**: a probabilidade diária do ensemble é redistribuída proporcionalmente ao `tp` HRES em cada passo. Para resolução sub-diária exata seria necessário processar os membros individuais (`enfo-ef`).

---

### `outputs/products/TPXO10_atlas_v2_recife.json`

Maré astronômica calculada pelo modelo **TPXO10-atlas-v2** com 15 componentes harmônicas (M2, S2, N2, K2, 2N2, K1, O1, P1, Q1, S1, M4, MS4, MN4, Mm, Mf). Resolução temporal: **5 minutos**. Datum aplicado: +1,282 m (Porto do Recife).

Série temporal de 6 dias com campos:

- `series.time_utc` — timestamps em UTC
- `series.tide_m` — altura da maré em metros (datum Porto do Recife)
- `tides_extremes` — lista de preamar/baixamar com hora e altura

---

### `outputs/products/cmems_mod_glo_phy_anfc_merged-sl_PT1H-i__recife_timeseries.json`

Série temporal da **análise e previsão oceânica global** do Copernicus Marine Service (CMEMS). Resolução horária, agregada espacialmente como média da bbox de Recife.

| Variável           | Descrição                                   | Unidade |
| ------------------- | --------------------------------------------- | ------- |
| `total_sea_level` | Nível do mar acima do geoide (+ datum Porto) | m       |
| `ocean_tide`      | Componente de maré (+ datum Porto)           | m       |

Dataset ID: `cmems_mod_glo_phy_anfc_merged-sl_PT1H-i`
DOI: `10.48670/moi-00016`

---

### `data_static/balneabilidade/balneabilidade_latest.json`

Metadados do boletim de balneabilidade mais recente da CPRH-PE.

```jsonc
{
  "updated_at": "2026-06-12T06:29:51",
  "bulletin_number": 24,
  "bulletin_year": 2026,
  "report_date": "11/06/2026",
  "periodo": "12/06/2026 a 18/06/2026",   // validade do boletim
  "data_coleta": "08/06/2026",             // data da coleta das amostras
  "station_count": 27,                     // número de pontos monitorados
  "pdf": "...",                            // caminho local no backend
  "source_url": "https://www2.cprh.pe.gov.br/..."  // URL original do PDF
}
```

O status de balneabilidade por ponto está **embutido nos objetos de setor e piscina**, nos campos `atributos.balneabilidade` e `balneabilidade` respectivamente.

Status possíveis: `"propria"` | `"impropria"`

---

### `data_static/setores/setoresRecife.json`

Array com os **31 setores de praia do Recife**. Cada setor tem:

```jsonc
{
  "id": "ID_0001",                          // chave única (usada para buscar imagem)
  "nome": "Buraco da véia",
  "centro": { "latitude": -8.079518, "longitude": -34.875937 },
  "limites": { "latMax", "lonMax", "latMin", "lonMin" },  // bounding box do setor
  "atributos": {
    "correnteRetorno": false,               // há corrente de retorno?
    "correntePermanente": true,             // corrente permanente?
    "mesesCorrenteSazonal": "",             // meses (se sazonal)
    "protecaoRecifal": true,                // protegido por recifes?
    "piscinasNaturais": true,               // tem piscinas naturais?
    "incidentesTubarao": false,             // histórico de incidente com tubarão?
    "restinga": false,                      // há restinga?
    "acessibilidade": false,                // infraestrutura de acessibilidade?
    "balneabilidade": {
      "status": "impropria",
      "dataReferencia": "11/06/2026",
      "periodo": "12/06/2026 a 18/06/2026",
      "codCPRHBalneabilidade": "REC-80"     // código de ponto da CPRH
    }
  }
}
```

Imagens dos setores: `data_static/setores/setores_img/ID_XXXX.jpg`
URL de exemplo: `https://syuaps.github.io/praia-segura-outputs/data_static/setores/setores_img/ID_0001.jpg`

---

### `data_static/piscinas/piscinasNaturais.json`

Array com as piscinas naturais mapeadas. Cada piscina referencia um setor via `setorId` e um ponto CPRH via `codCPRHBalneabilidade`.

```jsonc
{
  "id": "PISCINA_BURACO_DA_VEIA",
  "nome": "Piscina natural de Buraco da véia",
  "descricao": "...",
  "setorId": "ID_0001",                    // referência ao setor pai
  "codCPRHBalneabilidade": "REC-80",
  "imagem": "ID_0001",                     // chave para buscar em piscinas_img/
  "balneabilidade": {
    "status": "impropria",
    "dataReferencia": "11/06/2026",
    "periodo": "12/06/2026 a 18/06/2026",
    "codCPRHBalneabilidade": "REC-80"
  }
}
```

Imagens: `data_static/piscinas/piscinas_img/ID_XXXX.jpg`

---

### `data_static/guiadomar/guiaTemas.json`

Array de temas educativos sobre segurança no mar. Cada tema possui:

| Campo           | Descrição                                                    |
| --------------- | -------------------------------------------------------------- |
| `id`          | Identificador único                                           |
| `titulo`      | Título do tema                                                |
| `subtitulo`   | Subtítulo                                                     |
| `imagem`      | Nome do arquivo de imagem (sem extensão) em`guiadomar_img/` |
| `resumo`      | Texto curto para card/preview                                  |
| `explicacao`  | Texto explicativo completo                                     |
| `dicas`       | Array de strings com dicas práticas                           |
| `alertaFinal` | Mensagem de alerta final                                       |

Temas disponíveis: `mar-hoje`, `mare`, `ondas`, `correntes`, `recifes`, `tubaroes`, `balneabilidade`, `oceanografia`, `restingas`.

---

### `data_static/servicos/servicos.json`

Array de pontos de serviço e infraestrutura na orla. Cada ponto possui:

| Campo                        | Descrição                                                                        |
| ---------------------------- | ---------------------------------------------------------------------------------- |
| `id`                       | Identificador único                                                               |
| `categoria`                | Código de categoria (ex:`"AC"` = Academia da Cidade, `"BH"` = Banheiro, etc.) |
| `nome`                     | Nome do serviço                                                                   |
| `endereco`                 | Endereço (pode estar vazio)                                                       |
| `contato`                  | Telefone/contato (pode estar vazio)                                                |
| `funcionamento`            | Horário de funcionamento (pode estar vazio)                                       |
| `latitude` / `longitude` | Coordenadas geográficas                                                           |

---

### `data_static/emergencia/emergencia.json`

Array com números de emergência.

| Campo         | Descrição                                              |
| ------------- | -------------------------------------------------------- |
| `id`        | Identificador                                            |
| `titulo`    | Nome do serviço                                         |
| `subtitulo` | Descrição adicional                                    |
| `numero`    | Número de telefone ou`"Lista"` (para link para lista) |

---

### `data_static/projetos/projetos.json`

Array com projetos e iniciativas costeiras relacionadas ao aplicativo.

| Campo       | Descrição                    |
| ----------- | ------------------------------ |
| `id`      | Identificador                  |
| `title`   | Nome do projeto                |
| `summary` | Resumo                         |
| `focus`   | Área de foco                  |
| `links`   | Array de`{ "label", "url" }` |

---

## Fluxo de atualização dos dados

```
[Cron/manual no servidor de backend]
        │
        ▼
praia_segura_backend/
├── _01_get_forecast_tpxo.py           (maré TPXO10)
├── _02_get_forecast_copernicus.py     (CMEMS nível do mar)
├── _03_get_forecast_ecmwf.py          (IFS HRES + ENS)
├── _04_build_forecast_full.py         (agrega tudo → forecast_full.json)
└── (scripts de balneabilidade)        (scraping CPRH → balneabilidade_latest.json
                                        + atualiza setores e piscinas)
        │
        ▼
publicar.bat  (neste repositório)
  1. robocopy outputs/        → praia-segura-outputs/outputs/
  2. robocopy data_static/    → praia-segura-outputs/data_static/
  3. Atualiza rodada_atual.json com timestamp atual
  4. git add -A  →  git commit  →  git push
        │
        ▼
GitHub Pages publica automaticamente (~1–3 min após push)
```

**Frequência atual:** diária, rodada base `00z UTC` do ECMWF (disponível ~07–08 h UTC ≈ 04–05 h horário de Recife).

---

## Integração com o app Conecta Recife

### O que o app precisa fazer

1. **Verificar se há dados novos** (poll de `rodada_atual.json`): comparar `updated_at` com o valor em cache local. Se diferente, baixar os dados.
2. **Carregar previsão**: `GET outputs/forecast_full.json`. Este arquivo já agrega tudo; na maioria dos casos o app **não precisa** acessar os arquivos em `outputs/products/`.
3. **Carregar dados estáticos** (na primeira inicialização ou quando houver nova versão):

   - `data_static/setores/setoresRecife.json` — 31 setores
   - `data_static/piscinas/piscinasNaturais.json` — piscinas
   - `data_static/guiadomar/guiaTemas.json` — guia do mar
   - `data_static/servicos/servicos.json` — serviços
   - `data_static/emergencia/emergencia.json` — emergências
   - `data_static/projetos/projetos.json` — projetos
   - `data_static/balneabilidade/balneabilidade_latest.json` — metadados do boletim
4. **Imagens**: todas as imagens são servidas diretamente via URL. Não há API separada de imagens.

   ```
   Setor:   .../data_static/setores/setores_img/ID_0001.jpg
   Piscina: .../data_static/piscinas/piscinas_img/ID_0001.jpg
   Guia:    .../data_static/guiadomar/guiadomar_img/mare.png
   ```

### Considerações técnicas

| Item                     | Detalhe                                                                                                                                          |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Protocolo**      | HTTPS somente (GitHub Pages força HTTPS)                                                                                                        |
| **CORS**           | GitHub Pages serve com`Access-Control-Allow-Origin: *` — qualquer origem pode consumir a API                                                  |
| **Cache**          | GitHub Pages aplica cache agressivo. O app deve usar cache-busting no`rodada_atual.json` (ex: `?t=<timestamp>`) para garantir leitura fresca |
| **Autenticação** | Nenhuma — todos os arquivos são públicos                                                                                                      |
| **Rate limit**     | Não há rate limit imposto por este repositório. GitHub Pages tem limites de banda (100 GB/mês por repositório), suficientes para uso normal |
| **Formato**        | JSON UTF-8 sem BOM                                                                                                                               |
| **Timezone**       | Todos os horários locais estão em`America/Recife` (UTC-3, sem horário de verão)                                                            |
| **Datum de maré** | +1,282 m em relação ao datum do Porto do Recife — já aplicado em todos os campos de nível do mar                                            |

### Exemplo de requisição (JavaScript/fetch)

```js
const BASE_URL = 'https://syuaps.github.io/praia-segura-outputs';

// 1. Verificar atualização
const { updated_at } = await fetch(`${BASE_URL}/rodada_atual.json?t=${Date.now()}`).then(r => r.json());

// 2. Carregar previsão completa
const forecast = await fetch(`${BASE_URL}/outputs/forecast_full.json`).then(r => r.json());

// 3. Dados estáticos (exemplo)
const setores = await fetch(`${BASE_URL}/data_static/setores/setoresRecife.json`).then(r => r.json());
```

---

## Fontes de dados externas

| Fonte                               | Dataset                                     | Variáveis usadas                                                    | Licença                                                                                           |
| ----------------------------------- | ------------------------------------------- | -------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| **ECMWF Open Data**           | IFS HRES 0.25°                             | vento, temperatura, umidade, precipitação, radiação solar, ondas | [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)                                             |
| **ECMWF Open Data**           | IFS ENS probability products                | probabilidade de chuva e vento forte                                 | [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)                                             |
| **Copernicus Marine Service** | `cmems_mod_glo_phy_anfc_merged-sl_PT1H-i` | nível total do mar, componente de maré oceânica                   | [Copernicus Marine Licence](https://marine.copernicus.eu/user-corner/service-commitments-and-licence) |
| **TPXO10-atlas-v2**           | Oregon State University                     | maré astronômica (15 constituintes)                                | Uso acadêmico/científico — verificar licença para uso comercial                                |
| **CPRH-PE**                   | Boletins semanais de balneabilidade         | status própria/imprópria por ponto                                 | Dados públicos do governo estadual                                                                |

---

## Repositórios relacionados

| Repositório                    | Descrição                              | Acesso   |
| ------------------------------- | ---------------------------------------- | -------- |
| `praia-segura-outputs` (este) | API estática + GitHub Pages             | Público |
| `praia_segura_backend`        | Scripts Python de coleta e processamento | Privado  |

---

## Manutenção e troubleshooting

| Problema                                       | Causa provável                                          | Solução                                                                           |
| ---------------------------------------------- | -------------------------------------------------------- | ----------------------------------------------------------------------------------- |
| `rodada_atual.json` desatualizado há > 24 h | Rodada do backend não rodou ou falhou                   | Rodar`publicar.bat` manualmente após corrigir o backend                          |
| Arquivo retorna 404                            | Nome errado (case-sensitive) ou push ainda não propagou | Conferir nome exato no`index.html` e aguardar 1–3 min após push                 |
| Dados de balneabilidade desatualizados         | Boletim CPRH ainda não publicado ou script não rodou   | Verificar em`https://www2.cprh.pe.gov.br/monitoramento-ambiental/balneabilidade/` |
| Maré com valores inesperados                  | Datum não aplicado no cliente                           | Confirmar que os valores já chegam ajustados (+1,282 m) — não aplicar novamente  |

---

## Licença dos dados neste repositório

Os dados de previsão meteorológica/oceanográfica derivam de fontes com licenças abertas (ver tabela acima). Os dados de balneabilidade são públicos (CPRH-PE). Conteúdo editorial (Guia do Mar, textos dos projetos) é de autoria da equipe Praia Segura/UFPE.
