---Visão 01:
CREATE OR REPLACE VIEW vw_casos_ultimos_12_meses AS
WITH meses_serie AS (
    SELECT 
        DATE_TRUNC('month', CURRENT_DATE - INTERVAL '12 months')::date + 
        (INTERVAL '1 month' * generate_subscripts(ARRAY[0,1,2,3,4,5,6,7,8,9,10,11], 1)) as mes_inicio
),
casos_agrupados AS (
    SELECT
        DATE_TRUNC('month', c.data)::date as mes,
        COUNT(*) as quantidade
    FROM CASO c
    WHERE c.data >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '12 months')
    AND c.data <= DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month - 1 day'
    GROUP BY DATE_TRUNC('month', c.data)
)
SELECT
    EXTRACT(MONTH FROM ms.mes_inicio)::int as mes_numero,
    EXTRACT(YEAR FROM ms.mes_inicio)::int as ano,
    COALESCE(ca.quantidade, 0) as quantidade,
    ms.mes_inicio as data_referencia
FROM meses_serie ms
LEFT JOIN casos_agrupados ca ON ca.mes = ms.mes_inicio
ORDER BY ms.mes_inicio ASC;


---Visão 02:
CREATE OR REPLACE VIEW vw_comparativo_raca_violencia AS
SELECT
    COALESCE(brancas.tipo_violencia, nbrancas.tipo_violencia) AS tipo_violencia,
    COALESCE(nbrancas.vitimas_nao_brancas, 0) AS vitimas_nao_brancas,
    COALESCE(brancas.vitimas_brancas, 0) AS vitimas_brancas
FROM
    (SELECT v.tipo_violencia, COUNT(*) AS vitimas_brancas
    FROM assistida a
    JOIN tipo_violencia v ON v.id_assistida = a.id
    WHERE a.cor_raca = 'BRANCA'
    GROUP BY v.tipo_violencia) AS brancas
FULL OUTER JOIN
    (SELECT v.tipo_violencia, COUNT(*) AS vitimas_nao_brancas
    FROM assistida a
    JOIN tipo_violencia v ON v.id_assistida = a.id
    WHERE a.cor_raca IN ('PRETA', 'PARDA', 'INDÍGENA', 'AMARELA/ORIENTAL')
    GROUP BY v.tipo_violencia) AS nbrancas 
ON brancas.tipo_violencia = nbrancas.tipo_violencia
ORDER BY vitimas_nao_brancas DESC;

----Criação de Usuário: AdministradorBD
CREATE USER admin_procuradoria WITH PASSWORD 'admin1234';

----Concessão de Permissões ao Usuário AdministradorBD
GRANT CONNECT ON DATABASE pem_ocara TO admin_procuradoria;
GRANT USAGE ON SCHEMA public TO admin_procuradoria;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO admin_procuradoria;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO admin_procuradoria;

----Criação de Usuário: FuncionarioBD
CREATE USER funcionario_procuradoria WITH PASSWORD 'funcionario1234';

----Concessão de Permissões ao Usuário FuncionarioBD
GRANT CONNECT ON DATABASE pem_ocara TO funcionario_procuradoria;
GRANT USAGE ON SCHEMA public TO funcionario_procuradoria;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO funcionario_procuradoria;

----Revogação de Permissões Desnecessárias do Usuário FuncionarioBD
REVOKE SELECT ON endereco FROM funcionario_procuradoria;

