library(tidyverse)
library(DBI)
library(duckdb)

# 0. Base de participação eleitoral ----- 

con <- dbConnect(
  duckdb(),
  dbdir = here::here("minicurso_r/data/tratados/TSE")
)

mun_turnout_db <- tbl(con, "mun_turnout")

# 1. Tratando o duckdb ----

## 1.1 Filtragem no duckdb antes de trazer para a memória -----

anos_presidenciais <- seq(2002, 2024, 4)

mun_turnout_filtrado <- mun_turnout_db |>
  filter(
    ANO_ELEICAO %in% anos_presidenciais,
    NM_TIPO_ELEICAO == "ELEICAO ORDINARIA",
    DS_CARGO %in% c("PRESIDENTE", "GOVERNADOR")
  )

mun_turnout_filtrado |> 
  count(ANO_ELEICAO, DS_CARGO, NR_TURNO)

## 1.2 Traz para o environment o banco já filtrado -----

mun_turnout_df <- mun_turnout_filtrado |>
  collect()

dbDisconnect(con, shutdown = TRUE)

rm(con)
rm(mun_turnout_filtrado)
rm(mun_turnout_db)

# 2. Variáveis de interesse ----

## 2.1 Dummy: Houve 2º turno para o cargo de governador? ----

segundo_turno_gov <- mun_turnout_df |>
  filter(DS_CARGO == "GOVERNADOR") |>
  group_by(ANO_ELEICAO, SG_UF) |>
  summarise(
    segundo_turno_gov = as.numeric(max(NR_TURNO) == 2),
    .groups = "drop"
  )

segundo_turno_gov |> 
  count(ANO_ELEICAO, segundo_turno_gov)

## 2.2 Base final: presidencial + dummy de 2º turno estadual ----

presidencial_df <- mun_turnout_df |>
  filter(DS_CARGO == "PRESIDENTE")

painel_comparecimento <- presidencial_df |>
  filter(!SG_UF %in% c("ZZ", "VT")) |> 
  left_join(
    segundo_turno_gov,
    by = c("ANO_ELEICAO", "SG_UF")
  ) |> 
  mutate(
    p_nulos   = QT_VOTOS_NULOS/QT_APTOS * 100,
    p_brancos = QT_VOTOS_BRANCOS/QT_APTOS * 100,
    p_comp    = QT_COMPARECIMENTO/QT_APTOS * 100,
    p_abstencao = QT_ABSTENCOES/QT_APTOS * 100
  )
  
painel_comparecimento |> 
  count(is.na(segundo_turno_gov))

saveRDS(painel_comparecimento, file = here::here("minicurso_r/data/tratados/painel_comparecimento.rds"))
